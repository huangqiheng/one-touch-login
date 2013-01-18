library SilkRoadAddr;

uses
  Windows, SysUtils, GlobalObject, Classes;
  
{$I PlugBase.inc}

{
  2）寻找爆破地址，并爆破之。
  3）寻找发包接口地址，提供调用接口。
  4）寻找封包接受拦截地址，打上补丁，并提供回调服务。
  5）寻找登录准备就绪的判断，并提供查询接口。
}

const
  EXPORT_LIB_NAME = 'SilkRoadAddr';

Type
  TReportAddress = Procedure (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;

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
  lpvReserved: PPointer;
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  DebugPrint: Procedure (Msg: PChar); stdcall;

  ExportLibFunction: function (LibName, FuncName: PChar; FuncEntry: Pointer): BOOL; Stdcall;
  ImportLibFunction: function (LibName, FuncName: PChar): Pointer; Stdcall;


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


Procedure DbgFmt (const FmtStr: string; const Args: array of const);
var
  dbgstr: string;
begin
  dbgstr := Format (FmtStr, Args);
  DebugPrint (@dbgstr[1]);
end;

const
//00727247    83C4 04               add esp,4     << anchor
//0072724A    84C0                  test al,al
//0072724C    75 1F                 jnz short sro_clie.0072726D    << target
//0072724E    6A 00                 push 0
//00727250    68 08A7C400           push sro_clie.00C4A708                 ; ASCII "ERROR"
//00727255    68 E4A6C400           push sro_clie.00C4A6E4                 ; ASCII "Please Execute the "Silkroad.exe.""
//0072725A    6A 00                 push 0
//0072725C    FF15 C893C000         call dword ptr ds:[<&USER32.MessageBox>; USER32.MessageBoxA
  MARK_JMP_MSG_STRING: Array[0..8] of byte = ($83,$C4,$04,$84,$C0,$75,$1F,$6A,$00);
  MARK_JMP_MSG_OFFSET: INTEGER = $0072724C - $00727247;
  MARK_JMP_MSG_TO: BYTE = $EB;


//0075C53D    8B0D D065FB00         mov ecx,dword ptr ds:[FB65D0]    << target       ; sro_clie.00FB9390
//0075C543    8B31                  mov esi,dword ptr ds:[ecx]
//0075C545    53                    push ebx         << anchor
//0075C546    55                    push ebp
//0075C547    52                    push edx
//0075C548    8B56 10               mov edx,dword ptr ds:[esi+10]
//0075C54B    50                    push eax
//0075C54C    FFD2                  call edx                                    ; sro_clie.00493EE0

//00493EE0    A1 CC65FB00           mov eax,dword ptr ds:[FB65CC]
//00493EE5    83B8 FC000000 00      cmp dword ptr ds:[eax+FC],0
//00493EEC    53                    push ebx
//00493EED    8BD9                  mov ebx,ecx         
  MARK_LOGIN_STRING: ARRAY[0..10] OF byte = ($53,$55,$52,$8B,$56,$10,$50,$FF,$D2,$84,$C0);
  MARK_LOGIN_OFFSET: INTEGER = $0075C53D - $0075C545 + 2;

//00486889    8BF8                 mov edi,eax            << anchor
//0048688B    8B85 D8000000        mov eax,dword ptr ss:[ebp+D8]
//00486891    57                   push edi               << target             ; 6
//00486892    03C1                 add eax,ecx
//00486894    50                   push eax                                      ; From
//00486895    52                   push edx                                      ; To
//00486896    E8 75725800          call sro_clie.00A0DB10
//0048689B    83C4 0C              add esp,0C
//0048689E    01BD E0000000        add dword ptr ss:[ebp+E0],edi
//004868A4    8B85 38010000        mov eax,dword ptr ss:[ebp+138]
  MARK_RECEIVE_PACKET_STRING: ARRAY[0..13] OF BYTE = ($8B,$F8,$8B,$85,$D8,$00,$00,$00,$57,$03,$C1,$50,$52,$E8);
  MARK_RECEIVE_PACKET_OFFSET: INTEGER = $00486891 - $00486889;

//00478940  /$  8B48 28           mov ecx,dword ptr ds:[eax+28]
//00478943  |.  85C9              test ecx,ecx
//00478945  |.  74 15             je short sro_clie.0047895C
//00478947  |.  33C0              xor eax,eax
//00478949  |.  8379 04 FF        cmp dword ptr ds:[ecx+4],-1
//0047894D  |.  0F95C0            setne al
//00478950  |.  83F8 01           cmp eax,1
//00478953  |.  75 07             jnz short sro_clie.0047895C
//00478955  |.  52                push edx
//00478956  |.  E8 15D30000       call sro_clie.00485C70
//0047895B  |.  C3                retn
//0047895C  |>  B8 08800000       mov eax,8008
//00478961  \.  C3                retn
  MARK_SEND_PACKET_STRING: ARRAY[0..12] OF BYTE = ($8B,$48,$28,$85,$C9,$74,$15,$33,$C0,$83,$79,$04,$FF);
  MARK_SEND_PACKET_OFFSET: INTEGER = $00478956 - $00478940 + 1;

//RunCharEntry
//0075A3D0    6A FF               push -1
//0075A3D2    68 8015BD00         push sro_clie.00BD1580
//0075A3D7    64:A1 00000000      mov eax,dword ptr fs:[0]
//0075A3DD    50                  push eax
// ......
//0075A401    0FB615 60D4D200     movzx edx,byte ptr ds:[D2D460]  <<MouseCharAddr
//0075A408    8BF1                mov esi,ecx          << anthor
//0075A40A    8B8E 34010000       mov ecx,dword ptr ds:[esi+134]
//0075A410    33DB                xor ebx,ebx
//0075A412    3BCB                cmp ecx,ebx
//0075A414    74 0F               je short sro_clie.0075A425
//0075A416    8B86 38010000       mov eax,dword ptr ds:[esi+138]
//0075A41C    2BC1                sub eax,ecx
//0075A41E    C1F8 02             sar eax,2
//0075A421    3BD0                cmp edx,eax
//0075A423    72 05               jb short sro_clie.0075A42A
//0075A425  ^ E9 36E8FFFF         jmp sro_clie.00758C60
//8BF1 8B8E 34010000 33DB 3BCB 74
  MARK_RUN_CHAR_STRING: ARRAY[0..12] OF BYTE = ($8B,$F1,$8B,$8E,$34,$01,$00,$00,$33,$DB,$3B,$CB,$74);
  MARK_RUN_CHAR_ENTRY_OFFSET: INTEGER = $0075A3D0 - $0075A408;
  MARK_MOUSE_CHAR_OFFSET: INTEGER = $0075A401 - $0075A408 + 3;

//00A6217C   .  8BF0              mov esi,eax     << arthor
//00A6217E   .  3BF5              cmp esi,ebp
//00A62180   .  74 1B             je short sro_clie.00A6219D
//00A62182   .  A1 D03AF800       mov eax,dword ptr ds:[F83AD0]  << target
//00A62187   .  8B48 24           mov ecx,dword ptr ds:[eax+24]
//00A6218A   .  E8 1196FFFF       call sro_clie.00A5B7A0
//8BF03BF5741BA1
  MARK_CHAR_OBJECT_STRING: ARRAY[0..6] OF BYTE = ($8B,$F0,$3B,$F5,$74,$1B,$A1);
  MARK_CHAR_OBJECT_OFFSET: INTEGER = $00A62182 - $00A6217C + 1;

var
  CharObject: Pointer;
  RunCharEntry: Pointer;
  MouseCharAddr: Pointer;

Function GetRunCharacterECX: Pointer;
asm
  mov eax,CharObject
  mov eax,dword ptr ds:[eax]
  mov eax,dword ptr ds:[eax+$24]
end;    

function EnterGameWorld (CharIndex: Integer): BOOL; Stdcall;
asm
  push edx
  push ecx

  mov edx,MouseCharAddr
  mov eax,CharIndex
  mov byte ptr ds:[edx],al

  call GetRunCharacterECX
  mov ecx,eax
  mov edx,RunCharEntry
  call edx

  pop ecx
  pop edx
end;

Function GetCharacterCount: Integer;
asm
  push esi
  push ecx
  push ebx

  call GetRunCharacterECX
  mov esi,eax
  mov ecx,dword ptr ds:[esi+$134]
  xor ebx,ebx
  cmp ecx,ebx
  je @FalseExit

  mov eax,dword ptr ds:[esi+$138]
  cmp eax,ebx
  je @FalseExit

  sub eax,ecx
  sar eax,2
  jmp @ResultExit

@FalseExit:
  xor eax,eax

@ResultExit:
  pop ebx
  pop ecx
  pop esi
end;

//0074B72A   .  8B8E 34010000     mov ecx,dword ptr ds:[esi+134]
//0074B74A   > \8B0491            mov eax,dword ptr ds:[ecx+edx*4]
//0074B74D   .  05 9C010000       add eax,19C
Function GetCharacterObjArray: PPointerArray;
asm
  call GetRunCharacterECX
  mov eax,dword ptr ds:[eax+$134]
end;

Function GetCharNameByObj (Obj: Pointer): PWideChar;
asm
  mov eax,Obj
  add eax,$19C
  add eax,4
end;  

function GetCharacterIndex (RoleName: PChar; TimeOut: DWORD): Integer; Stdcall;
var
  CharName, ToSelectName: String;
  wCharName: PWideChar;
  CharCount: Integer;
  TimeOutTick: DWORD;
  CharList: PPointerArray;
  Index: Integer;
begin
  Result := -1;
  TimeOutTick := GetTickCount + TimeOut;
  
  CharCount := 0;
  while True do
  begin
    Sleep(100);
    CharCount := GetCharacterCount;
    if CharCount in [1,2,3,4,5,6,7] then Break;
    if GetTickCount > TimeOutTick then Exit;
  end;

  ToSelectName := StrPas (RoleName);
  CharList := GetCharacterObjArray;
  for Index := 0 to CharCount - 1 do
  begin   
    wCharName := GetCharNameByObj (CharList[Index]);
    CharName :=  WideCharToString (wCharName);

    if CharName = ToSelectName then
    begin
      Result := Index;
      Exit;
    end;
  end;
end;


Type
  LPTHeadStruct = ^THeadStruct;
  THeadStruct = Packed record
    ContentLen: WORD;
    ContentType: WORD;
    PacketType: WORD;
  end;

var
  RecverList: TList = NIL;
  RecvJmpFrom: Pointer = NIL;
  RecvJmpBack: Pointer;

function RecvCallBackFunc (pReg: PRegInfo):DWORD;stdcall;

var
  CallBack: Pointer;
  Buffer: LPTHeadStruct;
  PacketLen: Integer;
begin
  Result := 0;
  if not Assigned (RecverList) then Exit;
  if pReg.EDI <> 6 then Exit;

  Buffer := Pointer (pReg.EAX + pReg.ECX);


  while Buffer.ContentLen > 0 do
  begin
    PacketLen := Buffer.ContentLen + SizeOf(THeadStruct);

    if PacketLen >= $200 then Break;

    for CallBack in RecverList do
      TRecvPacketCallBack (CallBack) (Pointer(Buffer), PacketLen);

    Buffer := Pointer (Integer(Buffer) + PacketLen);
  end;              
end;

Procedure SetPacketRecver (CallBack: Pointer); Stdcall;
begin
  if not Assigned (CallBack) then Exit;  
  if not Assigned (RecverList) then
    RecverList := TList.Create;
  RecverList.Add(CallBack);
end;

var
  RawSender: Pointer;
  SenderList: TList = NIL;

//09F5A9C8  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
//09F5A9D8  00 00 00 00 02 00 00 00 00 00 00 00 00 00 00 00  ...............
//09F5A9E8  01 00 00 00 00 00 00 00 FC A9 F5 09 00 00 00 00  .......?....
//09F5A9F8  00 00 00 00 48 00 10 61 00 00 45 EB 25 BD 64 45  ....H.a..E?絛E
//09F5AA08  9B 73 0D 2B 44 6F 87 0F 96 37 38 F7 AF EA 98 09  泂.+Do??8鳢陿.

Procedure Hook_Sender (Param: Pointer); Stdcall;
var
  PacketBase: LPTHeadStruct;
  CallBack: Pointer;
  PacketLen: WORD;
begin
  if Assigned (SenderList) then
  begin
    PacketBase := PPointer(Integer(Param) + $28)^;
    PacketLen := PacketBase.ContentLen;

    if PacketLen >= $8000 then
      PacketLen := PacketLen - $8000;
    PacketLen := PacketLen + SizeOf(THeadStruct);

    for CallBack in SenderList do
      TRecvPacketCallBack (CallBack) (Pointer(PacketBase), PacketLen);
  end;
end;

Procedure SendHooker;
asm
  pushad

  mov eax, dword ptr ds:[esp + $24]
  push eax
  call Hook_Sender

  popad

  jmp dword ptr ds:[RawSender]
end;

Procedure SetPacketSendHooker (CallBack: Pointer); Stdcall;
begin
  if not Assigned (CallBack) then Exit;  
  if not Assigned (SenderList) then
    SenderList := TList.Create;
  SenderList.Add(CallBack);
end;


Procedure ReportAddress (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;
var
  List: TList absolute Sender;
begin
  List.Add(Found);
  BreakReport := True;
end;


var
  CodeBase: Pointer;
  CodeSize: Integer;
  KeyObject: Pointer;



Function HandleGameData: BOOL;
var
  List: TList;
  JmpAddr: Pointer;
  hTemplate: THandle;
  CallAimAddr: Pointer;
  CallOffset: Integer;
begin
  Result := False;
  List := TList.Create;

  if GetSectionMemory ($00400000, '.text', CodeBase, CodeSize) then
  begin
    Result := True;
    hTemplate := MakeTemplate (CodeBase, CodeSize);
    DbgFmt ('创建了代码段模板：base=$%p size=%d', [CodeBase, CodeSize]);

    if SearchAddress (hTemplate, List, @MARK_JMP_MSG_STRING, Length(MARK_JMP_MSG_STRING), ReportAddress) then
    begin
      JmpAddr := Pointer (Integer(List[0]) + MARK_JMP_MSG_OFFSET);
      DbgFmt ('发现了跳转地址 = $%p', [JmpAddr]);
      WriteMemory (JmpAddr, @MARK_JMP_MSG_TO, 1);
    end else
      Result := False;

    List.Clear;
    if SearchAddress (hTemplate, List, @MARK_LOGIN_STRING, Length(MARK_LOGIN_STRING), ReportAddress) then
    begin
      KeyObject := PPointer (Integer(List[0]) + MARK_LOGIN_OFFSET)^;
      DbgFmt ('发现了关键对象地址 = $%p', [KeyObject]);
    end else
      Result := False;

    List.Clear;
    if SearchAddress (hTemplate, List, @MARK_RECEIVE_PACKET_STRING, Length(MARK_RECEIVE_PACKET_STRING), ReportAddress) then
    begin
      RecvJmpFrom := Pointer (Integer(List[0]) + MARK_RECEIVE_PACKET_OFFSET);
      RecvJmpBack := Pointer (Integer(RecvJmpFrom) + 5);
      DbgFmt ('发现了封包接收回调地址 = $%p', [RecvJmpFrom]);
    end else
      Result := False;

    List.Clear;
    if SearchAddress (hTemplate, List, @MARK_SEND_PACKET_STRING, Length(MARK_SEND_PACKET_STRING), ReportAddress) then
    begin
      CallAimAddr := Pointer (Integer(List[0]) + MARK_SEND_PACKET_OFFSET);
      CallOffset := PInteger(CallAimAddr)^;
      RawSender := Pointer (Integer(CallAimAddr) + CallOffset + 4);

      CallOffset := Integer(@SendHooker) - Integer(CallAimAddr) - 4;
      WriteMemory (CallAimAddr, @CallOffset, 4);

      DbgFmt ('发现了封包发送回调地址 = $%p', [RawSender]);
    end else
      Result := False;

    List.Clear;
    if SearchAddress (hTemplate, List, @MARK_CHAR_OBJECT_STRING, Length(MARK_CHAR_OBJECT_STRING), ReportAddress) then
    begin
      CharObject := PPointer (Integer(List[0]) + MARK_CHAR_OBJECT_OFFSET)^;
      DbgFmt ('发现了角色对象地址 = $%p', [CharObject]);
    end else
      Result := False;

    List.Clear;
    if SearchAddress (hTemplate, List, @MARK_RUN_CHAR_STRING, Length(MARK_RUN_CHAR_STRING), ReportAddress) then
    begin
      RunCharEntry := Pointer (Integer(List[0]) + MARK_RUN_CHAR_ENTRY_OFFSET);
      DbgFmt ('发现了选人函数地址 = $%p', [RunCharEntry]);

      MouseCharAddr := PPointer (Integer(List[0]) + MARK_MOUSE_CHAR_OFFSET)^;
      DbgFmt ('发现了鼠标选人地址 = $%p', [MouseCharAddr]);
    end else
      Result := False;

    FreeTemplate(hTemplate);
  end;

  Repeat
    if Assigned (RecvJmpFrom) then
      if SetHook (RecvJmpFrom, RecvJmpBack, @RecvCallBackFunc, NIL) then
      begin
       DebugPrint ('SetHook封包接收 成功');
       Break;
      End;
    DebugPrint ('SetHook封包接收 失败');
    Result := False;
  Until True;

  List.Free;
end;               



//0075C53D    8B0D D065FB00         mov ecx,dword ptr ds:[FB65D0]    << target       ; sro_clie.00FB9390
//0075C543    8B31                  mov esi,dword ptr ds:[ecx]
//0075C545    53                    push ebx         << anchor
//0075C546    55                    push ebp
//0075C547    52                    push edx
//0075C548    8B56 10               mov edx,dword ptr ds:[esi+10]
//0075C54B    50                    push eax
//0075C54C    FFD2                  call edx
                
function LoginAccount (UserName,PassWord: PChar; Server, Flags: DWORD): BOOL; Stdcall;
asm
  mov ecx,KeyObject
  mov ecx,dword ptr ds:[ecx]
  mov esi,dword ptr ds:[ecx]
  mov edx,dword ptr ds:[esi+$10]
  push Flags
  push Server
  push PassWord
  push UserName
  call edx
end;


function Usage: PChar; Stdcall;    
begin
  Result := '这是TYPE_PLURINLIB SilkRoadAddr.dll插件的使用帮助';
end;

function PluginType: PChar; Stdcall;
begin
  Result := TYPE_PLURINLIB;
end;


Exports
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

      @ExportLibFunction := FindFuncEntry (HASH_PlugBaseLibrary, HASH_ExportLibFunction);
      @ImportLibFunction := FindFuncEntry (HASH_PlugBaseLibrary, HASH_ImportLibFunction);

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

      if IsTargetProcess then
      begin
        HandleGameData;
        ExportLibFunction (EXPORT_LIB_NAME, 'LoginAccount', @LoginAccount);
        ExportLibFunction (EXPORT_LIB_NAME, 'SetPacketRecver', @SetPacketRecver);
        ExportLibFunction (EXPORT_LIB_NAME, 'SetPacketSendHooker', @SetPacketSendHooker);
        ExportLibFunction (EXPORT_LIB_NAME, 'GetCharacterIndex', @GetCharacterIndex);
        ExportLibFunction (EXPORT_LIB_NAME, 'EnterGameWorld', @EnterGameWorld);
      end else
        DebugPrint ('IsTargetProcess = False, SilkRoadAddr Exit');
                                                
      DebugPrint ('SilkRoadAddr DLLEntryPoint');
    end;
    DLL_PROCESS_DETACH: DebugPrint ('SilkRoadAddr DLL_PROCESS_DETACH');
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
