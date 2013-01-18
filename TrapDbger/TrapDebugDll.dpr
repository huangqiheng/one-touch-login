library TrapDebugDll;

uses
  Windows,
  SysUtils, 
  Classes, PlugKernelLib,
  IdentifyFunc in '..\ShareUnit\IdentifyFunc.pas', ComObj, ShareMapMemory,
  Base64Unit;

Type
  LPTProxyTasker = ^TProxyTasker;
  TProxyTasker = record
    //设置的数据
    FOnMessage,FOnProgress,FOnAppData,FOnConfig,FOnKeyData: Pointer;
    ConfigSL: TStringList;
    AuthLib, PlugBase, Plugin: TMemoryStream;
    PlugLibs: Array of TMemoryStream;
    //代理连接数据
    DbgProcID: DWORD;        //TrapDebug的进程ID
    DbgProcHandle: THandle;  //TrapDebug的进程句柄
    DbgProcSrvName: String;  //TrapDebug的命令通道
    MsgServerName: String;   //从TrapDebug返回的回调消息
  end;

var
  TrapDbgExe: String;



Function TaskCreate (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall;
var
  AimTasker: LPTProxyTasker;
begin
  //创建资源
  New (AimTasker);
  With AimTasker^ do
  begin
    FOnMessage := OnMessage;
    FOnProgress := OnProgress;
    FOnAppData := OnAppData;
    FOnConfig := OnConfig;
    FOnKeyData := OnKeyData;

    ConfigSL := TStringList.Create;
    AuthLib := TMemoryStream.Create;
    PlugBase := TMemoryStream.Create;
    Plugin := TMemoryStream.Create;
  end;

  Result := THandle(AimTasker);
end;


Function TaskConfig (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall;
var
  AimTasker: LPTProxyTasker absolute Task;
  AddKey: String;
begin
  AddKey := StrPas(Key);
  AimTasker.ConfigSL.Values[AddKey] := Strpas(Value);
  Result := AimTasker.ConfigSL.IndexOfName(AddKey) >= 0;
end;

Procedure AddMsToLibArray (Tasker: LPTProxyTasker; AddMS: TMemoryStream);
var
  LibCount: Integer;
begin
  LibCount := Length(Tasker.PlugLibs);
  SetLength (Tasker.PlugLibs, LibCount + 1);
  Tasker.PlugLibs[LibCount] := AddMS;
end;

Function TaskPlugin (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall;
var
  AimTasker: LPTProxyTasker absolute Task;
  AddMS: TMemoryStream;
begin
  Result := False;
  case PlugType of
    PLUGIN_TYPE_AUTHLIB : AddMS := AimTasker.AuthLib;
    PLUGIN_TYPE_PLUGBASE : AddMS := AimTasker.PlugBase;
    PLUGIN_TYPE_PLUGLIB : begin
      AddMS := TMemoryStream.Create;
      AddMsToLibArray (AimTasker, AddMS);
    end;
    PLUGIN_TYPE_PLUGIN : AddMS := AimTasker.Plugin;
    ELSE Exit;
  end;

  AddMS.Clear;
  AddMS.Seek(0, soFromBeginning);
  Result := AddMS.Write(FileBuff^, FileSize) > 0;
end;

function NewProcess(AppCmdLine: PChar; var Process:THandle; var ProcID: DWORD): BOOL; stdcall;
var
  StartupInfo : TStartupInfo;
  ProcessInfo : TProcessInformation;
begin
  FillChar(StartupInfo,SizeOf(StartupInfo),#0);
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow   :=   SW_SHOWNORMAL;

  Result := CreateProcess(nil, AppCmdLine, nil, nil, false,
                       NORMAL_PRIORITY_CLASS,
                       nil, nil,
                       StartupInfo, ProcessInfo);

  if Result then
  begin
    Process := ProcessInfo.hProcess;
    ProcID := ProcessInfo.dwProcessId;
  end;
end;

Procedure TaskMsgCallBack (AimTasker: LPTProxyTasker; MsgBuf: Pointer; MsgSize: Integer); Stdcall;
begin

end;

function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

procedure DestroyFixedName (Name: String);
var
  NameSL: TStringList;
  Item: String;
begin
  if Name = '' then exit;
  NameSL := GetSplitBlankList (Name, [',']);
  for Item in NameSL do
    DestroyTheShare (Item);
end;

////////////////////////////////

const
  IpcTimeOut: dword = 18000;

function SendCommandBool (DbgProcSrvName, Cmd: String; Buffer: Pointer; Size: Integer): BOOL; overload;
var
  RetSize: dword;
  RetData: Pointer;
begin
  Result := SendIpcCommand (PChar(DbgProcSrvName), PChar(Cmd), IpcTimeOut, Buffer, Size, RetData, RetSize);
  if Result then
    Result := PBOOL(RetData)^;
end;

function SendCommandBool (DbgProcSrvName, Cmd: String): BOOL; overload;
begin
  Result := SendCommandBool (DbgProcSrvName, Cmd, @Result, SizeOf(BOOL));
end;

function Cmd_IsWOrking (DbgProcSrvName: String): BOOL;
begin
  Result := SendCommandBool (DbgProcSrvName, 'IsWorking');
end;

function Cmd_TaskRunning (DbgProcSrvName: String): BOOL;
begin
  Result := SendCommandBool (DbgProcSrvName, 'TaskRunning');
end;

function Cmd_TaskAppData (DbgProcSrvName: String; Buffer: Pointer; Size: Integer): BOOL;
begin
  Result := SendCommandBool (DbgProcSrvName, 'TaskAppData', Buffer, Size);
end;

function Cmd_TaskFinish (DbgProcSrvName: String; AppExit: BOOL): BOOL;
begin
  Result := SendCommandBool (DbgProcSrvName, 'TaskFinish', @AppExit, SizeOf(BOOL));
end;


function Cmd_TaskStart (DbgProcSrvName: String; SendSLText: String): BOOL;
begin
  Result := SendCommandBool (DbgProcSrvName, 'TaskStart', PChar(SendSLText), Length(SendSLText));
end;


/////////////////////////////

Function TaskRun (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall;
var
  AimTasker: LPTProxyTasker absolute Task;
  SendSL: TStringList;
  MapName: String;
  IterMS: TMemoryStream;
begin
  //创建回调信息通道
  AimTasker.MsgServerName := CreateClassID;
  if not CreateMsgServer (@AimTasker.MsgServerName[1], @TaskMsgCallBack, AimTasker) then
  begin
    AimTasker.MsgServerName := '';
    Result := -10;
    Exit;
  end;

  //创建调试器进程
  if not NewProcess (PChar(TrapDbgExe + ' ProxyMode'), AimTasker.DbgProcHandle, AimTasker.DbgProcID) then
  begin
    CloseMsgServer (@AimTasker.MsgServerName[1]);
    AimTasker.MsgServerName := '';
    Result := -11;
    Exit;
  end;        

  AimTasker.DbgProcSrvName := GetTargetChannelName (AimTasker.DbgProcID, TrapDbgExe);

  //构造TaskRun参数
  SendSL := TStringLIst.Create;
  SendSL.Values['ConfigSL'] := EncodeBase64 (AimTasker.ConfigSL.Text);
  SendSL.Values['MsgServerName'] := AimTasker.MsgServerName;
  SendSL.Values['AppCmdLine'] := StrPas(AppCmdLine);
  SendSL.Values['RightLevel'] := IntToStr(RightLevel);
  SendSL.Values['InjectMode'] := IntToStr(InjectMode);
  SendSL.Values['RunMode'] := IntToStr(RunMode);

  //插入各插件内存共享名
  SendSL.Values['AuthLib'] := CreateThrShare (AimTasker.AuthLib);
  SendSL.Values['PlugBase'] := CreateThrShare (AimTasker.PlugBase);
  SendSL.Values['Plugin'] := CreateThrShare (AimTasker.Plugin);     

  //这是库插件的
  MapName := '';
  for IterMS in AimTasker.PlugLibs do
    MapName := MapName + ',' + CreateThrShare (IterMS);

  if MapName <> '' then
  begin
    Delete (MapName, 1, 1);
    SendSL.Values['PlugLibs'] := MapName;
  end;

  //开始向TrapDebug进程发送指令
  if Cmd_TaskStart (AimTasker.DbgProcSrvName, SendSL.Text) then
    Result := 0
  else
    Result := -12;

  DestroyFixedName (SendSL.Values['AuthLib']);
  DestroyFixedName (SendSL.Values['PlugBase']);
  DestroyFixedName (SendSL.Values['Plugin']);
  DestroyFixedName (SendSL.Values['PlugLibs']);
  SendSL.Free;
end;
              
Function TaskDestroy (Task: THandle; AppExit: BOOL): BOOL; Stdcall;
var
  AimTasker: LPTProxyTasker absolute Task;
  IterMS: TMemoryStream;
begin
  //和TrapDebug通讯
  Result := Cmd_TaskFinish (AimTasker.DbgProcSrvName, AppExit);

  //清理资源
  with AimTasker^ do
  begin
    ConfigSL.Free;
    AuthLib.Free;
    PlugBase.Free;
    Plugin.Free;
    for IterMS in PlugLibs do IterMS.Free;
  end;

  Dispose (AimTasker);
end;

Function TaskRunning (Task: THandle): BOOL; Stdcall;
var
  AimTasker: LPTProxyTasker absolute Task;
begin
  Result := Cmd_TaskRunning (AimTasker.DbgProcSrvName);
end;

Function TaskAppData (Task: THandle; DataBuff: PChar; DataSize: Integer): BOOL; Stdcall;
var
  AimTasker: LPTProxyTasker absolute Task;
begin
  Result := Cmd_TaskAppData (AimTasker.DbgProcSrvName, DataBuff, DataSize);
end;

Function TaskCopy (Task: THandle): THandle; Stdcall;
var
  SrcTask: LPTProxyTasker absolute Task;
  NewTask: LPTProxyTasker;              
  IterMS: TMemoryStream;
begin
  New (NewTask);
  With NewTask^ do
  begin
    FOnMessage := SrcTask.FOnMessage;
    FOnProgress := SrcTask.FOnProgress;
    FOnAppData := SrcTask.FOnAppData;
    FOnConfig := SrcTask.FOnConfig;
    FOnKeyData := SrcTask.FOnKeyData;

    ConfigSL := TStringList.Create;
    AuthLib := TMemoryStream.Create;
    PlugBase := TMemoryStream.Create;
    Plugin := TMemoryStream.Create;

    ConfigSL.AddStrings(SrcTask.ConfigSL);
    AuthLib.LoadFromStream(SrcTask.AuthLib);
    PlugBase.LoadFromStream(SrcTask.PlugBase);
    Plugin.LoadFromStream(SrcTask.Plugin);
  end;

  for IterMS in SrcTask.PlugLibs do
    AddMsToLibArray (NewTask, IterMS);

  Result := THandle(NewTask);
end;



Exports
  TaskCreate,
  TaskDestroy,
  TaskConfig,
  TaskPlugin,
  TaskRun,
  TaskRunning,
  TaskAppData,
  TaskCopy;


begin                  
  TrapDbgExe := ChangeFileExt (GetModuleName (HInstance), '.exe');


end.
