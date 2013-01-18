unit AndIpcServer;

interface

uses windows, classes, sysUtils, IntList, ComObj, math;

Type
  TIpcCmdRecver = procedure (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;

function CreateIpcServer (IpcName: PChar): THandle; Stdcall;
function AddIpcCommand (hServer: THandle; Cmd: PChar; Handler: Pointer): BOOL; Stdcall;
function EchoIpcCommand (hClient: THandle; Buffer: Pointer; Size: Integer): BOOL; Stdcall;
function DestroyIpcServer (hServer: THandle): BOOL; Stdcall;

function SendIpcCommand (IpcName, Cmd: PChar; TimeOut: DWORD;
                         InBuffer: Pointer; InSize: DWORD;
                         out OutBuffer: Pointer; out OutSize: DWORD): BOOL; Stdcall;

var
  MaxSendIpcCommand: DWORD;

implementation

uses AndQueMessages, SyncObjs, ThreadTempMemory;

type
  LPTIpcServerData = ^TIpcServerData;
  TIpcServerData = record
    IpcName: String;
    CmdHandleList: TStringList;
  end;

  LPTSender = ^TSender;
  TSender = packed record
    Data: Pointer;
    Event: TEvent;
  end;

  LPTPassTime = ^TPassTime;
  TPassTime = record
    BeginTick: DWORD;
    LastRecTick: DWORD;
  end;

  LPTTransData = ^TTransData;
  TTransData = record
    Sender: TSender;
    PassTick: TPassTime;
    OutBuffer: PChar;
    OutSize: DWORD;
    
    RequestCmdIndex: Integer;
    RequestDataIndex: Integer;      
    FeedbackChandleIndex: Integer; 

    DataSize: Integer;
    Buffer: Array[0..0] of char;
  end;

  LPTClientData = ^TClientData;
  TClientData = record
    Sender: TSender;
    PassTick: TPassTime;
    IpcName: String;
  end;

  LPTTransFeedback = ^TTransFeedback;
  TTransFeedback = record
    Sender: TSender;
    DataSize: Integer;
    Buffer: Array[0..0] of char;    
  end;

var
  OnServiceLst: TintList;
  OnServiceLock: TCriticalSection;


function SetOnService (Sender: TSender; Enable: BOOL): BOOL;
var
  Input: PInt64;
  Index: Integer;
begin
  Result := False;
  Input := @Sender;
  OnServiceLock.Enter;

  Index := OnServiceLst.IndexOf(Input^);
  if Enable then
  begin
    if Index = -1 then
    begin
      OnServiceLst.Add(Input^);
      Result := True;
    end;
  end else
  begin
    if Index >= 0 then
    begin
      OnServiceLst.Delete(Index);
      Result := True;
    end;
  end;

  OnServiceLock.Leave;
end;

function IsOnService (Sender: TSender): BOOL;
begin
  Result := OnServiceLst.IndexOf(PInt64(@Sender)^) >= 0;
end;

function PrintPassTick (Hint: String; PassTick: LPTPassTime): DWORD;
begin
  if PassTick.BeginTick = 0 then
  begin
    PassTick.BeginTick := GetTickCount;
    PassTick.LastRecTick := PassTick.BeginTick;
    if Length(Hint) > 0 then
      OutputDebugString (PChar(Hint + ' Begin'));
    Result := 0;
    Exit;
  end;

  Result := GetTickCount - PassTick.LastRecTick;
  PassTick.LastRecTick := GetTickCount;
  if Length(Hint) > 0 then
    OutputDebugString (PChar(Hint + ' Offset = ' + IntToStr(Result)));
end;


var
  sMsgRecverName: String = '{1DB9A238-4D4B-44AB-BC48-4CDE0DB6E706}';

Procedure MsgRecverCallBack (Sender: Pointer; MsgBuf: LPTTransFeedback; MsgSize: Integer); Stdcall;
var
  TransData: LPTTransData;
begin
  OnServiceLock.Enter;
  if IsOnService (MsgBuf.Sender) then
  begin
    TransData := MsgBuf.Sender.Data;
    TransData.OutSize := MsgBuf.DataSize;
    GetMem (TransData.OutBuffer, TransData.OutSize);
    CopyMemory (TransData.OutBuffer, @MsgBuf.Buffer[0], TransData.OutSize);
    TransData.Sender.Event.SetEvent;
  end;
  OnServiceLock.Leave;
end;

var
  IsRecverInit: BOOL = False;

function RegistMsgRecver (Sender: TSender; Enable: BOOL): BOOL;
begin
  if not IsRecverInit then
  begin
    IsRecverInit := True;
    sMsgRecverName := CreateClassID;
    Assert (CreateMessageQueue (sMsgRecverName, TMsgCallBack(@MsgRecverCallBack), nil, DEFAULT_BUFFER_SIZE, 50), 'Create MsgRecver Failure');
  end;
  Result := SetOnService (Sender, Enable);
end;


function SendIpcCommand (IpcName, Cmd: PChar; TimeOut: DWORD;
                         InBuffer: Pointer; InSize: DWORD;
                         out OutBuffer: Pointer; out OutSize: DWORD): BOOL; Stdcall;
var
  TransData: LPTTransData;
  SendSize: DWORD;
  RetEvent: TEvent;
  WaitRet: TWaitResult;
begin
  Result := False;
  OutBuffer := nil;
  OutSize := 0;
  SendSize := SizeOf(TTransData) + StrLen(Cmd) + DWORD(Length(sMsgRecverName)) + 2 + InSize;
  TransData := AllocMem (SendSize);
  PrintPassTick ('', @TransData.PassTick);     

  RetEvent := TEvent.Create;
  TransData.Sender.Data := TransData;
  TransData.Sender.Event := RetEvent;
  RegistMsgRecver (TransData.Sender, True);

  TransData.OutBuffer := nil;
  TransData.OutSize := 0;
  TransData.RequestCmdIndex := 0;
  TransData.FeedbackChandleIndex := StrLen(Cmd) + 1;
  TransData.RequestDataIndex := TransData.FeedbackChandleIndex + Length(sMsgRecverName) + 1;
  TransData.DataSize := InSize;

  StrCopy (@TransData.Buffer[TransData.RequestCmdIndex], Cmd);
  StrCopy (@TransData.Buffer[TransData.FeedbackChandleIndex], PChar(sMsgRecverName));
  CopyMemory (@TransData.Buffer[TransData.RequestDataIndex], InBuffer, TransData.DataSize);

  if SendMsgToServer (IpcName, TransData, SendSize) then
  begin
    WaitRet := RetEvent.WaitFor(TimeOut);

    if wrSignaled = WaitRet then
    begin
      OutSize := TransData.OutSize;
      OutBuffer := GetThreadMem (OutSize);    
      if Assigned (TransData.OutBuffer) then
      if Assigned (OutBuffer) then
      begin    
        CopyMemory (OutBuffer, TransData.OutBuffer, OutSize);
        Result := True;
      end;
    end;
  end;

  RegistMsgRecver (TransData.Sender, False);
  RetEvent.Free;

  MaxSendIpcCommand := Max(PrintPassTick ('', @TransData.PassTick), MaxSendIpcCommand);

  if Assigned (TransData.OutBuffer) then
    FreeMem (TransData.OutBuffer);
  FreeMem (TransData);
end;

//////////////////////////////////////////
///  ·þÎñÆ÷¶Ë
  
Procedure IpcMsgCallBack (Server: LPTIpcServerData; MsgBuf: LPTTransData; MsgSize: Integer); Stdcall;
var
  CmdName: String;
  Index: Integer;
  Client: LPTClientData;
  IpcCmdRecver: TIpcCmdRecver;
begin
  CmdName := StrPas(@MsgBuf.Buffer[MsgBuf.RequestCmdIndex]);
  Index := Server.CmdHandleList.IndexOf(CmdName);

  if Index >= 0 then
  begin
    @IpcCmdRecver := Pointer(Server.CmdHandleList.Objects[Index]);

    New (Client);
    Client.Sender := MsgBuf.Sender;
    Client.IpcName := StrPas(@MsgBuf.Buffer[MsgBuf.FeedbackChandleIndex]);
    Client.PassTick := MsgBuf.PassTick;
    IpcCmdRecver (THandle(Server), THandle(Client), @MsgBuf.Buffer[MsgBuf.RequestDataIndex], MsgBuf.DataSize);
  end;
end;

function CreateIpcServer (IpcName: PChar): THandle; Stdcall;
var
  IpcSrvData: LPTIpcServerData;
begin
  Result := 0;
  New (IpcSrvData);
  IpcSrvData.IpcName := StrPas(IpcName);
  IpcSrvData.CmdHandleList := TStringList.Create;
  if CreateMessageQueue (StrPas(IpcName),TMsgCallBack(@IpcMsgCallBack), IpcSrvData, DEFAULT_BUFFER_SIZE, 50) then
    Result := THandle(IpcSrvData);
end;

function AddIpcCommand (hServer: THandle; Cmd: PChar; Handler: Pointer): BOOL; Stdcall;
var
  IpcSrvData: LPTIpcServerData absolute hServer;
begin
  Result := IpcSrvData.CmdHandleList.AddObject(StrPas(Cmd), Handler) >= 0;
end;

function EchoIpcCommand (hClient: THandle; Buffer: Pointer; Size: Integer): BOOL; Stdcall;
var
  Client: LPTClientData absolute hClient;
  TransFeedback: LPTTransFeedback;
  ReplySize: Integer;
begin
  ReplySize := SizeOf(TTransFeedback) + Size;
  TransFeedback := AllocMem (ReplySize);
  TransFeedback.Sender := Client.Sender;
  TransFeedback.DataSize := Size;

  CopyMemory (@TransFeedback.Buffer[0], Buffer, TransFeedback.DataSize); 
  Result := SendQueMessage (Client.IpcName, TransFeedback, ReplySize);
  FreeMem (TransFeedback);
  Dispose (Client);
end;

function DestroyIpcServer (hServer: THandle): BOOL; Stdcall;
var
  IpcSrvData: LPTIpcServerData absolute hServer;
begin
  if IsBadReadPtr (IpcSrvData, SizeOf(TIpcServerData)) then
  begin
    Result := false;
    Exit;
  end;
  
  IpcSrvData.CmdHandleList.Free;
  Result := CloseMsgServer (PChar(IpcSrvData.IpcName));
  Dispose (IpcSrvData);
end;


initialization
  OnServiceLst := TintList.Create;
  OnServiceLock := TCriticalSection.Create;


finalization
  OnServiceLst.Free;
  OnServiceLock.Free;
  
end.
