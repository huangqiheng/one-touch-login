library PlugBase;
                      
{$I ..\ShareUnit\GlobalDefine.inc}

uses SysUtils, windows, classes, DLLDatabase, 
     IntList, WideStrUtils, GlobalObject,
     TCodeEventNotify,
     AndQueMessages,
     TrapApiHook,
     FindAddress,
     SyncQueueHandler,
     PlugKernelUnit,
     TrapDbgUnit,
     AndIpcServer,
     DisAsmStr,
     CeAssembler;

var
  MsgChannel: String;
  CmdChannel: String;
  AppCmdLine: String;
  ParamSL: TStringList;
  RunMode, RightLevel: DWORD;


function GetParamStr (Key: String): String;
begin        
  Result := Trim(ParamSL.Values[Key]);
end;

function GetConfig (Key: PChar): PChar; Stdcall;
var
  RegStr: String[255];
begin
  Result := nil;
  RegStr := GetParamStr (StrPas(Key));
  if RegStr = '' then Exit;
  Result := @RegStr[1];
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

Function IsTargetProcess(): BOOL;
var
  RealAppName: String;
  sAppCmdLine: String;
begin
  sAppCmdLine := GetAppExeFromCmdLine (AppCmdLine);
  RealAppName := GetModuleName (0);
  Result := UpperCase (AppCmdLine) = UpperCase (RealAppName);
end;

const
  DEFAULT_LIB_HEAD = 'PLUGLIB_';

function ExportLibFunction (LibName, FuncName: PChar; FuncEntry: Pointer): BOOL; Stdcall;
var
  sLibName, sFuncName: String;
begin
  sLibName := DEFAULT_LIB_HEAD + StrPas(LibName);
  sFuncName := DEFAULT_LIB_HEAD + StrPas(FuncName);
  Result := SaveFuncEntry (sLibName, sFuncName, FuncEntry);
end;

function ImportLibFunction (LibName, FuncName: PChar): Pointer; Stdcall;
var
  sLibName, sFuncName: String;
begin
  sLibName := DEFAULT_LIB_HEAD + StrPas(LibName);
  sFuncName := DEFAULT_LIB_HEAD + StrPas(FuncName);
  Result := FindFuncEntryA (sLibName, sFuncName);
end;

////////////////////////////////////////////////////////////////////////////////
///                     通信通道
////////////////////////////////////////////////////////////////////////////////

function OnAppData (DataBuff: PChar; DataSize: Integer): BOOL; Stdcall;
begin
  Result := SendMsg_AppData (MsgChannel, DataBuff, DataSize);
end;

function OnProgress (OpType: Integer; Caption, Hint: PChar; Progress: Integer): BOOL; Stdcall;
begin
  Result := SendMsg_Progress (MsgChannel, OpType, Caption, Hint, Progress);
end;

function OnConfig (Key: PChar; Value: PChar): BOOL; Stdcall;
begin
  Result := SendMsg_Config (MsgChannel, Key, Value);
end;

function OnKeyData (Key: PChar; Value: PChar): BOOL; Stdcall;
begin
  Result := SendMsg_KeyData (MsgChannel, Key, Value);
end;

function OnMsgSystem (Msg: PChar): BOOL; Stdcall;
begin
  Result := SendMsg_System (MsgChannel, StrPas(Msg));
end;

function OnMsgError (Msg: PChar): BOOL; Stdcall;
begin
  Result := SendMsg_Error (MsgChannel, StrPas(Msg));
end;

function OnMsgDebug (Msg: PChar): BOOL; Stdcall;
begin
  Result := SendMsg_Debug (MsgChannel, StrPas(Msg));
end;

function OnMsgLog (Msg: PChar): BOOL; Stdcall;
begin
  Result := SendMsg_Log (MsgChannel, StrPas(Msg));
end;

function OnMsgNotice (Msg: PChar): BOOL; Stdcall;
begin
  Result := SendMsg_Notice (MsgChannel, StrPas(Msg));
end;

////////////////////////////////////////////////////////////////////////////////
///                     函数库初始化
////////////////////////////////////////////////////////////////////////////////



{$IFDEF MAKE_HASH_INC}

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

var
  RHashList: TStringList = NIL;
  ExpList: TStringList = NIL;

Procedure SaveHash;
var
  FileName, Item, ItemKey, ItemValue: String;
  Index: Integer;
  OldSL, HeadSL: TStringList;
begin
  if RightLevel <> $40000 then Exit;
  if not assigned (RHashList) then exit;

  FileName := 'D:\OneTouch\PlugIn\PlugBase.inc';               
  if not DirectoryExists (ExtractFilePath(FileName)) then Exit;

  if FileExists (FileName) then
  begin
    OldSL := TStringList.Create;
    OldSL.LoadFromFile(FileName);
    for Index := 0 to OldSL.Count - 1 do
    begin
      Item := OldSL[Index];
      if Item <> 'Const' then
      begin
        ItemKey := OldSL.Names[Index];
        ItemValue := OldSL.ValueFromIndex[Index];
        if RHashList.IndexOfName(ItemKey) = -1 then
          RHashList.Values[ItemKey] := ItemValue;
      end;
    end;
    OldSL.Free;

    Index := RHashList.IndexOf('Const');
    if Index > 0 then
      RHashList.Move(Index, 0);
    if Index = -1 then
      RHashList.Insert (0, 'Const');
  end else
  begin
    RHashList.Insert (0, 'Const');
  end;

  RHashList.SaveToFile (FileName);

  FileName := ChangeFileExt (FileName, '.h');
  HeadSL := TStringList.Create;
  HeadSL.Add ('#pragma once');
  for Index := 1 to RHashList.Count - 1 do
  begin
    ItemKey := RHashList.Names[Index];
    ItemValue := RHashList.ValueFromIndex[Index];
    Delete(ItemValue, 1, 1);
    Delete(ItemValue, Length(ItemValue), 1);
    HeadSL.Add('#define ' + ItemKey + ' 0x' + ItemValue);
  end;
  HeadSL.SaveToFile (FileName);
  

  FileName := 'D:\OneTouch\PlugIn\PlugKernelExp.inc';
  ExpList.SaveToFile(FileName);

  FreeAndNil (RHashList);
  FreeAndNil (HeadSL);
  FreeAndNil (ExpList);
end;
{$ELSE}
Procedure SaveHash;
begin
end;
{$ENDIF}

Function RH (Name: String; ExportIt: BOOL = False): DWORD;
begin
  Result := GetUpperNameHashS (Name);    
{$IFDEF MAKE_HASH_INC}
  if RightLevel <> $40000 then Exit;
  if not assigned (RHashList) then
  begin
    RHashList := TStringList.Create;
    ExpList := TStringList.Create;
  end;

  RHashList.Values['HASH_' + Name] := '$' + IntToHex(Result, 8) + ';';

  if ExportIt then
    ExpList.Add(Name + ',');
{$ENDIF}
end;

Procedure MakePlugBaseLibrary;
var
  HASH_PlugBaseLibrary: DWORD;
begin
  HASH_PlugBaseLibrary := RH ('PlugBaseLibrary');

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('ExportLibFunction'), @ExportLibFunction);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('ImportLibFunction'), @ImportLibFunction); 

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetUpperNameHash'), @GetUpperNameHash);


  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CreateMsgServer',True), @CreateMsgServer);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CreateMsgServerEx',True), @CreateMsgServerEx);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SendMsgToServer',True), @SendMsgToServer);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SendMsgToServerEx',True), @SendMsgToServerEx);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CloseMsgServer',True), @CloseMsgServer);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('MakeSyncQueue',True), @MakeSyncQueue);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('PushSyncQueue',True), @PushSyncQueue);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetSyncQueueCount',True), @GetSyncQueueCount);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('FreeSyncQueue',True), @FreeSyncQueue);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetConfig'), @GetConfig);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('IsTargetProcess'), @IsTargetProcess);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('WriteMemory',True), @WriteMemory);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCallingImage',True), @GetCallingImage);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCallingAddr',True), @GetCallingAddr);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SetHook',True), @SetHook);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('UnHook',True), @UnHook);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SMHookApi',True), @SMHookApi);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('UnSMHookApi',True), @UnSMHookApi);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('MakeTemplate',True), @MakeTemplate);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('FreeTemplate',True), @FreeTemplate);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CompareTemplate',True), @CompareTemplate);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('FineAddress',True), @FineAddress);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SearchAddress',True), @SearchAddress);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCodeSectionMemory',True), @GetCodeSectionMemory);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetDataSectionMemory',True), @GetDataSectionMemory);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetSectionMemory',True), @GetSectionMemory);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetImageBase',True), @GetImageBase);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetModuleSize',True), @GetModuleSize);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetEntryPoint',True), @GetEntryPoint);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetImageNtHeaders',True), @GetImageNtHeaders);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetSectionHeaders',True), @GetSectionHeaders);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('EnumRelocations',True), @EnumRelocations);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('EnumExports',True), @EnumExports);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCodeDisAsm',True), @GetCodeDisAsm);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetFuncDisAsm',True), @GetFuncDisAsm);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCodeStruct',True), @GetCodeStruct);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetFuncStruct',True), @GetFuncStruct);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCodeAssemble',True), @GetCodeAssemble);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnAppData'), @OnAppData);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnProgress'), @OnProgress);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnConfig'), @OnConfig);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnKeyData'), @OnKeyData);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnMsgSystem'), @OnMsgSystem);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnMsgError'), @OnMsgError);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnMsgDebug'), @OnMsgDebug);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnMsgLog'), @OnMsgLog);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OnMsgNotice'), @OnMsgNotice);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('TrapDbgSetup',True), @TrapDbgSetup);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('TrapDbgWait',True), @TrapDbgWait);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('TrapDbgRelease',True), @TrapDbgRelease);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('TrapDbgStepInto',True), @TrapDbgStepInto);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('TrapDbgStepOver',True), @TrapDbgStepOver);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('TrapDbgRunUntilRet',True), @TrapDbgRunUntilRet);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('TrapDbgRunUntilAddr',True), @TrapDbgRunUntilAddr);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CreateIpcServer',True), @CreateIpcServer);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('AddIpcCommand',True), @AddIpcCommand);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('EchoIpcCommand',True), @EchoIpcCommand);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('DestroyIpcServer',True), @DestroyIpcServer);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SendIpcCommand',True), @SendIpcCommand);

  SaveHash;
end;

////////////////////////////////////////////////////////////////////////////////
///                     DLL 入口
////////////////////////////////////////////////////////////////////////////////


Procedure MakeSureDirectory;
begin
  SetCurrentDir (ExtractFilePath (GetModuleName (0)));
end;                   

Function GetReservedParam: Pointer; Register;
asm
  mov eax,[ebp+16]       //[ebp+16] lpvReserved
end;

Type
  LPTransParam = ^TTransParam;
  TTransParam = packed record
    lpParameter: Pointer;
    lpResult: DWORD;
  end;
  
var
  InputParam: LPTransParam;

procedure DLLEntryPoint(dwReason : DWord);
begin
  case dwReason of
    DLL_PROCESS_ATTACH: begin
      if Assigned (InputParam) then
      begin
        ParamSL := TStringList.Create;
        ParamSL.Text := StrPas (InputParam.lpParameter);
        MsgChannel := GetParamStr ('MsgChannel');
        AppCmdLine   := GetParamStr ('AppCmdLine');
        CmdChannel := GetParamStr ('CmdChannel');
        RunMode := StrToInt (GetParamStr ('RunMode'));
        RightLevel := StrToInt (GetParamStr ('RightLevel'));

        MakePlugBaseLibrary;
        InputParam.lpResult := DWORD(@FindFuncEntry);
        OnMsgDebug ('DefaultPlugBase DLLEntryPoint');
      end else
        OutputDebugString ('非法模块加载');
    end;
    DLL_PROCESS_DETACH: begin
      if Assigned (ParamSL) then
        ParamSL.Free;
    end;
  end;
end;

begin
  InputParam := GetReservedParam;
  if Assigned (InputParam) then
  if Assigned (InputParam.lpParameter) then
  begin
    DLLProc := @DLLEntryPoint;
    DLLEntryPoint(DLL_PROCESS_ATTACH);
  end;
end.

