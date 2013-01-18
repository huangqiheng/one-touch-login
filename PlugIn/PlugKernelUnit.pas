unit PlugKernelUnit;

interface

uses windows, classes, sysutils;

{$I PlugKernelDef.inc}

Function TaskCreate (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall;
Function TaskDestroy (Task: THandle; AppExit: BOOL): BOOL; Stdcall;
Function TaskConfig (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall;
Function TaskPlugin (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall;
Function TaskRun (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall;
Function TaskRunning (Task: THandle): BOOL; Stdcall;
Function TaskAppData (Task: THandle; DataBuff: PChar; DataSize: Integer): BOOL; Stdcall;
Function TaskCopy (Task: THandle): THandle; Stdcall;

Procedure SetConfigMS (Task: THandle; ConfigSL: TStringList);
Procedure SetPluginMS (Task: THandle; FileName: String; PlugType: Integer);

function SendMsg_AppData (Const IpcName: String; DataBuff: PChar; DataSize: Integer): BOOL;
function SendMsg_Progress (Const IpcName: String; OpType: Integer; Caption, Hint: String; Progress: Integer): BOOL;
function SendMsg_Config (Const IpcName, Key, Value: String): BOOL;
function SendMsg_KeyData (Const IpcName, Key, Value: String): BOOL;
function SendMsg_System (const IpcName, Msg: String): BOOL;
function SendMsg_Error (const IpcName, Msg: String): BOOL;
function SendMsg_Debug (const IpcName, Msg: String): BOOL;
function SendMsg_Log (const IpcName, Msg: String): BOOL;
function SendMsg_Notice (const IpcName, Msg: String): BOOL;


implementation

uses ComObj, AndQueMessages, SmartInjectUnit, SyncObjs, DLLLoader;

Type
  LPTPatchTask = ^TPatchTask;
  TPatchTask = Record
    Active: BOOL;
    OnMessage: Procedure (Task: THandle; MsgType: Integer; MsgBuff: PChar; MsgSize: Integer); Stdcall;
    OnAppData: Procedure (Task: THandle; DataBuff: PChar; DataSize: Integer); Stdcall;
    OnProgress: Procedure (Task: THandle; OpType: Integer; Caption, Hint: PChar; Progress: Integer); Stdcall;
    OnConfig: Procedure (Task: THandle; Key: PChar; Value: PChar); Stdcall;
    OnKeyData: Procedure (Task: THandle; Key: PChar; Value: PChar); Stdcall;
    AuthLib: TMemoryStream;
    PlugBase: TMemoryStream;
    Plugin: TMemoryStream;
    PlugLibs: TList;
    ConfigSL: TStringList;
    RunApp: Record
      FBeginTick: DWORD;
      FConfigSL: TStringList;
      FCmdChannel: String;
      FMsgChannel: String;
      FAppCmdLine: String;
      FRightLevel, FInjectMode, FRunMode: Integer;
      FAppHandle: THandle;
      FDaemonThread: THandle;
      FDaemonThreadID: DWORD;
      FForceTerminate: BOOL;
    end;
  end;



Procedure ReportSystemMessage (Task: LPTPatchTask; Const Msg: String);
begin
  if Assigned (Task.OnMessage) then
    Task.OnMessage (THandle(Task), MESSAGE_TYPE_SYSTEM, PChar(Msg), Length(Msg));
end;

var
  UsedTask: TList;

Procedure ClearUsedTask;
var
  Item: Pointer;
begin
  for Item in UsedTask do
    Dispose (Item);
  UsedTask.Clear;
end;

Procedure ClearInactiveTask;
var
  PatchTask: LPTPatchTask;
  Index: Integer;
begin
  for Index := UsedTask.Count - 1 downto 0 do
  begin
    PatchTask := UsedTask[Index];
    if not PatchTask.Active then
    begin
      Dispose (PatchTask);
      UsedTask.Delete(Index);
    end;
  end;
end;

Function IsActiveTask (Task: THandle): BOOL;
var
  PatchTask: LPTPatchTask absolute Task;
begin
  Result := False;
  if UsedTask.IndexOf(Pointer(Task)) = -1 Then
  begin
    ReportSystemMessage (PatchTask, ERROR_TASK_INVALID);
    Exit;
  end;
  Result := PatchTask.Active;

  if not Result then
    ReportSystemMessage (PatchTask, ERROR_TASK_INACTIVE);
end;


Function TaskCreate (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall;
var
  PatchTask: LPTPatchTask;
begin
  New (PatchTask);
  UsedTask.Add(PatchTask);

  @PatchTask.OnMessage := OnMessage;
  @PatchTask.OnProgress := OnProgress;
  @PatchTask.OnAppData := OnAppData;
  @PatchTask.OnConfig := OnConfig;
  @PatchTask.OnKeyData := OnKeyData;

  With PatchTask^ do
  begin
    ConfigSL := TStringList.Create;
    AuthLib := TMemoryStream.Create;
    PlugBase := TMemoryStream.Create;
    Plugin := TMemoryStream.Create;
    PlugLibs := TList.Create;
    Active := True;
  end;

  With PatchTask.RunApp do
  begin
    FBeginTick := 0;
    FDaemonThread := 0;
    FConfigSL := TStringList.Create;
  end;
  Result := THandle(PatchTask);

  ReportSystemMessage (PatchTask, SYSTEM_TASK_STARTED);
end;

Function TaskCopy (Task: THandle): THandle; Stdcall;
var
  PatchTask, SrcTask: LPTPatchTask;
  Item: Pointer;
  AddMS: TMemoryStream;
begin
  SrcTask := Pointer(Task);

  New (PatchTask);
  UsedTask.Add(PatchTask);

  With PatchTask^ do
  begin
    @OnMessage := @SrcTask.OnMessage;
    @OnProgress := @SrcTask.OnProgress;
    @OnAppData := @SrcTask.OnAppData;
    @OnConfig := @SrcTask.OnConfig;
    @OnKeyData := @SrcTask.OnKeyData;

    ConfigSL := TStringList.Create;     ConfigSL.AddStrings(SrcTask.ConfigSL);
    AuthLib := TMemoryStream.Create;    AuthLib.LoadFromStream(SrcTask.AuthLib);
    PlugBase := TMemoryStream.Create;   PlugBase.LoadFromStream(SrcTask.PlugBase);
    Plugin := TMemoryStream.Create;     Plugin.LoadFromStream(SrcTask.Plugin);
    PlugLibs := TList.Create;
    for Item in SrcTask.PlugLibs do
    begin
      AddMS := TMemoryStream.Create;
      AddMS.LoadFromStream(TMemoryStream (Item));
      PlugLibs.Add(AddMS);
    end;

    Active := True;
  end;

  With PatchTask.RunApp do
  begin
    FBeginTick := 0;
    FDaemonThread := 0;
    FConfigSL := TStringList.Create;
  end;
  Result := THandle(PatchTask);

  ReportSystemMessage (PatchTask, SYSTEM_TASK_COPIED);
end;

Function TaskDestroy (Task: THandle; AppExit: BOOL): BOOL; Stdcall;
var
  PatchTask: LPTPatchTask absolute Task;
  Item: Pointer;
  AimProc: THandle;
begin
  Result := False;

  if Task = 0 then
  begin
    ClearInactiveTask;
    Result := True;
    Exit;
  end;

  if not IsActiveTask (Task) then Exit;

  With PatchTask^ do
  begin
    AuthLib.Free;
    PlugBase.Free;
    Plugin.Free;
    for Item in PlugLibs do
      TMemoryStream (Item).Free;
    PlugLibs.Free;
    ConfigSL.Free;
    Active := False;
  end;

  With PatchTask.RunApp do
  begin
    if AppExit then
      TerminateProcess (FAppHandle, 0)
    else begin
      FForceTerminate := True;
      Repeat
        if WAIT_TIMEOUT <> WaitForSingleObject (FDaemonThread, 200) then Break;
      until FDaemonThread = 0;
    end;
    FConfigSL.Free;
  end;
                   
  Result := True;
  ReportSystemMessage (PatchTask, SYSTEM_TASK_FINISHED);
end;

Function TaskConfig (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall;
var
  PatchTask: LPTPatchTask absolute Task;
  InputKey, InputValue: String;
begin
  Result := False;
  if not IsActiveTask (Task) then Exit;

  InputKey := Trim(StrPas(Key));
  InputValue := Trim(StrPas(Value));
  if InputKey = '' then Exit;

  PatchTask.ConfigSL.Values[InputKey] := InputValue;
  Result := True;
end;

Procedure SetConfigMS (Task: THandle; ConfigSL: TStringList);
var
  PatchTask: LPTPatchTask absolute Task;
  InputKey, InputValue: String;
  Index: Integer;
begin
  if not IsActiveTask (Task) then Exit;
  if ConfigSL.Count = 0 then exit;

  for Index := 0 to ConfigSL.Count - 1 do
  begin
    InputKey := ConfigSL.Names[Index];
    InputValue := ConfigSL.ValueFromIndex[Index];
    PatchTask.ConfigSL.Values[InputKey] := InputValue;
  end;
end;

Procedure SetPluginMS (Task: THandle; FileName: String; PlugType: Integer);
var
  MS: TMemoryStream;
begin
  if not FileExists (FileName) then exit;
  
  MS := TMemoryStream.Create;
  Try
    MS.LoadFromFile(FileName);
    TaskPlugin (Task, MS.Memory, MS.Size, PlugType);
  finally
    MS.Free;
  end;      
end;

Function TaskPlugin (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall;
var
  PatchTask: LPTPatchTask absolute Task;
  AimMS: TMemoryStream;
begin
  Result := False;
  if not IsActiveTask (Task) then Exit;
  if not Assigned (FileBuff) then Exit;
  if FileSize < 512 then Exit;

  if PLUGIN_TYPE_AUTHLIB = PlugType then
    AimMS := PatchTask.AuthLib
  else if PLUGIN_TYPE_PLUGBASE = PlugType then
    AimMS := PatchTask.PlugBase
  else if PLUGIN_TYPE_PLUGIN = PlugType then
    AimMS := PatchTask.Plugin
  else if PLUGIN_TYPE_PLUGLIB = PlugType then
  begin
    AimMS := TMemoryStream.Create;
    PatchTask.PlugLibs.Add(AimMS);
  end else Exit;

  AimMS.Clear;
  AimMS.Seek(0, soFromBeginning);
  AimMS.WriteBuffer(FileBuff^, FileSize);
  Result := AimMS.Size > 0;
end;

////////////////////////////////////////////////////////////////////////////
//                           协议解释
////////////////////////////////////////////////////////////////////////////

Type
  LPTMsgStruct = ^TMsgStruct;
  TMsgStruct = record
    MsgType: Integer;
    MsgSize: Integer;
    MsgBuff: Array[0..0] of char;
  end;   


Procedure MsgCallBack (PatchTask: LPTPatchTask; MsgBuf: Pointer; MsgSize: Integer); Stdcall;
var
  MsgStruct: LPTMsgStruct absolute MsgBuf;
  DataSL: TStringList;
  OpType, Caption, Hint, Progress, Key, Value: String;
begin
  Case MsgStruct.MsgType of
  MESSAGE_TYPE_APPDATA: begin
    if Assigned(@PatchTask.OnAppData) then
      PatchTask.OnAppData (THandle(PatchTask), @MsgStruct.MsgBuff[0], MsgStruct.MsgSize);
  end;
  MESSAGE_TYPE_SYSTEM,MESSAGE_TYPE_ERROR,MESSAGE_TYPE_DEBUG,MESSAGE_TYPE_LOG,MESSAGE_TYPE_NOTICE: begin
    if Assigned(@PatchTask.OnMessage) then
      PatchTask.OnMessage (THandle(PatchTask), MsgStruct.MsgType, @MsgStruct.MsgBuff[0], MsgStruct.MsgSize);
  end;
  MESSAGE_TYPE_PROGRESS: begin
    if Assigned(@PatchTask.OnProgress) then
    begin
      DataSL := TStringList.Create;
      DataSL.Text := StrPas (@MsgStruct.MsgBuff[0]);
      OpType := DataSL.Values ['OpType'];
      Caption := DataSL.Values ['Caption'];
      Hint := DataSL.Values ['Hint'];
      Progress := DataSL.Values ['Progress'];
      PatchTask.OnProgress (THandle(PatchTask), StrToInt(OpType), PChar(Caption), PChar(Hint), StrToInt(Progress));
      DataSL.Free;
    end;
  end;
  MESSAGE_TYPE_CONFIG: begin
    if Assigned(@PatchTask.OnConfig) then
    begin
      DataSL := TStringList.Create;
      DataSL.Text := StrPas (@MsgStruct.MsgBuff[0]);
      Key := DataSL.Values ['Key'];
      Value := DataSL.Values ['Value'];
      PatchTask.OnConfig (THandle(PatchTask), PChar(Key), PChar(Value));
      DataSL.Free;
    end;
  end;
  MESSAGE_TYPE_KEYDATA: begin
    if Assigned(@PatchTask.OnKeyData) then
    begin
      DataSL := TStringList.Create;
      DataSL.Text := StrPas (@MsgStruct.MsgBuff[0]);
      Key := DataSL.Values ['Key'];
      Value := DataSL.Values ['Value'];
      PatchTask.OnKeyData (THandle(PatchTask), PChar(Key), PChar(Value));
      DataSL.Free;
    end;
  end;
  end;
end;
 
function SendStringMessage (Const IpcName, Msg: String; MsgType: Integer): BOOL;
var
  MsgStruct: LPTMsgStruct;
  MsgSize: Integer;
begin
  MsgSize := SizeOf(TMsgStruct) + Length(Msg);
  MsgStruct := AllocMem (MsgSize);
  MsgStruct.MsgType := MsgType;
  MsgStruct.MsgSize := Length(Msg);
  CopyMemory (@MsgStruct.MsgBuff[0], PChar(Msg), MsgStruct.MsgSize);
  Result := SendQueMessage (IpcName, MsgStruct, MsgSize);
  FreeMem (MsgStruct);
end;

function SendMsg_AppData (Const IpcName: String; DataBuff: PChar; DataSize: Integer): BOOL;
var
  MsgStruct: LPTMsgStruct;
  MsgSize: Integer;
begin
  MsgSize := SizeOf(TMsgStruct) + DataSize;
  MsgStruct := AllocMem (MsgSize);
  MsgStruct.MsgType := MESSAGE_TYPE_APPDATA;
  MsgStruct.MsgSize := DataSize;
  CopyMemory (@MsgStruct.MsgBuff[0], DataBuff, DataSize);
  Result := SendQueMessage (IpcName, MsgStruct, MsgSize);
  FreeMem (MsgStruct);
end;

function SendMsg_Progress (Const IpcName: String; OpType: Integer; Caption, Hint: String; Progress: Integer): BOOL;
var
  ContentSL: TStringList;
begin
  ContentSL := TStringList.Create;
  ContentSL.Values ['OpType'] := IntToStr(OpType);
  ContentSL.Values ['Caption'] := Caption;
  ContentSL.Values ['Hint'] := Hint;
  ContentSL.Values ['Progress'] := IntToStr(Progress);
  Result := SendStringMessage (IpcName, ContentSL.Text, MESSAGE_TYPE_PROGRESS);
  ContentSL.Free;
end;

function SendMsg_Config (Const IpcName, Key, Value: String): BOOL;
var
  ContentSL: TStringList;
begin
  ContentSL := TStringList.Create;
  ContentSL.Values ['Key'] := Key;
  ContentSL.Values ['Value'] := Value;
  Result := SendStringMessage (IpcName, ContentSL.Text, MESSAGE_TYPE_CONFIG);
  ContentSL.Free;
end;

function SendMsg_KeyData (Const IpcName, Key, Value: String): BOOL;
var
  ContentSL: TStringList;
begin
  ContentSL := TStringList.Create;
  ContentSL.Values ['Key'] := Key;
  ContentSL.Values ['Value'] := Value;
  Result := SendStringMessage (IpcName, ContentSL.Text, MESSAGE_TYPE_KEYDATA);
  ContentSL.Free;
end;

function SendMsg_System (const IpcName, Msg: String): BOOL;
begin
  Result := SendStringMessage (IpcName, Msg, MESSAGE_TYPE_SYSTEM);
end;

function SendMsg_Error (const IpcName, Msg: String): BOOL;
begin
  Result := SendStringMessage (IpcName, Msg, MESSAGE_TYPE_ERROR);
end;

function SendMsg_Debug (const IpcName, Msg: String): BOOL;
begin
  Result := SendStringMessage (IpcName, Msg, MESSAGE_TYPE_DEBUG);
end;

function SendMsg_Log (const IpcName, Msg: String): BOOL;
begin
  Result := SendStringMessage (IpcName, Msg, MESSAGE_TYPE_LOG);
end;

function SendMsg_Notice (const IpcName, Msg: String): BOOL;
begin
  Result := SendStringMessage (IpcName, Msg, MESSAGE_TYPE_NOTICE);
end;

////////////////////////////////////////////////////////////////////////////

var
  InjectCRTS: TCriticalSection;

Function SyncInjectThem (PatchTask: LPTPatchTask): THandle;
var
  InjectType: TInjectType;
  Item: Pointer;
  LibMS: TMemoryStream;
begin
  case PatchTask.RunApp.FInjectMode of
    INJECT_MODE_REMOTE_THREAD: InjectType := ijRemoteThread;
    INJECT_MODE_DRIVER: InjectType := ijDriver;
    Else InjectType := ijAuto;
  end;

  SmartInjectUnit.InjectMode (InjectType);

  InjectCRTS.Enter;
  Try
    With PatchTask^ do
    begin
      AddMainDLL (PlugBase, RunApp.FConfigSL.Text);
      for Item in PlugLibs do
      begin
        LibMS := Item;
        AddSubDLL (LibMS);
      end;
      AddSubDLL (Plugin);

      Result := InjectThemALL (RunApp.FAppCmdLine, RunApp.FRightLevel,DEFAULT_INJECT_TIMEOUT);
    end;
  finally
    InjectCRTS.Leave;
  end;      
end;


Procedure DaemonTaskThread (PatchTask: LPTPatchTask); Stdcall;
var
  WaitRet: DWORD;
begin
  ReportSystemMessage (PatchTask, SYSTEM_TASK_DAEMON_BEGIN);
  With PatchTask.RunApp do
  begin
    Repeat
      WaitRet := WaitForSingleObject (FAppHandle ,500);
      if WAIT_OBJECT_0 = WaitRet then
      begin
        FDaemonThread := 0;
        ReportSystemMessage (PatchTask, SYSTEM_APP_TERMINATED);
        Break;
      end else
      if WAIT_TIMEOUT = WaitRet then
      begin

      end else Break;
    until FForceTerminate;

    CloseHandle (FAppHandle);
    FDaemonThread := 0;
  end;
  ReportSystemMessage (PatchTask, SYSTEM_TASK_DAEMON_EXIT);
end;

Function TaskRunning (Task: THandle): BOOL; Stdcall;
var
  PatchTask: LPTPatchTask absolute Task;
begin
  if Task = 0 then
  begin
    Result := False;
    Exit;
  end;
  Result := PatchTask.RunApp.FDaemonThread > 0;
end;

Function TaskRun (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall;
var
  PatchTask: LPTPatchTask absolute Task;
  AuthDecrypt: Function (Image: Pointer; ImgSize: Integer): BOOL; Stdcall;
  MsgChannel: String;
  AuthDLL: TDLLLoader;
begin
  Result := -1;
  if not IsActiveTask (Task) then Exit;
  Result := -2;
  if PatchTask.PlugBase.Size < 100 then exit;
  Result := -3;
  if PatchTask.Plugin.Size < 100 then exit;
  Result := -4;
  if PatchTask.RunApp.FBeginTick > 0 then Exit;

  //装配Auth插件，验证身份
  if PatchTask.AuthLib.Size > 0 then
  begin
    AuthDLL := TDLLLoader.Create;
    Try
      if AuthDLL.Load(PatchTask.AuthLib, PChar(PatchTask.ConfigSL.Text)) then
      begin
        @AuthDecrypt := AuthDLL.FindExport('Decrypt');
        if not AuthDecrypt (PatchTask.Plugin.Memory, PatchTask.Plugin.Size) then
        begin
          Result := -5;
          AuthDLL.Unload();
          Exit;
        end;
        AuthDLL.Unload();
      end else
      begin
        Result := -6;
        Exit;
      end;
    finally
      AuthDLL.Free;
    end;
  end;                


  With PatchTask.RunApp do
  begin
    //创建消息接收管道
    MsgChannel := CreateClassID;
    if not CreateMsgServer (PChar(MsgChannel), @MsgCallBack, PatchTask) then
    begin
      Result := -7;
      Exit;
    end;

    //填写RunApp相关信息
    FRightLevel := RightLevel;
    FInjectMode := InjectMode;
    FRunMode := RunMode;
    FAppCmdLine := StrPas(AppCmdLine);
    FCmdChannel := CreateClassID;
    FMsgChannel := MsgChannel;
    FConfigSL.Clear;
    FConfigSL.AddStrings (PatchTask.ConfigSL);
    FConfigSL.Values['CmdChannel'] := FCmdChannel;
    FConfigSL.Values['MsgChannel'] := FMsgChannel;
    FConfigSL.Values['AppCmdLine'] := FAppCmdLine;
    FConfigSL.Values['RightLevel'] := IntToStr(FRightLevel);
    FConfigSL.Values['RunMode'] := IntToStr(FRunMode);

    //装配插件，执行注射
    FAppHandle := SyncInjectThem (PatchTask);
    if FAppHandle = 0 then
    begin
      Result := -8;
      CloseMsgServer (PChar(FMsgChannel));
      Exit;
    end;
    ReportSystemMessage (PatchTask, SYSTEM_APP_CREATED);

    //创建守护线程
    FBeginTick := GetTickCount;
    FForceTerminate := False;
    FDaemonThread := CreateThread (nil, 0, @DaemonTaskThread, PatchTask, 0, FDaemonThreadID);
  end;

  Result := 0;
end;



Function TaskAppData (Task: THandle; DataBuff: PChar; DataSize: Integer): BOOL; Stdcall;
var
  PatchTask: LPTPatchTask absolute Task;
begin
  Result := SendQueMessage (PatchTask.RunApp.FCmdChannel, DataBuff, DataSize);
end;


Initialization
  UsedTask := TList.Create;
  InjectCRTS := TCriticalSection.Create;

Finalization
  ClearUsedTask;
  UsedTask.Free;
  InjectCRTS.Free;

end.
