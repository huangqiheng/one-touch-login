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
  MsgInit ('��PlugsHolder.exe����ʱ��������');
  MsgLine ('  ��1��ConfigID���ܺ��ԣ����봫�롣');
  MsgLine ('  ��2��ConfigID��ʽ�磺{9E179ED2-C5FF-4D19-9E03-60429558FACA}��');
  MsgLine ('  ��3��ConfigID��PlugsHolder.json�ļ��ж�Ӧ����');
  MsgLine ('');
  MsgLine ('����취��');
  MsgLine ('  ��1���鿴PlugsHolder�ļ�����ConfigID�Ƿ��д�');
  MsgLine ('  ��2����PlugsExplorer.exe�������������ĳ���', True);
end;

Procedure ShowRFLCreateError (EMsg: String);
begin
  MsgInit ('����PlugsHolder.json����ʱ��������ԭ�����Ϊ��');
  MsgLine ('  ��1��' + EMsg);
  MsgLine ('  ��2��RunInfo.DB�ļ��𻵡�');
  MsgLine ('  ��3��PlugsHolder.json�ļ���');
  MsgLine ('');
  MsgLine ('����취��');
  MsgLine ('  ��1����PlugsExplorer.exe���������Ƿ�������');
  MsgLine ('  ��2��RunInfo.DB��PlugsHolder.json�ļ�ɾ����������������', True);
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

  //���������в���
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

  //�����������ļ��Ķ���
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


  //�鿴�Ƿ���ȱ���ġ�˽�С��ֶ�
  MsgInit;
  AimNumber := 0;
  PrivateField := RFL.GetPrivateField;
  for FieldItem in PrivateField do
  begin
    //�Դ������Ϊ����
    FieldVal := '';
    Index := CmdLineSL.IndexOfName(FieldItem);
    if Index >= 0 then
      FieldVal := CmdLineSL.ValueFromIndex[Index];

    //д������ֵҲ���Բο�һ��
    if FieldVal = '' then
      FieldVal := RFL.Values[FieldItem];

    //ʵ���ǿգ�ֻ����ʾһ���û������˳�
    if FieldVal = '' then
    begin
      Inc (AimNumber);
      if MsgLineCount = 0 then
        MsgLine ('���Ҫִ�е����ã�����PrivateField�ֶ�δ���룺');
      MsgLine ('  ��' + IntToStr(AimNumber) + '����' + FieldItem + '���ֶ�Ϊ��');
    end;
  end;

  if MsgLineCount > 0 then
  begin
    MsgLine ('');
    MsgLine ('����취��');
    MsgLine ('  ��1������PlugsHolder.exeʱ���봫��PrivateField������');
    MsgLine ('  ��2����PlugsExplorer.exe����ʱ��Ҫ�����롣', True);
    Exit;
  end;

  //��ʼװ����
  MsgInit ('���װ������з�������');
  AimNumber := MsgLineCount;
  Repeat
        //����IPC����ͨ��
      CmdChannel := CreateClassID;
      if not CreateIpcProcedure (PChar(CmdChannel), @CMDIpcCallBack) then
      begin
        DBG ('Command Channel CreateIpcProcedure error');
        MsgLine ('  ����������ͨ�����󣬿��ܷ���������������⡣');
        Break;
      end;
      RFL.SetCmdChannel (CmdChannel);

      //����������Ϣͨ��
      DebugChannel := CreateClassID;
      if not CreateMsgServer (PChar(DebugChannel), @MsgCallBack, NIL) then
      begin
        DBG ('Debug Channel CreateMsgServer error');
        MsgLine ('  ������������Ϣͨ�����󣬿��ܷ���������������⡣');
        Break;
      end;
      RFL.SetDbgChanel (DebugChannel);

      //װ���ػ����
      DaemonMM := RFL.GetDaemon;
      if DaemonMM <> NIL then
      begin
        MakePlugDaemonLibrary; //����������
        DaemonDLL := TDLLLoaderEx.Create;
        if not DaemonDLL.Load(DaemonMM, @FindFuncEntry) then
        begin
          DBG ('Load PlugDaemon error');
          MsgLine ('  �������ػ�����������⣬�������ػ������ڷ��������쳣��');
          Break;
        end;
      end;

      Repeat
          //׼���������
          PlugParamStr := RFL.GetMainPluginParam;
          if RunMode = 'Debug' then
            DBG (PlugParamStr);

          InjectMode ();
          if not AddMainDLL (RFL.GetPlugBase, PlugParamStr) then
          begin
            DBG ('AddMainDLL error');
            MsgLine ('  ��װ���������������⣬�����ǲ��DLL�����¡�');
            Break;
          end;
                                   
          //׼���������DLL
          Libs := RFL.GetPlugLib;
          if Libs <> NIL then
            if not AddSubDLLs (Libs) then
            begin
              DBG ('AddSubDLL MainPlugin error');
              MsgLine ('  ��װ������DLL�������⣬�����ǲ��DLL�����¡�');
              Break;
            end;

          //׼�������DLL
          if not AddSubDLL (RFL.GetMainPlugin) then
          begin
            DBG ('AddSubDLL MainPlugin error');
            MsgLine ('  ��װ�������DLL�������⣬�����ǲ��DLL�����¡�');
            Break;
          end;

          case RFL.RightLevel of
            SAFER_LEVELID_FULLYTRUSTED : DBG ('RightLevel = SAFER_LEVELID_FULLYTRUSTED');
            SAFER_LEVELID_NORMALUSER   : DBG ('RightLevel = SAFER_LEVELID_NORMALUSER');
            SAFER_LEVELID_CONSTRAINED  : DBG ('RightLevel = SAFER_LEVELID_CONSTRAINED');
            SAFER_LEVELID_UNTRUSTED    : DBG ('RightLevel = SAFER_LEVELID_UNTRUSTED');
            SAFER_LEVELID_DISALLOWED   : DBG ('RightLevel = SAFER_LEVELID_DISALLOWED');
          end;

          //ע�����Ϸ����
          if not InjectThemALL (RFL.AppCmdLine, RFL.RightLevel, DEFAULT_INJECT_TIMEOUT, True) then
          begin
            DBG ('InjectThemALL error');
            MsgLine ('  ��ע����ģ�鵽Ŀ��ʱ�������󣬿����ǲ��DLL�����¡�');
            MsgLine ('  ��AppCmdLine=' + RFL.AppCmdLine);
            Break;
          end;      
      until True;

      //�����ػ����
      if DaemonMM <> NIL then
      begin
        if not DaemonDLL.UnLoad then
        begin
          DBG ('UnLoad PlugDaemon error');
          MsgLine ('  �������ػ�����������⣬�������ػ������Դ�ͷ��쳣��');
        end;
      end;

      //������Թܵ�
      if not CloseMsgServer (PChar(DebugChannel)) then
      begin
        DBG ('CloseMsgServer error');
        MsgLine ('  �����������Ϣͨ�����󣬿��ܷ���������������⡣');
      end;

      //��������ͨ��
      if not DestroyIpcProcedure (PChar(CmdChannel)) then
      begin
        DBG ('DestroyIpcProcedure error');
        MsgLine ('  ����������ͨ�����󣬿��ܷ���������������⡣');
      end;             
  until True;

  RFL.Free;

  if AimNumber <> MsgLineCount then
  begin
    MsgLine ('    �����ռ����������Ϣ�����������߲ο����Ը��������');
    MsgLine ('');
    MsgLine ('  лл���ڴ����æ���Ʊ������', True);
  end;

  if RunMode = 'Debug' then
  begin
    DBG ('�밴�س��˳���');
    ReadLn;
  end;
end.
