unit CodeProxy;

interface

uses Windows, Classes, SysUtils, SyncObjs;

const
  DEFAULT_INJECT_TIMEOUT = 18*1000;
  DEFAULT_MAP_SIZE = $1000 * $100 * 2;
  DEFAULT_SPY_TIMEOUT = 1000 * 10;

function DirverInitial (MapSize: DWORD = DEFAULT_MAP_SIZE;
                        SpyTimeOut: DWORD = DEFAULT_SPY_TIMEOUT): BOOL;

function _AddSubDLL (ImageBase: Pointer; ImageSize: DWORD): BOOL; stdcall;
function _AddMainDLL (ImageBase: Pointer; ImageSize: DWORD; ParmaBase: Pointer; ParmaSize: DWORD): BOOL; STDCALL;
function _InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD): THandle; Stdcall;
function _ScanInjectThem (AppCmdLines: TStringList; TimeOut: DWORD): BOOL; Stdcall;


function AddMainDLL (Image: TMemoryStream; ParmaStr: WideString): BOOL; STDCALL; overload;
function AddSubDLL (Image: TMemoryStream): BOOL; stdcall; overload;
function InjectThemALL (AppCmdLine: String; TimeOut: DWORD; WaitExit: BOOL): BOOL; Stdcall; Overload;


function GetMappedProcessName (dwProcessId: DWORD; var ProcName: String): BOOL;
function AcquireNotifyEvent (var Event: TEvent): BOOL;
function AcqureSyncModeEvent (ProceID: DWORD; var Event: TEvent): BOOL;

function TestMakeSpyCode (out CodeBase: Pointer; out CodeSize: DWORD): LongBool;
function PushProxyCodeTo (ProcHandle: THandle; MapName: String; CodeBase: Pointer; CodeSize: Integer; TimeOut: DWORD): BOOL;
function MakeSpyProxyCode (var CodeBase: Pointer; var CodeSize: Integer): BOOL;

implementation

uses
  dll2funcUnit, SpyMemCode, RelocFuncUnit, GlobalType, PEHead,RunAsUserUnit,
  DrvRunUnit, tlhelp32, DropMyRights;


const
  DEFAULT_MAP_HEAD = 'Global\XXXSpyMapName_';
  DEFAULT_EVENT_HEAD = 'Global\XXXSpyEventName_';
  DEFAULT_EVENT_TAIL = '_ResultEvent';
  DEFAULT_DEBUG_HEAD = 'SpyCodeError = ';
  DEFAULT_SCAN_NOFITY_EVENT = 'Global\NotifyEventForScaner';
  DEFAULT_YOU_ARE_SYNC_MODE = 'Global\NofityEventForSyncMode_';


function AcqureSyncModeEvent (ProceID: DWORD; var Event: TEvent): BOOL;
var
  EventName: String;
begin
  Result := False;
  EventName := DEFAULT_YOU_ARE_SYNC_MODE + IntToStr(ProceID);

  Event := TEvent.Create(nil, False, False, EventName);
  Repeat
    if Event.Handle = 0 then break;
    if GetLastError = ERROR_ALREADY_EXISTS then break;
    Result := True;
    Exit;
  until True;
  FreeAndNil (Event);
end;

function AcquireNotifyEvent (var Event: TEvent): BOOL;
begin
  Result := False;

  Event := TEvent.Create(nil, False, False, DEFAULT_SCAN_NOFITY_EVENT);
  Repeat
    if Event.Handle = 0 then break;
    if GetLastError = ERROR_ALREADY_EXISTS then break;
    Result := True;
    Exit;
  until True;
  FreeAndNil (Event);
end;


function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;


function GetAppExeFromCmdLine (CmdLine: String): String;
var
  ExtStr: String;
  ExtSL: TStringList;
begin
  Result := '';
  if Length (CmdLine) < 7 then exit;

  ExtStr := ExtractFileExt (CmdLine);
  if Length (ExtStr) < 2 then exit;

  Result := Copy (CmdLine, 1, Length(CmdLine) - Length(ExtStr));

  ExtSL := GetSplitBlankList (ExtStr);
  ExtStr := ExtSL[0];
  Result := Result + ExtStr;
end;

function MakeProceList: TList;
var
  hSnapshot: THandle;
  pe: PROCESSENTRY32;
  bOk: BOOL;
begin
  Result := TList.Create;
  pe.dwSize := sizeof(PROCESSENTRY32);
  hSnapshot := CreateToolhelp32Snapshot (TH32CS_SNAPPROCESS,0);
                       
  bOk := Process32First(hSnapshot,pe);
  while bOk do
  begin
    Result.Add(Pointer(PE.th32ProcessID));
    bOk := Process32Next(hSnapshot,pe);
  end;
  CloseHandle (hSnapshot);
end;

function GetNewProcess (var PreProcList: TList): TList;
var
  NewProcList: TList;
  Index: Integer;
  Item: Pointer;
begin
  Result := TList.Create;
  NewProcList := MakeProceList;

  for Index := 0 to NewProcList.Count - 1 do
  begin
    Item := NewProcList.Items[Index];
    if PreProcList.IndexOf(Item) = -1 then
      Result.Add(Item);
  end;
  PreProcList.Free;
  PreProcList := NewProcList;
end;                    

var
  IsScanning: BOOL;
  BreakScan: BOOL;
  FAppCmdLineSL: TStringList;
  FTimeOut: DWORD;
  FNotifyEvent: TEvent;

Procedure WaitNewProcessThread (Param: Pointer); Stdcall;
var
  WaitResult: TWaitResult;
  PreProcList, NewCreates: TList;
  Item: Pointer;
  ItemStr, AimProcName, MapName: String;
  TargetSL: TStringList;
  CodeBase: Pointer;
  CodeSize: Integer;
begin
  if not MakeSpyProxyCode (CodeBase, CodeSize) then
  begin
    IsScanning := False;
    Exit;
  end;
  
  TargetSL := TStringList.Create;
  for ItemStr in FAppCmdLineSL do
  begin
    AimProcName := GetAppExeFromCmdLine (ItemStr);
    AimProcName := UpperCase(AimProcName);
    TargetSL.Add(AimProcName);
  end;

  PreProcList := MakeProceList;

  Repeat
    WaitResult := FNotifyEvent.WaitFor(100);
    case WaitResult of
      wrSignaled: begin

        NewCreates := GetNewProcess (PreProcList);
        for Item in NewCreates do
          if GetMappedProcessName (DWORD(Item), AimProcName) then
          begin
            MapName := DEFAULT_MAP_HEAD + IntToStr(DWORD(Item));
            AimProcName := UpperCase(AimProcName);
            if TargetSL.IndexOf(AimProcName) >= 0 then
              if not PushProxyCodeTo (0, MapName, CodeBase, CodeSize, FTimeOut) then
                OutputDebugString ('扫描到目标进程，但注射失败！');
          end;
        NewCreates.Free;

      end;
      wrTimeout: if BreakScan then Break;
    end;
  until WaitResult in [wrAbandoned, wrError];

  if Assigned (CodeBase) then
    FreeMem (CodeBase);
      
  TargetSL.Free;
  PreProcList.Free;       
  IsScanning := False;
end;


function _ScanInjectThem (AppCmdLines: TStringList; TimeOut: DWORD): BOOL; Stdcall;
var
  tid: dword;
  hThread: THandle;
begin
  Result := False;

  if Assigned (AppCmdLines) then
  begin
    if AppCmdLines.Count > 0 then
      if not IsScanning then
        if AcquireNotifyEvent (FNotifyEvent) then
        begin
          IsScanning := True;

          if not Assigned (FAppCmdLineSL) then
            FAppCmdLineSL := TStringList.Create;
          FAppCmdLineSL.Clear;
          FAppCmdLineSL.AddStrings(AppCmdLines);
          FTimeOut := TimeOut;
          BreakScan := False;
          hThread := CreateThread (nil, 0, @WaitNewProcessThread, nil, 0, tid);
          CloseHandle (hThread);
          Result := True;
        end;

  end else
  begin
    BreakScan := True;
    while IsScanning do
      Sleep(100);
    FNotifyEvent.Free;
  end;
end;



//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 关键可复制代码
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


Type
  LPTParamFromLead = ^TParamFromLead;
  TParamFromLead = packed record
    hKernel32: THandle;
    fnLoadLibrary: Pointer;
    SyncMode: BOOL;
    GetProcAddress: function (hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall;
    OutputDebugStringA: procedure (lpOutputString: PAnsiChar); stdcall;
    VirtualAlloc: function (lpvAddress: Pointer; dwSize, flAllocationType, flProtect: DWORD): Pointer; stdcall;
    VirtualFree: function (lpAddress: Pointer; dwSize, dwFreeType: DWORD): BOOL; stdcall;
    CreateThread: function (lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: TFNThreadStartRoutine; lpParameter: Pointer; dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle; stdcall;
    ExitThread: procedure (dwExitCode: DWORD); stdcall;
    OpenEventA: function (dwDesiredAccess: DWORD; bInheritHandle: BOOL; lpName: PAnsiChar): THandle; stdcall;
    CloseHandle: function (hObject: THandle): BOOL; stdcall;
    GetCurrentProcessId: function () : DWORD; stdcall;
  end;

  LPTParamFromMain = ^TParamFromMain;
  TParamFromMain = packed record
    MapSize: Integer;
    SpyTimeOut: DWORD;
  end;

  LPTFunctionTable = ^TFunctionTable;
  TFunctionTable = packed record
    GetKernel32Base: function: Pointer;
    PrintError: Procedure (Error: DWORD);
    CopyMemory: procedure (Dest: Pointer; Source: Pointer; count : Integer);
    GetFileNameA: function (FileName: PChar): PChar;
    StrCopy: function (Dest: PChar; const Source: PChar): PChar;
    StrLen: function (const Str: PChar): Cardinal;
    StrEnd: function (const Str: PChar): PChar; 
    LongIntToStr: procedure (N: DWORD; var Dist);
    FillChar: procedure (var Dest; count : Integer; Value : Char);
    ClearExit: function (Base: Pointer; ExitCode: DWORD): Integer;
  end;

  LPTStringTable = ^TStringTable;
  TStringTable = packed record
    sOutputDebugStringA,
    sVirtualAlloc,
    sCreateThread,
    sGetCurrentProcessId,
    sGetModuleFileNameA,
    sMapNameHead,
    sEventNameHead,
    sVirtualFree,
    sExitThread,
    sCreateFileMappingA,
    sMapViewOfFile,
    sUnmapViewOfFile,
    sCloseHandle,
    sCreateEventA,
    sWaitForSingleObject,
    sGetTickCount,
    sGetCurrentThreadId,
    sDebugHead,
    sGetLastError,
    sResultEventExt,
    sScanNotifyName,
    sOpenEventA,
    sSetEvent,
    sYouAreSyncMode,
    sNull: PChar;
  end;

  LPTResourceTable = ^TResourceTable;
  TResourceTable = Packed record
    FunctionTable: TFunctionTable;
    StringTable: TStringTable;
  end;
                      
  LPTBuildinDataStru = ^TBuildinDataStru;
  TBuildinDataStru = packed record
    SIGN: Array[0..3] of char;
    Size: Integer;
    ParamFromLead: TParamFromLead;
    ParamFromMain: TParamFromMain;
    ResourceTable: TResourceTable;
    DaemonEntry: Array[0..0] of char;
  end;

//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 关键可复制代码
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


procedure CopyMemory(Dest: Pointer; Source: Pointer; count : Integer);
var
  S: PChar absolute Source;
  D: PChar absolute Dest;
  I: Integer;
begin                               
  if S = D then Exit;
  if Cardinal(D) > Cardinal(S) then
    for I := count-1 downto 0 do
      D[I] := S[I]
  else
    for I := 0 to count-1 do
      D[I] := S[I];
end;
procedure CopyMemory_End; begin end;


procedure LongIntToStr(N: DWORD; var Dist);
var
  m, Len, I, K: DWORD;
  D: PChar;
  BufA: Array[0..15] of char;
begin
  D := @Dist;
  Len := 0;
  While N div 10 > 0 do
  begin
    m := N mod 10;
    BufA[Len] := Char(m + Ord('0'));
    N := N div 10;
    inc(Len);
  end;
  m := N mod 10;
  BufA[Len] := Char(m + Ord('0'));
  inc(Len);
  BufA[Len] := #0;

  K := 0;
  for I := Len - 1 downto 0 do
  begin
    D[K] := BufA[I];
    INC(K);
  end;
  D[K] := #0;
end;
procedure LongIntToStr_end; begin end;


function GetKernel32Base: Pointer;
var
  m_Peb   :PPeb;
  ListEntry :PListEntry;
begin
  asm
    mov eax,fs:[$30]
    mov m_Peb, eax
  end;
  ListEntry := m_Peb.Ldr.InInitializationOrderModuleList.Flink.Flink;
  result := PPointer ( DWORD(ListEntry) + SizeOf(TListEntry))^;
end;
procedure GetKernel32Base_End; begin end;


Procedure PrintError (Error: DWORD);
var
  BuildinData: LPTBuildinDataStru;
  Buffer: Array[0..47] of char;
  MeBase: Pointer;
begin
  //查找本代码块的头
  asm
    call @Next
  @Next:
    pop MeBase
  end;
  
  Repeat
    Dec (PChar(MeBase));
  until PDWORD(MeBase)^ = $45504D55;     
  BuildinData := MeBase;

  With BuildinData.ResourceTable do
  begin
    FunctionTable.FillChar(Buffer, Length(Buffer), #0);
    FunctionTable.StrCopy (Buffer, StringTable.sDebugHead);
    FunctionTable.LongIntToStr (Error, FunctionTable.StrEnd(Buffer)[0]);
  end;
  BuildinData.ParamFromLead.OutputDebugStringA (Buffer);
end;
Procedure PrintError_end; begin end;


function StrCopy(Dest: PChar; const Source: PChar): PChar;
var
  I: Integer;
begin
  I := 0;
  Repeat
    Dest[I] := Source[I];
    Inc (I);
  until Source[I] = #0;
  Result := Dest;
end;
procedure StrCopy_end; begin end;


function StrLen(const Str: PChar): Cardinal;
asm
        MOV     EDX,EDI
        MOV     EDI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        MOV     EAX,0FFFFFFFEH
        SUB     EAX,ECX
        MOV     EDI,EDX
end;
procedure StrLen_end; begin end;

function StrEnd(const Str: PChar): PChar;
asm
        MOV     EDX,EDI
        MOV     EDI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        LEA     EAX,[EDI-1]
        MOV     EDI,EDX
end;
procedure StrEnd_end; begin end;

procedure FillChar (var Dest; count : Integer; Value : Char);
var
  I   : Integer;
  P   : PChar;
begin
  P := PChar(@Dest);
  for I := count - 1 downto 0 do
    P[I] := Value;
end;
procedure FillChar_End;begin end;

function GetFileNameA (FileName: PChar): PChar;
begin
  Result := FileName;
  Repeat
    inc (FileName);
    if (FileName^ = '\') or (FileName^ = ':') then
      Result := @FileName[1];
  until FileName^ = #0;         
end;
procedure GetFileNameA_end; begin end;

type
  TClearExit= function (Base: Pointer; ExitCode: DWORD): Integer;

procedure ClearExit_End; forward;
function ClearExit (Base: Pointer; ExitCode: DWORD): Integer;
var
  BuildinData: LPTBuildinDataStru absolute Base;
  ExitThread: procedure (dwExitCode: DWORD); stdcall;
begin
  Result := Integer(@ClearExit_End) - Integer (@ClearExit);
  if Base = nil then Exit;

  @ExitThread := @BuildinData.ParamFromLead.ExitThread;
  BuildinData.ParamFromLead.VirtualFree (Base, 0, MEM_RELEASE);
  ExitThread (ExitCode);
end;
procedure ClearExit_End; begin end;
                                      

//守护代码
Function DaemonCodeThread (Param: Pointer): DWORD; Stdcall;
var
  GetModuleFileNameA: function (hModule: HINST; lpFilename: PAnsiChar; nSize: DWORD): DWORD; stdcall;
  CreateFileMappingA: function (hFile: THandle; lpFileMappingAttributes: PSecurityAttributes; flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName: PAnsiChar): THandle; stdcall;
  MapViewOfFile: function (hFileMappingObject: THandle; dwDesiredAccess: DWORD; dwFileOffsetHigh, dwFileOffsetLow, dwNumberOfBytesToMap: DWORD): Pointer; stdcall;
  UnmapViewOfFile: function (lpBaseAddress: Pointer): BOOL; stdcall;
  CreateEventA: function (lpEventAttributes: PSecurityAttributes; bManualReset, bInitialState: BOOL; lpName: PAnsiChar): THandle; stdcall;
  WaitForSingleObject: function (hHandle: THandle; dwMilliseconds: DWORD): DWORD; stdcall;
  GetTickCount: function : DWORD; stdcall;
  ThreadEntry: Function (Param: Pointer): DWORD; Stdcall;
  GetLastError: function : DWORD; stdcall;
  SetEvent: function (hEvent: THandle): BOOL; stdcall;
var
  BuildinData: LPTBuildinDataStru absolute Param;
  FTbl: LPTFunctionTable;
  STbl: LPTStringTable;
  LTbl: LPTParamFromLead;
  Main: LPTParamFromMain;
  Buffer :array[Byte] of char;
  AimBuffer :array[Byte] of char;
  TimePass, ErrorCode, WaitRet, TickCount: DWORD;
  AimName, ResultEventName, EntryBase: PChar;
  SpyCodeEntry: Pointer;
  CopyLen: Integer;
  FMapHandle, EventHandle, EvtResult: THandle;
  SpyMemData: LPTSpyMemCodeData;
begin
  Result := 0;
  FTbl := @BuildinData.ResourceTable.FunctionTable;
  STbl := @BuildinData.ResourceTable.StringTable;
  LTbl := @BuildinData.ParamFromLead;
  Main := @BuildinData.ParamFromMain;
  
  FMapHandle := 0;
  SpyMemData := nil;
  EventHandle := 0;

  Repeat
    //从定位关键函数
    With LTbl^ do begin
      With STbl^ do begin
        @GetModuleFileNameA := GetProcAddress (hKernel32, sGetModuleFileNameA);
        @CreateFileMappingA := GetProcAddress (hKernel32, sCreateFileMappingA);
        @MapViewOfFile := GetProcAddress (hKernel32, sMapViewOfFile);
        @UnmapViewOfFile := GetProcAddress (hKernel32, sUnmapViewOfFile);
        @CreateEventA := GetProcAddress (hKernel32, sCreateEventA);
        @WaitForSingleObject := GetProcAddress (hKernel32, sWaitForSingleObject);
        @GetTickCount := GetProcAddress (hKernel32, sGetTickCount);
        @GetLastError := GetProcAddress (hKernel32, sGetLastError);
        @SetEvent := GetProcAddress (hKernel32, sSetEvent);
      end;
    end;

    Repeat
      ErrorCode := 30002; if @GetModuleFileNameA  = NIL then Break;
      ErrorCode := 30003; if @CreateFileMappingA  = NIL then Break;
      ErrorCode := 30004; if @MapViewOfFile  = NIL then Break;
      ErrorCode := 30005; if @UnmapViewOfFile  = NIL then Break;
      ErrorCode := 30007; if @CreateEventA  = NIL then Break;
      ErrorCode := 30008; if @WaitForSingleObject  = NIL then Break;
      ErrorCode := 30009; if @GetTickCount = NIL then Break;
      ErrorCode := 30010; if @GetCurrentThreadId  = NIL then Break;
      ErrorCode := 30011; if @GetLastError  = NIL then Break;
      ErrorCode := 30013; if @SetEvent  = NIL then Break;
      ErrorCode := 0;
    until True;
    if ErrorCode <> 0 then Break;

    //构造内存映射文件名样式 Game.exe_3342
    FTbl.LongIntToStr (LTbl.GetCurrentProcessId, Buffer);  //追加进程ID

    //内存映射文件名  SpyMapName_3342
    FTbl.FillChar (AimBuffer, SizeOf(AimBuffer), #0);
    FTbl.StrCopy (AimBuffer, STbl.sMapNameHead);  //填入默认头名
    FTbl.StrCopy (FTbl.StrEnd(AimBuffer), Buffer);

    //事件名 EventName_3342_2353434
    AimName := FTbl.StrEnd(AimBuffer);
    Inc (AimName);
    FTbl.StrCopy (AimName, STbl.sEventNameHead);  //填入默认头名
    FTbl.StrCopy (FTbl.StrEnd(AimName), Buffer);
    FTbl.StrEnd(AimName)^ := '_';
    FTbl.LongIntToStr (GetTickCount, FTbl.StrEnd(AimName)^);  //追加随机串

    //返回结果事件名EventName_3342_2353434_ResultEvent
    ResultEventName := FTbl.StrEnd(AimName);
    Inc (ResultEventName);
    FTbl.StrCopy (ResultEventName, AimName);
    FTbl.StrCopy (FTbl.StrEnd(ResultEventName), STbl.sResultEventExt);     

    //打开内存映射，填入关键信息
    FMapHandle := CreateFileMappingA(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, Main.MapSize, AimBuffer);
    if FMapHandle = 0 then begin ErrorCode := 40001; Break; end;
    if ERROR_ALREADY_EXISTS = GetLastError then begin ErrorCode := 40002; Break; end;

    SpyMemData := MapViewOfFile(FMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, Main.MapSize);
    if SpyMemData = nil then begin ErrorCode := 40003; Break; end;
                                         
    //将信息填入内存映射中
    With SpyMemData^ do
    begin
      OnService := False;
      Size := Main.MapSize;

      //填入事件名称
      CopyLen := FTbl.StrLen(AimName);
      FTbl.StrCopy (@CodeBuffer[0], AimName);
      AimName := @CodeBuffer[0];
      SpyEventOffset := Integer(AimName) - Integer(SpyMemData);
      AimName[CopyLen] := #0;

      //填入进程名称
      Inc (CopyLen);
      AimName := @AimName[CopyLen];
      CopyLen := GetModuleFileNameA (0, AimName, High(Byte) - CopyLen);
      ProcessNameOffset := Integer(AimName) - Integer(SpyMemData);
      AimName[CopyLen] := #0;

      //填入代码存放偏移
      EntryBase := @AimName[CopyLen+1];
      SpyCodeOffset := Integer(EntryBase) - Integer(SpyMemData);
      SpyCodeMaxSize := Size - SpyCodeOffset;
    end;

    //创建守护等待事件
    EventHandle := CreateEventA (NIL, False, False, @SpyMemData.CodeBuffer[0]);
    if EventHandle = 0 then begin ErrorCode := 40003; Break; end;

    //准备工作
    TickCount := GetTickCount;
    SpyMemData.ServiceTimeLeft := Main.SpyTimeOut;
    EntryBase^ := #0;
    SpyMemData.OnService := True;

    //发出全局扫描事件通告
    EvtResult := LTbl.OpenEventA (EVENT_MODIFY_STATE, False, STbl.sScanNotifyName);
    if EvtResult > 0 then
    begin
      SetEvent (EvtResult);
      LTbl.CloseHandle (EvtResult);
    end;

    //等代码注入方将代码存放在内存映射区
    Repeat
      WaitRet := WaitForSingleObject (EventHandle, 1000);
      TimePass := GetTickCount - TickCount;
      case WaitRet of
        WAIT_OBJECT_0: begin  //前往执行注入的代码
          if EntryBase^ <> #0 then
          begin
            SpyCodeEntry := LTbl.VirtualAlloc(nil, SpyMemData.SpyCodeMaxSize, MEM_COMMIT,PAGE_EXECUTE_READWRITE);
            FTbl.CopyMemory (SpyCodeEntry , EntryBase, SpyMemData.SpyCodeMaxSize);
            @ThreadEntry := SpyCodeEntry;
            Result := ThreadEntry (NIL);
            LTbl.VirtualFree (SpyCodeEntry, 0, MEM_RELEASE);

            SpyMemData.RunResult := Result;

            EvtResult := LTbl.OpenEventA (EVENT_MODIFY_STATE, False, ResultEventName);
            if EvtResult > 0 then
            begin
              if not SetEvent (EvtResult) then
                 FTbl.PrintError (50001);
              if not LTbl.CloseHandle (EvtResult) then
                FTbl.PrintError (50002);
            end else
              FTbl.PrintError (50003);
            Break;
          end;
        end;
        WAIT_TIMEOUT: begin
          if TimePass >= Main.SpyTimeOut then
            SpyMemData.ServiceTimeLeft := 0
          else
            SpyMemData.ServiceTimeLeft := Main.SpyTimeOut - TimePass;
        end;
        ELSE begin ErrorCode := 50002; Break; end;
      end;
    until TimePass > Main.SpyTimeOut; //N秒超时后，将会自动退出守护状态
    SpyMemData.OnService := False;

  until True;

  //清理资源，关闭内存映射
  if EventHandle > 0 then
    if not LTbl.CloseHandle (EventHandle) then
      FTbl.PrintError (60001);

  if Assigned (SpyMemData) then
    if not UnMapViewOfFile(SpyMemData) then
      FTbl.PrintError (60002);

  if FMapHandle > 0 then
    if not LTbl.CloseHandle (FMapHandle) then
      FTbl.PrintError (60003);

  if ErrorCode > 0 then
    FTbl.PrintError (ErrorCode);

  //释放自身内存
  if not LTbl.SyncMode then
  begin
    CopyLen := FTbl.ClearExit (NIL, 0);
    EntryBase := LTbl.VirtualAlloc (nil, CopyLen, MEM_COMMIT, PAGE_EXECUTE_READWRITE);     
    FTbl.CopyMemory (EntryBase, @FTbl.ClearExit, CopyLen);
    TClearExit(EntryBase)(Param, Result);
  end;
end;

Procedure DaemonCodeThread_End;
begin
end;


function GetMappedProcessName (dwProcessId: DWORD; var ProcName: String): BOOL;
var
  MapHandle: THandle;
  SpyMemData: LPTSpyMemCodeData;
  AimName: PChar;
  MapName: String;
begin
  Result := False;
  MapName := DEFAULT_MAP_HEAD + IntToStr(dwProcessId);

  //打开内存映射
  MapHandle := OpenFileMappingA (FILE_MAP_READ, False, PChar(MapName));
  if MapHandle = 0 then Exit;

  //先取得内存映射大小
  SpyMemData := MapViewOfFile(MapHandle, FILE_MAP_READ, 0, 0, $1000);
  if SpyMemData = NIL then
  begin
    CloseHandle (MapHandle);
    Exit;
  end;

  AimName := Pointer (Integer(SpyMemData) + SpyMemData.ProcessNameOffset);
  ProcName := StrPas (AimName);
  Result := Length(ProcName) > 0;
  
  UnMapViewOfFile(SpyMemData);
  CloseHandle (MapHandle);
end;



function PushProxyCodeTo (ProcHandle: THandle; MapName: String; CodeBase: Pointer; CodeSize: Integer;
          TimeOut: DWORD): BOOL;
var
  MapHandle: THandle;
  BeginTick: DWORD;
  SpyMemData: LPTSpyMemCodeData;
  MapSize: DWORD;
  ActiveEventName: String;
  EvtHandle, EvtRetHandle: THandle;
  CodeEntry: Pointer;
  ExitCode: DWORD;
  SecurityAttribute: SECURITY_ATTRIBUTES;
  SecurityDescriptor: SECURITY_DESCRIPTOR;
  function IsTimeOut: BOOL;
  begin
    Result := GetTickCount - BeginTick > TimeOut;
  end;
begin
  Result := False;
  BeginTick := GetTickCount;

  //打开内存映射
  Repeat
    MapHandle := OpenFileMappingA (FILE_MAP_ALL_ACCESS, False, PChar(MapName));
    if MapHandle > 0 then Break;
    Sleep(100);
  until IsTimeOut;
  if MapHandle = 0 then Exit;

  //先取得内存映射大小
  MapSize := $1000;
  SpyMemData := MapViewOfFile(MapHandle, FILE_MAP_READ, 0, 0, MapSize);
  if SpyMemData = NIL then
  begin
    CloseHandle (MapHandle);
    Exit;
  end;

  //真正映射
  MapSize := SpyMemData.Size;
  UnMapViewOfFile(SpyMemData);
  SpyMemData := MapViewOfFile(MapHandle, FILE_MAP_ALL_ACCESS, 0, 0, MapSize);
  if SpyMemData = NIL then
  begin
    CloseHandle (MapHandle);
    Exit;
  end;

  //等待对方准备好
  while not SpyMemData.OnService do
  begin
    Sleep(50);
    if IsTimeOut then Break;
  end;

  if not SpyMemData.OnService  then
  begin
    UnMapViewOfFile(SpyMemData);
    CloseHandle (MapHandle);
    exit;
  end;

  ActiveEventName := StrPas(@PChar(SpyMemData)[SpyMemData.SpyEventOffset]);
  EvtHandle := OpenEvent (EVENT_MODIFY_STATE, False, PChar(ActiveEventName));
  ActiveEventName := ActiveEventName + DEFAULT_EVENT_TAIL;

  InitializeSecurityDescriptor(@SecurityDescriptor,SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDACL(@SecurityDescriptor,true,nil,false);
  SecurityAttribute.nLength := sizeof(SECURITY_ATTRIBUTES);
  SecurityAttribute.lpSecurityDescriptor := @SecurityDescriptor;
  SecurityAttribute.bInheritHandle := false;  
  EvtRetHandle := CreateEvent (@SecurityAttribute, False, False, PChar(ActiveEventName));

  if (EvtHandle > 0) and (EvtRetHandle > 0) then
  begin                       
    CodeEntry := @PChar(SpyMemData)[SpyMemData.SpyCodeOffset];
    if SpyMemData.SpyCodeMaxSize >= CodeSize then
    begin
      CopyMemory (CodeEntry, CodeBase, CodeSize);
      SetEvent (EvtHandle);

      Repeat
        if WAIT_OBJECT_0 = WaitForSingleObject (EvtRetHandle, 500) then
        begin
          Result := SpyMemData.RunResult > 0;
          Break;
        end;
        
        if ProcHandle > 0 then
          if GetExitCodeProcess (ProcHandle, ExitCode) then
            if not (ExitCode = STILL_ACTIVE) then
              break;
      until IsTimeOut;
    end;
  end;

  CloseHandle (EvtHandle);
  CloseHandle (EvtRetHandle);
  
  UnMapViewOfFile(SpyMemData);
  CloseHandle (MapHandle);
end;

Type
  TDaemonCodeThread = Function  (Param: Pointer): DWORD; Stdcall;

Procedure LeaderCode; Stdcall;
Type
  LPTRelocArray = ^TRelocArray;
  TRelocArray = Array[byte] of DWORD;
var
  BuildinData, NewBuildinData: LPTBuildinDataStru;
  TID: DWORD;
  ErrorCode: DWORD;
  RelocA: LPTRelocArray;
  Index: Integer;
  FTbl: LPTFunctionTable;
  STbl: LPTStringTable;
  LTbl: LPTParamFromLead;
  EvtResult: THandle;
  Buffer: Array[0..47] of char;
begin
  //找出内嵌的守护代码和大小
  asm
      Call @Next
    @Start:
      DD  $AAAAAAAA
      DD  $AAAAAAAA
    @Next:
      Pop  BuildinData
  end;

  //对守护代码的资源从定位
  RelocA := @BuildinData.ResourceTable;
  for Index := 0 to (SizeOf (TResourceTable) div 4) - 1 do
    Inc (RelocA[Index], Integer(BuildinData));

  FTbl := @BuildinData.ResourceTable.FunctionTable;
  STbl := @BuildinData.ResourceTable.StringTable;
  LTbl := @BuildinData.ParamFromLead;

  With LTbl^ do
  begin
    //自动从定位出关键函数
    hKernel32 := THandle(FTbl.GetKernel32Base());    
    if not GetPrimeFunction(hKernel32, @GetProcAddress, fnLoadLibrary) then exit;

    @OutputDebugStringA := GetProcAddress(hKernel32, STbl.sOutputDebugStringA);
    @OpenEventA := GetProcAddress(hKernel32, STbl.sOpenEventA);
    @CloseHandle := GetProcAddress (hKernel32, STbl.sCloseHandle);
    @GetCurrentProcessId := GetProcAddress (hKernel32, STbl.sGetCurrentProcessId);
    @VirtualAlloc := GetProcAddress(hKernel32, STbl.sVirtualAlloc);
    @VirtualFree := GetProcAddress (hKernel32, STbl.sVirtualFree);

    if @OutputDebugStringA = NIL then exit;
    if @OpenEventA = NIL THEN exit;
    if @CloseHandle = NIL THEN exit;
    if @GetCurrentProcessId = NIL THEN exit;
    if @VirtualAlloc = NIL THEN exit;
    if @VirtualFree = NIL THEN exit;
  end;

  //判断是否同步模式
  FTbl.FillChar (Buffer, SizeOf(Buffer), #0);
  FTbl.StrCopy (Buffer, STbl.sYouAreSyncMode);
  FTbl.LongIntToStr (LTbl.GetCurrentProcessId, FTbl.StrEnd(Buffer)^);

  EvtResult := LTbl.OpenEventA (EVENT_MODIFY_STATE, False, Buffer);
  if EvtResult > 0 then
  begin
    LTbl.SyncMode := True;
    LTbl.CloseHandle (EvtResult);
    TDaemonCodeThread (@BuildinData.DaemonEntry[0])(BuildinData);
    Exit;
  end;
           
  //异步模式
  With LTbl^ do
  begin
    Repeat
      @CreateThread := GetProcAddress (hKernel32, STbl.sCreateThread);
      @ExitThread := GetProcAddress (hKernel32, STbl.sExitThread);

      ErrorCode := 10012; if @CreateThread = NIL THEN Break;
      ErrorCode := 10013; if @ExitThread = NIL THEN Break;

      //分配内存，将守护代码复制过去
      NewBuildinData := VirtualAlloc(nil, BuildinData.Size, MEM_COMMIT,PAGE_EXECUTE_READWRITE);
      ErrorCode := 10004; if NewBuildinData = NIL then Break;

      FTbl.CopyMemory (NewBuildinData, BuildinData, BuildinData.Size);

      //对新复制的守护代码的资源从定位
      RelocA := @NewBuildinData.ResourceTable;
      for Index := 0 to (SizeOf (TResourceTable) div 4) - 1 do
        Inc (RelocA[Index], Integer(NewBuildinData)-Integer(BuildinData));

      //创建线程，运行守护代码
      CloseHandle(CreateThread (nil, 0, @NewBuildinData.DaemonEntry[0], NewBuildinData, 0, TID));
      ErrorCode := 10005; if TID = 0 then Break;

      Exit;
    until True;

    FTbl.PrintError (ErrorCode);
  end;
end;

Procedure LeaderCode_End;
begin
end;


//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 组装代码的函数
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

function GetCopyValue (var HeadBase: PChar; var HeadSize: Integer;
                        var SizeOffset: Integer;
                        var TailBase: PChar; var TailSize: Integer): LongBool;
var
  IterPtr: PChar;
  SampleStart, SampleEnd: Pointer;
begin
  SampleStart := @LeaderCode;
  SampleEnd   := @LeaderCode_End;

  HeadBase := SampleStart;

  Result := False;
  IterPtr := HeadBase;
  Repeat
    if PInt64(IterPtr)^ = $AAAAAAAAAAAAAAAA then
    begin
      Result := True;
      Break;
    end;
    Inc (IterPtr);
  until IterPtr = @LeaderCode_End;

  if Result then
  begin
    HeadSize := Integer(IterPtr) - Integer(HeadBase);
    SizeOffset := HeadSize - 4;
    TailBase := Pointer (Integer(HeadBase) + HeadSize + SizeOf(Int64));
    TailSize := Integer (SampleEnd) - Integer(TailBase);
  end;
end;


function MakeSpyCode (Param: TParamFromMain; out CodeBase: Pointer; out CodeSize: DWORD): LongBool;
var
  HeadBase: PChar;  HeadSize: Integer;
  SizeOffset: Integer;
  TailBase: PChar;  TailSize: Integer;
  BuildinData: TBuildinDataStru;
  CodeMM: TMemoryStream;
  BuildMM: TMemoryStream;
  BuildinDataHeadSize: Integer;
  FTbl: LPTFunctionTable;
  STbl: LPTStringTable;
  function FillFuncTable (FuncStart, FuncEnd: Pointer): Pointer;
  begin
    Result := Pointer(BuildMM.Size);
    BuildMM.WriteBuffer(FuncStart^, Integer (FuncEnd) - Integer (FuncStart));
  end;
  function FillStringTable (ResStr: String): Pointer;
  begin
    Result := Pointer(BuildMM.Size);
    ResStr := ResStr + #0;
    BuildMM.WriteBuffer(PChar(ResStr)^, Length(ResStr));
  end;
begin
  if Param.MapSize < $1000 * 100 * 1 then
     Raise Exception.Create('代码映射区不能少于1M');

  if Param.SpyTimeOut < 1000 * 5 then
     Raise Exception.Create('注入超时时间不能少于5秒');

  if Param.MapSize and $FFF > 0 then
    Param.MapSize := Param.MapSize and $FFFFF000 + $1000;

  Result := False;
  BuildMM := TMemoryStream.Create;
  BuildMM.Seek(0, soFromBeginning);

  //构造内嵌数据
  BuildinDataHeadSize := Integer(@BuildinData.DaemonEntry[0]) - Integer(@BuildinData);
  ZeroMemory (@BuildinData, SizeOf(TBuildinDataStru));
  BuildinData.SIGN := 'UMPE';
  BuildinData.ParamFromMain := Param;
  BuildMM.WriteBuffer(BuildinData, BuildinDataHeadSize);
  BuildMM.WriteBuffer(Pointer(@DaemonCodeThread)^, Integer(@DaemonCodeThread_End) - Integer(@DaemonCodeThread));
                
  //在内嵌数据里填入内置函数和函数表
  FTbl := @LPTBuildinDataStru(BuildMM.Memory).ResourceTable.FunctionTable;


  @FTbl.GetKernel32Base :=  FillFuncTable (@GetKernel32Base, @GetKernel32Base_End);
  @FTbl.PrintError :=  FillFuncTable (@PrintError, @PrintError_End);
  @FTbl.CopyMemory :=  FillFuncTable (@CopyMemory, @CopyMemory_End);
  @FTbl.GetFileNameA :=  FillFuncTable (@GetFileNameA, @GetFileNameA_End);
  @FTbl.StrCopy :=  FillFuncTable (@StrCopy, @StrCopy_End);
  @FTbl.StrEnd :=  FillFuncTable (@StrEnd, @StrEnd_End);
  @FTbl.StrLen :=  FillFuncTable (@StrLen, @StrLen_End);
  @FTbl.LongIntToStr :=  FillFuncTable (@LongIntToStr, @LongIntToStr_End);
  @FTbl.FillChar :=  FillFuncTable (@FillChar, @FillChar_End);
  @FTbl.ClearExit :=  FillFuncTable (@ClearExit, @ClearExit_End);


  //在内嵌数据里填入字符串资源
  STbl := @LPTBuildinDataStru(BuildMM.Memory).ResourceTable.StringTable;

  STbl.sMapNameHead := FillStringTable (DEFAULT_MAP_HEAD);
  STbl.sEventNameHead := FillStringTable (DEFAULT_EVENT_HEAD);
  STbl.sResultEventExt := FillStringTable (DEFAULT_EVENT_TAIL);
  STbl.sDebugHead := FillStringTable (DEFAULT_DEBUG_HEAD);
  STbl.sScanNotifyName := FillStringTable (DEFAULT_SCAN_NOFITY_EVENT);
  STbl.sYouAreSyncMode := FillStringTable (DEFAULT_YOU_ARE_SYNC_MODE);


  STbl.sOutputDebugStringA := FillStringTable ('OutputDebugStringA');
  STbl.sCreateThread := FillStringTable ('CreateThread');
  STbl.sVirtualAlloc := FillStringTable ('VirtualAlloc');
  STbl.sGetCurrentProcessId := FillStringTable ('GetCurrentProcessId');  
  STbl.sGetModuleFileNameA := FillStringTable ('GetModuleFileNameA');   
  STbl.sVirtualFree := FillStringTable ('VirtualFree');
  STbl.sExitThread := FillStringTable ('ExitThread');
  STbl.sCreateFileMappingA := FillStringTable ('CreateFileMappingA');
  STbl.sMapViewOfFile := FillStringTable ('MapViewOfFile');
  STbl.sUnmapViewOfFile := FillStringTable ('UnmapViewOfFile');
  STbl.sCloseHandle := FillStringTable ('CloseHandle');
  STbl.sCreateEventA := FillStringTable ('CreateEventA');
  STbl.sWaitForSingleObject := FillStringTable ('WaitForSingleObject');
  STbl.sGetTickCount := FillStringTable ('GetTickCount');
  STbl.sGetCurrentThreadId := FillStringTable ('GetCurrentThreadId');
  STbl.sGetLastError := FillStringTable ('GetLastError');
  STbl.sOpenEventA := FillStringTable ('OpenEventA');
  STbl.sSetEvent := FillStringTable ('SetEvent');



  //准备被复制，投入使用
  LPTBuildinDataStru(BuildMM.Memory).Size := BuildMM.Size;
  BuildMM.Seek(0, soFromBeginning);

  if GetCopyValue (HeadBase, HeadSize, SizeOffset, TailBase, TailSize) then
  begin
      CodeMM := TMemoryStream.Create;
      CodeMM.Seek(0, soFromBeginning);

      CodeMM.WriteBuffer(HeadBase^, HeadSize); //复制引导代码头节
      CodeMM.CopyFrom(BuildMM, BuildMM.Size);  //复制内嵌数据段
      CodeMM.WriteBuffer(TailBase^, TailSize); //复制引导代码尾节

      PInteger (@PChar(CodeMM.Memory)[SizeOffset])^ := BuildMM.Size; //修正跳转偏移

      CodeSize := CodeMM.Size;
      CodeBase := AllocMem (CodeSize);
      CopyMemory (CodeBase, CodeMM.Memory, CodeSize);
      CodeMM.Free;

      Result := True;
  end;

  BuildMM.Free;
end;

function TestMakeSpyCode (out CodeBase: Pointer; out CodeSize: DWORD): LongBool;
var
  Param: TParamFromMain;
begin
  Param.MapSize := $1000 * $100 * 2;
  Param.SpyTimeOut := 1000 * 10;
  Result := MakeSpyCode (Param, CodeBase, CodeSize);
end;


function DirverInitial (MapSize: DWORD = DEFAULT_MAP_SIZE;
                        SpyTimeOut: DWORD = DEFAULT_SPY_TIMEOUT): BOOL;
var
  hDev: THandle;
  CodeBase: Pointer;
  CodeSize, Writed: DWORD;
  Times: Integer;
  Param: TParamFromMain;
begin
  Result := False;

  Param.MapSize := MapSize;
  Param.SpyTimeOut := SpyTimeOut;

  if not MakeSpyCode (Param, CodeBase, CodeSize)then
  begin
    SetLastError (10000);
    Exit;
  end;

  Times := 0;
  Repeat
    hDev := CreateFileA('\\.\KPatch',	GENERIC_READ or GENERIC_WRITE, 0, NIL, CREATE_ALWAYS,	FILE_ATTRIBUTE_NORMAL, 0);
    if hDev = INVALID_HANDLE_VALUE then
    begin
      if Times = 0 then
        if not EnsureDriver then
        begin
          SetLastError (10001);
          FreeMem (CodeBase);
          Exit;
        end;
      Sleep(1000);
    end else
      Break;

    Inc (Times);
    if Times = 3 then
    begin
      SetLastError (10002);
      FreeMem (CodeBase);
      Exit;
    end;
  until False;

  if WriteFile(hDev, CodeBase^, CodeSize, Writed, nil) then
  begin
    Result := true;
  end else begin
    SetLastError (10003);
  end;

  FreeMem (CodeBase);
  CloseHandle(hDev);
end;



//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 引导头
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

const
  THREAD_ENTRY = 0;
  THREAD_PARAM = 1;
  PARAM_HEAD = 'ANDX';

type
  LPTHookHeaderParam = ^THookHeaderParam;
  THookHeaderParam = packed record
    SIGN: Array[0..3] of Char;
    Count: Integer;
    FuncArray: Array[WORD] of Array[THREAD_ENTRY..THREAD_PARAM] of Pointer;
  end;


function HookHeadThread (Param: Pointer): BOOL; Stdcall;
var
  HookHeader: LPTHookHeaderParam;
  Index: Integer;
  ThreadCall: function (Param: Pointer): Pointer; Stdcall;
  MainResult: Pointer;
  DeltaOffset: Integer;
  RealMeBase, ScanBase: Pointer;
  FuncEntry,FuncParam: Pointer;
  ScanValue: Integer;
  AimSign: Array[0..3] of Char;
begin
  //寻找本函数实际内存地址
  asm
    push eax
    Call @AimMark
  @AimMark:
    Pop eax
    sub eax, OFFSET @AimMark
    mov DeltaOffset, eax
    pop eax
  end;
  RealMeBase := Pointer (Integer(@HookHeadThread) + DeltaOffset);

  //寻找本函数附带的参数的实际内存地址
  AimSign[0] := 'A';
  AimSign[1] := 'N';
  AimSign[2] := 'D';
  AimSign[3] := 'X';
  ScanValue := PInteger(@AimSign[0])^;

  HookHeader := NIL;
  for Index := 1 to $1000 do
  begin
    ScanBase := @PChar(RealMeBase)[Index];
    if PInteger(ScanBase)^ = ScanValue then
    begin
      HookHeader := ScanBase;
      Break;
    end;
  end;

  //查看参数是否正常
  Result := False;
  if HookHeader = NIL then Exit;
  if HookHeader.Count = 0 then exit;

  //修正所有的偏移值
  for Index := 0 to HookHeader.Count - 1 do
  begin
    //修正函数线程入口
    FuncEntry := HookHeader.FuncArray[Index][THREAD_ENTRY];
    HookHeader.FuncArray[Index][THREAD_ENTRY] := Pointer (DWORD(RealMeBase) + DWORD(FuncEntry));

    //修正线程函数的参数
    FuncParam := HookHeader.FuncArray[Index][THREAD_PARAM];
    if FuncParam <> Pointer(0) then
      HookHeader.FuncArray[Index][THREAD_PARAM] := Pointer (DWORD(RealMeBase) + DWORD(FuncParam));
  end;

  //调用主DLL
  ThreadCall := HookHeader.FuncArray[0][THREAD_ENTRY];
  MainResult := ThreadCall (HookHeader.FuncArray[0][THREAD_PARAM]);

  Result := MainResult <> nil;
  if HookHeader.Count = 1 then exit;

  //调用各从属DLL
  for Index := 1 to HookHeader.Count - 1 do
  begin
    ThreadCall := HookHeader.FuncArray[Index][THREAD_ENTRY];
    ThreadCall (MainResult);
  end;          
end;

procedure HookHeadThread_End;
begin
end;

//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 连续注射有从属关系的DLLs
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Type
  LPTHookDLLInfo = ^THookDLLInfo;
  THookDLLInfo = packed record
    ImageBase: Pointer;
    ImageSize: DWORD;
    ParmaBase: Pointer;
    ParmaSize: DWORD;
    Buffer: Array[WORD] of char;
  end;

var
  DLLsList: TList;

function AddHookDll (ImageBase: Pointer; ImageSize: DWORD; ParmaBase: Pointer = nil; ParmaSize: DWORD = 0): Integer; STDCALL;
var
  HookDLLInfo: LPTHookDLLInfo;
begin
  if not assigned (DLLsList) then
    DLLsList := TList.Create;
    
  if (ImageBase = NIL) or (ImageSize = 0) then
  begin
    Result := -1;
    Exit;
  end;

  HookDLLInfo := AllocMem (ImageSize + ParmaSize + SizeOf(THookDLLInfo));

  HookDLLInfo.ImageBase := @HookDLLInfo.Buffer[0];
  HookDLLInfo.ImageSize := ImageSize;
  CopyMemory (HookDLLInfo.ImageBase, ImageBase, ImageSize);

  HookDLLInfo.ParmaBase := nil;
  HookDLLInfo.ParmaSize := 0;
  Result := DLLsList.Add(HookDLLInfo);

  if ParmaBase = nil then exit;
  if ParmaSize = 0 then exit;

  HookDLLInfo.ParmaBase := @HookDLLInfo.Buffer[ImageSize];
  HookDLLInfo.ParmaSize := ParmaSize;
  CopyMemory (HookDLLInfo.ParmaBase, ParmaBase, ParmaSize);
end;

Procedure ClearHookDll;
var
  ToFree: Pointer;
begin
  if not assigned (DLLsList) then
    DLLsList := TList.Create;

  for ToFree in DLLsList do
    FreeMem (ToFree);
    
  DLLsList.Clear;    
end;

function _AddMainDLL (ImageBase: Pointer; ImageSize: DWORD; ParmaBase: Pointer; ParmaSize: DWORD): BOOL; STDCALL;
begin
  ClearHookDll;
  Result := AddHookDll (ImageBase, ImageSize, ParmaBase, ParmaSize) = 0;
end;

function AddMainDLL (Image: TMemoryStream; ParmaStr: WideString): BOOL; STDCALL;
begin
  Result := False;
  if Not Assigned (Image) then Exit;

  ParmaStr := ParmaStr + #0;
  Result := _AddMainDLL (Image.Memory, Image.Size, PWideChar(ParmaStr), Length(ParmaStr)*2);
end;

function _AddSubDLL (ImageBase: Pointer; ImageSize: DWORD): BOOL; stdcall;
begin
  Result := AddHookDll (ImageBase, ImageSize) > 0;
end;

function AddSubDLL (Image: TMemoryStream): BOOL; stdcall;
begin
  Result := False;
  if Not Assigned (Image) then Exit;
  if not assigned (DLLsList) then exit;
  if DLLsList.Count = 0 then Exit;

  Result := _AddSubDLL (Image.Memory, Image.Size);
end;

function MakeSpyProxyCode (var CodeBase: Pointer; var CodeSize: Integer): BOOL;
var
  HookHeaderParam: LPTHookHeaderParam;
  HookHeaderSize: DWORD;
  HookHeaderParamSize: DWORD;
  HookHeaderParamOffset: DWORD;
  HookDLLInfo: LPTHookDLLInfo; 
  Index: Integer;
  FuncEntry: Pointer;
  FuncSize, AimOffset, WriteCount, TotalMayBeSize: DWORD;
  ToCopyMM: TMemoryStream;
begin
  Result := False;
  if not assigned (DLLsList) then exit;
  if DLLsList.Count = 0 then exit;

  //将DLL转化成函数，原地存放
  for HookDLLInfo in DLLsList do
  begin
    if Dll2Function (HookDLLInfo.ImageBase, HookDLLInfo.ImageSize, FuncEntry, FuncSize) then
    begin
      HookDLLInfo.ImageBase := FuncEntry;
      HookDLLInfo.ImageSize := FuncSize;
    end;
  end;

  //计算引导代码和参数的大小
  HookHeaderSize := DWORD(@HookHeadThread_End) - DWORD(@HookHeadThread);
  HookHeaderParamSize := 4 + SizeOf(Integer) + (SizeOf(Pointer)*2 * (DLLsList.Count + 1));

  //估计总大小
  TotalMayBeSize := HookHeaderSize + HookHeaderParamSize;
  for HookDLLInfo in DLLsList do
    Inc (TotalMayBeSize, HookDLLInfo.ImageSize);
  HookDLLInfo := DLLsList[0];
  Inc (TotalMayBeSize, HookDLLInfo.ParmaSize);

  //复制引导代码，开始制作远程copy模板
  ToCopyMM := TMemoryStream.Create;
  ToCopyMM.SetSize(TotalMayBeSize);
  ToCopyMM.Seek(0, soFromBeginning);
  AimOffset := ToCopyMM.Write(PChar(@HookHeadThread)^, HookHeaderSize);
  HookHeaderParamOffset := AimOffset;

  //复制引导代码的参数
  HookHeaderParam := AllocMem (HookHeaderParamSize);
  WriteCount :=  ToCopyMM.Write(HookHeaderParam^, HookHeaderParamSize);
  FreeMem (HookHeaderParam);
  HookHeaderParam := Pointer (DWORD(ToCopyMM.Memory) + HookHeaderParamOffset);

  //记录主DLL的偏移地址
  Inc (AimOffset, WriteCount);

  //复制主DLL
  HookHeaderParam.SIGN := PARAM_HEAD;
  HookHeaderParam.Count := DLLsList.Count;
  HookDLLInfo := DLLsList[0];
  WriteCount := ToCopyMM.Write (HookDLLInfo.ImageBase^, HookDLLInfo.ImageSize);
  HookHeaderParam.FuncArray[0][THREAD_ENTRY] := Pointer(AimOffset);
  Inc (AimOffset, WriteCount);

  //复制主DLL参数
  WriteCount := ToCopyMM.Write (HookDLLInfo.ParmaBase^, HookDLLInfo.ParmaSize);
  HookHeaderParam.FuncArray[0][THREAD_PARAM] := Pointer(AimOffset);
  Inc (AimOffset, WriteCount);

  //复制其他从属DLL，它们没有参数的
  for Index := 1 to DLLsList.Count - 1 do
  begin
      HookDLLInfo := DLLsList[Index];
      WriteCount := ToCopyMM.Write (HookDLLInfo.ImageBase^, HookDLLInfo.ImageSize);

      HookHeaderParam.FuncArray[Index][THREAD_ENTRY] := Pointer(AimOffset);
      HookHeaderParam.FuncArray[Index][THREAD_PARAM] := Pointer(0);
      Inc (AimOffset, WriteCount);
  end;

  //输出结果
  CodeSize := ToCopyMM.Size;
  CodeBase := AllocMem (CodeSize);
  CopyMemory (CodeBase, ToCopyMM.Memory, CodeSize);
  Result := True;

  //回收资源
  ClearHookDLL;
  ToCopyMM.Free;
end;

function InjectThemALL_Src (dwProcessId: DWORD; hProcess: THandle; TimeOut: DWORD): BOOL; Stdcall;
var
  MapName: String;
  CodeBase: Pointer;
  CodeSize: Integer;
begin
  Result := False;

  MapName := DEFAULT_MAP_HEAD + IntToStr(dwProcessId);
  CodeBase := NIL;
  Repeat
    if not MakeSpyProxyCode (CodeBase, CodeSize) then break;
    if not PushProxyCodeTo (hProcess, MapName, CodeBase, CodeSize, TimeOut) then break;
    Result := True;
  until True;

  if Assigned (CodeBase) then
    FreeMem (CodeBase);
end;
                                  

function _InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD): THandle; Stdcall;
var
  ProcessInfo : TProcessInformation;
  Event: TEvent;
begin
  Result := 0;

  if DropMeSuspend(RightLevel, AppCmdLine, ProcessInfo) then
  begin
    if AcqureSyncModeEvent (ProcessInfo.dwProcessId, Event) then
    begin
      ResumeThread (ProcessInfo.hThread);  
      if InjectThemALL_Src (ProcessInfo.dwProcessId, ProcessInfo.hProcess, TimeOut) then
      begin
        Result := ProcessInfo.hProcess;
        CloseHandle (ProcessInfo.hThread);
        Event.Free;
        Exit;
      end;
      Event.Free;
    end;
    
    TerminateProcess (ProcessInfo.hThread, 0);
    CloseHandle (ProcessInfo.hThread);
    CloseHandle (ProcessInfo.hProcess);
  end;
end;


function InjectThemALL (AppCmdLine: String; TimeOut: DWORD; WaitExit: BOOL): BOOL; Stdcall;
var
  ProcHandle: THandle;
begin
  Result := False;
  ProcHandle := _InjectThemALL (AppCmdLine, SAFER_LEVELID_FULLYTRUSTED, TimeOut);
  if ProcHandle > 0 then
  begin
    if WaitExit then
      WaitForSingleObject (ProcHandle ,INFINITE);
    CloseHandle (ProcHandle);
    Result := True;
  end;
end;



end.
