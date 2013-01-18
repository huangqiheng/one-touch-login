unit TrapDbgLibUnit;

interface

uses windows, sysUtils, Classes, PlugKernelLib;

const
  REPORT_BREAK_START = 1;
  REPORT_BREAK_DATA = 2;
  REPORT_BREAK_END = 3;

Type
  TInfoCallback = Procedure (hTrap: THandle; EIP: Pointer; RegInfo: LPTRegister; DisAsm: PChar); Stdcall;
  TMsgCallBack = Procedure (Sender: Pointer; MsgBuf: Pointer; MsgSize: Integer); Stdcall;
  TIpcCmdRecver = procedure (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;

  LPTMemBlock = ^TMemBlock;
  TMemBlock = packed record
    Address: Pointer;
    Size: Integer;
  end;

  LPTMemBuffer = ^TMemBuffer;
  TMemBuffer = packed record
    Address: Pointer;
    BuffSize: DWORD;
    Buffer: Array[0..0] of char;
  end;

  LPTReport = ^TReport;
  TReport = packed record
    ReportType: Integer;
    hAim: THandle;
  end;

  LPTBreakStart = ^TBreakStart;
  TBreakStart = packed record
    Report: TReport;
    Start: Pointer;
  end;

  LPTBreakEnd = ^TBreakEnd;
  TBreakEnd = TReport;

  LPTBreakDetail = ^TBreakDetail;
  TBreakDetail = packed record
    Report: TReport;
    EIP: Pointer;
    StackBase: Pointer;   
    StackLimit: Pointer;
    RegInfoReal: Pointer; //线程中真正的LPTRegister内容
    RegInfo: TRegister;   //这是复制到内容
    DisAsm: Array[Byte] of char;
  end;

  LPTStackRequest = ^TStackRequest;
  TStackRequest = packed record
    Esp: DWORD;
    UpSize: DWORD;
  end;

  TOnBreak = Procedure (Data: LPTReport); stdcall;

  LPTSectionInfo = ^TSectionInfo;
  TSectionInfo = packed record
    CodeBase: Pointer;
    CodeSize: Integer;
  end;

function Cmd_GetModuleList (): TStringList; Stdcall;
function Cmd_GetModuleNodes(Handle: THandle) : Pointer; Stdcall;

function Cmd_GetCodeDisAsm (Address: Pointer; CodeLen: Integer): LPTCodeInfos; Stdcall;
function Cmd_GetCodeDisAsmRet (Address: Pointer): LPTCodeInfos; Stdcall;
function Cmd_GetFuncDisAsm (Entry: Pointer): LPTFuncInfos; Stdcall;
function Cmd_GetMemBuffer (Address: Pointer; Size: Integer): Pointer; Stdcall;
function Cmd_GetDataSectionMemory (Image: THandle): LPTSectionInfo; Stdcall;
function Cmd_SetMemBuffer (Address: Pointer; Buffer: Pointer; Size: Integer): BOOL; Stdcall;
Function Cmd_RunNakedCode (CodeBase: PChar; Size: Integer): Integer; Stdcall;

Function Cmd_TrapDbgSetup (StartAddr: Pointer; SuspendMode: BOOL): THandle; Stdcall;
Function Cmd_TrapDbgStepInto (hTrap: THandle): BOOL; Stdcall;
Function Cmd_TrapDbgStepOver (hTrap: THandle): BOOL; Stdcall;
Function Cmd_TrapDbgRunUntilRet (hTrap: THandle): BOOL; Stdcall;
Function Cmd_TrapDbgRunUntilAddr (hTrap: THandle; Addr: Pointer): BOOL; Stdcall;
Function Cmd_TrapDbgRelease (hTrap: THandle): BOOL; Stdcall;

Procedure Cmd_ReleaseAllBreak; Stdcall;

function ResetTrapDbgClient (DbgEvtName, IpcCmdServer: String; CmdTimeOut: DWORD; OnBreak: TOnBreak): BOOL; Stdcall;


implementation

var
  DbgIpcServer, DbgEvent: String;
  IpcTimeOut: dword = 18000;
  AliveBreak: TThreadList;

Procedure BreakMsgCallBack (Sender: TOnBreak; MsgBuf: Pointer; MsgSize: Integer); Stdcall;
begin
  Sender (MsgBuf);
end;

function ResetTrapDbgClient (DbgEvtName, IpcCmdServer: String; CmdTimeOut: DWORD; OnBreak: TOnBreak): BOOL; Stdcall;
begin
  Result := False;
  if CreateMsgServerEx (PChar(DbgEvtName), @BreakMsgCallBack, @OnBreak, $1000 * 256 * 2, 500) then
  begin
    if DbgEvent <> '' then
      CloseMsgServer (PChar(DbgEvent));
    DbgEvent := DbgEvtName;
    DbgIpcServer := IpcCmdServer;
    IpcTimeOut := CmdTimeOut;
    AliveBreak := TThreadList.Create;
    Result := True;
  end;
end;

function SendCommand (Cmd: String; InBuff: Pointer; InSize: dword; out OutBuff: Pointer; out OutSize: dword): BOOL; overload;
begin
  Result := SendIpcCommand (PChar(DbgIpcServer), PChar(Cmd), IpcTimeOut, InBuff, InSize, OutBuff, OutSize);
end;

function SendCommand (Cmd: String; Buffer: Pointer; Size: Integer): BOOL; overload;
var
  RetSize: dword;
  RetData: Pointer;
begin
  Result := SendCommand (Cmd, Buffer, Size, RetData, RetSize);
  if Result then
    Result := PBOOL(RetData)^;
end;

function Cmd_GetModuleList (): TStringList; Stdcall;
var
  Input: DWORD;
  OutBuff: Pointer;
  OutSize: Dword;
begin
  Result := TStringList.Create;
  Input := 0;
  if SendCommand ('GetModuleList', @Input, SizeOf(Input), OutBuff, OutSize) then
  begin
    Result.Text := StrPas (OutBuff);
  end;
end;

function Cmd_GetModuleNodes(Handle: THandle) : Pointer; Stdcall;
var
  OutSize: DWORD;
begin
  SendCommand ('GetModuleNodes', @Handle, SizeOf(Handle), Result, OutSize);
end;

function Cmd_GetCodeDisAsm (Address: Pointer; CodeLen: Integer): LPTCodeInfos; Stdcall;
var
  MemBlock: TMemBlock;
  CodeInfos: LPTCodeInfos;
  TotalSize: dword;
begin
  Result := nil;
  MemBlock.Address := Address;
  MemBlock.Size := CodeLen;
  if SendCommand ('GetCodeDisAsm', @MemBlock, SizeOf(TMemBlock), Pointer(CodeInfos), TotalSize) then
  begin
    Result := CodeInfos;
  end;
end;

function Cmd_GetCodeDisAsmRet (Address: Pointer): LPTCodeInfos; Stdcall;
begin
  Result := Cmd_GetCodeDisAsm (Address, -1);
end;

function Cmd_GetFuncDisAsm (Entry: Pointer): LPTFuncInfos; Stdcall;
var
  MemBlock: TMemBlock;
  FuncInfos: LPTFuncInfos;
  TotalSize: dword;
begin
  Result := nil;
  MemBlock.Address := Entry;
  if SendCommand ('GetFuncDisAsm', @MemBlock, SizeOf(TMemBlock), Pointer(FuncInfos), TotalSize) then
  begin
    Result := FuncInfos;
  end;    
end;

function Cmd_GetDataSectionMemory (Image: THandle): LPTSectionInfo; Stdcall;
var
  Reply: Pointer;
  TotalSize: dword;
begin
  Result := nil;
  if SendCommand ('GetDataSectionMemory', @Image, SizeOf(THandle), Reply, TotalSize) then
    Result := Reply;
end;

function Cmd_GetMemBuffer (Address: Pointer; Size: Integer): Pointer; Stdcall;
var
  SendTo: TMemBuffer;
  HasRead: LPTMemBuffer;
  TotalSize: dword;
begin
  Result := nil;
  SendTo.Address := Address;
  SendTo.BuffSize := Size;
  if SendCommand ('GetMemBuffer', @SendTo, SizeOf(TMemBuffer), Pointer(HasRead), TotalSize) then
  begin
    if HasRead.BuffSize > 0 then
      Result := @HasRead.Buffer[0];
  end;
end;


function Cmd_SetMemBuffer (Address: Pointer; Buffer: Pointer; Size: Integer): BOOL; Stdcall;
var
  ToWrite: LPTMemBuffer;
  ToWriteSize: Integer;
begin
  ToWriteSize := SizeOf(TMemBuffer) + Size;
  ToWrite := AllocMem (ToWriteSize);
  ToWrite.Address := Address;
  ToWrite.BuffSize := Size;
  CopyMemory (@ToWrite.Buffer[0], Buffer, Size);

  Result := SendCommand ('SetMemBuffer', ToWrite, ToWriteSize);
  FreeMem (ToWrite);
end;

Function Cmd_RunNakedCode (CodeBase: PChar; Size: Integer): Integer; Stdcall;
var
  HasRead: Pointer;
  TotalSize: dword;
begin
  Result := 0;
  if SendCommand ('RunNakedCode', CodeBase, Size, HasRead, TotalSize) then
  begin
    Result := PInteger(HasRead)^;
  end;
end;

Function Cmd_TrapDbgSetup (StartAddr: Pointer; SuspendMode: BOOL): THandle; Stdcall;
var
  Buffer: Array[0..7] of char;
  HasRead: Pointer;
  TotalSize: dword;
begin
  Result := 0;
  PPointer(@Buffer[0])^ := StartAddr;
  PBOOL(@Buffer[4])^ := SuspendMode;

  if SendCommand ('TrapDbgSetup', @Buffer[0], SizeOf(Buffer), HasRead, TotalSize) then
  begin
    Result := PDWORD(HasRead)^;
    AliveBreak.Add(Pointer(Result));
  end;
end;


Function Cmd_TrapDbgStepInto (hTrap: THandle): BOOL; Stdcall;
begin
  Result := SendCommand ('TrapDbgStepInto', @hTrap, SizeOf(THandle));
end;

Function Cmd_TrapDbgStepOver (hTrap: THandle): BOOL; Stdcall;
begin
  Result := SendCommand ('TrapDbgStepOver', @hTrap, SizeOf(THandle));
end;

Function Cmd_TrapDbgRunUntilRet (hTrap: THandle): BOOL; Stdcall;
begin
  Result := SendCommand ('TrapDbgRunUntilRet', @hTrap, SizeOf(THandle));
end;

Function Cmd_TrapDbgRunUntilAddr (hTrap: THandle; Addr: Pointer): BOOL; Stdcall;
var
  Buffer: Array[0..7] of char;
begin
  PDWORD(@Buffer[0])^ := hTrap;
  PPointer(@Buffer[4])^ := Addr;
  Result := SendCommand ('TrapDbgRunUntilAddr', @Buffer[0], SizeOf(Buffer));
end;

Function Cmd_TrapDbgRelease (hTrap: THandle): BOOL; Stdcall;
begin
  Result := SendCommand ('TrapDbgRelease', @hTrap, SizeOf(THandle));
  AliveBreak.Remove(Pointer(Result));
end;

Procedure Cmd_ReleaseAllBreak; Stdcall;
var
  List: TList;
  Item: Pointer;
  hTrap: THandle;
begin        
  List := AliveBreak.LockList;
  Try
    for Item in List do
    begin
      hTrap := THandle(Item);
      if not SendCommand ('TrapDbgRelease', @hTrap, SizeOf(THandle)) then
        OutputDebugStringA ('Error Cmd_TrapDbgRelease');
    end;
    List.Clear;
  finally
    AliveBreak.UnlockList;
  end;           
end;

end.
