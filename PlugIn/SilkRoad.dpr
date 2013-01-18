library SilkRoad;

uses
  SysUtils, WinSock, WinSock2,
  Windows, SyncObjs,
  Classes, GlobalObject;

{$I PlugBase.inc}

const
  //ϵͳҪ��
  Param_Depend_Daemon     = 'Daemon=<DefaultDaemon.dll>�벻Ҫ�ı��Ĭ��ֵ';    //�ڲ�����ʱ������Ĭ��ֵ
  Param_Depend_PlugBase   = 'PlugBase=<DefaultPlugBase.dll>�벻Ҫ�ı��Ĭ��ֵ';  //�ڲ�����ʱ������Ĭ��ֵ
  Param_Depend_Library    = 'PluginLib=<SilkRoadAddr.dll>��ҪԤ�ȼ��صĿ�,����趺�Ÿ���';
  Param_PrivacyField      = 'PrivacyField=<��Ϸ����>���ܸı��Ĭ��ֵ��������������������,����趺�Ÿ���'; //��PasswordFieldΪ��ʱ����������Ϸ�������롣

  //�û������ֶ�����
  Param_Service_Aera      = '��Ϸ�����=<����һ��>��������Ӫ�����������һ������ͨһ��';
  Param_Game_Server       = '��Ϸ������=<����ʢ��[����]>��������������ƣ���סҪ��������';
  Param_Account_UserName  = '��Ϸ�ʺ���=��Ϸ��Ӫ���˻�ƽ̨����';
  Param_Account_Password  = '��Ϸ����=������Ϸ��Ӫ���˻���Ӧ���룬�����գ������˾���ΪĬ��������';
  Param_Character_Name    = '�����ɫ��=������Ҫ�Զ���¼����Ϸ��ɫ����';


function GetParamList: PChar; Stdcall;
var
  ResultTmp: String;
begin
  With TStringList.Create do
  try
    Append(Param_Depend_Daemon);
    Append(Param_Depend_PlugBase);
    Append(Param_Depend_Library);
    Append(Param_PrivacyField);
    Append(Param_Service_Aera);
    Append(Param_Game_Server);
    Append(Param_Account_UserName);
    Append(Param_Account_Password);
    Append(Param_Character_Name);
    ResultTmp := Text;
    Result := PChar(ResultTmp);
  finally
    Free;
  end;     
end;

function IsTargetApp (AppPath: PChar): BOOL; Stdcall;
var
  AppExe: String;
begin
  AppExe := ExtractFilePath (StrPas(AppPath)) + 'SilkRoad.exe';
  Result := FileExists (AppExe);
end;

function IsAutoSet: BOOL; Stdcall;
begin
  Result := False;
end;

function Usage: PChar; Stdcall;
begin
  Result := '����TYPE_PLUGIN SilkRoad.dll�����ʹ�ð���';
end;

function PluginType: PChar; Stdcall;
begin
  Result := TYPE_PLUGIN;
end;

const
  IMPORT_LIB_NAME = 'SilkRoadAddr';


var
  lpvReserved: PPointer;
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  DebugPrint: Procedure (Msg: PChar); stdcall;
  ImportLibFunction: function (LibName, FuncName: PChar): Pointer; Stdcall;

  SMHookApi: function (FuncEntry, Hooker: Pointer): Pointer; stdcall;
  UnSMHookApi: function (FuncEntry: Pointer): LongBool; stdcall;
  GetJsonParam: function  (Path: PChar): PChar; Stdcall;
  IsTargetProcess: Function (): BOOL;
  WriteMemory: function (pAddress:pointer; pBuf:pointer; dwLen:dword):LongBool; stdcall;

  LoginAccount: function (UserName,PassWord: PChar; Server, Flags: DWORD): BOOL; Stdcall;
  SetPacketRecver: Procedure (CallBack: Pointer); Stdcall;
  SetPacketSendHooker: Procedure (CallBack: Pointer); Stdcall;
  GetCharacterIndex: function (RoleName: PChar; TimeOut: DWORD): Integer; Stdcall;
  EnterGameWorld: function (CharIndex: Integer): BOOL; Stdcall;

  ShowUserMessage: function (MsgSL: PChar): BOOL; Stdcall;
  OpenProgressWindow: function (Caption: PChar): THandle; Stdcall;
  ReportProgress: function (ProHandle: THandle; Hint: PChar; Progress: Integer): BOOL; Stdcall;
  CloseProgressWindow: function (ProHandle: THandle): BOOL; Stdcall;  

Procedure DbgFmt (const FmtStr: string; const Args: array of const);
var
  dbgstr: string;
begin
  Try
  dbgstr := Format (FmtStr, Args);
  DebugPrint (@dbgstr[1]);
  Except
  End;
end;


Procedure PrintBuffer (Head: String; Buffer: PChar; BufLen: Integer);
var
  Index: Integer;
begin
  for Index := 0 to BufLen - 1 do
    Head := Head + ' ' + IntToHex (Ord(Buffer[Index]), 2);
  Head := Trim(Head);
  DebugPrint (PChar(Head));
end;                             


Type
  LPTHeadStruct = ^THeadStruct;
  THeadStruct = Packed record
    ContentLen: WORD;
    ContentType: WORD;
    PacketType: WORD;
  end;
//Recv = �������б�
//F4 01 01 A1 00 00
//01 03 1C 00 43 49 4D 4F 5F 4F 66 66 69 63 69 61 6C 5F 53 68 61 6E 67 48 61 69 20 5B 46 5D 20 30
//01 10 1C 00 43 49 4D 4F 5F 4F 66 66 69 63 69 61 6C 5F 53 68 61 6E 67 48 61 69 20 5B 46 5D 20 31
//01 11 1C 00 43 49 4D 4F 5F 4F 66 66 69 63 69 61 6C 5F 53 68 61 6E 67 48 61 69 20 5B 46 5D 20 32
//01 16 1C 00 43 49 4D 4F 5F 4F 66 66 69 63 69 61 6C 5F 53 68 61 6E 67 48 61 69 20 5B 46 5D 20 33
//01 1B 1C 00 43 49 4D 4F 5F 4F 66 66 69 63 69 61 6C 5F 53 68 61 6E 67 48 61 69 20 5B 46 5D 20 35
//01 28 1B 00 53 52 4F 5F 4F 66 66 69 63 69 61 6C 5F 53 68 61 6E 67 48 61 69 20 5B 46 5D 20 36
//00
//
//01 16 00 0E 00 B4 F3 CC C6 CA A2 CA C0 5B BB AA B6 AB 5D B2 06 C4 09 01 03 
//01 1C 00 0E 00 CD A5 CA F7 C7 E5 B7 E7 5B BB AA B6 AB 5D 4E 05 C4 09 01 03
//01 21 00 0E 00 B4 F3 C3 CE B6 D8 BB CD 5B BB AA B6 AB 5D D9 04 C4 09 01 03 
//01 35 00 0E 00 CB AD D3 EB D5 F9 B7 E6 5B CE F7 C4 CF 5D 0B 07 98 08 01 10
//01 37 00 0E 00 B7 E7 C6 F0 D4 C6 D3 BF 5B CE F7 C4 CF 5D 28 06 98 08 01 10 
//01 3A 00 0A 00 BF AD D0 FD 5B BB AA D6 D0 5D F5 01 D0 07 01 11
//01 3B 00 0A 00 B7 E9 BB F0 5B BB AA D6 D0 5D 88 01 61 06 01 11 
//01 3C 00 0E 00 B9 FA CA BF CE DE CB AB 5B BB AA D6 D0 5D 04 06 D0 07 01 11
//01 5F 00 0E 00 CD F2 B3 AF B9 E9 D2 BB 5B C0 B6 B7 FE 5D 08 02 E8 03 01 1B
//01 75 00 0A 00 B2 D4 F1 B7 5B BB AA B6 AB 5D E3 06 FC 08 01 28
//01 76 00 09 00 F0 A9 D4 C2 5B 56 49 50 5D BF 03 DC 05 01 28
//01 BA 00 0E 00 BF AA CC EC B1 D9 B5 D8 5B BB AA C4 CF 5D B3 05 C4 09 01 28
//01 D4 00 0D 00 C2 E5 BF CB 5B 56 49 50 D0 C2 B7 FE 5D A7 05 DC 05 01 1B
//00

var
  ServerNameList: TStringList = NIL;

Procedure AddToServerList (Name: String; ID: WORD);
begin
  if not assigned (ServerNameList) then
    ServerNameList := TStringList.Create;
  ServerNameList.AddObject(Name, Pointer(ID));
end;

Function GetServerID (Name: String; Out ID: WORD): BOOL;
var
  Index: Integer;
begin
  Result := False;
  Index := ServerNameList.IndexOf(Name);
  if Index >= 0 then 
  begin
    ID := WORD (ServerNameList.Objects[Index]);
    Result := True;
  end;
end;

Procedure RecordServerList (Buffer: LPTHeadStruct; BufLen: Integer);
var
  ScanSign: PByte;
  ContentLen, ServerID: WORD;
  ServerName: String;
begin
  ScanSign := Pointer (Integer(Buffer) + SizeOf(THeadStruct));
  while ScanSign^ <> 0 do
  begin
    Inc (ScanSign, 2);
    ContentLen := PWORD(ScanSign)^;
    Inc (ScanSign, ContentLen + 2);
  end;

  Inc (ScanSign);

  while ScanSign^ <> 0 do
  begin
    Inc (ScanSign);
    ServerID := PWORD(ScanSign)^;

    Inc (ScanSign, 2);
    ContentLen := PWORD(ScanSign)^;
                       
    Inc (ScanSign, 2);
    SetString (ServerName, PChar(ScanSign), ContentLen);   

    Inc (ScanSign, ContentLen + 6);           

    AddToServerList (ServerName, ServerID);
    DbgFmt ('������ID = [$%x] %s', [ServerID, ServerName]);
  end;

end;

//�����б�
//Recv =
//C3 00 07 B0 00 00
//02 01 03 77 07 00 00
//
//06 00 CF B9 D7 D3 41 41 //Ϲ��AA 2
//22 01 00 00 00 00 00 00 00 00 14 00 14 00 00 00 C8 00 00 00 C8 00 00 00 00 00 00 00 04 35 0E 00 00 00 36 0E 00 00 00 37 0E 00 00 00 33 0E 00 00 00 00 69 3A//00 00
//
//07 00 4A 61 73 43 61 6D 72 //JasCamr 0
//22 03 39 00 00 00 00 00 00 00 16 00 16 00 06 00 E4 00 00 00 E4 00 00 00 00 00 00 00 04 8A 2D 00 00 00 8B 2D 00 00 00 8C 2D 00 00 00 B2 2A 00 00 00 00 64 3A //00 00
//
//06 00 64 64 6F 61 6E 64    //ddoand 1
//22 01 00 00 00 00 00 00 00 00 14 00 14 00 00 00 C8 00 00 00 C8 00 00 00 00 00 00 00 05 8D 2D 00 00 00 8E 2D 00 00 00 8F 2D 00 00 00 B8 2A 00 00 00 B9 2A 00//00 00
//
//00

var
  CharCountFromPacket: Integer = -1;
  
Procedure RecordCharList (Buffer: LPTHeadStruct; BufLen: Integer);
begin
  CharCountFromPacket := Byte(PChar(Buffer)[8]);
end;

Procedure RecvPacketCallBack (Buffer: Pointer; BufLen: Integer); Stdcall;
var
  Packet: LPTHeadStruct absolute Buffer;
begin
  if Packet.PacketType = $00 then
  begin
    PrintBuffer ('Recv =', Buffer, BufLen);

    if Packet.ContentType = $A101 then
      RecordServerList (Packet, BufLen);

    if Packet.ContentType = $B007 then
      RecordCharList (Packet, BufLen);
  end else
  begin
    PrintBuffer ('RecvH =', Buffer, SizeOf(THeadStruct));
  end;

end;

var
  HBCounter: Integer = 0;
  RPCounter: Integer = 0;

Procedure HeartBeat;
begin
  Inc (HBCounter);
end;

Procedure ReportPacket;
begin
  Inc (RPCounter);
end;

Function WaitHeartBeat (TimeOut: DWORD): BOOL;
var
  BeginTick: DWORD;
begin
  BeginTick := GetTickCount;
  HBCounter := 0;
  RPCounter := 0;
  Repeat
    Sleep (100);
    if GetTickCount - BeginTick > TimeOut then
    begin
      Result := False;
      Exit;
    end;
  until (HBCounter > 0) or (RPCounter > 3);
  Result := True;
end;


Procedure SendPacketCallBack (Buffer: Pointer; BufLen: Integer); Stdcall;
var
  Packet: LPTHeadStruct absolute Buffer;
begin
  PrintBuffer ('Send =', Buffer, BufLen);

  if BufLen = 6 then
  begin
    if Packet.ContentLen = 0 then      //00 00 02 20 22 40
      if Packet.ContentType = $2002 then
        HeartBeat;
    Exit;
  end;

  if Packet.ContentType = $6110 then
    if Packet.PacketType = 0 then
      ReportPacket;
end;

var
  ProgHandle: THandle;

Procedure Progress (Hint: String; Value: Integer);
begin
  Hint := format ('%s [%d%%]', [Hint, Value]);
  ReportProgress (ProgHandle, PChar(Hint), Value);
end;

procedure LoginRoutineProcedure;
var
  UserName, Password: String;
  ServerName, RoleName: String;
  BeginTick, ModTick: DWORD;
  Index, Persent: Integer;
  ServerID: WORD;
  procedure PrintTimePass (Head: String);
  begin
    Head := Trim(Head) + ' [��%d��]';
    DbgFmt (Head, [(GetTickCount - BeginTick) div 1000]);
  end;
begin
  DbgFmt ('��½�߳����� %s', [TimeToStr(Now)]);
  BeginTick := GetTickCount;

  UserName := StrPas(GetJsonParam ('��Ϸ�ʺ���'));
  Password := StrPas(GetJsonParam ('��Ϸ����'));
  ServerName := StrPas(GetJsonParam ('��Ϸ������'));
  RoleName := StrPas(GetJsonParam ('�����ɫ��'));

  Persent := 1;
  Repeat
    Sleep(300);
    ModTick := (GetTickCount - BeginTick) mod 1000;
    if ModTick < 300 then
    begin
      Inc(Persent);
      Progress ('��Ϸ���ڳ�ʼ��', Persent);
    end;
  Until Assigned (ServerNameList);

  if not GetServerID (ServerName, ServerID) then
  begin
    DbgFmt ('���������ô���%s', [ServerName]);
    Exit;
  end;

  Progress ('��ʼ��½�˻�', 50);

  PrintTimePass (Format ('��ʼ��½ %s [$%x]', [ServerName, ServerID]));

  if not LoginAccount (PChar(UserName), PChar(Password), ServerID, 0) then
  begin
    DebugPrint ('��¼ʧ��[LoginAccount]');
    Exit;
  end;

  Progress ('��¼�ɹ����ȴ������б�', 60);

  Repeat
    Sleep(100);
  until CharCountFromPacket <> -1;

  if CharCountFromPacket = 0 then
  begin
    DebugPrint ('�ʺ���û�н�ɫ���Զ���¼�˳�');
    Exit;
  end;

  Index := GetCharacterIndex (PChar(RoleName), 30 * 1000);
  if Index = -1 then
  begin
    Index := 0;
    PrintTimePass (format('�����ɫ��%s�� ��������˻��Ĭ��ѡ��һ������', [RoleName]));
  end;
    
  PrintTimePass (format('ѡ�˲˵�׼����ϣ�ѡ��[%d]��%s��', [Index, RoleName]));
  Progress ('�Ѿ���ȷѡ���ɫ', 70);

  if not WaitHeartBeat (60 * 1000) then
  begin
    PrintTimePass ('ѡ�˳�ʱ�ˣ���������ͨ�š�');
    Exit;
  end;

  PrintTimePass ('��ʼѡ�˲�������Ϸ����');
  Progress ('ѡ�˲�������Ϸ����', 80);

  Try
    if not EnterGameWorld (Index) then
      PrintTimePass ('RunCharacter = False');
  Except
    PrintTimePass ('ѡ�˴����쳣������');
  End;

  Progress ('�ɹ�������Ϸ����', 100);
  Sleep (1000);
  
  PrintTimePass ('��½�߳̽���');
end;

procedure LoginRoutineProc (Param: Pointer); Stdcall;
begin
  ProgHandle := OpenProgressWindow ('˿·��˵�Զ���¼����');
  Try
    LoginRoutineProcedure;
  Finally
    CloseProgressWindow (ProgHandle);
  end;
end;

var
  GetCommandLineA_Raw: Pointer;
  GetCommandLineA_Real: function : PAnsiChar; stdcall;
  CmdLine: String;

function GetCommandLineA_Hook: PAnsiChar; stdcall;
begin
  Result := PChar(CmdLine);           
end;            

Procedure MakeCommandLine;
var
  Index: integer;
  AearType, ServerAddr, SampleAddr: String;
  AreaNum, ServNum: Integer;
  wsaData: TWSADATA;
  HostEnt: PHostEnt;
  s: TSocket;
  svr: TSockAddrIn;
  InAddr: TInAddr;
begin
  AearType := GetJsonParam ('��Ϸ�����');
  if AearType = '����һ��' then
  begin
    AreaNum := 0;
    SampleAddr := 'shlogin%d.srocn.com';
  end else
  if AearType = '��ͨһ��' then
  begin
    AreaNum := 1;
    SampleAddr := 'bjlogin%d.srocn.com';
  end else
  begin
    AreaNum := 0;
    SampleAddr := 'shlogin%d.srocn.com';
    DbgFmt ('��Ϸ��������ô����ˣ� %s', [AearType]);
  end;

  ZeroMemory (@wsaData, SizeOf(TWSADATA));
	WSAStartup(MAKEWORD(2, 2), wsaData);

  ServNum := -1;
  for Index := 1 to 4 do
  begin
    ServerAddr := Format (SampleAddr, [Index]);
    HostEnt := GetHostByName (PChar(ServerAddr));
    if Assigned (HostEnt) then
    begin
      s := socket(AF_INET, SOCK_STREAM, IPPROTO_IP);

      InAddr := PInAddr(PDWORD(HostEnt.h_addr)^)^;
      ZeroMemory (@svr, SizeOf(TSockAddrIn));
      svr.sin_addr := InAddr;
      svr.sin_family := AF_INET;
      svr.sin_port := htons(15779);
      
      DbgFmt (ServerAddr + ' = %s : %d', [inet_ntoa (InAddr), 15779]);

      if connect(s, @svr, SizeOf(svr)) = 0 then
      begin
        closesocket(s);
        ServNum := Index - 1;
        break;
      end;
      closesocket(s);
    end;
  end;

  WSACleanup();

  if ServNum = -1 then
  begin
    ServNum := 0;
    DbgFmt ('���Է�����״̬ʧ�ܣ� %d', [ServNum]);
  end;

  CmdLine := Format ('%s %d /%d %d %d'#0, [GetModuleName(0), 4678, 4, AreaNum, ServNum]);
  DbgFmt ('GetCommandLineA = %s', [CmdLine]);
end;


Procedure HandleGameData;
var
  hLibHandle: THandle;
  tid: dword;
begin
  MakeCommandLine;

  hLibHandle := LoadLibrary (kernel32);
  GetCommandLineA_Raw := GetProcAddress (hLibHandle, 'GetCommandLineA');
  @GetCommandLineA_Real := SMHookApi (GetCommandLineA_Raw, @GetCommandLineA_Hook);
  FreeLibrary (hLibHandle);

  SetPacketRecver (@RecvPacketCallBack);
  SetPacketSendHooker (@SendPacketCallBack);

  CreateThread (nil, 0, @LoginRoutineProc, nil, 0, tid);
end;


//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

Exports
  IsAutoSet name 'IsAutoSet',
  IsTargetApp  name 'IsTarget',
  GetParamList name 'ParamList',
  Usage name 'Help',
  PluginType name 'Type';

Function GetReservedParam: Pointer; Register;
asm
  mov eax,[ebp+16]       //[ebp+16] lpvReserved
end;

procedure DLLEntryPoint(dwReason : DWord);
begin
  case dwReason of
    DLL_PROCESS_ATTACH:
    begin
      @FindFuncEntry := lpvReserved^;
      @DebugPrint := FindFuncEntry (HASH_PlugBaseLibrary, HASH_DebugPrint);

      @SMHookApi := FindFuncEntry (HASH_PlugBaseLibrary, HASH_SMHookApi);
      @UnSMHookApi := FindFuncEntry (HASH_PlugBaseLibrary, HASH_UnSMHookApi);
      @GetJsonParam := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetJsonParam);
      @IsTargetProcess := FindFuncEntry (HASH_PlugBaseLibrary, HASH_IsTargetProcess);
      @ImportLibFunction := FindFuncEntry (HASH_PlugBaseLibrary, HASH_ImportLibFunction);
      @WriteMemory := FindFuncEntry (HASH_PlugBaseLibrary, HASH_WriteMemory);

      @ShowUserMessage := FindFuncEntry (HASH_PlugBaseLibrary, HASH_ShowUserMessage);
      @OpenProgressWindow := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OpenProgressWindow);
      @ReportProgress := FindFuncEntry (HASH_PlugBaseLibrary, HASH_ReportProgress);
      @CloseProgressWindow := FindFuncEntry (HASH_PlugBaseLibrary, HASH_CloseProgressWindow);

      @LoginAccount := ImportLibFunction (IMPORT_LIB_NAME, 'LoginAccount');
      @SetPacketRecver := ImportLibFunction (IMPORT_LIB_NAME, 'SetPacketRecver');
      @SetPacketSendHooker := ImportLibFunction (IMPORT_LIB_NAME, 'SetPacketSendHooker');
      @GetCharacterIndex := ImportLibFunction (IMPORT_LIB_NAME, 'GetCharacterIndex');
      @EnterGameWorld := ImportLibFunction (IMPORT_LIB_NAME, 'EnterGameWorld');

      if IsTargetProcess then
        HandleGameData
      else
        DebugPrint ('IsTargetProcess = False, SilkRoad Exit');

      DebugPrint ('SilkRoad DLLEntryPoint'#0);
    end;
    DLL_PROCESS_DETACH: DebugPrint ('DLL_PROCESS_DETACH');
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
