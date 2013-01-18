program PlugsHolder;

{$APPTYPE CONSOLE}

{$I ..\ShareUnit\GlobalDefine.inc}

{$R '..\Injector\KPatchRC.res' '..\Injector\KPatchRC.rc'}

uses
  SysUtils,
  windows,
  classes,
  superobject,
  ComObj,
  DLLDatabase,
  DLLLoader,
  SmartInjectUnit,
  AndQueMessages, AndIpcProcedure,DropMyRights,
  ReadSOUnit in '..\ShareUnit\ReadSOUnit.pas',
  NotifyingClient in 'NotifyingClient.pas',
  CmdChannelUnit in 'CmdChannelUnit.pas';

var
  AimConfigID, RunMode: String;
  ConfigFile: String;
  PlugParamStr: SOString;
  DaemonMM: TMemoryStream;
  DaemonDLL: TDLLLoaderEx = NIL;
  Libs: TLibMMArray;
  DebugChannel, CmdChannel: String;
  CmdLineSL, PrivateField: TStringList;
  FieldItem, FieldVal: String;
  Index, AimNumber: Integer;




//////////////////////////////////////////////////////////
///               Simple Show Message
//////////////////////////////////////////////////////////
var
  MsgSL: TStringList = NIL;

Procedure MsgInit (Msg: String = '');
begin
  if not Assigned (MsgSL) then
    MsgSL := TStringList.Create;
  MsgSL.Clear;
  if Msg <> '' then
    MsgSL.Add(Msg);
end;

Function MsgLineCount: Integer;
begin
  Result := MsgSL.Count;
end;

Function MsgLine (Msg: String; ShowIt: BOOL = False): BOOL;
begin
  Result := False;
  if MsgSL = NIL then Exit;
  
  Result := MsgSL.Add(Msg) >= 0;
  if ShowIt then
  begin
    WriteLn (MsgSL.Text);
    Result := ShowUserMessage (MsgSL);
  end;
end;

//////////////////////////////////////////////////////////
  

Procedure DBG (Msg: String);
begin
  if RunMode = 'Debug' then
    WriteLn (Msg);
end;

Procedure DebugPrint (Msg: PChar); stdcall;
begin
  DBG (StrPas(Msg));
end;

Procedure MsgCallBack (Sender: Pointer; MsgBuf: Pointer; MsgSize: Integer); Stdcall;
var
  MsgStr: AnsiString;
begin
  SetLength (MsgStr, MsgSize);
  CopyMemory (@MsgStr[1], MsgBuf, MsgSize);
  DBG (MsgStr);
end;


{$IFDEF MAKE_HASH_INC}
var
  RHashList: TStringList = NIL;

function GetUpperDir (FilePath:String): String;
begin
  if FilePath [Length(FilePath)] = '\' then
    Delete (FilePath, Length(FilePath), 1)
  else begin
    if DirectoryExists (FilePath) then
      FilePath := FilePath + '..';
  end;
  Result := ExtractFilePath (FilePath);
end;

Procedure SaveHash;
var
  filePath: String;
begin
  if not assigned (RHashList) then exit;
  RHashList.Insert (0, 'Const');

  filePath := ExtractFilePath (GetModuleName (0));
  filePath := GetUpperDir (filePath);
  FilePath := filePath + 'PlugIn\PlugsHolder.inc';

  if DirectoryExists (ExtractFilePath (FilePath)) then
    RHashList.SaveToFile (FilePath);
end;

{$ENDIF}

Function RH (Name: String): DWORD;
begin
  Result := GetUpperNameHashS (Name);
{$IFDEF MAKE_HASH_INC}
  if not assigned (RHashList) then
    RHashList := TStringList.Create;

  Name := 'HASH_' + Name;
  RHashList.Values[Name] := '$' + IntToHex(Result, 8) + ';';
{$ENDIF}
end;


Procedure MakePlugDaemonLibrary;
var
  HASH_DaemonLibrary: DWORD;
begin
  HASH_DaemonLibrary := RH ('DaemonLibrary');

  SaveFuncEntry (HASH_DaemonLibrary, RH('GetUpperNameHash'), @GetUpperNameHash);

  SaveFuncEntry (HASH_DaemonLibrary, RH('CreateMsgServer'), @CreateMsgServer);
  SaveFuncEntry (HASH_DaemonLibrary, RH('SendMsgToServer'), @SendMsgToServer);
  SaveFuncEntry (HASH_DaemonLibrary, RH('SendMsgToServerEx'), @SendMsgToServerEx);
  SaveFuncEntry (HASH_DaemonLibrary, RH('CloseMsgServer'), @CloseMsgServer);
  SaveFuncEntry (HASH_DaemonLibrary, RH('DebugPrint'), @DebugPrint);
                                       
{$IFDEF MAKE_HASH_INC}
  SaveHash;
{$ENDIF}
end;


function MakeCmdLineSL : TStringList;
var
  Index: Integer;
begin
  Result := TStringList.Create;
  for Index := 1 to ParamCount do
    Result.Add (ParamStr (Index));
end;

Procedure ShowConfigIDError;
begin
  MsgInit ('对PlugsHolder.exe调用时参数有误：');
  MsgLine ('  （1）ConfigID不能忽略，必须传入。');
  MsgLine ('  （2）ConfigID格式如：{9E179ED2-C5FF-4D19-9E03-60429558FACA}。');
  MsgLine ('  （3）ConfigID在PlugsHolder.json文件中对应配置');
  MsgLine ('');
  MsgLine ('解决办法：');
  MsgLine ('  （1）查看PlugsHolder文件，看ConfigID是否有错。');
  MsgLine ('  （2）在PlugsExplorer.exe中启动被补丁的程序。', True);
end;

Procedure ShowRFLCreateError (EMsg: String);
begin
  MsgInit ('创建PlugsHolder.json对象时发生错误，原因可能为：');
  MsgLine ('  （1）' + EMsg);
  MsgLine ('  （2）RunInfo.DB文件损坏。');
  MsgLine ('  （3）PlugsHolder.json文件损坏');
  MsgLine ('');
  MsgLine ('解决办法：');
  MsgLine ('  （1）在PlugsExplorer.exe检查各配置是否正常。');
  MsgLine ('  （2）RunInfo.DB和PlugsHolder.json文件删除，从置所有配置', True);
end;

procedure InitialWindowsStyle;
var
  lpBufferInfo: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenBufferInfo (GetStdHandle(STD_OUTPUT_HANDLE), lpBufferInfo);
  lpBufferInfo.dwSize.Y := lpBufferInfo.dwSize.Y * 10;
  lpBufferInfo.dwSize.X := lpBufferInfo.dwSize.X * 5 div 4;
  lpBufferInfo.dwMaximumWindowSize.X := lpBufferInfo.dwMaximumWindowSize.X * 5 div 4;
  SetConsoleScreenBufferSize( GetStdHandle(STD_OUTPUT_HANDLE), lpBufferInfo.dwSize);
end;

begin
  SetCurrentDir (ExtractFilePath (GetModuleName (0)));

  //解释命令行参数
  CmdLineSL := MakeCmdLineSL;

  RunMode := CmdLineSL.Values['RunMode'];
  if RunMode = '' then
    RunMode := 'Normal';

  if RunMode = 'Debug' then
    InitialWindowsStyle;

  DBG (CmdLineSL.Text);

  AimConfigID := CmdLineSL.Values['ConfigID'];
  if AimConfigID = '' then
  begin
    DBG ('ConfigID error');
    ShowConfigIDError;
    Exit;
  end;      

  //创建读配置文件的对象
  ConfigFile := GetAppPaths ('Data') + 'PlugsHolder.json';
  Try
    RFL := TReadForLoadAPP.Create (ConfigFile, AimConfigID);
    RFL.SetRunMode(RunMode);
  Except
    On E:Exception do
    begin
      ShowRFLCreateError (E.Message);
      Exit;
    end;           
  end;


  //查看是否有缺乏的“私有”字段
  MsgInit;
  AimNumber := 0;
  PrivateField := RFL.GetPrivateField;
  for FieldItem in PrivateField do
  begin
    //以传入参数为优先
    FieldVal := '';
    Index := CmdLineSL.IndexOfName(FieldItem);
    if Index >= 0 then
      FieldVal := CmdLineSL.ValueFromIndex[Index];

    //写死的数值也可以参考一下
    if FieldVal = '' then
      FieldVal := RFL.Values[FieldItem];

    //实在是空，只能提示一下用户，并退出
    if FieldVal = '' then
    begin
      Inc (AimNumber);
      if MsgLineCount = 0 then
        MsgLine ('检查要执行的配置，发现PrivateField字段未填入：');
      MsgLine ('  （' + IntToStr(AimNumber) + '）“' + FieldItem + '”字段为空');
    end;
  end;

  if MsgLineCount > 0 then
  begin
    MsgLine ('');
    MsgLine ('解决办法：');
    MsgLine ('  （1）调用PlugsHolder.exe时，请传入PrivateField参数。');
    MsgLine ('  （2）在PlugsExplorer.exe启动时依要求填入。', True);
    Exit;
  end;

  //开始装配插件
  MsgInit ('插件装配过程中发生错误：');
  AimNumber := MsgLineCount;
  Repeat
        //创建IPC命令通道
      CmdChannel := CreateClassID;
      if not CreateIpcProcedure (PChar(CmdChannel), @CMDIpcCallBack) then
      begin
        DBG ('Command Channel CreateIpcProcedure error');
        MsgLine ('  ◆创建命令通道错误，可能发生了软件兼容问题。');
        Break;
      end;
      RFL.SetCmdChannel (CmdChannel);

      //创建调试信息通道
      DebugChannel := CreateClassID;
      if not CreateMsgServer (PChar(DebugChannel), @MsgCallBack, NIL) then
      begin
        DBG ('Debug Channel CreateMsgServer error');
        MsgLine ('  ◆创建调试信息通道错误，可能发生了软件兼容问题。');
        Break;
      end;
      RFL.SetDbgChanel (DebugChannel);

      //装载守护插件
      DaemonMM := RFL.GetDaemon;
      if DaemonMM <> NIL then
      begin
        MakePlugDaemonLibrary; //构建函数库
        DaemonDLL := TDLLLoaderEx.Create;
        if not DaemonDLL.Load(DaemonMM, @FindFuncEntry) then
        begin
          DBG ('Load PlugDaemon error');
          MsgLine ('  ◆加载守护插件发生问题，可能是守护插件入口发生访问异常。');
          Break;
        end;
      end;

      Repeat
          //准备插件容器
          PlugParamStr := RFL.GetMainPluginParam;
          if RunMode = 'Debug' then
            DBG (PlugParamStr);

          InjectMode ();
          if not AddMainDLL (RFL.GetPlugBase, PlugParamStr) then
          begin
            DBG ('AddMainDLL error');
            MsgLine ('  ◆装配插件容器发生问题，可能是插件DLL损坏所致。');
            Break;
          end;
                                   
          //准备各插件库DLL
          Libs := RFL.GetPlugLib;
          if Libs <> NIL then
            if not AddSubDLLs (Libs) then
            begin
              DBG ('AddSubDLL MainPlugin error');
              MsgLine ('  ◆装配插件库DLL发生问题，可能是插件DLL损坏所致。');
              Break;
            end;

          //准备主插件DLL
          if not AddSubDLL (RFL.GetMainPlugin) then
          begin
            DBG ('AddSubDLL MainPlugin error');
            MsgLine ('  ◆装配主插件DLL发生问题，可能是插件DLL损坏所致。');
            Break;
          end;

          case RFL.RightLevel of
            SAFER_LEVELID_FULLYTRUSTED : DBG ('RightLevel = SAFER_LEVELID_FULLYTRUSTED');
            SAFER_LEVELID_NORMALUSER   : DBG ('RightLevel = SAFER_LEVELID_NORMALUSER');
            SAFER_LEVELID_CONSTRAINED  : DBG ('RightLevel = SAFER_LEVELID_CONSTRAINED');
            SAFER_LEVELID_UNTRUSTED    : DBG ('RightLevel = SAFER_LEVELID_UNTRUSTED');
            SAFER_LEVELID_DISALLOWED   : DBG ('RightLevel = SAFER_LEVELID_DISALLOWED');
          end;

          //注射进游戏进程
          if not InjectThemALL (RFL.AppCmdLine, RFL.RightLevel, DEFAULT_INJECT_TIMEOUT, True) then
          begin
            DBG ('InjectThemALL error');
            MsgLine ('  ◆注射插件模块到目标时发生错误，可能是插件DLL损坏所致。');
            MsgLine ('  ◆AppCmdLine=' + RFL.AppCmdLine);
            Break;
          end;      
      until True;

      //清理守护插件
      if DaemonMM <> NIL then
      begin
        if not DaemonDLL.UnLoad then
        begin
          DBG ('UnLoad PlugDaemon error');
          MsgLine ('  ◆清理守护插件发生问题，可能是守护插件资源释放异常。');
        end;
      end;

      //清理调试管道
      if not CloseMsgServer (PChar(DebugChannel)) then
      begin
        DBG ('CloseMsgServer error');
        MsgLine ('  ◆清理调试信息通道错误，可能发生了软件兼容问题。');
      end;

      //清理命令通道
      if not DestroyIpcProcedure (PChar(CmdChannel)) then
      begin
        DBG ('DestroyIpcProcedure error');
        MsgLine ('  ◆清理命令通道错误，可能发生了软件兼容问题。');
      end;             
  until True;

  RFL.Free;

  if AimNumber <> MsgLineCount then
  begin
    MsgLine ('    恳请收集本机软件信息，发给开发者参考，以改善软件。');
    MsgLine ('');
    MsgLine ('  谢谢！期待你帮忙改善本软件！', True);
  end;

  if RunMode = 'Debug' then
  begin
    DBG ('请按回车退出。');
    ReadLn;
  end;
end.
