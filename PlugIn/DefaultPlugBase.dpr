library DefaultPlugBase;
                      
{$I ..\ShareUnit\GlobalDefine.inc}

uses SysUtils, windows, classes, superobject, DLLDatabase, AndQueMessages,
     TCodeEventNotify, IntList, WideStrUtils, GlobalObject, TrapApiHook,
     CmdChannelUnit, FindAddress, SyncQueueHandler;

var
  DebugChannel: String;
  AppCmdLine: String;
  RunMode: String;
  PlugParamSO: ISuperObject;
  IsDebugMode: BOOL = False;
  RightLevel: DWORD;

function GetParamStr (Path: String): String;
begin
  Result := PlugParamSO.S[Path];   
end;
                          
function GetJsonParam (Path: PChar): PChar; Stdcall;
var
  TempRet: String;
begin
  TempRet := StrPas (Path);
  TempRet := GetParamStr (TempRet);
  Result := @TempRet[1];
end;

function GetJsonString: PChar; Stdcall;
var
  JsonStr: String;
begin
  JsonStr := PlugParamSO.AsJSon(True, False);
  Result := PChar(JsonStr);
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

Procedure SaveHash;
var
  FileName, Item, ItemKey, ItemValue: String;
  Index: Integer;
  OldSL: TStringList;
begin
  if RightLevel <> $40000 then Exit;
  if not assigned (RHashList) then exit;

  FileName := 'D:\OneTouch\PlugIn\PlugBase.inc';
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
  end else
  begin
    RHashList.Insert (0, 'Const');
  end;
  RHashList.SaveToFile (FileName);
end;
{$ELSE}
Procedure SaveHash;
begin
end;
{$ENDIF}

Function RH (Name: String): DWORD;
begin
  Result := GetUpperNameHashS (Name);    
{$IFDEF MAKE_HASH_INC}
  if RightLevel <> $40000 then Exit;
  if not assigned (RHashList) then
    RHashList := TStringList.Create;

  Name := 'HASH_' + Name;
  RHashList.Values[Name] := '$' + IntToHex(Result, 8) + ';';
{$ENDIF}
end;

Procedure DebugPrint (Msg: PChar); stdcall;
begin
  if IsDebugMode then
    SendMsgToServer (@DebugChannel[1], Msg, StrLen (Msg));
end;

Procedure DebugPrintEx (Msg: PChar); stdcall;
begin
  if IsDebugMode then
    SendMsgToServerEx (@DebugChannel[1], Msg, StrLen (Msg));
end;


Procedure MakePlugBaseLibrary;
var
  HASH_PlugBaseLibrary: DWORD;
begin
  HASH_PlugBaseLibrary := RH ('PlugBaseLibrary');

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('ExportLibFunction'), @ExportLibFunction);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('ImportLibFunction'), @ImportLibFunction); 

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetUpperNameHash'), @GetUpperNameHash);


  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CreateMsgServer'), @CreateMsgServer);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SendMsgToServer'), @SendMsgToServer);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SendMsgToServerEx'), @SendMsgToServerEx);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CloseMsgServer'), @CloseMsgServer);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('MakeSyncQueue'), @MakeSyncQueue);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('PushSyncQueue'), @PushSyncQueue);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetSyncQueueCount'), @GetSyncQueueCount);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('FreeSyncQueue'), @FreeSyncQueue);  

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetJsonParam'), @GetJsonParam);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetJsonString'), @GetJsonString);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('IsTargetProcess'), @IsTargetProcess);


  SaveFuncEntry (HASH_PlugBaseLibrary, RH('DebugPrint'), @DebugPrint);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('DebugPrintEx'), @DebugPrintEx);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('WriteMemory'), @WriteMemory);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCallingImage'), @GetCallingImage);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetCallingAddr'), @GetCallingAddr);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SetHook'), @SetHook);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('UnHook'), @UnHook);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SMHookApi'), @SMHookApi);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('UnSMHookApi'), @UnSMHookApi);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('MakeTemplate'), @MakeTemplate);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('FreeTemplate'), @FreeTemplate);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CompareTemplate'), @CompareTemplate);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('SearchAddress'), @SearchAddress);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('GetSectionMemory'), @GetSectionMemory);

  SaveFuncEntry (HASH_PlugBaseLibrary, RH('ShowUserMessage'), @CMD_ShowUserMessage);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('OpenProgressWindow'), @CMD_OpenProgressWindow);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('ReportProgress'), @CMD_ReportProgress);
  SaveFuncEntry (HASH_PlugBaseLibrary, RH('CloseProgressWindow'), @CMD_CloseProgressWindow);

  SaveHash;
end;

////////////////////////////////////////////////////////////////////////////////
///                     DLL 入口
////////////////////////////////////////////////////////////////////////////////


function Usage: PChar; Stdcall;
begin
  Result := '这是TYPE_PLUGBASE DefaultPlugBase.dll插件的使用帮助';
end;

function PluginType: PChar; Stdcall;
begin
  Result := TYPE_PLUGBASE;
end;
          
Exports
  Usage name 'Help',
  PluginType name 'Type';

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
        PlugParamSO := TSuperObject.ParseString(InputParam.lpParameter);
        DebugChannel := PlugParamSO.S['DbgChannel'];
        AppCmdLine   := PlugParamSO.S['AppCmdLine'];
        Default_CmdChannel := PlugParamSO.S['CmdChannel'];
        RunMode := PlugParamSO.S['RunMode'];
        IsDebugMode := RunMode = 'Debug';
        RightLevel := PlugParamSO.I['DropMyRights'];

        MakePlugBaseLibrary;
        InputParam.lpResult := DWORD(@FindFuncEntry);

        DebugPrint ('DefaultPlugBase DLLEntryPoint');   
      end else
        OutputDebugString ('非法模块加载');
    end;
    DLL_PROCESS_DETACH: begin
      if Assigned (PlugParamSO) then
        PlugParamSO := NIL;
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

//{
// "PlugPath": "D:\\OneTouch\\release\\PlugIn\\",
// "PlugBase": "DefaultPlugBase.dll",
// "AppCmdLine": "d:\\Silkroad\\sro_client.exe",
// "\u4eba\u7269\u89d2\u8272\u540d": "JasCamr",
// "PrivacyField": [
//  "\u6e38\u620f\u5bc6\u7801"],
// "Enable": true,
// "\u6e38\u620f\u670d\u52a1\u5668": "\u5927\u5510\u76db\u4e16[\u534e\u4e1c]",
// "\u6e38\u620f\u5e10\u53f7\u540d": "siestii",
// "\u6e38\u620f\u5927\u5206\u533a": "\u7535\u4fe1\u4e00\u533a",
// "PluginName": "SilkRoad.dll",
// "Daemon": "DefaultDaemon.dll",
// "DbgChannel": "{25CEADF5-1949-4310-AEB6-C2FC197B1BA4}",
// "AppKeyInfo": "{2DC6879E-5A66-4DD9-BCA3-2C5CDA9D43A6}.json",
// "ID": "{2DC6879E-5A66-4DD9-BCA3-2C5CDA9D43A6}",
// "AppLogFile": "{2DC6879E-5A66-4DD9-BCA3-2C5CDA9D43A6}.log",
// "\u6e38\u620f\u5bc6\u7801": "darren",
// "TempPath": "D:\\OneTouch\\release\\TempData\\",
// "Name": "\u72c2\u98ce\u6c99",
// "RunMode": "Debug",
// "PluginLib": [
//  "SilkRoadAddr.dll"]
//}
