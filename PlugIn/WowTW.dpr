library WowTW;

uses
  SysUtils, Windows, SyncObjs, Winsock2, tlhelp32, formatfunction,
  Classes, GlobalObject;


{$I PlugBase.inc}

const
  //系统要求
  Param_Depend_Daemon     = 'Daemon=<>请不要改变此默认值';    //在不设置时，就是默认值
  Param_Depend_PlugBase   = 'PlugBase=<DefaultPlugBase.dll>请不要改变此默认值';  //在不设置时，就是默认值
  Param_Depend_Library    = 'PluginLib=<>需要预先加载的库,多个需逗号隔开';
  Param_PrivacyField      = 'PrivacyField=<游戏密码>不能改变此默认值，否则插件不能正常工作,多个需逗号隔开'; //当PasswordField为空时，表明该游戏不需密码。

  //用户输入字段配置
  Param_Account_UserName  = '游戏帐号名=<>游戏运营商账户平台名称';
  Param_Account_Password  = '游戏密码=<>填入游戏运营商账户对应密码，可留空，但填了就作为默认密码了';
  Param_Game_Server       = '游戏服务器=<>请填入服务器名称，记住要完整填入';
  Param_Character_Name    = '人物角色名=<>填入你要自动登录的游戏角色名称';


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
    Append(Param_Account_UserName);
    Append(Param_Account_Password);
    Append(Param_Game_Server);
    Append(Param_Character_Name);
    ResultTmp := Text;
    Result := PChar(ResultTmp);
  finally
    Free;
  end;     
end;

function IsTargetApp (AppPath: PChar): BOOL; Stdcall;
var
  AimPath, AppExe: String;
begin
  Result := False;
  AimPath := ExtractFilePath (StrPas(AppPath));
  Repeat
    AppExe := Format ('%sWow.exe', [AimPath]);
    if not FileExists (AppExe) then Break;

    AppExe := Format ('%sWowError.exe', [AimPath]);
    if not FileExists (AppExe) then Break;

    Result := True;
  until True;
end;

function IsAutoSet: BOOL; Stdcall;
begin
  Result := False;
end;

function Usage: PChar; Stdcall;
begin
  Result := '这是TYPE_PLUGIN WowTW.dll插件的使用帮助';
end;

function PluginType: PChar; Stdcall;
begin
  Result := TYPE_PLUGIN;
end;

//////////////////////////////////////////////////////////////////
///                   以下业务代码
/////////////////////////////////////////////////////////////////

Type
  TReportAddress = Procedure (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;
  TSyncQueueProcedure = procedure (Sender:Pointer; Buffer:Pointer; Size:Integer; var Rollback: BOOL); Stdcall;

  PRegInfo = ^TRegInfo;
  TRegInfo = packed record
   EDI,
   ESI,
   EBP,
   ESP,
   EBX,
   EDX,
   ECX,
   EAX:DWORD;
  end;

  TCallBackFunc        = function(pReg:pointer):DWORD;stdcall;
  TCheckCanBeHook      = function (HookAddr: Pointer):LongBool;stdcall;
  TRecvPacketCallBack  = Procedure (Buffer: Pointer; BufLen: Integer); Stdcall;

var
  IsDebugMode: BOOL;
  lpvReserved: PPointer;
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  DebugPrint: Procedure (Msg: PChar); stdcall;
     
  MakeTemplate: function (Base: Pointer; Size: Integer): THandle; stdcall;
  FreeTemplate: function (TmpHandle: THandle): LongBool; Stdcall;
  SearchAddress: function (TmpHandle: THandle; Sender: Pointer; ToFind: PChar; ToFindSize: Integer; Report: TReportAddress): LongBool; Stdcall;
  GetSectionMemory: Function (Handle: THandle; SectionName: PChar; var CodeBase: Pointer; var CodeSize: Integer):LongBool;stdcall;
  SMHookApi: function (FuncEntry, Hooker: Pointer): Pointer; stdcall;
  UnSMHookApi: function (FuncEntry: Pointer): LongBool; stdcall;
  SetHook: function (HookAddress, JumpBackAddress, fnCallBack, fnCanBeHook : Pointer): LongBool; stdcall;
  UnHook: function (HookAddress: pointer): LongBool; stdcall;
  GetJsonParamA: function  (Path: PChar): PChar; Stdcall;
  WriteMemory: function (pAddress:pointer; pBuf:pointer; dwLen:dword):LongBool; stdcall;
  IsTargetProcess: Function (): BOOL;

  ShowUserMessage: function (MsgSL: PChar): BOOL; Stdcall;
  OpenProgressWindow: function (Caption: PChar): THandle; Stdcall;
  ReportProgress: function (ProHandle: THandle; Hint: PChar; Progress: Integer): BOOL; Stdcall;
  CloseProgressWindow: function (ProHandle: THandle): BOOL; Stdcall;

  MakeSyncQueue: function (Handler: TSyncQueueProcedure; DurationIdleTime: DWORD = 10000): THandle; Stdcall;
  PushSyncQueue: Procedure (Handle: THandle; Sender, Buffer: Pointer; Size: Integer); Stdcall;
  GetSyncQueueCount: function (Handle: THandle): Integer; Stdcall;
  FreeSyncQueue: Procedure (Handle: THandle); Stdcall;

Procedure DbgFmt (const FmtStr: string; const Args: array of const);
var
  dbgstr: string;
begin
  dbgstr := Format (FmtStr, Args);
  DebugPrint (@dbgstr[1]);
end;


//Procedure PrintBuffer (Head: String; Buffer: PChar; BufLen: Integer);
//var
//  PrintSL: TStringList;
//begin
//    PrintSL := TStringList.Create;
//    PrintSL.Add(Head + IntToStr(BufLen));
//    PcharToFormatedViewUtf8 (Buffer, BufLen, 0, PrintSL);
//    DebugPrint (PChar(PrintSL.Text));
//    PrintSL.Free;
//end;

Procedure PrintBuffer (Head: String; Buffer: PChar; BufLen: Integer);
var
  PrintSL: TStringList;
  Msg: String;
begin
  if BufLen > 16 then BufLen := 16;

  PrintSL := TStringList.Create;
  PcharToFormatedViewNull (Buffer, BufLen, PrintSL);
  Msg := Head + PrintSL[0];
  DebugPrint (PChar(Msg));
  PrintSL.Free;
end;


var
  SendRaw: Pointer;
  SendReal: function (s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
  RecvRaw: Pointer;
  RecvReal: function (s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;


function send_Hook(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
begin
  Result := SendReal (s, buf, len, flags);
  if Result = SOCKET_ERROR  then
    DebugPrint ('SendR: SOCKET_ERROR')
  else
    PrintBuffer ('SendR:', @buf, Result);
end;

function recv_Hook(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
begin
  Result := RecvReal (s, buf, len, flags);
  if Result =  SOCKET_ERROR  then
    DebugPrint ('RecvR: SOCKET_ERROR')
  else
    PrintBuffer ('RecvR:', @buf, Result);
end;

Procedure SetSendHook;
var
  libHandle: Thandle;
begin
  libHandle := LoadLibrary ('ws2_32.dll');

  SendRaw := GetProcAddress (libHandle, 'send');
  @SendReal := SMHookApi (SendRaw, @send_Hook);

  RecvRaw := GetProcAddress (libHandle, 'recv');
  @RecvReal := SMHookApi (RecvRaw, @recv_Hook);

  FreeLibrary (libHandle);
end;

Procedure UnSetSendHook;
begin
  UnSMHookApi (SendRaw);
end;


var
  EnterCrtsCounter: DWORD;

function IsHeartBeatException: BOOL;
var
  OldCtrs: DWORD;
begin
  OldCtrs := EnterCrtsCounter;
  Sleep(500);
  Result := EnterCrtsCounter - OldCtrs < 10;
end;

//------------------------------------------------------------------------------
//
//                          封包分析和采集
//
//------------------------------------------------------------------------------

Type
  LPTStorePacket = ^TStorePacket;
  TStorePacket = packed record
    Length: Integer;
    Buffer: Array[word] of byte;
  end;
  TSelectCharState = (scNone, scSucceed, scFailure);
  TPacketType = (ptSendLogin, ptRecvLogin, ptSend, ptRecv);

var
  LoginSend, LoginRecv, SendSL, RecvSL: TThreadList;
  DisableRecord: BOOL;
  CharNameList: TStringList;
  SelectCharState: TSelectCharState = scNone;
  DefaultCharName: String;
  hSyncPacket: THandle = 0;

Procedure MakeCachePakcetSL;
begin
  LoginSend := TThreadList.Create;
  LoginRecv := TThreadList.Create;
  SendSL := TThreadList.Create;
  RecvSL := TThreadList.Create;
end;

Procedure CleanAList (TSL: TThreadList);
var
  Item: Pointer;
  AimList: TList;
begin
  AimList := TSL.LockList;
  for Item in AimList do
    FreeMem (Item);
  AimList.Clear;
  TSL.UnlockList;
end;

Procedure ClearCachePakcetSL;
begin
  CleanAList (LoginSend);
  CleanAList (LoginRecv);
  CleanAList (SendSL);
  CleanAList (RecvSL);
end;

Procedure FreeCachePakcetSL;
begin
  ClearCachePakcetSL;
  FreeAndNil (LoginSend);
  FreeAndNil (LoginRecv);
  FreeAndNil (SendSL);
  FreeAndNil (RecvSL);
end;

Procedure RecordPacketToSL (List: TThreadList; Buffer: Pointer; BufLen: Integer);
var
  Item: LPTStorePacket;
begin
  if DisableRecord then Exit;

  if Assigned (List) then
  begin
    Item := AllocMem (BufLen + SizeOf(Integer) + 4);
    Item.Length := BufLen;
    CopyMemory (@Item.Buffer[0], Buffer, Item.Length);
    List.Add(Item);
  end;
end;

var
//选人Index地址     //台服
//00485FE9  |.  8B88 C02D0000      mov ecx,dword ptr ds:[eax+2DC0]
//00485FEF  |.  8B15 74090B01      mov edx,dword ptr ds:[10B0974]     << target value
//00485FF5  |.  890D 04890D01      mov dword ptr ds:[10D8904],ecx
//00485FFB  |.  33C9               xor ecx,ecx
//00485FFD  |.  8935 04D00301      mov dword ptr ds:[103D004],esi
//00486003  |.  8B42 30            mov eax,dword ptr ds:[edx+30]
//00486006  |.  3BC6               cmp eax,esi
//00486008  |.  0F9CC1             setl cl                  
//0048600B  |.  83E9 01            sub ecx,1
//0048600E  |.  23C1               and eax,ecx
//00486010  |.  3B05 14890D01      cmp eax,dword ptr ds:[10D8914]
//00486016  |.  7C 02              jl short Wow.0048601A      << anchor
//00486018  |.  33C0               xor eax,eax
//0048601A  |>  A3 D4D10301        mov dword ptr ds:[103D1D4],eax
//0048601F  |.  E8 4CF6FFFF        call Wow.00485670
//00486024  |.  8B15 D4D10301      mov edx,dword ptr ds:[103D1D4]

//网易                                    
//007BA7F0  |> \8B15 74690601      mov edx,dword ptr ds:[1066974]  << target value
//007BA7F6  |.  C705 E460A400 0000>mov dword ptr ds:[A460E4],0
//007BA800  |.  8B42 30            mov eax,dword ptr ds:[edx+30]
//007BA803  |.  33D2               xor edx,edx
//007BA805  |.  85C0               test eax,eax
//007BA807  |.  0F9CC2             setl dl       
//007BA80A  |.  83EA 01            sub edx,1     
//007BA80D  |.  23C2               and eax,edx
//007BA80F  |.  3BC1               cmp eax,ecx
//007BA811  |.  7C 02              jl short Wow.007BA815   << anchor
//007BA813  |.  33C0               xor eax,eax                << anchor2
//007BA815  |>  A3 8462A400        mov dword ptr ds:[A46284],eax
//007BA81A  |.  E8 31F7FFFF        call Wow.007B9F50
//007BA81F  |.  A1 8462A400        mov eax,dword ptr ds:[A46284]
//007BA824  |.  83C0 01            add eax,1
//007BA827  |.  50                 push eax                                ; /Arg3
//007BA828  |.  68 EC259800        push Wow.009825EC                       ; |Arg2 = 009825EC ASCII "%d"
  DefaultCharIndexAddr: Pointer;
  MARK_SELECT_CHAR_STRING : ARRAY[0..4] OF BYTE = ($7C,$02,$33,$C0,$A3);
                         

Procedure SetSelectCharIndex (CharIndex: Integer);
asm
  push edx
  mov edx, DefaultCharIndexAddr
  mov edx, [edx]
  mov [edx + $30],eax
  pop edx
end;            

function GetBackwardMarkAddr (SrcAddr, Mark: Pointer; MarkSize: Integer; MaxFoot: Integer): Pointer;
var
  Scan: Pointer;
begin
  Result := NIL;
  Scan := SrcAddr;
  Repeat
    Dec(PChar(Scan));
    if CompareMem (Scan, Mark, MarkSize) then
    begin
      Result := Scan;
      Exit;
    end;
  until Integer(SrcAddr) - Integer(Scan) > MaxFoot;
end;

Procedure ReportSelectCharAddr (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;
const
  MarkA : Array[0..2] of byte = ($8B,$42,$30);
  MarkB : Array[0..1] of byte = ($8B,$15);
var
  List: TList absolute Sender;
  Target: Pointer;
begin
  Target := GetBackwardMarkAddr (Found, @MarkA, SizeOf(MarkA), $007BA828 - $007BA7F0);
  if Target = NIL then Exit;

  Target := GetBackwardMarkAddr (Target, @MarkB, SizeOf(MarkB), $007BA828 - $007BA7F0);
  if Target = NIL then Exit;

  Inc(PChar(Target), 2);
  Target := PPointer(Target)^;

  List.Add(Target);
  BreakReport := True;
end;

Procedure RecvCallBack (Buffer: Pointer; BufLen: Integer);
var
  Name: String;
  ScanIter: PChar;
  ScanValue: DWORD;
  CharCount: ShortInt;
  Index: Integer;
begin
  Repeat
    //3B 00 04 8C 14 EC 00 00 00 00 02 E5 81 A5 E6 AC
    //A1 E9 83 8E 00 06 07 00 06 03 06 02 03 01 00 00
    //00 00 01 00 00 00 48 59 36 C5 71 FD 80 C3 B9 FC
    //53 42 00 00 00 00 00 00 00 00 00 00 00 00 01 00
    if BufLen < 32 then Break;
    if PWORD (Buffer)^ <> $003B then Break;
    CharCount := ShortInt(PChar(Buffer)[2]);
    if CharCount <= 0 then Break;

    ScanIter := @PChar(Buffer)[7];
    ScanValue := PDWORD(ScanIter)^;

    if Not Assigned (CharNameList) then
      CharNameList := TStringList.Create;
    CharNameList.Clear;
    SelectCharState := scNone;

    Repeat
      if PDWORD(ScanIter)^ = ScanValue then
      begin
        Dec(ScanIter, 4);
        if PDWORD(ScanIter)^ <> 0 then
        begin
          Inc (ScanIter, 8);
          if Byte(ScanIter^) > 32 then
          begin
            Name := StrPas (ScanIter);
            Name := Utf8ToAnsi (Name);
            CharNameList.Add(Name);

            Inc (ScanIter, StrLen(ScanIter));
            Dec(CharCount);
          end;
        end;
        Inc (ScanIter, 4);
      end;

      Inc (ScanIter);
    until Integer(ScanIter)-Integer(Buffer) >= BufLen;

    if CharCount = 0 then
    begin
      DbgFmt ('游戏角色列表：'#13#10'%s', [CharNameList.Text]);
      if DefaultCharName = '' then
        DefaultCharName  := GetJsonParamA ('人物角色名');
      Index := CharNameList.IndexOf(DefaultCharName);
      if Index >= 0 then
      begin
        DbgFmt ('选择了[%d]%s', [Index, DefaultCharName]);
        SelectCharState := scSucceed;
        SetSelectCharIndex (Index);
      end else
        SelectCharState := scFailure;
    end else
      DebugPrint ('分析角色列表错误');   
  until True;
end;

//异步处理封包事件
procedure SyncPacketQueueHandler (Sender:Pointer; Buffer:Pointer; Size:Integer; var Rollback: BOOL); Stdcall;
var
  PacketType: TPacketType absolute Sender;
  ToHandleSL: TThreadList;
  HeadStr: String;
begin
  case PacketType of
    ptSendLogin: begin
      ToHandleSL := LoginSend;
      HeadStr := 'SendL: ';
    end;
    ptRecvLogin: begin
       ToHandleSL := LoginRecv;
      HeadStr := 'RecvL: ';
    end;
    ptSend: begin
      ToHandleSL := SendSL; 
      HeadStr := 'Send : ';
    end;
    ptRecv: begin
      ToHandleSL := RecvSL;
      HeadStr := 'Recv : ';
    end;
    Else Exit;
  end;

  RecordPacketToSL (ToHandleSL, Buffer, Size);
  if IsDebugMode then
    PrintBuffer (HeadStr, Buffer, Size);
end;

//同步处理封包事件
Procedure ImportPacketQueue (PacketType: TPacketType; Buffer:Pointer; Size:Integer);
begin
  case PacketType of
    ptSendLogin: ;
    ptRecvLogin: ;
    ptSend: ;
    ptRecv: RecvCallBack (Buffer, Size);
  end;

  if hSyncPacket = 0 then Exit;    
  PushSyncQueue (hSyncPacket, Pointer (PacketType), Buffer, Size);
end;

//------------------------------------------------------------------------------
//
//                          登录流程
//
//------------------------------------------------------------------------------

////登录接口
//0047BB90  /$  55                push ebp
//0047BB91  |.  8BEC              mov ebp,esp
//0047BB93  |.  803D 142B0C01 00  cmp byte ptr ds:[10C2B14],0
//0047BB9A  |.  0F84 00010000     je Wow.0047BCA0
//0047BBA0  |.  833D A8260C01 00  cmp dword ptr ds:[10C26A8],0
//0047BBA7  |.  0F84 F3000000     je Wow.0047BCA0
//0047BBAD  |.  833D B0260C01 00  cmp dword ptr ds:[10C26B0],0
//0047BBB4  |.  0F84 E6000000     je Wow.0047BCA0
//0047BBBA  |.  833D 90210C01 00  cmp dword ptr ds:[10C2190],0
//0047BBC1  |.  0F85 D9000000     jnz Wow.0047BCA0
//0047BBC7  |.  8B45 08           mov eax,dword ptr ss:[ebp+8]
//55 8B EC 80 3D 14 2B 0C 01 00 0F 84 00 01 00 00 83 3D A8 26 0C 01 00 0F 84 F3 00 00 00 83 3D B0

//0047EFFD  |.  83C4 0C           add esp,0C
//0047F000  |.  50                push eax                                         ; |Arg1
//0047F001  |.  E8 8ACBFFFF       call wow.0047BB90                                ; \wow.0047BB90
//0047F006  |.  83C4 08           add esp,8
//0047F009  |.  33C0              xor eax,eax
const
  MARK_LOGIN_STRING: ARRAY[0..4] OF BYTE = ($55,$8B,$EC,$80,$3D);
var
  LoginEntryAddr: Pointer;
  Condition1, Condition2, Condition3, Condition4: Pointer;
  ProgHandle: THandle;
  ProgValue: Integer;

Procedure SearchLoginAddress (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;
var
  List: TList absolute Sender;
  cmpSign: PWORD;
  cmpValue: PPointer;
begin
  cmpSign := Pointer (Integer(Found) + ($0047BBA0 - $0047BB90));
  if cmpSign^ <> $3D83 then Exit;
  
  cmpSign := Pointer (Integer(Found) + ($0047BBAD - $0047BB90));
  if cmpSign^ <> $3D83 then Exit;

  cmpSign := Pointer (Integer(Found) + ($0047BBBA - $0047BB90));
  if cmpSign^ <> $3D83 then Exit;

  LoginEntryAddr := Found;
  
  cmpValue := Pointer (Integer(Found) + ($0047BB93 - $0047BB90 + 2));
  Condition1 := cmpValue^;

  cmpValue := Pointer (Integer(Found) + ($0047BBA0 - $0047BB90 + 2));
  Condition2 := cmpValue^;

  cmpValue := Pointer (Integer(Found) + ($0047BBAD - $0047BB90 + 2));
  Condition3 := cmpValue^;

  cmpValue := Pointer (Integer(Found) + ($0047BBBA - $0047BB90 + 2));
  Condition4 := cmpValue^;  

  List.Add(Found);
  BreakReport := True;
end;

function IsLonginPresent: BOOL;
asm
  push ebx
  mov eax,0

  mov ebx,Condition1
  cmp byte ptr ds:[ebx],0
  je @NoExit

  mov ebx,Condition2
  cmp dword ptr ds:[ebx],0
  je @NoExit

  mov ebx,Condition3
  cmp dword ptr ds:[ebx],0
  je @NoExit

  mov ebx,Condition4
  cmp dword ptr ds:[ebx],0
  jnz @NoExit
  
  mov eax,1
@NoExit:
  pop ebx
end;


Procedure LoginEntry (UserID, PassWD: PChar); 
asm
  pushfd
  pushad

  push edx
  push eax
  mov edx, LoginEntryAddr
  call edx
  add esp,8
  
  popad
  popfd
end;

function WaitForLoginCompleted (TimeOut: DWORD): BOOL;
var
  BeginTick: DWORD;
  Item: LPTStorePacket;
  Index, ScanIndex: Integer;
  AimLst: TList;
begin
  BeginTick := GetTickCount;
  Result := False;
  ScanIndex := 0;
  Repeat
    sleep (500);
    AimLst := RecvSL.LockList;
    Try
      for Index := ScanIndex to AimLst.Count - 1 do
      begin
        Item := AimLst[Index];
        //Recv : 8B 03 FF FF FF FF 00 00 00 00 30 31 2F 30 31 2F
        if Item.Length > 2 then     
        if PWORD(@Item.Buffer[0])^ = $038B then
        begin
          Result := True;
          Exit;
        end;
      end;
      ScanIndex := AimLst.Count;
    finally
      RecvSL.UnlockList;
    end;
    if GetTickCount - BeginTick > TimeOut then Exit;
  until False;
end;

function SendKeyEnter: THandle;
begin
  Result := FindWindow('GxWindowClassD3d',nil);
  PostMessage(Result, $0100, VK_RETURN,0);
  PostMessage(Result, $0101, VK_RETURN,0);
end;

function PressEnterGameWorld (TimeOut: DWORD): BOOL;
var
  BeginTick: DWORD;
  Item: LPTStorePacket;
  Index, ScanIndex: Integer;
  ToCheck: PDWORD;
  AimLst: TList;
begin
  BeginTick := GetTickCount;
  Result := False;
  //Send: 09 04 00 00 00 00 00 00   //Send_2: 3D 00 00 00 8C 14 EC 00 00 00 00 02
  //Recv_1: 29 03 00 00 00 00 01 00 00 00 00 00 00 00
  ScanIndex := 0;
  Repeat
    SendKeyEnter;
    Sleep(800);
    AimLst := SendSL.LockList;
    Try
      for Index := ScanIndex to AimLst.Count - 1 do
      begin
        Item := AimLst[Index];
        ToCheck := @Item.Buffer[0];
        if Item.Length > 4 then
        if (ToCheck^ = $00000409) or (ToCheck^ = $0000003D) then
        begin
          Result := True;
          Exit;
        end;
      end;
      ScanIndex := AimLst.Count;
    finally
      SendSL.UnlockList;
    end;       
    if GetTickCount - BeginTick > TimeOut then Exit;
    Sleep (500);
  until False;
end;

function WaitGameServerAccept (TimeOut: DWORD): BOOL;
var
  BeginTick: DWORD;
  Item: LPTStorePacket;
  Index, ScanIndex: Integer;
  AimLst: TList;
begin
  BeginTick := GetTickCount;
  Result := False;
  //Send: 09 04 00 00 00 00 00 00
  //Recv_1: 29 03 00 00 00 00 01 00 00 00 00 00 00 00
  ScanIndex := 0;
  Repeat
    sleep (300);
    AimLst := RecvSL.LockList;
    Try
      for Index := ScanIndex to AimLst.Count - 1 do
      begin
        Item := AimLst[Index];
        if Item.Length > 4 then
        if PDWORD(@Item.Buffer[0])^ = $00000329 then
        begin
          Result := True;
          Exit;
        end;
      end;
      ScanIndex := AimLst.Count;
    finally
      RecvSL.UnlockList;
    end;
    if GetTickCount - BeginTick > TimeOut then Exit;
  until False;
end;

Procedure WaitForInGameWorld;
begin
  Repeat
    sleep (500);
    if IsHeartBeatException then
    begin
      DebugPrint ('HeartBeat Exception');
      break;
    end;
  until false;
end;

Procedure Progress (Hint: String; Value: Integer);
begin
  Hint := format ('%s [%d%%]', [Hint, Value]);
  ReportProgress (ProgHandle, PChar(Hint), Value);
end;

function WaitForInitialComplete (TimeOut: DWORD): BOOL;
var
  BeginTick, TryCount: DWORD;
begin
  Result := False;
  BeginTick := GetTickCount;
  TryCount := 0;
  Repeat
    Sleep (500);
    Inc (TryCount);

    if TryCount mod 2 = 0 then
    begin
      Inc (ProgValue, 2);
      Progress ('游戏正在初始化', ProgValue);
    end;

    if TryCount mod 6 = 0 then
      DbgFmt ('Try Login: %d 秒', [(GetTickCount - BeginTick) div 1000]);

    if GetTickCount - BeginTick > TimeOut then Exit;

  until IsLonginPresent;
  Result := True;
end;
                          
function IsLoginSucceed (TimeOut: DWORD): BOOL;
var
  UserID, PassWD: String;
  BeginTick, SocketErr: DWORD;
  Index, ScanIndex: Integer;
  Item: LPTStorePacket;    
  AimLst: TList;
begin
  Result := False;
  BeginTick := GetTickCount;

  //直接call登录过程，凭socket状态判断是否正确按下
  Repeat
    UserID := GetJsonParamA ('游戏帐号名');
    PassWD := GetJsonParamA ('游戏密码');

    WSASetLastError (0);
    LoginEntry (@UserID[1], @PassWD[1]);
    SocketErr := WSAGetLastError;

    if SocketErr = 0 then Break;
    if SocketErr = WSAEWOULDBLOCK then Break;

    DbgFmt ('WSAGetLastError = %d', [SocketErr]);
    Sleep(500);
  Until GetTickCount - BeginTick > TimeOut;

  //从账户服务器封包活动来判断：是否已经正确登录
  ScanIndex := 0;
  Repeat
    Sleep(500);
    if GetTickCount - BeginTick > TimeOut then Exit;

    //扫描接受的封包
    AimLst := LoginRecv.LockList;
    Try
      for Index := ScanIndex to AimLst.Count - 1 do
      begin
        Item := AimLst[Index];
        //Recv1: 01 04 03 00
        if Item.Length = 4 then
          if PDWORD(@Item.Buffer[0])^ = $00030401 then
            Exit;
                                  
        //Recv3: 40 28 00 E8 00 00 00 00
        if Item.Length > 4 then
          if PDWORD(@Item.Buffer[0])^ = $E8002840 then
            Exit;

        //Recv1: 01 09
        if Item.Length >= 2 then
          if PWORD(@Item.Buffer[0])^ = $0901 then
            Exit;      
      end;
      ScanIndex := AimLst.Count;
    finally
      LoginRecv.UnlockList;
    end;

    //如果收到来自游戏服务器的封包，就表明登录成功了。
    AimLst := RecvSL.LockList;
    Result := AimLst.Count > 0;
    RecvSL.UnlockList;

    if not Result then
    begin
      AimLst := SendSL.LockList;
      Result := AimLst.Count > 0;
      SendSL.UnlockList;
    end;

  Until Result;
end;


Procedure LoginRoutine (Param: Pointer); Stdcall;
begin            
  ProgHandle := OpenProgressWindow ('魔兽世界自动登录进度');
  MakeCachePakcetSL;

  Repeat
    Progress ('游戏正在初始化', 1);

    if not WaitForInitialComplete (90*1000) then
    begin
      Progress ('初始化时间过长', 20);
      DebugPrint ('<--------------- WaitForInitialComplete = Time out  ------------------>');
      Break;
    end;

    Progress ('开始登录游戏账户', 40);
    SelectCharState := scNone;

    if not IsLoginSucceed (20*1000) then
    begin
      Progress ('超时或帐户密码错误', 50);
      DebugPrint ('<------------ IsLoginSucceed : Input Error, Or Time out  --------------->');
      Break;
    end;

    Progress ('成功登录账户，等待角色信息', 50);

    if not WaitForLoginCompleted (30*1000) then
    begin
      Progress ('识别账户信息异常', 60);
      DebugPrint ('<--------------- WaitForLoginCompleted = Time out  ------------------>');
      Break;
    end;

    if SelectCharState <> scSucceed then
    begin
      Progress ('没有选中指定的游戏角色', 65);
      DebugPrint ('<--------------- SelectCharState = scNone  ------------------>');
      Break;
    end;                         

    Progress ('向游戏世界请求登录', 60);

    ClearCachePakcetSL;

    if not PressEnterGameWorld (30*1000) then
    begin
      Progress ('无法登录游戏世界', 70);
      DebugPrint ('<--------------- PressEnterGameWorld = Time out  ------------------>');
      Break;
    end;

    Progress ('等待服务器认可并建立对话', 70);

    if not WaitGameServerAccept (10*1000) then
    begin
      Progress ('登录游戏世界失败', 80);
      DebugPrint ('<--------------- WaitGameServerAccept = Time out  ------------------>');
      Break;
    end;

  //  WaitForInGameWorld;      

    Progress ('成功登录游戏世界', 100);
  until True;

  DisableRecord := True;
  FreeCachePakcetSL;
  Sleep(1000);
  CloseProgressWindow (ProgHandle);

  DebugPrint ('LoginRoutine End');
end;

//------------------------------------------------------------------------------
//
//                          封包捕获钩子
//
//------------------------------------------------------------------------------


CONST
//主动发送接口
//005B5F60    55                   push ebp
//005B5F61    8BEC                 mov ebp,esp
//005B5F63    56                   push esi
//005B5F64    8BF1                 mov esi,ecx
//005B5F66    83BE 34050000 06     cmp dword ptr ds:[esi+534],6
//005B5F6D    75 67                jnz short Wow.005B5FD6
//005B5F6F    8B45 08              mov eax,dword ptr ss:[ebp+8]   <<anthor
//005B5F72    57                   push edi
//005B5F73    8B78 10              mov edi,dword ptr ds:[eax+10]
//005B5F76    2B78 14              sub edi,dword ptr ds:[eax+14]
//005B5F79    74 5A                je short Wow.005B5FD5
//005B5F7B    8B8E FC2C0000        mov ecx,dword ptr ds:[esi+2CFC]
//005B5F81    6A 00                push 0
//005B5F83    50                   push eax
//005B5F84    E8 978EE6FF          call Wow.0041EE20
//005B5F89    8B8E FC2C0000        mov ecx,dword ptr ds:[esi+2CFC]   <<target
//8B4508578B7810
///////////////////////////////////////////////////////////////////////  
//Send
//0019FDC0   006E90B7  返回到 Wow.006E90B7 来自 ntdll.RtlEnterCriticalSection
//0019FDC4   08906758
//0019FDC8   0041EE61  返回到 Wow.0041EE61 来自 Wow.006E90B0
//0019FDCC   00000008
//0019FDD0   06C28188
//0019FDD4   00000000
//0019FDD8   08906758
//0019FDDC   09E74AC8
//0019FDE0   00000002
//0019FDE4  /0019FDFC
//0019FDE8  |005B5F89  返回到 Wow.005B5F89 来自 Wow.0041EE20     << anchor
//0019FDEC  |0019FE14                              << target packet
//0019FDF0  |00000000
//0019FDF4  |06C2AEEC
//0019FDF8  |06C28188

  MARK_SEND_PACKET_STRING: ARRAY[0..6] OF BYTE = ($8B,$45,$08,$57,$8B,$78,$10);
  MARK_SEND_PACKET_OFFSET: INTEGER = $005B5F89 - $005B5F6F;

//主动发送接口  台服
//0041F150    55                   push ebp
//0041F151    8BEC                 mov ebp,esp
//0041F153    83EC 10              sub esp,10
//0041F156    53                   push ebx
//0041F157    56                   push esi
//0041F158    57                   push edi
//0041F159    8B7D 08              mov edi,dword ptr ss:[ebp+8]
//0041F15C    8B5F 10              mov ebx,dword ptr ds:[edi+10]
//0041F15F    53                   push ebx
//0041F160    8D45 F8              lea eax,dword ptr ss:[ebp-8]
//0041F163    8BF1                 mov esi,ecx
//0041F165    50                   push eax
//0041F166    8BCF                 mov ecx,edi
//0041F168    E8 332C0000          call Wow.00421DA0
//0041F16D    8BC3                 mov eax,ebx
//0041F16F    99                   cdq
//0041F170    0105 502E0B01        add dword ptr ds:[10B2E50],eax
//0041F176    8D8E 08010000        lea ecx,dword ptr ds:[esi+108]   <<anthor
//0041F17C    C745 FC 02000000     mov dword ptr ss:[ebp-4],2
//0041F183    1115 542E0B01        adc dword ptr ds:[10B2E54],edx
//0041F189    894D F0              mov dword ptr ss:[ebp-10],ecx
//0041F18C    E8 3FAF2C00          call Wow.006EA0D0
//0041F191    85DB                 test ebx,ebx               <<target
//0041F193    0F8E 80020000        jle Wow.0041F419
//8D8E08010000C745FC02000000
///////////////////////////////////////////////////////////////////////
//send2
//0019FAE8   006EA0D7  返回到 Wow.006EA0D7 来自 ntdll.RtlEnterCriticalSection
//0019FAEC   0A56D9B0
//0019FAF0   0041F191  返回到 Wow.0041F191 来自 Wow.006EA0D0   << anchor
//0019FAF4   00000004
//0019FAF8   0A569A60
//0019FAFC   13A67DD8
//0019FB00   0A56D9B0
//0019FB04   0019FB44
//0019FB08   153E1480
//0019FB0C   00000002
//0019FB10  /0019FB28
//0019FB14  |005B6509  返回到 Wow.005B6509 来自 Wow.0041F150
//0019FB18  |0019FB44                          << target packet


  MARK_SEND_PACKET_STRING2: ARRAY[0..12] OF BYTE = ($8D,$8E,$08,$01,$00,$00,$C7,$45,$FC,$02,$00,$00,$00);
  MARK_SEND_PACKET_OFFSET2: INTEGER = $0041F191 - $0041F176;


//接收拦截接口
//005B6710    55                   push ebp
//005B6711    8BEC                 mov ebp,esp
//005B6713    51                   push ecx
//005B6714    53                   push ebx
//005B6715    8BD9                 mov ebx,ecx
//005B6717    56                   push esi       << anthor
//005B6718    8D4B 04              lea ecx,dword ptr ds:[ebx+4]
//005B671B    57                   push edi
//005B671C    894D FC              mov dword ptr ss:[ebp-4],ecx
//005B671F    E8 8C291300          call Wow.006E90B0
//005B6724    6A 08                push 8             << target
//005B6726    6A FE                push -2
//568D4B0457894DFCE8
///////////////////////////////////////////////////////////////////////
//Recv
//121DFEC0   006E90B7  返回到 Wow.006E90B7 来自 ntdll.RtlEnterCriticalSection
//121DFEC4   0F1C062C
//121DFEC8   005B6724  返回到 Wow.005B6724 来自 Wow.006E90B0   << anchor
//121DFECC   0F2E8660
//121DFED0   121DFF28
//121DFED4   0000009F
//121DFED8   0F1C062C
//121DFEDC  /121DFF08
//121DFEE0  |005B6050  返回到 Wow.005B6050 来自 Wow.005B6710
//121DFEE4  |00000018
//121DFEE8  |100C6630
//121DFEEC  |0F2E8660
//121DFEF0  |11830E82       << target buffer
//121DFEF4  |0000009F       << target length

  MARK_RECV_PACKET_STRING: ARRAY[0..8] OF BYTE = ($56,$8D,$4B,$04,$57,$89,$4D,$FC,$E8);
  MARK_RECV_PACKET_OFFSET: INTEGER = $005B6724 - $005B6717;
                                     
//登录发包  - 台服
//0041F110  /$  55                push ebp
//0041F111  |.  8BEC              mov ebp,esp
//0041F113  |.  53                push ebx
//0041F114  |.  56                push esi
//0041F115  |.  57                push edi
//0041F116  |.  8B7D 0C           mov edi,dword ptr ss:[ebp+C]
//0041F119  |.  8BC7              mov eax,edi
//0041F11B  |.  99                cdq
//0041F11C  |.  0105 50CE0901     add dword ptr ds:[109CE50],eax
//0041F122  |.  8BF1              mov esi,ecx
//0041F124  |.  8D8E 08010000     lea ecx,dword ptr ds:[esi+108]
//0041F12A  |.  1115 54CE0901     adc dword ptr ds:[109CE54],edx
//0041F130  |.  BB 02000000       mov ebx,2                  << anthor
//0041F135  |.  894D 0C           mov dword ptr ss:[ebp+C],ecx
//0041F138  |.  E8 739F2C00       call Wow.006E90B0
//0041F13D  |.  807D 10 00        cmp byte ptr ss:[ebp+10],0  << target
//0041F141  |.  75 3E             jnz short Wow.0041F181
//0041F143  |.  80BE 74030000 00  cmp byte ptr ds:[esi+374],0
//0041F14A  |.  74 35             je short Wow.0041F181        
//BB 02 00 00 00 89 4D 0C E8
//-----------------------------------------------------------------------
// login send
//001AF548    006E90B7   返回到 wow.006E90B7 来自 ntdll.RtlEnterCriticalSection
//001AF54C    1D25C8E8
//001AF550    0041F13D   返回到 wow.0041F13D 来自 wow.006E90B0  << anchor
//001AF554    00000005
//001AF558    0A317EA0
//001AF55C    0A318028
//001AF560   /001AF580
//001AF564   |00861320   返回到 wow.00861320 来自 wow.0041F110
//001AF568   |001AF5AC    << target buffer pointer
//001AF56C   |1D25C8E8
//001AF570   |00000000
//
//EAX 00000005
//ECX 1D25C8E8
//EDX 00000000
//EBX 00000002
//ESP 001AF548
//EBP 001AF560
//ESI 1D25C7E0
//EDI 00000005     << target buffer len
//EIP 7C921000 ntdll.RtlEnterCriticalSection

  MARK_SEND_LOGIN_STRING: ARRAY[0..8] OF BYTE = ($BB,$02,$00,$00,$00,$89,$4D,$0C,$E8);
  MARK_SEND_LOGIN_OFFSET: INTEGER = $0041F13D - $0041F130;

//登录发包  - 网易
//00460FB0    83C4 10              add esp,10                       << anthor
//00460FB3    8D8E 08010000        lea ecx,dword ptr ds:[esi+108]
//00460FB9    894D 10              mov dword ptr ss:[ebp+10],ecx
//00460FBC    E8 3FFB0D00          call Wow.00540B00
//00460FC1    85FF                 test edi,edi                    << target
//83C4108D8E08010000894D10E8
  MARK_SEND_LOGIN_STRING2: ARRAY[0..12] OF BYTE = ($83,$C4,$10,$8D,$8E,$08,$01,$00,$00,$89,$4D,$10,$E8);
  MARK_SEND_LOGIN_OFFSET2: INTEGER = $00460FC1 - $00460FB0;


//登录收包
//0041EB11             |.  E8 0A194000       |call Wow.00820420
//0041EB16             |.  8B55 F8           |mov edx,dword ptr ss:[ebp-8]
//0041EB19             |.  8B4D FC           |mov ecx,dword ptr ss:[ebp-4]
//0041EB1C             |.  50                |push eax
//0041EB1D             |.  8B02              |mov eax,dword ptr ds:[edx] << anthor
//0041EB1F             |.  56                |push esi
//0041EB20             |.  FFD0              |call eax
//0041EB22             |>  8D8E 08010000     |lea ecx,dword ptr ds:[esi+108]
//0041EB28             |.  E8 A3B52C00       |call Wow.006EA0D0
//0041EB2D             |.  8BCF              |mov ecx,edi       <<target
//0041EB2F             |.  E8 9CB52C00       |call Wow.006EA0D0
//0041EB34             |.  8B86 D4000000     |mov eax,dword ptr ds:[esi+D4]
//0041EB3A             |.  8386 CC000000 FF  |add dword ptr ds:[esi+CC],-1
//0041EB41             |.  85C0              |test eax,eax
//0041EB43             |.  74 0D             |je short Wow.0041EB52
//8B0256FFD08D8E08010000E8
//-----------------------------------------------------------------------
//login recv4
//0FFDEF2C   006EA0D7  返回到 Wow.006EA0D7 来自 ntdll.RtlEnterCriticalSection
//0FFDEF30   1086EE58
//0FFDEF34   0041EB2D  返回到 Wow.0041EB2D 来自 Wow.006EA0D0    <<anchor
//0FFDEF38   1086EE58
//0FFDEF3C   1086ED50
//0FFDEF40   00000002
//0FFDEF44   00065410
//buffer = [ebp - $100c]  ebx = length      

  MARK_RECV_LOGIN_STRING : ARRAY[0..11] OF BYTE = ($8B,$02,$56,$FF,$D0,$8D,$8E,$08,$01,$00,$00,$E8);
  MARK_RECV_LOGIN_OFFSET: INTEGER = $0041EB2D - $0041EB1D;


Type
  LPTPacketStruct = ^TPacketStruct;
  TPacketStruct = Packed record
    U1: DWORD;
    Buffer: Pointer;
    U2,U3: DWORD;
    BufLen: Integer;
    U4: DWORD;
  end;

var
  RecvMark, SendMark, SendMark2, SendLoginMark, RecvLoginMark: Pointer;
  EnterCriticalSection_Raw: Pointer;
  EnterCriticalSection_Real: Pointer;


Procedure PacketSender (Packet: LPTPacketStruct); Stdcall;
begin
  if Packet.BufLen > 0 then
    ImportPacketQueue (ptSend, Packet.Buffer, Packet.BufLen);
end;

Procedure PacketRecver (Buffer: Pointer; BufLen: Integer); Stdcall;
begin
  if BufLen > 0 then
    ImportPacketQueue (ptRecv, Buffer, BufLen);
end;

Procedure LoginPacketSender (Buffer: Pointer; BufLen: Integer); Stdcall;
begin
  if BufLen > 0 then
    ImportPacketQueue (ptSendLogin, Buffer, BufLen);
end;

Procedure LoginPacketRecver (Buffer: Pointer; BufLen: Integer); Stdcall;
begin
  if BufLen > 0 then
    ImportPacketQueue (ptRecvLogin, Buffer, BufLen);
end;

procedure EnterCriticalSection_Hook;
asm
  inc EnterCrtsCounter

  push eax
  mov eax,SendMark
  cmp eax,dword ptr ss:[esp + 4 + $0019FDE8 - $0019FDC0]
  pop eax
  je @SendHook

  push eax
  mov eax,SendMark2
  cmp eax,dword ptr ss:[esp + 4 + $0019FAF0 - $0019FAE8]
  pop eax
  je @SendHook2

  push eax
  mov eax,RecvMark
  cmp eax,dword ptr ss:[esp + 4 + $121DFEC8 - $121DFEC0]
  pop eax
  je @RecvHook

  push eax
  mov eax,SendLoginMark
  cmp eax,dword ptr ss:[esp + 4 + $001AF550 - $001AF548]
  pop eax
  je @SendLoginHook

  push eax
  mov eax,RecvLoginMark
  cmp eax,dword ptr ss:[esp + 4 + $0FFDEF34 - $0FFDEF2C]
  pop eax
  je @RecvLoginHook4

  jmp @HookExit

@SendHook:
  pushad
  push dword ptr ss:[esp + $20 + $0019FDEC - $0019FDC0]     //LPTPacketStruct
  call PacketSender
  popad
  jmp @HookExit
                    
@SendHook2:
  pushad
  push dword ptr ss:[esp + $20 + $0019FB18 - $0019FAE8]     //LPTPacketStruct
  call PacketSender
  popad
  jmp @HookExit

@RecvHook:
  pushad
  mov eax,dword ptr ss:[esp + $20 + $121DFEF4 - $121DFEC0]  //length
  mov ebx,dword ptr ss:[esp + $20 + $121DFEF0 - $121DFEC0]  //buffer
  push eax
  push ebx
  call PacketRecver
  popad
  jmp @HookExit

@SendLoginHook:
  pushad
  mov ebx,dword ptr ss:[esp + $20 + $001AF568 - $001AF548]  //buffer
  push edi
  push ebx
  call LoginPacketSender
  popad
  jmp @HookExit


@RecvLoginHook4:
  pushad
  push ebx  //lenth
  lea eax,dword ptr ss:[ebp-$100C]   //buffer
  push eax
  call LoginPacketRecver
  popad
  jmp @HookExit


@HookExit:
  mov eax,EnterCriticalSection_Real
  jmp eax
end;

//------------------------------------------------------------------------------
//
//                          文件操作钩子 - 一次性
//
//------------------------------------------------------------------------------
var
  CreateFileW_Raw: Pointer;
  CreateFileW_Real: function (lpFileName: PWideChar; dwDesiredAccess, dwShareMode: DWORD; lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes: DWORD;  hTemplateFile: THandle): THandle; stdcall;
  CloseHandle_Raw: Pointer;
  CloseHandle_Real: function (hObject: THandle): BOOL; stdcall;
  ConfigFileName: String;
  DefaultRealmName: String;
  ConfigHandle: THandle = 0;
  CreateFileW_Hook_Enable: BOOL = True;


function SetRealmNameNewFile (Source, Distin: String; RealmName:String): BOOL;
const
  KeyHead = 'SET realmName ';
var
  SL: TStringList;
  Index: Integer;
  Item: String;
  FS: THandle;
  ReadBuffer: PChar;
  ReadCount: Integer;
  MM: TMemoryStream;
begin
  Result := False;

  MM := TMemoryStream.Create;
  FS := FileOpen (Source, fmOpenRead);
  SL := TStringList.Create;
  SL.LineBreak := #10;
  ReadBuffer := AllocMem ($1000 * 256);

  SetFilePointer (FS, 0, nil, soFromBeginning);
  ReadCount := FileRead (FS, ReadBuffer[0], $1000 * 256);
  MM.Seek(0, soFromBeginning);
  MM.Write(ReadBuffer[0], ReadCount);
  MM.Seek(0, soFromBeginning);
  SL.LoadFromStream(MM);

  FreeMem (ReadBuffer);
  FileClose (FS);
  MM.Free;
              
  for Index := 0 to SL.Count - 1 do
  begin
    Item := SL[Index];
    if CompareMem (PChar(Item), PChar(KeyHead), Length(KeyHead)) then
    begin
      RealmName := Trim (RealmName);
      RealmName := AnsiToUtf8 (RealmName);
      Item := KeyHead + '"' + RealmName + '"';
      SL.Delete(Index);
      SL.Insert(Index, Item);
      SL.SaveToFile(Distin);
      Result := True;
      Exit;
    end;
  end;
end;

function CreateFileW_Hook (lpFileName: PWideChar; dwDesiredAccess, dwShareMode: DWORD; lpSecurityAttributes: PSecurityAttributes; dwCreationDisposition, dwFlagsAndAttributes: DWORD; hTemplateFile: THandle): THandle; stdcall;
var
  ToHandleFile, FileName, FilePath: String;
  BeHookFile: PWideChar;
begin
  Repeat
    if not CreateFileW_Hook_Enable then Break;
    if not Assigned (lpFileName) then Break;

    ToHandleFile := WideCharToString (lpFileName);
    if CompareMem (@ToHandleFile[1], PChar('\\'), 2) then Break;
    if not FileExists (ToHandleFile) then Break;

    FileName := ExtractFileName (ToHandleFile);
    if FileName <> 'Config.wtf' then Break;

    CreateFileW_Hook_Enable := False;
    ToHandleFile := ExtractFilePath(GetModuleName(0)) + ToHandleFile;
    FilePath := ExtractFilePath (ToHandleFile) + 'bak\';
    ForceDirectories (FilePath);
    ConfigFileName := FilePath + IntToStr(GetCurrentProcessID) + FileName;
    DefaultRealmName := GetJsonParamA ('游戏服务器');
    ConfigHandle := 0;

    if not SetRealmNameNewFile (ToHandleFile, ConfigFileName, DefaultRealmName) then Break;

    BeHookFile := StringToOleStr (ConfigFileName);
    Result := CreateFileW_Real (BeHookFile, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
    UnSMHookApi (CreateFileW_Raw);

    if INVALID_HANDLE_VALUE <> Result then
      ConfigHandle := Result;

    Exit;
  until True;
 
  Result := CreateFileW_Real (lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
end;

function CloseHandle_Hook (hObject: THandle): BOOL; stdcall;
begin
  Result := CloseHandle_Real (hObject);

  Repeat
    if ConfigHandle = 0 then Break;
    if hObject = 0 then Break;
    if ConfigHandle <> hObject then Break;    
    if not Result then Break;
    if not FileExists (ConfigFileName) then Break;

    ConfigHandle := 0;
    UnSMHookApi (CloseHandle_Raw);
    CloseHandle_Raw := NIL;
    DeleteFile (PChar(ConfigFileName));
  until True;
end;

Procedure ReportAddress (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;
var
  List: TList absolute Sender;
begin
  List.Add(Found);
  BreakReport := True;
end;


//------------------------------------------------------------------------------
//
//                          以下初始化代码
//
//------------------------------------------------------------------------------

function IsAddressError (var ErrIndex: Integer; const Args: array of Pointer): BOOL;
var
  Index: Integer;
  Item: Pointer;
begin
  for Index := Low(Args) to High(Args) do
  begin
    Item := Args[Index];
    if Item = NIL then
    begin
      ErrIndex := Index;
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

Procedure HandleGameData;
var
  List: TList;
  hTemplate: THandle;
  CodeBase: Pointer;
  CodeSize: Integer;
  LibHanele: THandle;
  tid: DWORD;
  ErrIndex: Integer;
begin
  List := TList.Create;
  hTemplate := 0;

  Repeat
    if not GetSectionMemory ($00400000, '.text', CodeBase, CodeSize) then
    begin
      DebugPrint ('寻找代码段失败');
      break;
    end;

    hTemplate := MakeTemplate (CodeBase, CodeSize);
    if hTemplate = 0 then
    begin
      DebugPrint ('创建代码段模板失败');
      break;
    end;

    List.Clear;
    if not SearchAddress (hTemplate, List, @MARK_LOGIN_STRING, Length(MARK_LOGIN_STRING), SearchLoginAddress) then
    begin
      DebugPrint ('没有找到登录入口地址');
      Break;
    end;    

    List.Clear;
    if not SearchAddress (hTemplate, List, @MARK_SELECT_CHAR_STRING, Length(MARK_SELECT_CHAR_STRING), ReportSelectCharAddr) then
    begin
      DebugPrint ('没有找到默认人物地址');
      Break;
    end;
    DefaultCharIndexAddr := List[0];

    List.Clear;
    if not SearchAddress (hTemplate, List, @MARK_SEND_PACKET_STRING, Length(MARK_SEND_PACKET_STRING), ReportAddress) then
    begin
      DebugPrint ('没有找到 SendMark');
      Break;
    end;
    SendMark := Pointer (Integer(List[0]) + MARK_SEND_PACKET_OFFSET);

    List.Clear;    
    if not SearchAddress (hTemplate, List, @MARK_SEND_PACKET_STRING2, Length(MARK_SEND_PACKET_STRING2), ReportAddress) then
    begin
      DebugPrint ('没有找到 SendMark2');
      Break;
    end;
    SendMark2 := Pointer (Integer(List[0]) + MARK_SEND_PACKET_OFFSET2);    

    List.Clear;
    if not SearchAddress (hTemplate, List, @MARK_RECV_PACKET_STRING, Length(MARK_RECV_PACKET_STRING), ReportAddress) then
    begin
      DebugPrint ('没有找 RecvMark');
      Break;
    end;
    RecvMark := Pointer (Integer(List[0]) + MARK_RECV_PACKET_OFFSET);

    List.Clear;
    if not SearchAddress (hTemplate, List, @MARK_SEND_LOGIN_STRING, Length(MARK_SEND_LOGIN_STRING), ReportAddress) then
    begin
      List.Clear;
      if not SearchAddress (hTemplate, List, @MARK_SEND_LOGIN_STRING2, Length(MARK_SEND_LOGIN_STRING2), ReportAddress) then
      begin
        DebugPrint ('没有找到 SendLoginMark');
        Break;
      end else
        SendLoginMark := Pointer (Integer(List[0]) + MARK_SEND_LOGIN_OFFSET2);
    end else
      SendLoginMark := Pointer (Integer(List[0]) + MARK_SEND_LOGIN_OFFSET);

    List.Clear;
    if not SearchAddress (hTemplate, List, @MARK_RECV_LOGIN_STRING, Length(MARK_RECV_LOGIN_STRING), ReportAddress) then
    begin
      DebugPrint ('没有找到 RecvLoginMark');
      Break;
    end;
    RecvLoginMark := Pointer (Integer(List[0]) + MARK_RECV_LOGIN_OFFSET);
                          
    DbgFmt ('SendMark = $%p'#13#10'SendMark2 = $%p'#13#10'RecvMark = $%p'#13#10'SendLoginMark = $%p'#13#10'RecvLoginMark = $%p'#13#10'DefaultCharIndexAddr = $%p',
        [SendMark, SendMark2, RecvMark, SendLoginMark, RecvLoginMark, DefaultCharIndexAddr]);

    //创建封包缓存队列
    hSyncPacket := MakeSyncQueue (SyncPacketQueueHandler);

    //拦截api调用
    LibHanele := Loadlibrary (kernel32);
    EnterCriticalSection_Raw := GetProcAddress (LibHanele, 'EnterCriticalSection');
    CreateFileW_Raw := GetProcAddress (LibHanele, 'CreateFileW');
    CloseHandle_Raw := GetProcAddress (LibHanele, 'CloseHandle');
    FreeLibrary (LibHanele);

    EnterCriticalSection_Real := SMHookApi (EnterCriticalSection_Raw, @EnterCriticalSection_Hook);
    @CreateFileW_Real := SMHookApi (CreateFileW_Raw, @CreateFileW_Hook);
    @CloseHandle_Real := SMHookApi (CloseHandle_Raw, @CloseHandle_Hook);

    if IsAddressError (ErrIndex, [EnterCriticalSection_Real, @CreateFileW_Real, @CloseHandle_Real]) then
    begin
      DbgFmt ('SMHookApi失败了 [%d]', [ErrIndex]);
      Break;
    end;
                                                
    //创建登录线程
    CloseHandle (CreateThread (nil, 0, @LoginRoutine, nil, 0, tid));

  Until true;

  if hTemplate > 0 then
    FreeTemplate(hTemplate);
  
  List.Free;
end;

Procedure StartPlugin;
begin
  @MakeTemplate := FindFuncEntry (HASH_PlugBaseLibrary, HASH_MakeTemplate);
  @FreeTemplate := FindFuncEntry (HASH_PlugBaseLibrary, HASH_FreeTemplate);
  @SearchAddress := FindFuncEntry (HASH_PlugBaseLibrary, HASH_SearchAddress);
  @GetSectionMemory := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetSectionMemory);

  @SMHookApi := FindFuncEntry (HASH_PlugBaseLibrary, HASH_SMHookApi);
  @UnSMHookApi := FindFuncEntry (HASH_PlugBaseLibrary, HASH_UnSMHookApi);

  @SetHook := FindFuncEntry (HASH_PlugBaseLibrary, HASH_SetHook);
  @UnHook := FindFuncEntry (HASH_PlugBaseLibrary, HASH_UnHook);
  @WriteMemory := FindFuncEntry (HASH_PlugBaseLibrary, HASH_WriteMemory);

  @GetJsonParamA := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetJsonParam);
  @IsTargetProcess := FindFuncEntry (HASH_PlugBaseLibrary, HASH_IsTargetProcess);

  @ShowUserMessage := FindFuncEntry (HASH_PlugBaseLibrary, HASH_ShowUserMessage);
  @OpenProgressWindow := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OpenProgressWindow);
  @ReportProgress := FindFuncEntry (HASH_PlugBaseLibrary, HASH_ReportProgress);
  @CloseProgressWindow := FindFuncEntry (HASH_PlugBaseLibrary, HASH_CloseProgressWindow);


  @MakeSyncQueue := FindFuncEntry (HASH_PlugBaseLibrary, HASH_MakeSyncQueue);
  @PushSyncQueue := FindFuncEntry (HASH_PlugBaseLibrary, HASH_PushSyncQueue);
  @GetSyncQueueCount := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetSyncQueueCount);
  @FreeSyncQueue := FindFuncEntry (HASH_PlugBaseLibrary, HASH_FreeSyncQueue);

  IsDebugMode := GetJsonParamA ('RunMode') = 'Debug';

  if not IsTargetProcess then
  begin
    DebugPrint ('IsTargetProcess = False, WowTW Exit');
    Exit;
  end;

  HandleGameData;
end;

Procedure EndPlugin;
begin
  DebugPrint ('DLL_PROCESS_DETACH');
end;


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

      StartPlugin;
    end;
    DLL_PROCESS_DETACH: EndPlugin;
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
