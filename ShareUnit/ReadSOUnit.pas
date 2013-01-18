unit ReadSOUnit;

interface

uses Windows, SysUtils, Classes, SuperObject,
     WideStrings, WideStrUtils, md5, GlobalObject, DLLLoader, RunInfoDB;

Type
  TLibMMArray = Array Of TMemoryStream;

  TReadForLoadAPP = Class(TObject)
  Private
    FConfigFile, FConfigID: String;
    FRunMode: String;
    FRawData: String;
    WorkSO: ISuperObject;
    AimConfig: ISuperObject;
  Protected
    function GetKeyNameBySrcDefine (MainKeyName, SrcDefine: String; var KeyName: String): BOOL;
    function GetPlugMMBySrcDefine (SrcDefine: String): TMemoryStream;
    Procedure SetProperty (Const Name: String; Value: String);
    function  GetProperty (const Name: string): string;
  Public
    Constructor Create (ConfigFile, ConfigID: String);
    Destructor Destroy; override;
    Procedure SetRunMode (RunMode: String);
    Procedure SetDbgChanel (DbgChanel: String);
    Procedure SetCmdChannel (CmdChannel: String);
  Public
    PlugPath: String;
    TempPath: String;
    PlugName: String;
    AppCmdLine: String;
    RightLevel: DWORD;
    Function GetDaemon: TMemoryStream;
    Function GetPlugBase: TMemoryStream;
    Function GetPlugLib: TLibMMArray;
    Function GetMainPlugin: TMemoryStream;
    Function GetMainPluginParam: SOString;
    Function GetPrivateField: TStringList;
    Property Values[const Name: string]: string read GetProperty write SetProperty;
  end;

var
  RFL: TReadForLoadAPP;

function GetAppPaths (DirName: String): String;
function GetSOJsonText (Aim: ISuperObject): String;

implementation

uses DropMyRights;

function GetSOJsonText (Aim: ISuperObject): String;
begin
  Result := Aim.AsJSon(True, False);
end;

function GetAppPaths (DirName: String): String;
begin
  Result := GetModuleName (0);
  Result := ExtractFilePath (Result) + DirName + '\';
end;

function TReadForLoadAPP.GetKeyNameBySrcDefine (MainKeyName, SrcDefine: String; var KeyName: String): BOOL;
var
  MainPluginPath, TmpName: String;
begin
  Result := False;
  MainPluginPath := ExtractFilePath (PlugPath + MainKeyName);
  if MainKeyName = '' then exit;
  if SrcDefine = '' then exit;

  TmpName := MainPluginPath + SrcDefine;
  if FileExists (TmpName) then
  begin
    KeyName := StrPas(@TmpName[Length(PlugPath)+1]);
    Result := True;
  end else
  begin
    TmpName := PlugPath + SrcDefine;
    if FileExists (TmpName) then
    begin
      KeyName := SrcDefine;
      Result := True;
    end;
  end;
end;


Procedure TReadForLoadAPP.SetProperty (Const Name: String; Value: String);
begin
  AimConfig.S[Name] := Value;
end;

function  TReadForLoadAPP.GetProperty (const Name: string): string;
begin
  Try
    Result := AimConfig.S[Name];
  Except
    Result := '';
  end;
end;

Procedure TReadForLoadAPP.SetRunMode (RunMode: String);
begin
  FRunMode := RunMode;
  AimConfig.S['RunMode'] := RunMode;
end;

Procedure TReadForLoadAPP.SetDbgChanel (DbgChanel: String);
begin
  AimConfig.S['DbgChannel'] := DbgChanel;
end;

Procedure TReadForLoadAPP.SetCmdChannel (CmdChannel: String);
begin
  AimConfig.S['CmdChannel'] := CmdChannel;
end;

function TReadForLoadAPP.GetPlugMMBySrcDefine (SrcDefine: String): TMemoryStream;
var
  PlugFile: String;
  AimKeyName: String;
begin
  Result := NIL;
  if GetKeyNameBySrcDefine (PlugName, SrcDefine, AimKeyName) then
  begin
    PlugFile := PlugPath + AimKeyName;
    if FileExists (PlugFile) then
    begin
      Result := TMemoryStream.Create;
      Result.Seek(0, soFromBeginning);
      Result.LoadFromFile(PlugFile);
    end;
  end;
end;

Function TReadForLoadAPP.GetDaemon: TMemoryStream;
var
  SrcDefine: String;
begin
  SrcDefine := Aimconfig.S['Daemon'];
  Result := GetPlugMMBySrcDefine (SrcDefine);
end;

Function TReadForLoadAPP.GetPlugBase: TMemoryStream;
var
  SrcDefine: String;
begin
  SrcDefine := Aimconfig.S['PlugBase'];
  Result := GetPlugMMBySrcDefine (SrcDefine);
end;


Function TReadForLoadAPP.GetPlugLib: TLibMMArray;
var
  LibArray: TSuperArray;
  Index, AddIndex: Integer;
  SrcDefine: String;
  LibMM: TMemoryStream;
begin
  LibArray := Aimconfig.A['PluginLib'];

  for Index := 0 to LibArray.Length - 1 do
  begin
    SrcDefine := LibArray.S[Index];
    LibMM := GetPlugMMBySrcDefine (SrcDefine);
    if Assigned (LibMM) then
    begin
      AddIndex := Length(Result);
      SetLength(Result, AddIndex + 1);
      Result[AddIndex] := LibMM;
    end;
  end;
end;

Function TReadForLoadAPP.GetPrivateField: TStringList;
var
  LibArray: TSuperArray;
  Index: Integer;
  SrcDefine: String;
begin
  Result := TStringList.Create;
  LibArray := Aimconfig.A['PrivacyField'];

  for Index := 0 to LibArray.Length - 1 do
  begin
    SrcDefine := LibArray.S[Index];
    Result.Add(SrcDefine);
  end;
end;

Function TReadForLoadAPP.GetMainPlugin: TMemoryStream;
var
  PlugFile: String;
begin
  Result := NIL;
  PlugFile := PlugPath + PlugName;
  if FileExists (PlugFile) then
  begin
    Result := TMemoryStream.Create;
    Result.Seek(0, soFromBeginning);
    Result.LoadFromFile(PlugFile);
  end;
end;

Function TReadForLoadAPP.GetMainPluginParam: SOString;
begin
  Result := GetSOJsonText (Aimconfig);
end;


Constructor TReadForLoadAPP.Create (ConfigFile, ConfigID: String);
var
  Index: Integer;
  List: TSuperArray;
  Item: ISuperObject;
  IterID, AppRight: String;
  SubRight: DWORD;
begin
  Inherited Create;
  FConfigFile := ConfigFile;
  FConfigID := ConfigID;
  FRunMode := 'Normal';

  if not FileExists (FConfigFile) then
    Raise Exception.Create('PlugsHolder.json文件缺失！');

  if not (Length(FConfigID) = Length('{76B68A2D-9A87-4512-A550-88DCA52687ED}')) then
    Raise Exception.Create('ConfigID长度错误！');

  WorkSO := TSuperObject.ParseFile(FConfigFile);
  FRawData := GetSOJsonText (WorkSO);

  PlugPath := WorkSO.S['PluginList.PlugPath'];
  TempPath := WorkSO.S['AppConfigList.TempPath'];
  RightLevel := WorkSO.I['AppConfigList.DropMyRights'];

  if not DirectoryExists (PlugPath) then
    Raise Exception.Create('PlugPath目录不存在！');

  if not DirectoryExists (TempPath) then
    Raise Exception.Create('TempPath目录不存在！');

  AimConfig := NIL;
  List := WorkSO.A['AppConfigList.Items'];
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    IterID := Item.S['ID'];
    if IterID = FConfigID then
    begin
      AimConfig := Item;
      Break;
    end;
  end;
  if AimConfig = NIL then
    Raise Exception.Create('ConfigID不存在！');

  AppCmdLine := AimConfig.S['AppCmdLine'];
  PlugName := AimConfig.S['PluginName'];
  AppRight := AimConfig.S['AppRight'];   
  
  AppRight := UpperCase (AppRight);
  if AppRight = 'HIGH' then
    SubRight := SAFER_LEVELID_FULLYTRUSTED
  else if AppRight = 'MIDDLE' then
    SubRight := SAFER_LEVELID_NORMALUSER
  else if AppRight = 'LOW' then
    SubRight := SAFER_LEVELID_CONSTRAINED
  else
    SubRight := SAFER_LEVELID_FULLYTRUSTED;

  if SubRight < RightLevel then
    RightLevel := SubRight;

  if PlugName = '' then
    Raise Exception.Create('PluginName错误！');

  AimConfig.S['TempPath'] := TempPath;
  AimConfig.S['PlugPath'] := PlugPath;
  AimConfig.I['DropMyRights'] := RightLevel;

  if (GetTickCount mod 11) = 1 then  //按一定几率发生执行
    AppConfigList_Delete (30); //自动清除那些废配置运行记录。
end;

Destructor TReadForLoadAPP.Destroy;
begin
  WorkSO := NIL;
  AimConfig := NIL;
  Inherited Destroy;
end;

end.
