library TrapDbgLib;

uses
  SysUtils,
  Windows,
  Classes,
  TlHelp32,
  SyncObjs,
  ImportUnit in 'ImportUnit.pas',
  GetCodeAreaList in 'GetCodeAreaList.pas', math;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////  

const
  REPORT_BREAK_START = 1;
  REPORT_BREAK_DATA = 2;
  REPORT_BREAK_END = 3;
  REPORT_FUNCTION_MAP = 4;
                              

var
  DbgIpcServer, DbgEvent: String;
  hIpcServer: THandle;
  lpvReserved: PPointer;




function IsRetCode (Addr: Pointer): BOOL;
var
  RetSign: PByte absolute Addr;
begin
  Result := RetSign^ in [$C2,$C3,$CA,$CB];
end;

function AddCodeStrToList (List: TList; Address: Pointer): LPTCodeInfos;
var
  CodeInfos: LPTCodeInfos;
begin
  Result := nil;
  CodeInfos := GetCodeDisAsm (Address);
  if CodeInfos = nil then Exit;
  Result := AllocMem (SizeOf(TCodeInfos));
  CopyMemory (Result, CodeInfos, SizeOf(TCodeInfos));
  List.Add(Result);
end;

procedure Srv_GetCodeDisAsm (hServer, hClient: THandle; Buffer: LPTMemBlock; Size: Integer); Stdcall;
var
  CodeInfos: LPTCodeInfos;
  RetList: TList;
  CodeLen, HandleLen, AllocSize: Integer;
  IterAddr, AllocBase: Pointer;
  IterCodeInfos: LPTCodeInfos;
begin
  RetList := TList.Create;

  IterAddr := Buffer.Address;
  HandleLen := 0;

  if Buffer.Size > 0 then
  begin
    while HandleLen < Buffer.Size do
    begin
      CodeInfos := AddCodeStrToList (RetList, IterAddr);
      if CodeInfos = nil then break;
      CodeLen := Integer(CodeInfos.Next) - Integer(CodeInfos.This);
      Inc (HandleLen, CodeLen);
      IterAddr := CodeInfos.Next;
    end;
  end else
  if Buffer.Size = -1 then
  begin
    Repeat
      CodeInfos := AddCodeStrToList (RetList, IterAddr);
      if CodeInfos = nil then break;
      if IsRetCode (IterAddr) then Break;      
      IterAddr := CodeInfos.Next;
    until False;
  end else
  begin
    AddCodeStrToList (RetList, IterAddr);
  end;

  AllocSize := (RetList.Count + 1) * SizeOf (TCodeInfos);
  AllocBase := AllocMem (AllocSize);
  IterCodeInfos := AllocBase;
  
  for CodeInfos in RetList do
  begin
    IterCodeInfos^ := CodeInfos^;
    FreeMem (CodeInfos);
    Inc (IterCodeInfos);
  end;
  RetList.Free;

  IterCodeInfos.This := nil;
  IterCodeInfos.Next := nil;

  EchoIpcCommand (hClient, AllocBase, AllocSize);
  FreeMem (AllocBase);    
end;

procedure Srv_GetFuncDisAsm (hServer, hClient: THandle; Buffer: LPTMemBlock; Size: Integer); Stdcall;
var
  FuncInfos: LPTFuncInfos;
  NullSample: TFuncInfos;
begin
  FuncInfos := GetFuncDisAsm (Buffer.Address);
  if Assigned (FuncInfos) then
  begin
    EchoIpcCommand (hClient, FuncInfos, FuncInfos.Size);
  end else
  begin
    NullSample.Size := 0;
    NullSample.CodeBegin := nil;
    EchoIpcCommand (hClient, @NullSample, SizeOf(TFuncInfos));
  end;
end;


procedure Srv_GetMemBuffer (hServer, hClient: THandle; Buffer: LPTMemBuffer; Size: Integer); Stdcall;
var
  ToRead: LPTMemBuffer;
  ReplySize: Integer;
begin                 
  if IsBadReadPtr (Buffer.Address, Buffer.BuffSize) then
  begin
    ReplySize := SizeOf(TMemBuffer);
    ToRead := AllocMem (ReplySize);
    ToRead.Address := Buffer.Address;
    ToRead.BuffSize := 0;
  end else
  begin
    ReplySize := SizeOf(TMemBuffer) + Buffer.BuffSize;
    ToRead := AllocMem (ReplySize);
    ToRead.Address := Buffer.Address;
    ToRead.BuffSize := Buffer.BuffSize;
    CopyMemory (@ToRead.Buffer[0], Buffer.Address, Buffer.BuffSize);
  end;

  EchoIpcCommand (hClient, ToRead, ReplySize);
  FreeMem (ToRead);
end;

procedure Srv_GetModuleList (hServer, hClient: THandle; Buffer: Pointer; Size: Integer); Stdcall;
var
  hModuleSnap: THandle;
  me32: MODULEENTRY32;
  ModuleList: TStringList;
begin
  ZeroMemory(@me32, sizeof(MODULEENTRY32));
  me32.dwSize := sizeof(MODULEENTRY32);
  ModuleList := TStringList.Create;
  ModuleList.Add('$00000000 = AllModules');

  hModuleSnap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessID);
  if Module32First (hModuleSnap, me32) then
  repeat
    ModuleList.Add('$'+ IntToHex(me32.hModule, 8) + ' = ' + me32.szExePath);
  until not Module32Next (hModuleSnap,me32);
  CloseHandle (hModuleSnap);

  EchoIpcCommand (hClient, @ModuleList.Text[1], Length(ModuleList.Text) + 1);
  ModuleList.Free;
end;

procedure Srv_GetModuleNodes (hServer, hClient: THandle; Buffer: Pointer; Size: Integer); Stdcall;
var
  Nodes: LPTFlatNodeLst;
  Image: THandle;
begin
  Image := PDWORD(Buffer)^;

  Nodes := GetImageFlatNodeLst (Image);
  if not Assigned (Nodes) then
  begin
    GetMem (Nodes, SizeOf(TFlatNodeLst));
    Nodes.Size := SizeOf(TFlatNodeLst);
    Nodes.Count := 0;
  end;

  EchoIpcCommand (hClient, Nodes, Nodes.Size);
  FreeMem (Nodes);
end;

Procedure ReplyResult (hClient: THandle; RetResult: DWORD); overload;
begin
  EchoIpcCommand (hClient, @RetResult, SizeOf(RetResult));
end;

Procedure ReplyResult (hClient: THandle; RetResult: BOOL); overload;
begin
  EchoIpcCommand (hClient, @RetResult, SizeOf(RetResult));
end;

procedure Srv_SetMemBuffer (hServer, hClient: THandle; ToWrite: LPTMemBuffer; Size: Integer); Stdcall;
begin
  ReplyResult (hClient, WriteMemory (ToWrite.Address, @ToWrite.Buffer[0], ToWrite.BuffSize));
end;

Procedure ReportData (Buffer: Pointer; Size: Integer);
begin
  SendMsgToServer (PChar(DbgEvent), Buffer, Size);
end;


Procedure ReportBreakStart (hTrap: THandle; Start: Pointer);
var
  BreakStart: TBreakStart;
begin
  BreakStart.Report.ReportType := REPORT_BREAK_START;
  BreakStart.Report.hAimHandle := hTrap;
  BreakStart.Start := Start;
  ReportData (@BreakStart, SizeOf(TBreakStart));
end;

Procedure ReportBreakEnd (hTrap: THandle);
var
  Report: TBreakEnd;
begin
  Report.ReportType := REPORT_BREAK_END;
  Report.hAimHandle := hTrap;
  ReportData (@Report, SizeOf(TReport));
end;


function GetStackBase: Pointer;
asm
  mov eax,fs:[4]
end;

function GetStackLimit: Pointer;
asm
  mov eax,fs:[8]
end;

Procedure InfoCallback (hTrap: THandle; EIP: Pointer; RegInfo: LPTRegister; DisAsm: PChar); Stdcall;
var
  BreakData: TBreakDetail;
  AsmSize: Integer;
begin
  BreakData.Report.ReportType := REPORT_BREAK_DATA;
  BreakData.Report.hAimHandle := hTrap;
  BreakData.EIP := EIP;
  BreakData.StackBase := GetStackBase;
  BreakData.StackLimit := GetStackLimit;
  BreakData.RegInfoReal := Pointer(RegInfo);
  BreakData.RegInfo := RegInfo^;
  AsmSize := StrLen (DisAsm);
  CopyMemory(@BreakData.DisAsm[0], DisAsm, AsmSize);
  BreakData.DisAsm[AsmSize] := #0;
  ReportData (@BreakData, SizeOf(TBreakDetail));
  TrapDbgWait (hTrap);
end;                         

procedure Srv_TrapDbgSetup (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
var
  hTrap: THandle;
  Start: Pointer;
begin
  Start := PPointer(@Buffer[0])^;
  hTrap := TrapDbgSetup (Start, @InfoCallback, PBOOL(@Buffer[4])^);
  ReplyResult (hClient, hTrap);
  if hTrap > 0 then
    ReportBreakStart (hTrap, Start);
end;

procedure Srv_TrapDbgStepInto (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin
  ReplyResult (hClient, TrapDbgStepInto (PDWORD(Buffer)^, False));
end;

procedure Srv_TrapDbgStepOver (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin
  ReplyResult (hClient, TrapDbgStepOver (PDWORD(Buffer)^, False));
end;

procedure Srv_TrapDbgRunUntilRet (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin
  ReplyResult (hClient, TrapDbgRunUntilRet (PDWORD(Buffer)^));
end;

procedure Srv_TrapDbgRunUntilAddr (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin
  ReplyResult (hClient, TrapDbgRunUntilAddr (PDWORD(Buffer)^, PPointer(@Buffer[4])^));
end;

procedure Srv_TrapDbgRelease (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin          
  ReplyResult (hClient, TrapDbgRelease (PDWORD(Buffer)^));
  ReportBreakEnd (PDWORD(Buffer)^);
end;

function RunNakeCodeThread (Entry: Pointer): Integer; stdcall;
var
  ToRunFunc: function (): Integer; Stdcall;
begin
  @ToRunFunc := Entry;
  Result := ToRunFunc;
end;

procedure Srv_RunNakedCode (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
var
  EntryBase: Pointer;     
  ExitCode: DWORD;
  Tid: DWORD;
  ExecThread: THandle;
begin
  ExitCode := 0;
  EntryBase := VirtualAlloc(nil, Size, MEM_COMMIT,PAGE_EXECUTE_READWRITE);
  if Assigned (EntryBase) then
  begin
    CopyMemory (EntryBase, Buffer, Size);
    ExecThread := CreateThread (nil, 0, @RunNakeCodeThread, EntryBase, 0, tid);
    WaitForSingleObject (ExecThread, 30*1000);
    GetExitCodeThread(ExecThread,  ExitCode);
    VirtualFree (EntryBase, 0, MEM_RELEASE);
  end;
  ReplyResult (hClient, ExitCode);
end;

Type
  LPTSectionInfo = ^TSectionInfo;
  TSectionInfo = packed record
    CodeBase: Pointer;
    CodeSize: Integer;
  end;

procedure DataSectionCallback (List: TList; CodeBase: Pointer; CodeSize: Integer); Stdcall;
var
  SectionInfo: LPTSectionInfo;
begin
  New (SectionInfo);
  SectionInfo.CodeBase := CodeBase;
  SectionInfo.CodeSize := CodeSize;
  List.Add(SectionInfo);
end;

procedure Srv_GetDataSectionMemory (hServer, hClient: THandle; Image: PHandle; Size: Integer); Stdcall;
var
  List: TList;
  SectionInfo, IterSection: LPTSectionInfo;
  ReplySize: Integer;
  AimHandle: THandle;
  SectionMM: Pointer;
begin
  AimHandle := Image^;
  if AimHandle = 0 then
    AimHandle := GetModuleHandle (nil);
  IterSection := nil;
  ReplySize := 0;

  //获取具有写入属性的节段
  List := TList.Create;
  SectionMM := nil;
  if GetDataSectionMemory (AimHandle, @DataSectionCallback, List) then
  begin
    ReplySize := (List.Count + 1) * SizeOf(TSectionInfo);
    SectionMM := AllocMem (ReplySize);
    IterSection := SectionMM;
    for SectionInfo in List do
    begin
      IterSection^ := SectionInfo^;
      Inc (IterSection);
      Dispose (SectionInfo);
    end;
  end;
  List.Free;

  if Assigned (SectionMM) then
  begin
    EchoIpcCommand (hClient, SectionMM, ReplySize);
    FreeMem (IterSection);
  end;                
end;


Procedure HandleLogic;
begin
  DbgIpcServer := StrPas(GetConfig ('DbgIpcServer'));
  DbgEvent := StrPas(GetConfig ('DbgEvent'));
  if (DbgIpcServer = '') or (DbgEvent = '') then
  begin
    OnMsgError ('DbgIpcServer or DbgEvent is null.');
    Exit;
  end;

  hIpcServer := CreateIpcServer (PChar(DbgIpcServer));
  if hIpcServer = 0 then
  begin
    OnMsgError ('CreateMsgServer failure.');
    Exit;
  end;                        

  AddIpcCommand (hIpcServer, 'GetModuleList', @Srv_GetModuleList);
  AddIpcCommand (hIpcServer, 'GetModuleNodes', @Srv_GetModuleNodes);

  AddIpcCommand (hIpcServer, 'GetCodeDisAsm', @Srv_GetCodeDisAsm);
  AddIpcCommand (hIpcServer, 'GetFuncDisAsm', @Srv_GetFuncDisAsm);
  AddIpcCommand (hIpcServer, 'GetMemBuffer', @Srv_GetMemBuffer);
  AddIpcCommand (hIpcServer, 'SetMemBuffer', @Srv_SetMemBuffer);
  AddIpcCommand (hIpcServer, 'RunNakedCode', @Srv_RunNakedCode);

  AddIpcCommand (hIpcServer, 'GetDataSectionMemory', @Srv_GetDataSectionMemory);

  AddIpcCommand (hIpcServer, 'TrapDbgSetup', @Srv_TrapDbgSetup);
  AddIpcCommand (hIpcServer, 'TrapDbgStepInto', @Srv_TrapDbgStepInto);
  AddIpcCommand (hIpcServer, 'TrapDbgStepOver', @Srv_TrapDbgStepOver);
  AddIpcCommand (hIpcServer, 'TrapDbgRunUntilRet', @Srv_TrapDbgRunUntilRet);
  AddIpcCommand (hIpcServer, 'TrapDbgRunUntilAddr', @Srv_TrapDbgRunUntilAddr);
  AddIpcCommand (hIpcServer, 'TrapDbgRelease', @Srv_TrapDbgRelease);
end;


Procedure EndLogic;
begin
  if hIpcServer > 0 then
  begin
    DestroyIpcServer (hIpcServer);
    hIpcServer := 0;
  end;
end;

////////////////////////////////////////////////////////////////////////////////  

Function GetReservedParam: Pointer; Register;
asm
  mov eax,[ebp+16]       //[ebp+16] lpvReserved
end;

procedure DLLEntryPoint(dwReason : DWord);
begin
  case dwReason of
    DLL_PROCESS_ATTACH:
    begin
      ImportLib (lpvReserved^);
      HandleLogic;  
      OnMsgLog ('TrapDbgLib Initial Succeed.');
    end;
    DLL_PROCESS_DETACH: EndLogic;
  end;
end;

begin
  lpvReserved := GetReservedParam;
  if Assigned (lpvReserved) then
  if Assigned (lpvReserved^) then
  begin
    DLLProc := @DLLEntryPoint;
    DLLEntryPoint(DLL_PROCESS_ATTACH);
  end;
end.
