unit DataUnit;

interface

uses Windows, SysUtils, Classes, SuperObject, CheckLst, ValEdit, ComCtrls,
     WideStrings, WideStrUtils, md5, GlobalObject, DLLLoader, RunInfoDB,
     CategoryButtons, ImgList;

Type

  TTDataCfgModule = class (TObject)
  Private
    FNeedSave: BOOL;
    FConfigFile: String;
    FAccessMutexName: String;
    FPlugPath, FTempPath: String;
    FSkipPluginEntry: BOOL;
    FRawData: String;
    WorkSO: ISuperObject;
    FPluginDLLs: TStringList;
    FErrorPluginList: TStringList;
    FChangeLoger: TStringList;
    FSystemFields, FConstFields: TStringList;
  Protected
    function GetIsViewPrivateField: BOOL;
    Procedure SetIsViewPrivateField (Value: BOOL);
    Procedure SetIsViewConstField (Value: BOOL);
    function GetIsViewConstField: BOOL;
    Procedure SetIsDropMyRights (Value: DWORD);
    function GetIsDropMyRights: DWORD;
    function GetIsAllwayOnTop: BOOL;
    Procedure SetIsAllwayOnTop(Value: BOOL);
    Procedure SetNeedSave (Value: BOOL);


    Procedure ClearUeslessPluginItem;
    function IsInPluginList (KeyName: String): BOOL;
    function AddInPluginList (KeyName: String): BOOL;
    function MakeANewPluginItem (KeyName: String): ISuperObject;
    function MakeRealInputSL (UserInput, DefaultSL: TStrings): TStringList;    
  public
    function GetPluginDLLLoader (KeyName: String): TDLLLoaderEx;
    function LoadPluginDLL (KeyName: String): TDLLLoaderEx;
    Procedure UnloadPluginDLLs;

    function CallPluginFuncForText (KeyName: String; FuncName: String): String;
    function CheckIsSafe (KeyName: String): BOOL;
    function CheckIsCredible (KeyName: String): BOOL;
    function GetPluginType (KeyName: String): String;
    function GetPluginMD5 (KeyName: String): String;
    function GetPluginHelp (KeyName: String): String;
    function CheckIsTargetApp (KeyName, AppPath: String): BOOL;
    function CheckIsAutoSet (KeyName: String): BOOL;
  Public
    Constructor Create (ConfigFile: String);
    Destructor Destroy; override;

    //文件处理
    Function IsRawFileChanged: BOOL;
    Procedure SaveToFile (MixMode: BOOL = False);
    Procedure SaveAsFile (FileName: String);
    Procedure RestoreALL;
    Procedure LoadFromFile (ConfigFile: String = '');

    //读取显示,获取信息
    Procedure ReloadConfigList (var ListBox: TCheckListBox); overload;
    Procedure ReloadConfigList (var ConfigList: TCategoryButtons); overload;
    Procedure ReloadPluginList (var ListBox: TCheckListBox);
    Procedure ReloadParamList (ConfigID: String; var ValueLst: TValueListEditor; ViewEnable: BOOL = False);

    Procedure LoadPluginFromDisk;

    FUNCTION GetMainPluginList (AppPath: String = ''): TStringList;
    FUNCTION GetNeedPluginList_Dll (MainKeyName: String; var HaveSL, LackSL: TStringList): BOOL;
    function GetNeedPluginList_Cfg (ConfigID: String; var HaveSL, LackSL: TStringList): BOOL; overload;
    function GetNeedPluginList_Cfg (var HaveSL, LackSL: TStringList): BOOL; overload;
    FUNCTION GetUsePluginList_Cfg (var UseSL: TStringList): BOOL;
    function GetUselessPluginList_Cfg (var UselessSL: TStringList): BOOL;
    function GetKeyNameBySrcDefine (MainKeyName, SrcDefine: String; var KeyName: String): BOOL;
    function GetPluginLastRunTime (KeyName: String; LastRunTime: TDateTime): BOOL;
    function GetLastRunPlugin (Const Plugins: TStringList): String;
    function GetPluginParamList (KeyName: String): TStringList;
    function GetParamValueList (KeyName: String): TStringList;
    function GetParamKeyNameList (KeyName: String): TStringList;
    function GetLastRunApp(): String;
    function GetPluginFromConfigID (ConfigID: String; var AppExe, PluginName: String): BOOL;
    function IsLackPlugin (var LackSL: TStringList): BOOL; overload;
    Function IsLackPlugin (ConfigID: String): BOOL; overload;
    Function IsLackPlugin (ConfigID: String; var LackSL: TStringList): BOOL; overload;
    function IsSystemField (ParamKey: String): BOOL;
    function IsConstField (ParamKey: String): BOOL;

    //修改配置
    function GetConfigAppList (): TStringList;
    Function GetBlankPrivateField (ConfigID: String): TStringList;
    function FindConfig (ConfigID: String; out Item: ISuperObject): BOOL; overload;
    function FindConfig (ConfigID: String; out Item: ISuperObject; out ItemIndex: Integer): BOOL; overload;
    Function ViewConfig (ConfigID: String; ValueLst: TValueListEditor; ViewEnable: BOOL = False): BOOL;
    function AddConfig (PluginName: String; ValueLst: TValueListEditor): BOOL;
    function ModifyConfig (ConfigID: String; ValueLst: TValueListEditor): BOOL;
    function CloneConfig (ConfigID: String; NewName: String; Out NewConfigID: String): BOOL;
    Function DeleteConfig (ConfigID: String): BOOL;
    Function EnableConfig (ConfigID: String; Enable: BOOL = True): BOOL;
    Procedure ClearAllConfig;
    Procedure UpdateAppCmdLine (KeyName: String; OldCmdLine, NewCmdLine: String);
    function  GetAppCmdLine (ConfigID: String; Out AppCmdLine: String): BOOL; overload;
    function  GetAppCmdLine (ConfigID: String): String; overload;
    function  GetPlugInName (ConfigID: String; Out PluginName: String): BOOL;


    Procedure ResetSortConfig (SortMode: TSortMode);
    Procedure MoveConfig (ConfigID: String; Step: Integer);
    Procedure MoveUpConfig (ConfigID: String);
    Procedure MoveDownConfig (ConfigID: String);

    Procedure Log (sType, Msg: String);

    Property ChangeLog: TStringList Read FChangeLoger;
    Property ViewConstField: BOOL read GetIsViewConstField write SetIsViewConstField;
    Property ViewPrivateField: BOOL read GetIsViewPrivateField write SetIsViewPrivateField;
    Property AllwayOnTop: BOOL read GetIsAllwayOnTop write SetIsAllwayOnTop;
    Property DropMyRights: DWORD read GetIsDropMyRights write SetIsDropMyRights;
    Property PlugPath: String read FPlugPath;
    Property TempPath: String read FTempPath;
    Property AccessMutex: String read FAccessMutexName;
    Property NeedSave: BOOL Read FNeedSave write SetNeedSave;
  end;
  

function GetSOJsonText (Aim: ISuperObject): String;
function GetAppPaths (DirName: String): String;
function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
function GetAppExeFromCmdLine (CmdLine: String): String;
Procedure ExtractHitAndConst (Source: String; var ConstStr,HitStr: String);

var
  DCM: TTDataCfgModule;

implementation

uses RcFuncUnit, ComObj, SearchFileUnit, Graphics, shellapi;

Procedure DbgPrint (Msg: WideString); overload;
begin
  OutputDebugStringW (PWideChar(Msg));
end;

Procedure DbgPrint (Msg: String); overload;
begin
  OutputDebugStringA (PChar(Msg));
end;

Procedure DbgPrint (Item: ISuperObject); overload;
begin
  DbgPrint (GetSOJsonText(Item));
end;

function GetAppPaths (DirName: String): String;
begin
  Result := GetModuleName (0);
  Result := ExtractFilePath (Result) + DirName + '\';
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

Procedure ExtractHitAndConst (Source: String; var ConstStr,HitStr: String);
var
  LeftIndex, RightIndex: Integer;
  Found: BOOL;
  ConstLen: Integer;
begin
  Found := False;
  Source := Trim (Source);
  ConstStr := '';
  HitStr := Source;

  for LeftIndex := 1 to Length(Source) do
  begin
    if Source[LeftIndex] = '<' then
    begin
      Found := True;
      break;
    end;
  end;

  if not Found then  exit;

  Found := False;
  for RightIndex := Length(Source) downto 1 do
  begin
    if Source[RightIndex] = '>' then
    begin
      Found := True;
      break;
    end;
  end;

  if not Found then exit;

  ConstLen := RightIndex - LeftIndex - 1;

  if ConstLen = 0 then
  begin
    ConstStr := '';
    HitStr := Source;
    Delete (HitStr, LeftIndex, RightIndex - LeftIndex + 1);
    Exit;
  end;

  if ConstLen > 0 then
  begin
    ConstStr := Copy (Source, LeftIndex + 1, RightIndex - LeftIndex - 1);
    HitStr := Source;
    Delete (HitStr, LeftIndex, RightIndex - LeftIndex + 1);
  end;
end;

Procedure TTDataCfgModule.RestoreALL;
begin
  WorkSO.Clear();
  WorkSO := NIL;
  WorkSO := SO (FRawData);
  NeedSave := True;
end;

Procedure TTDataCfgModule.LoadFromFile (ConfigFile: String = '');
begin
  if Assigned (WorkSO) then
  begin
    WorkSO.Clear();
    WorkSO := NIL;
  end;

  if ConfigFile = '' then
    ConfigFile := FConfigFile;
    
  WorkSO := TSuperObject.ParseFile(ConfigFile);
  FRawData := GetSOJsonText (WorkSO);
  NeedSave := True;
end;

function GetSOJsonText (Aim: ISuperObject): String;
begin
  Result := Aim.AsJSon(True, False);
end;

Constructor TTDataCfgModule.Create (ConfigFile: String);
var
  ConstFile: String;
  List: TSuperArray;
  Index: Integer;
  ItemStr: String;
begin
  FNeedSave := False;
  Inherited Create;
  FConfigFile := ConfigFile;

  ConstFile := RcAnsiSLToString ('STRING_FILE', 'DEFAULT_DATA_STRUCT');

  if FileExists (FConfigFile) then
  begin
    LoadFromFile (FConfigFile);
    FNeedSave := False;
  end else
  begin
    WorkSO := SO (ConstFile);
    WorkSO.S['Control.AccessMutex'] := CreateClassID;
    WorkSO.S['Control.HolderVersion'] := 'NULL';
    WorkSO.S['Control.HolderMD5'] := 'NULL';
    WorkSO.S['Control.VerifyBlock'] := 'NULL';

    WorkSO.S['PluginList.PlugPath'] := GetAppPaths ('PlugIn');
    WorkSO.S['AppConfigList.TempPath'] := GetAppPaths ('TempData');

    FRawData := GetSOJsonText (WorkSO);
    WorkSO.SaveTo(FConfigFile, True);
  end;

  FAccessMutexName := WorkSO.S['Control.AccessMutex'];
  FSkipPluginEntry := WorkSO.B['Control.SkipPluginEntry'];
  FPlugPath := WorkSO.S['PluginList.PlugPath'];
  FTempPath := WorkSO.S['AppConfigList.TempPath'];

  if not DirectoryExists (FPlugPath) then
  begin
    FPlugPath := GetAppPaths ('PlugIn');
    WorkSO.S['PluginList.PlugPath'] := FPlugPath;
    NeedSave := True;
  end;
  if not DirectoryExists (FPlugPath) then
    DbgPrint (FPlugPath + ' not exists!');


  if not DirectoryExists (FTempPath) then
  begin
    FTempPath := GetAppPaths ('TempData');
    WorkSO.S['AppConfigList.TempPath'] := FTempPath;
    NeedSave := True;
  end;
  if not DirectoryExists (FTempPath) then
    DbgPrint (FTempPath + ' not exists!');

  FSystemFields :=  TStringList.Create;
  List := WorkSO.A['AppConfigList.SystemField'];
  for Index := 0 to List.Length - 1 do
  begin
    ItemStr := List.O[Index].AsString;
    FSystemFields.Add (ItemStr);
  end;

  FConstFields :=  TStringList.Create;
  List := WorkSO.A['AppConfigList.ConstField'];
  for Index := 0 to List.Length - 1 do
  begin
    ItemStr := List.O[Index].AsString;
    FConstFields.Add (ItemStr);
  end;

  FPluginDLLs := TStringList.Create;
  FErrorPluginList := TStringList.Create;
  FChangeLoger := TStringList.Create;

  if (GetTickCount mod 11) = 1 then  //按一定几率发生执行
    AppConfigList_Delete (30); //自动清除那些废配置运行记录。
end;

Destructor TTDataCfgModule.Destroy;
begin
  UnloadPluginDLLs;
  FPluginDLLs.Free;
  FErrorPluginList.Free;
  FChangeLoger.Free;
  FSystemFields.Free;
  FConstFields.Free;
  WorkSO := NIL;
  Inherited Destroy;
end;


function TTDataCfgModule.GetPluginDLLLoader (KeyName: String): TDLLLoaderEx;
var
  Index: Integer;
begin
  result := nil;
  Index := FPluginDLLs.IndexOf(KeyName);
  if Index = -1 then exit;
  result := FPluginDLLs.Objects[Index] as TDLLLoaderEx;
end;

function TTDataCfgModule.LoadPluginDLL (KeyName: String): TDLLLoaderEx;
var
  Index: Integer;
  PluginFile: string;
  PlugDLL: TDLLLoaderEx;
begin
  Result := NIL;
  Index := FPluginDLLs.IndexOf(KeyName);
  if Index >= 0 then
  begin
    Result := FPluginDLLs.Objects[Index] as TDLLLoaderEx;
    Exit;
  end;

  PlugDLL := TDLLLoaderEx.Create;
  PlugDLL.IsSkipDLLProc := FSkipPluginEntry;
  PluginFile := FPlugPath + KeyName;

  Repeat
    if not PlugDLL.LoadDLL (PluginFile) then Break;
    if PlugDLL.FindExport('Help') = NIL then Break;
    if PlugDLL.FindExport('Type') = NIL then Break;

    Result := PlugDLL;
    FPluginDLLs.AddObject (KeyName, Result);
    Exit;
  until True;
  PlugDLL.Free;
end;


Procedure TTDataCfgModule.UnloadPluginDLLs;
var
  Index: Integer;
  ItemSL: TDLLLoaderEx;
begin
  for Index := 0 to FPluginDLLs.Count - 1 do
  begin
    ItemSL := FPluginDLLs.Objects[Index] as TDLLLoaderEx;
    ItemSL.Free;
  end;
  FPluginDLLs.Clear;
end;

Function TTDataCfgModule.IsRawFileChanged: BOOL;
var
  DiskData: String;
  TempSO: ISuperObject;
begin
  Result := not FileExists (FConfigFile);
  if Result then Exit;

  TempSO := TSuperObject.ParseFile(FConfigFile);
  DiskData := GetSOJsonText (TempSO);
  TempSO := nil;

  Result := Trim(DiskData) <> Trim (FRawData);
end;

Procedure TTDataCfgModule.SaveAsFile (FileName: String);
begin
  ClearUeslessPluginItem;
  WorkSO.SaveTo (FileName, True, False);
  FNeedSave := False;
end;

Procedure TTDataCfgModule.SaveToFile (MixMode: BOOL = False);  
begin
  SaveAsFile (FConfigFile);
end;


Procedure TTDataCfgModule.ResetSortConfig (SortMode: TSortMode);
var
  MapSL, SortSL: TStringList;
  List: TSuperArray;
  Item: ISuperObject;
  Index, MapIndex: Integer;
  AimConfigID: String;
begin
  MapSL := TStringList.Create;
  List := WorkSO.A['AppConfigList.Items'];
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    AimConfigID := Item.S['ID'];
    MapSL.Add(AimConfigID);
  end;

  SortSL := TStringList.Create;
  if AppConfigList_GetSortedList (SortMode, MapSL, SortSL) then
  begin
    for Index  := 0 to SortSL.Count - 1 do
    begin
      AimConfigID := SortSL.Strings[Index];
      MapIndex := MapSL.IndexOf(AimConfigID);
      if MapIndex >= 0 then
      if Index <> MapIndex then          
      begin
        MapSL.Move(MapIndex, Index);
        Item := List.Delete(MapIndex);
        List.Insert(Index, Item);
      end;
    end;
  end;
  MapSL.Free;
  SortSL.Free;
  NeedSave := True;
end;

Procedure TTDataCfgModule.MoveConfig (ConfigID: String; Step: Integer);
var
  List: TSuperArray;
  Item: ISuperObject;
  Index, BeforeIndex, ToIndex: Integer;
  AimConfigID: String;
begin
  if Step = 0 then exit;
  List := WorkSO.A['AppConfigList.Items'];
  BeforeIndex := -1;
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    AimConfigID := Item.S['ID'];
    if AimConfigID = ConfigID then
    begin
      BeforeIndex := Index;
      Break;
    end;
  end;
  if BeforeIndex = -1 then exit;

  ToIndex := BeforeIndex + Step;
  if ToIndex < 0 then
    ToIndex := 0;
  if ToIndex > List.Length - 1 then
    ToIndex := List.Length - 1;

  if ToIndex = BeforeIndex then Exit;
                              
  Item := List.Delete(BeforeIndex);
  List.Insert(ToIndex, Item);
  NeedSave := True;
end;

Procedure TTDataCfgModule.MoveUpConfig (ConfigID: String);
begin
  MoveConfig (ConfigID, -1);
end;

Procedure TTDataCfgModule.MoveDownConfig (ConfigID: String);  
begin
  MoveConfig (ConfigID, 1);
end;

Procedure TTDataCfgModule.ClearAllConfig;
var
  List: TSuperArray;          
begin
  List := WorkSO.A['AppConfigList.Items'];
  List.Clear(True);
  NeedSave := True;
end;


procedure GrayBitmap(ABitmap: TBitmap; Value: integer);
var
  Pixel: PRGBTriple;
  w, h: Integer;
  x, y: Integer;
  avg: integer;
begin
  ABitmap.PixelFormat := pf24Bit;
  w := ABitmap.Width;
  h := ABitmap.Height;
  for y := 0 to h - 1 do
  begin
    Pixel := ABitmap.ScanLine[y];
    for x := 0 to w - 1 do
    begin
      avg := ((Pixel^.rgbtRed + Pixel^.rgbtGreen + Pixel^.rgbtBlue) div 3)
        + Value;
      if avg > 240 then avg := 240;
      Pixel^.rgbtRed := avg;
      Pixel^.rgbtGreen := avg;
      Pixel^.rgbtBlue := avg;
      Inc(Pixel);
    end;
  end;
end;


function LoadIconToImageList (PeFile: String; ImageList: TCustomImageList; GragValue: Integer = 0): Integer;
var
  ico: TIcon;
  Bitmap : TBitmap;
begin
  ico := TIcon.Create;
  ico.Handle := ExtractIcon (HInstance, PChar(PeFile), 0);   
  Result := ImageList.AddIcon(ico);
  ico.Free;

  if Result = -1 then
  begin
    Result := 0;
    Exit;
  end;

  if GragValue > 0 then
  begin
    Bitmap := TBitmap.Create;
    if ImageList.GetBitmap(Result, Bitmap) then
    begin
      ImageList.Delete(Result);
      GrayBitmap (Bitmap, GragValue);
      Result := ImageList.Add(Bitmap, nil);
    end;
    Bitmap.Free;
  end;          
end;

var
  CacheIcoIndex: TStringList = nil;

Procedure TTDataCfgModule.ReloadConfigList (var ConfigList: TCategoryButtons);
var
  List: TSuperArray;
  Item: ISuperObject;
  Index, Index2, AddIndex: Integer;
  PluginName, ItemName, ConfigID, AimConfigID, AppExe: String;
  StoreStr: PChar;
  Selected, IterItem: TButtonItem;
  BtnCategory: TButtonCategory;
  PlugEnable: boolean;
  CollapsedSL: TStringList;
  KeyIcoName: String;
begin
  if CacheIcoIndex = nil then
    CacheIcoIndex := TStringList.Create;
  CacheIcoIndex.Clear;

  CollapsedSL := TStringList.Create;

  AimConfigID := '';          
  Selected := ConfigList.SelectedItem;
  if Assigned (Selected) then
    if Assigned (Selected.Data) then
      AimConfigID := StrPas (Selected.Data);

  for Index := 0 to ConfigList.Categories.Count - 1 do
  begin
    BtnCategory := ConfigList.Categories.Items[Index];
    if BtnCategory.Collapsed then
      CollapsedSL.Add(BtnCategory.Caption);
    for Index2 := 0 to BtnCategory.Items.Count - 1 do
    begin
      IterItem := BtnCategory.Items[Index2];
      FreeMem (IterItem.Data);
    end;
  end;
  ConfigList.Categories.Clear;

      
  List := WorkSO.A['AppConfigList.Items'];
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    PluginName := Item.S['PluginName'];
    ItemName := Item.S['Name'];
    ConfigID := Item.S['ID'];
    PlugEnable := UpperCase(Item.S['Enable']) = 'TRUE';
    AppExe := GetAppExeFromCmdLine (Item.S['AppCmdLine']);
    AppExe := UpperCase (AppExe);

    StoreStr := AllocMem (Length(ConfigID)+1);
    StrCopy (StoreStr, PChar(ConfigID));

    Index2 := ConfigList.Categories.IndexOf(PluginName);
    if Index2 = -1 then
    begin
      BtnCategory := ConfigList.Categories.Add;
      BtnCategory.Caption := PluginName;
      BtnCategory.Color := clSkyBlue;   
      BtnCategory.GradientColor := clWebAliceBlue;
      BtnCategory.Collapsed := True;
    end else
      BtnCategory :=  ConfigList.Categories.Items[Index2];

    IterItem := BtnCategory.Items.Add;
    IterItem.Caption := ItemName;
    IterItem.Data := StoreStr;

    if PlugEnable then
      KeyIcoName := AppExe + '.TRUE'
    else
      KeyIcoName := AppExe + '.FALSE';

    AddIndex := CacheIcoIndex.IndexOfName(KeyIcoName);
    if AddIndex = -1 then
    begin
      if PlugEnable then
        IterItem.ImageIndex := LoadIconToImageList (AppExe, ConfigList.Images)
      else
        IterItem.ImageIndex := LoadIconToImageList (AppExe, ConfigList.Images, 50);
      CacheIcoIndex.Values[KeyIcoName] := IntToStr(IterItem.ImageIndex);
    end else
    begin
      IterItem.ImageIndex := StrToInt (CacheIcoIndex.ValueFromIndex[AddIndex]);
    end;                        

  end;

  if AimConfigID <> '' then
    for Index := 0 to ConfigList.Categories.Count - 1 do
    begin
      BtnCategory := ConfigList.Categories.Items[Index];
      BtnCategory.Collapsed := CollapsedSL.IndexOf(BtnCategory.Caption) >= 0;

      for Index2 := 0 to BtnCategory.Items.Count - 1 do
      begin
        IterItem := BtnCategory.Items[Index2];
        if AimConfigID = StrPas (IterItem.Data) then
        begin      
          ConfigList.SelectedItem := IterItem;
          Break;
        end;
      end;
    end;

  CollapsedSL.Free;
end;

Procedure TTDataCfgModule.ReloadConfigList (var ListBox: TCheckListBox);
var
  List: TSuperArray;
  Item: ISuperObject;
  Index, AddIndex: Integer;
  ItemName, ConfigID, AimConfigID: String;
  StoreStr: PChar;
begin
  AimConfigID := '';
  Index := ListBox.ItemIndex;
  if Index >= 0 then
    AimConfigID := StrPas (Pointer (ListBox.Items.Objects[Index]));

  for Index := 0 to ListBox.Count - 1 do
  begin
    StoreStr := Pointer (ListBox.Items.Objects[Index]);
    FreeMem (StoreStr);
  end;
  ListBox.Clear;
                     
  List := WorkSO.A['AppConfigList.Items'];
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    ItemName := Item.S['Name'];
    ConfigID := Item.S['ID'];
    StoreStr := AllocMem (Length(ConfigID)+1);
    StrCopy (StoreStr, PChar(ConfigID));
    AddIndex := ListBox.Items.AddObject(ItemName, Pointer(StoreStr));
    ListBox.Checked[AddIndex] := UpperCase(Item.S['Enable']) = 'TRUE';
  end;

  if AimConfigID <> '' then
    for Index := 0 to ListBox.Count - 1 do
    begin
      StoreStr := Pointer (ListBox.Items.Objects[Index]);
      if AimConfigID = StrPas (StoreStr) then
      begin
        ListBox.ItemIndex := Index;
        Break;
      end;
    end;
end;


Procedure EmuProc (Sender: Pointer; szFileName: PChar); stdcall;
var
  PlugList: TStringList absolute Sender;
  FileName, FileExt: String;
begin
  FileName := StrPas (szFileName);
  FileExt := UpperCase (ExtractFileExt (FileName));
  if FileExt = '.DLL' then
  begin
    PlugList.Add(FileName);
  end;
end;

function TTDataCfgModule.CheckIsSafe (KeyName: String): BOOL;
begin
  Result := False;
end;

function TTDataCfgModule.CheckIsCredible (KeyName: String): BOOL;
begin
  Result := False;
end;

function TTDataCfgModule.GetPluginMD5 (KeyName: String): String;
begin
  KeyName := FPlugPath + KeyName;
  Result := FileMD5Str (KeyName);
end;


function TTDataCfgModule.CheckIsAutoSet (KeyName: String): BOOL;
var
  IsAutoSet: function: BOOL; Stdcall;
  PlugDLL: TDLLLoaderEx;
begin
  Result := False;
  PlugDLL := GetPluginDLLLoader(KeyName);
  if PlugDLL = nil then exit;
  IsAutoSet := PlugDLL.FindExport('IsAutoSet');
  if Addr(IsAutoSet) = nil then exit;
  Result := IsAutoSet;
end;

function TTDataCfgModule.CheckIsTargetApp (KeyName, AppPath: String): BOOL;
var
  IsTargetApp: function (AppPath: PChar): BOOL; Stdcall;
  PlugDLL: TDLLLoaderEx;
begin
  Result := False;
  PlugDLL := GetPluginDLLLoader(KeyName);
  if PlugDLL = nil then exit;
  IsTargetApp := PlugDLL.FindExport('IsTargetApp');
  if Addr(IsTargetApp) = nil then exit;
  Result := IsTargetApp (PChar(AppPath));
end;

function TTDataCfgModule.CallPluginFuncForText (KeyName: String; FuncName: String): String;
var
  PlugDLL: TDLLLoaderEx;
  FuncEntry: function : PChar; Stdcall;
begin
  Result := '';
  PlugDLL := GetPluginDLLLoader(KeyName);
  if PlugDLL = nil then exit;

  FuncEntry := PlugDLL.FindExport(FuncName);
  if not assigned (FuncEntry) then exit;

  result := StrPas (FuncEntry());
end;

function TTDataCfgModule.GetPluginHelp (KeyName: String): String;
begin
  Result := CallPluginFuncForText (KeyName, 'Help');
end;

function TTDataCfgModule.GetPluginType (KeyName: String): String;
begin
  Result := CallPluginFuncForText (KeyName, 'Type');
end;

function TTDataCfgModule.MakeANewPluginItem (KeyName: String): ISuperObject;
var
  PlugDLL: TDLLLoaderEx;
begin
  PlugDLL := LoadPluginDLL (KeyName);
  if PlugDLL = nil then
  begin
    Log('插件列表', '加载插件失败：' + KeyName);
    Result := nil;
    Exit;
  end;

  Result := SO;
  Result.S['Name'] := KeyName;
  Result.S['Enable'] := 'true';
  Result.B['IsModifyDetect'] := True;
  Result.S['Type'] := GetPluginType (KeyName);
  Result.B['IsSafe'] := CheckIsSafe (KeyName);
  Result.B['IsCredible'] := CheckIsCredible (KeyName);
  Result.B['IsAutoSet'] := CheckIsAutoSet (KeyName); 
  Result.B['NeedUserConfirm'] := True;
  Result.S['VoteResult'] := VOTE_NONE;

  PluginList_RunRecord (KeyName);
  PluginList_SetMD5 (KeyName, GetPluginMD5 (KeyName));
end;

Procedure TTDataCfgModule.ClearUeslessPluginItem;
var
  List: TSuperArray;
  Item, ToDelete: ISuperObject;
  Index: Integer;
  FileName: String;
begin
  List := WorkSO.A['PluginList.Items'];

  for Index := List.Length - 1 downto 0 do
  begin
    Item := List.O[Index]; 
    FileName := FPlugPath + Item.S['Name'];
    if not FileExists (FileName) then
    begin
      ToDelete := List.Delete(Index);
      ToDelete.Clear(True);
      ToDelete := NIL;
    end;
  end;
end;

function TTDataCfgModule.IsInPluginList (KeyName: String): BOOL;
var
  List: TSuperArray;
  Item: ISuperObject;
  Index: Integer;
begin
  List := WorkSO.A['PluginList.Items'];

  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    if KeyName = Item.S['Name'] then
    begin  
      Result := True;
      Exit;
    end;
  end;

  Result := False;
end;

Procedure TTDataCfgModule.Log (sType, Msg: String);
begin
  Msg := TimeToStr(Now) + #9'[' + sType + '] ' + Msg;
  FChangeLoger.Add (Msg);
end;

function TTDataCfgModule.AddInPluginList (KeyName: String): BOOL;
var
  List: TSuperArray;
  Item: ISuperObject;
begin
  Item := MakeANewPluginItem (KeyName);
  if Item = nil then
  begin
    Result := False;
    Exit;
  end;

  List := WorkSO.A['PluginList.Items'];
  List.Add(Item);

  Item := NIL;
  Result := True;
  NeedSave := True;

  Log('插件列表', '从插件目录发现新插件：' + KeyName);
end;

Procedure TTDataCfgModule.LoadPluginFromDisk;
var
  PlugList: TStringList;
  KeyName: String;
begin
  PlugList := TStringList.Create;
  EnumerateFile (PlugList, FPlugPath, EmuProc, FPlugPath);

  for KeyName in PlugList do
    if FErrorPluginList.IndexOf (KeyName) = -1 then
    begin
      if FPluginDLLs.IndexOf(KeyName) = -1 then
        LoadPluginDLL(KeyName);

      if not IsInPluginList (KeyName) then
        if not AddInPluginList (KeyName) then
          FErrorPluginList.Add (KeyName);
    end;

  PlugList.Free;
end;

Procedure TTDataCfgModule.ReloadPluginList (var ListBox: TCheckListBox);
var
  List: TSuperArray;
  Item: ISuperObject;
  Index, AddIndex: Integer;
  KeyName, RealPath: String;
begin
  List := WorkSO.A['PluginList.Items'];

  ListBox.Clear;
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    KeyName := Item.S['Name'];
    RealPath := FPlugPath + KeyName;
    if FileExists (RealPath) then
    begin
      AddIndex := ListBox.Items.Add(KeyName);
      ListBox.Checked[AddIndex] := UpperCase(Item.S['Enable']) = 'TRUE';
    end;
  end;
end;


function TTDataCfgModule.GetPluginLastRunTime (KeyName: String; LastRunTime: TDateTime): BOOL;
var
  RunTimes: Integer;
  LastConfirmTime: TDateTime;
begin
  Result := PluginList_GetRunInfo (KeyName, RunTimes, LastRunTime, LastConfirmTime);
end;

function TTDataCfgModule.GetLastRunPlugin (Const Plugins: TStringList): String;
var
  LastRunTime: TDateTime;
  Name: String;
  DBPlugins: TStringList;
begin
  if Plugins.Count = 0 then
  begin
    Result := '';
    Exit;
  end;

  DBPlugins := TStringList.Create;
  Repeat
    if PluginList_GetLastRunPlugin (DBPlugins, LastRunTime) then
      if DBPlugins.Count > 0 then Break;
                                  
    DBPlugins.Free;
    Result := Plugins[0];
    Exit;
  until True;

  for Name in DBPlugins do
    if Plugins.IndexOf(Name) >= 0 then
    begin
      Result := Name;
      Break;
    end;

  if Result = '' then
    Result := Plugins[0];

  DBPlugins.Free;
end;



Procedure TTDataCfgModule.ReloadParamList (ConfigID: String; var ValueLst: TValueListEditor; ViewEnable: BOOL = False);
begin
  self.ViewConfig(ConfigID, ValueLst, ViewEnable);
end;           

function TTDataCfgModule.GetKeyNameBySrcDefine (MainKeyName, SrcDefine: String; var KeyName: String): BOOL;
var
  MainPluginPath, TmpName: String;
begin
  Result := False;
  MainPluginPath := ExtractFilePath (FPlugPath + MainKeyName);
  if MainKeyName = '' then exit;
  if SrcDefine = '' then exit;

  TmpName := MainPluginPath + SrcDefine;
  if FileExists (TmpName) then
  begin
    KeyName := StrPas(@TmpName[Length(FPlugPath)+1]);
    Result := True;
  end else
  begin
    TmpName := FPlugPath + SrcDefine;
    if FileExists (TmpName) then
    begin
      KeyName := SrcDefine;
      Result := True;
    end;
  end;
end;

function TTDataCfgModule.GetNeedPluginList_Dll (MainKeyName: String; var HaveSL, LackSL: TStringList): BOOL;
var
  FullKeyName, SrcName, AimKeyName: String;
  ParamSL, LibSL: TStringList;
begin
  Result := False;
  FullKeyName := FPlugPath + MainKeyName;
  if not FileExists (FullKeyName) then exit;

  ParamSL := GetParamValueList(MainKeyName);

  SrcName := ParamSL.Values['Daemon'];
  if GetKeyNameBySrcDefine (MainKeyName, SrcName, AimKeyName) then
    HaveSL.Add(AimKeyName)
  else
    LackSL.Add(SrcName);

  SrcName := ParamSL.Values['PlugBase'];
  if GetKeyNameBySrcDefine (MainKeyName, SrcName, AimKeyName) then
    HaveSL.Add(AimKeyName)
  else
    LackSL.Add(SrcName);

  SrcName := ParamSL.Values['PluginLib'];
  LibSL := GetSplitBlankList (SrcName, [',']);
  for SrcName in LibSL do
  begin
    if GetKeyNameBySrcDefine (MainKeyName, SrcName, AimKeyName) then
      HaveSL.Add(AimKeyName)
    else
      LackSL.Add(SrcName);
  end;

  LibSL.Free;
  ParamSL.Free;
  Result := True;
end;

function TTDataCfgModule.GetNeedPluginList_Cfg (ConfigID: String; var HaveSL, LackSL: TStringList): BOOL;
var
  IterID, TmpName, SrcName, AimKeyName, MainKeyName: String;
  PlugLst: TStringList;
  List, LibArray: TSuperArray;
  Item: ISuperObject;
  Index, Index2: Integer;
  DaemonDLL: String;
begin
  Result := False;
  ConfigID := Trim(ConfigID);
  if not (Length(ConfigID) = Length('{76B68A2D-9A87-4512-A550-88DCA52687ED}')) then Exit;

  List := WorkSO.A['AppConfigList.Items'];

  PlugLst := TStringList.Create;
  for Index := 0 to List.Length - 1 do
  begin                        
    Item := List.O[Index];
    IterID := Item.S['ID'];
    if IterID = ConfigID then
    begin
      MainKeyName := Item.S['PluginName'];
      TmpName := FPlugPath + MainKeyName;
      if FileExists (TmpName) then
        HaveSL.Add(MainKeyName)
      else
        LackSL.Add(MainKeyName);

      DaemonDLL := Item.S['Daemon'];
      if DaemonDLL <> '' then
        PlugLst.Add(DaemonDLL);

      PlugLst.Add(Item.S['PlugBase']);

      LibArray := Item.A['PluginLib'];
      if Assigned (LibArray) then
      for Index2 := 0 to LibArray.Length - 1 do
      begin
        SrcName := LibArray.S[Index2];
        PlugLst.Add(SrcName);
      end;

      for SrcName in PlugLst do
      begin
        if GetKeyNameBySrcDefine (MainKeyName, SrcName, AimKeyName) then
          HaveSL.Add(AimKeyName)
        else
          LackSL.Add(SrcName);
      end;

      Result := True;
      Break;
    end;
  end;
  PlugLst.Free;
end;


function TTDataCfgModule.GetNeedPluginList_Cfg (var HaveSL, LackSL: TStringList): BOOL;
var
  TmpName, SrcName, AimKeyName, MainKeyName: String;
  PlugLst: TStringList;
  List, LibArray: TSuperArray;
  Item: ISuperObject;
  Index, Index2: Integer;
begin
  List := WorkSO.A['AppConfigList.Items'];
  PlugLst := TStringList.Create;

  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];

    MainKeyName := Item.S['PluginName'];
    TmpName := FPlugPath + MainKeyName;
    if FileExists (TmpName) then
      HaveSL.Add(MainKeyName)
    else
      LackSL.Add(MainKeyName);

    PlugLst.Clear;
    PlugLst.Add(Item.S['Daemon']);
    PlugLst.Add(Item.S['PlugBase']);

    LibArray := Item.A['PluginLib'];
    for Index2 := 0 to LibArray.Length - 1 do
    begin
      SrcName := LibArray.S[Index2];
      PlugLst.Add(SrcName);
    end;

    for SrcName in PlugLst do
    begin
      if GetKeyNameBySrcDefine (MainKeyName, SrcName, AimKeyName) then
        HaveSL.Add(AimKeyName)
      else
        LackSL.Add(SrcName);
    end;
  end;

  PlugLst.Free;
  Result := (HaveSL.Count > 0) or (LackSL.Count > 0);
end;



function TTDataCfgModule.GetUsePluginList_Cfg (var UseSL: TStringList): BOOL;
var
  TmpName, SrcName, AimKeyName, MainKeyName: String;
  PlugLst: TStringList;
  List, LibArray: TSuperArray;
  Item: ISuperObject;
  Index, Index2: Integer;
  MainPath: String;
begin
  List := WorkSO.A['AppConfigList.Items'];
  PlugLst := TStringList.Create;
  UseSL.Clear;
  
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];

    MainKeyName := Item.S['PluginName'];
    UseSL.Add(MainKeyName);

    PlugLst.Clear;
    PlugLst.Add(Item.S['Daemon']);
    PlugLst.Add(Item.S['PlugBase']);

    LibArray := Item.A['PluginLib'];
    for Index2 := 0 to LibArray.Length - 1 do
    begin
      SrcName := LibArray.S[Index2];
      PlugLst.Add(SrcName);
    end;

    MainPath := ExtractFilePath (PlugPath + MainKeyName);
    for SrcName in PlugLst do
    begin
      if UseSL.IndexOf(SrcName) = -1 then
        UseSL.Add(SrcName);

      TmpName := MainPath + SrcName;
      AimKeyName := StrPas(@TmpName [Length(PlugPath)+1]);
      if UseSL.IndexOf(AimKeyName) = -1 then
        UseSL.Add(AimKeyName);
    end;
  end;

  PlugLst.Free;
  Result := UseSL.Count > 0;
end;

function TTDataCfgModule.GetUselessPluginList_Cfg (var UselessSL: TStringList): BOOL;
var
  UseSL: TStringList;
  DiskPlugin: String;
begin
  UselessSL.Clear;
  UseSL := TStringList.Create;
  if GetUsePluginList_Cfg (UseSL) then
    for DiskPlugin in FPluginDLLs do
      if UseSL.IndexOf (DiskPlugin) = -1 then
        if UselessSL.IndexOf (DiskPlugin) = -1 then
          UselessSL.Add(DiskPlugin);
  UseSL.Free;
  Result := UselessSL.Count > 0;
end;

function TTDataCfgModule.GetPluginParamList (KeyName: String): TStringList;
var
  EnumDLL: TDLLLoaderEx;
  Index: Integer;
  ParamList : function : PChar; Stdcall;
  ParamText: String;
begin
  Result := TStringList.Create;

  Index := FPluginDLLs.IndexOf(KeyName);
  if Index >= 0 then
  begin
    EnumDLL := FPluginDLLs.Objects[Index] as TDLLLoaderEx;
    ParamList := EnumDLL.FindExport('ParamList');
    if Assigned (ParamList) then
    begin
      ParamText := StrPas(ParamList);
      Result.Text := ParamText;
    end;
  end;
end;

function TTDataCfgModule.GetParamKeyNameList (KeyName: String): TStringList;
var
  RawParamList: TStringList;
  Index: Integer;
  ParamKey: String;
begin
  Result := TStringList.Create;
  RawParamList := GetPluginParamList (KeyName);

  for Index := 0 to RawParamList.Count - 1 do
  begin
    ParamKey := RawParamList.Names[Index];
    Result.Add(ParamKey);
  end;
  RawParamList.Free;
end;

function TTDataCfgModule.GetParamValueList (KeyName: String): TStringList;
var
  RawParamList: TStringList;
  Index: Integer;
  ParamKey, ParamValue, ConstStr, HitStr: String;
begin
  Result := TStringList.Create;
  RawParamList := GetPluginParamList (KeyName);

  for Index := 0 to RawParamList.Count - 1 do
  begin
    ParamKey := RawParamList.Names[Index];
    ParamValue := RawParamList.ValueFromIndex[Index];
    ExtractHitAndConst (ParamValue, ConstStr, HitStr);
    if ConstStr = '' then
      Result.Add (ParamKey + '=')
    else
      Result.Values[ParamKey] := ConstStr;
  end;
  RawParamList.Free;
end;


FUNCTION TTDataCfgModule.GetMainPluginList (AppPath: String = ''): TStringList;
var
  EnumDLL: TDLLLoaderEx;
  Index: Integer;
  KeyName: String;
  IsTarget: function (AppPath: PChar): BOOL; Stdcall;
  GetPlugType: function : PChar; Stdcall;
begin
  Result := TStringList.Create;

  for Index := 0 to FPluginDLLs.Count - 1 do
  begin
    KeyName := FPluginDLLs[Index];
    EnumDLL := FPluginDLLs.Objects[Index] as TDLLLoaderEx;
    GetPlugType := EnumDLL.FindExport('Type');
    IsTarget := EnumDLL.FindExport('IsTarget');

    repeat
      if not Assigned (GetPlugType) then break;
      if StrPas(GetPlugType) <> TYPE_PLUGIN then break;

      if AppPath = '' then
      begin
        Result.Add(KeyName);
        break;
      end;

      if not Assigned (IsTarget) then break;
      if not IsTarget (PChar(AppPath)) then break;

      Result.Add(KeyName);
    until True;
  end;
end;

function TTDataCfgModule.GetPluginFromConfigID (ConfigID: String; var AppExe, PluginName: String): BOOL;
var
  List: TSuperArray;
  Item: ISuperObject;
  Index: Integer;
  IterID: String;
begin
  Result := False;
  ConfigID := Trim(ConfigID);
  if not (Length(ConfigID) = Length('{76B68A2D-9A87-4512-A550-88DCA52687ED}')) then Exit;

  List := WorkSO.A['AppConfigList.Items'];

  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    IterID := Item.S['ID'];
    if IterID = ConfigID then
    begin
      AppExe := Item.S['AppCmdLine'];
      AppExe := GetAppExeFromCmdLine (AppExe);
      PluginName := Item.S['PluginName'];
      Result := True;
      Break;
    end;
  end;
end;

function TTDataCfgModule.GetLastRunApp(): String;
var
  List: TSuperArray;
  Item: ISuperObject;
  Index: Integer;
  ConfigID, IterID, AppExe: String;
  DBConfigIDs, CfgIDList: TStringList;
  LastRunTime: TDateTime;
begin
  Result := '';
  
  List := WorkSO.A['AppConfigList.Items'];
  CfgIDList := TStringList.Create;
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    IterID := Item.S['ID'];
    AppExe := Item.S['AppCmdLine'];
    AppExe := GetAppExeFromCmdLine (AppExe);
    CfgIDList.Values[IterID] := AppExe;
  end;

  DBConfigIDs := TStringList.Create;
  if not AppConfigList_GetLastRunConfig (DBConfigIDs, LastRunTime) then
  begin
    if CfgIDList.Count > 0 then
      Result := CfgIDList[0];
    CfgIDList.Free;
    DBConfigIDs.Free;
    exit;
  end;

  for ConfigID in DBConfigIDs do
  begin
    Index := CfgIDList.IndexOfName(ConfigID);
    if Index >= 0 then
    begin
      Result := CfgIDList.ValueFromIndex[Index];
      Break;
    end;
  end;

  CfgIDList.Free;
  DBConfigIDs.Free;
end;

function TTDataCfgModule.GetConfigAppList (): TStringList;
var
  List: TSuperArray;
  Item: ISuperObject;
  Index: Integer;
  ConfigID, IterID, AppExe: String;
  DBConfigIDs, CfgIDList: TStringList;
  LastRunTime: TDateTime;
begin
  Result := TStringList.Create;

  List := WorkSO.A['AppConfigList.Items'];
  CfgIDList := TStringList.Create;
  for Index := 0 to List.Length - 1 do
  begin
    Item := List.O[Index];
    IterID := Item.S['ID'];
    AppExe := Item.S['AppCmdLine'];
    AppExe := GetAppExeFromCmdLine (AppExe);
    CfgIDList.Values[IterID] := AppExe;
  end;

  DBConfigIDs := TStringList.Create;
  Repeat
    if AppConfigList_GetLastRunConfig (DBConfigIDs, LastRunTime) then
      if DBConfigIDs.Count > 0 then break;

    for Index := 0 to CfgIDList.Count - 1 do
    begin
      AppExe := CfgIDList.ValueFromIndex[Index];
      if Result.IndexOf(AppExe) = -1 then
        Result.Add(AppExe);
    end;

    CfgIDList.Free;
    DBConfigIDs.Free;
    exit;
  until true;

  for ConfigID in DBConfigIDs do
  begin
    Index := CfgIDList.IndexOfName(ConfigID);
    if Index >= 0 then
    begin
      AppExe := CfgIDList.ValueFromIndex[Index];
      if Result.IndexOf(AppExe) = -1 then
        Result.Add(AppExe);
    end;
  end;

  CfgIDList.Free;
  DBConfigIDs.Free;
end;

function TTDataCfgModule.IsLackPlugin (var LackSL: TStringList): BOOL;
var
  TmpName, SrcName, AimKeyName, MainKeyName: String;
  PlugLst: TStringList;
  List, LibArray: TSuperArray;
  Item: ISuperObject;
  Index, Index2: Integer;
  HasCheckSL: TStringList;
begin
  List := WorkSO.A['AppConfigList.Items'];

  PlugLst := TStringList.Create;
  HasCheckSL := TStringList.Create;
  for Index := 0 to List.Length - 1 do
  begin
      Item := List.O[Index];

      MainKeyName := Item.S['PluginName'];
      if HasCheckSL.IndexOf(MainKeyName) >= 0 then continue;
      HasCheckSL.Add(MainKeyName);  

      TmpName := FPlugPath + MainKeyName;
      if not FileExists (TmpName) then
        LackSL.Add(MainKeyName);

      PlugLst.Clear;
      PlugLst.Add(Item.S['Daemon']);
      PlugLst.Add(Item.S['PlugBase']);   
      LibArray := Item.A['PluginLib'];
      for Index2 := 0 to LibArray.Length - 1 do
      begin
        SrcName := LibArray.S[Index2];
        PlugLst.Add(SrcName);
      end;

      for SrcName in PlugLst do
        if Trim(SrcName) <> '' then
          if not GetKeyNameBySrcDefine (MainKeyName, SrcName, AimKeyName) then
            LackSL.Add(SrcName);
  end;
  HasCheckSL.Free;
  PlugLst.Free;

  Result := LackSL.Count > 0;
end;


Function TTDataCfgModule.IsLackPlugin (ConfigID: String; var LackSL: TStringList): BOOL;
var
  HaveSL: TStringList;
begin
  Result := False;
  HaveSL := TStringList.Create;
  if GetNeedPluginList_Cfg(ConfigID, HaveSL, LackSL) then
  begin
    Result := LackSL.Count > 0;
  end;
  HaveSL.Free;
end;

Function TTDataCfgModule.IsLackPlugin (ConfigID: String): BOOL;
var
  HaveSL, LackSL: TStringList;
begin
  Result := False;
  HaveSL := TStringList.Create;
  LackSL := TStringList.Create;
  if GetNeedPluginList_Cfg(ConfigID, HaveSL, LackSL) then
  begin
    Result := LackSL.Count > 0;
  end;
  HaveSL.Free;
  LackSL.Free;
end;

function SOArrayToString (List: TSuperArray): String;
var
  IterStr: String;
  Index: Integer;
begin
  Result := '';
  for Index := 0 to List.Length - 1 do
  begin
    IterStr := List.O[Index].AsString;
    Result := Result + ',' + IterStr;
  end;
  if Length (Result) > 0 then
    Delete (Result, 1, 1);
end;

function SOArrayToStringList (List: TSuperArray): TStringList;
var
  IterStr: String;
  Index: Integer;
begin
  Result := TStringList.Create;
  for Index := 0 to List.Length - 1 do
  begin
    IterStr := List.O[Index].AsString;
    Result.Add(IterStr);
  end;
end;

function StringToSOArray (InputStr: String; Separate: TSysCharSet = [',']): ISuperObject;
var
  ArraySL: TStringList;
  Index: Integer;
  SOSample: String;
  IterStr, ResultSO: String;
begin
  ResultSO := '[]';

  Repeat
    ArraySL := GetSplitBlankList (InputStr, Separate);
    if ArraySL.Count = 0 then 
    begin
      ArraySL.Free;
      Break;
    end;

    SOSample := '';
    for Index := 0 to ArraySL.Count - 1 do
    begin
      IterStr := Trim(ArraySL[Index]);
      if IterStr <> '' then
        SOSample := SOSample + ',"' + IterStr + '"';
    end;
    ArraySL.Free;

    SOSample := Trim (SOSample);
    if SOSample = '' then Break;

    Delete (SOSample, 1, 1);
    ResultSO := '[' + SOSample + ']';
  until True;

  Result := SO(ResultSO);
end;

Procedure TTDataCfgModule.SetNeedSave (Value: BOOL);
begin
  FNeedSave := Value;
end;                     

function TTDataCfgModule.GetIsViewConstField: BOOL;
begin
  Result := WorkSO.B['AppConfigList.IsViewConst'];
end;

Procedure TTDataCfgModule.SetIsViewConstField (Value: BOOL);
begin
  if GetIsViewConstField xor Value then
  begin
    WorkSO.B['AppConfigList.IsViewConst'] := Value;
    self.NeedSave := True;
  end;
end;

function TTDataCfgModule.GetIsAllwayOnTop: BOOL;
begin
  Result := WorkSO.B['AppConfigList.AllwayOnTop'];
end;

Procedure TTDataCfgModule.SetIsAllwayOnTop(Value: BOOL);
begin
  if GetIsAllwayOnTop xor Value then
  begin
    WorkSO.B['AppConfigList.AllwayOnTop'] := Value;
    self.NeedSave := True;
  end;
end;

function TTDataCfgModule.GetIsDropMyRights: DWORD;
begin
  Result := WorkSO.I['AppConfigList.DropMyRights'];
end;

Procedure TTDataCfgModule.SetIsDropMyRights (Value: DWORD);
begin
  if GetIsDropMyRights <> Value then
  begin
    WorkSO.I['AppConfigList.DropMyRights'] := Value;
    self.NeedSave := True;
  end;
end;


function TTDataCfgModule.GetIsViewPrivateField: BOOL;
begin
  Result := WorkSO.B['AppConfigList.IsViewPrivate'];
end;

Procedure TTDataCfgModule.SetIsViewPrivateField (Value: BOOL);
begin
  if GetIsViewPrivateField xor Value then
  begin
    WorkSO.B['AppConfigList.IsViewPrivate'] := Value;
    self.NeedSave := True;
  end;
end;

function TTDataCfgModule.IsConstField (ParamKey: String): BOOL;
begin
  Result := FConstFields.IndexOf(ParamKey) >= 0;
end;

function TTDataCfgModule.IsSystemField (ParamKey: String): BOOL;
begin
  Result := FSystemFields.IndexOf(ParamKey) >= 0;
end;

Function TTDataCfgModule.DeleteConfig (ConfigID: String): BOOL;
var
  List: TSuperArray;
  IterItem: ISuperObject;
  Index, BeFound: Integer;
  IterID: String;
begin
  Result := False;
  List := WorkSO.A['AppConfigList.Items'];

  BeFound := -1;
  for Index := 0 to List.Length - 1 do
  begin
    IterItem := List.O[Index];
    IterID := IterItem.S['ID'];
    if ConfigID = IterID then
    begin
      BeFound := Index;
      Break;
    end;
  end;

  if BeFound = -1 then exit;
  IterItem := List.Delete(BeFound);
  IterItem := NIL;
  Result := True;
  NeedSave := True;
end;

Function TTDataCfgModule.EnableConfig (ConfigID: String; Enable: BOOL = True): BOOL;
var
  Item: ISuperObject;
begin
  Result := False;
  if FindConfig (ConfigID, Item) then
  begin
    if Enable then
      Item.S['Enable'] := 'true'
    else
      Item.S['Enable'] := 'false';
    Result := True;
    NeedSave := True;
  end;
end;

Procedure TTDataCfgModule.UpdateAppCmdLine (KeyName: String; OldCmdLine, NewCmdLine: String);
var
  List: TSuperArray;
  IterItem: ISuperObject;
  Index: Integer;
  PluginName, AppCmdLine: String;
begin
  List := WorkSO.A['AppConfigList.Items'];

  for Index := 0 to List.Length - 1 do
  begin
    IterItem := List.O[Index];
    PluginName := IterItem.S['PluginName'];
    AppCmdLine := IterItem.S['AppCmdLine'];
    if (PluginName = KeyName) or (KeyName = '') then
      if AppCmdLine = OldCmdLine then
        IterItem.S['AppCmdLine'] := NewCmdLine;
  end;
end;

function TTDataCfgModule.GetAppCmdLine (ConfigID: String; Out AppCmdLine: String): BOOL;
var
  Item: ISuperObject;
begin
  Result := False;
  if FindConfig (ConfigID, Item) then
  begin
    AppCmdLine := Item.S['AppCmdLine'];
    Result := True;
  end;
end;

function TTDataCfgModule.GetAppCmdLine (ConfigID: String): String;
var
  Item: ISuperObject;
begin
  Result := '';
  if FindConfig (ConfigID, Item) then
    Result := Item.S['AppCmdLine'];
end;

function TTDataCfgModule.GetPlugInName (ConfigID: String; Out PluginName: String): BOOL;
var
  Item: ISuperObject;
begin
  Result := False;
  if FindConfig (ConfigID, Item) then
  begin
    PluginName := Item.S['PluginName'];
    Result := True;
  end;
end;

function  TTDataCfgModule.FindConfig (ConfigID: String; out Item: ISuperObject): BOOL;
var
  List: TSuperArray;
  IterItem: ISuperObject;
  Index: Integer;
  IterID: String;
begin
  Item := nil;
  Result := False;
  List := WorkSO.A['AppConfigList.Items'];

  for Index := 0 to List.Length - 1 do
  begin
    IterItem := List.O[Index];
    IterID := IterItem.S['ID'];
    if ConfigID = IterID then
    begin
      Item := IterItem;
      Result := True;
      Break;
    end;
  end;
end;

function  TTDataCfgModule.FindConfig (ConfigID: String; out Item: ISuperObject; out ItemIndex: Integer): BOOL;
var
  List: TSuperArray;
  IterItem: ISuperObject;
  Index: Integer;
  IterID: String;
begin
  Item := nil;
  Result := False;
  List := WorkSO.A['AppConfigList.Items'];

  for Index := 0 to List.Length - 1 do
  begin
    IterItem := List.O[Index];
    IterID := IterItem.S['ID'];
    if ConfigID = IterID then
    begin
      Item := IterItem;
      ItemIndex := Index;
      Result := True;
      Break;
    end;
  end;
end;



Function TTDataCfgModule.GetBlankPrivateField (ConfigID: String): TStringList;
var
  Item: ISuperObject;
  LibArray: TSuperArray;
  Index: Integer;
  SrcDefine, ItemVal: String;
begin
  Result := TStringList.Create;

  if FindConfig (ConfigID, Item) then
  begin
    LibArray := Item.A['PrivacyField'];

    for Index := 0 to LibArray.Length - 1 do
    begin
      SrcDefine := LibArray.S[Index];
      ItemVal := Item.S[SrcDefine];
      if Trim(ItemVal) = '' then
        Result.Add(SrcDefine);
    end;
  end;
end;


function TTDataCfgModule.MakeRealInputSL (UserInput, DefaultSL: TStrings): TStringList;
var
  Key, Value: String;
  Index: Integer;
begin
  Result := TstringList.Create;
  Result.AddStrings(DefaultSL);

  for Index := 0 to UserInput.Count - 1 do
  begin
    Key := UserInput.Names[Index];
    Value := UserInput.ValueFromIndex[index];

    if Result.IndexOfName(Key) = -1 then
      Result.Add(key + '=' + Value)
    else
      Result.Values[key] := Value;
  end;
end; 

function TTDataCfgModule.CloneConfig (ConfigID: String; NewName: String; Out NewConfigID: String): BOOL;
var
  List: TSuperArray;
  Item, NewItem: ISuperObject;
  PluginName: String;
  ItemIndex: Integer;
begin
  result := False;
  if FindConfig (ConfigID, Item, ItemIndex) then
  begin
    NewItem := Item.Clone;

    NewConfigID := CreateClassID;
    PluginName := NewItem.S['PluginName'];

    NewItem.S['Name'] := NewName;
    NewItem.S['ID'] := NewConfigID;

    List := WorkSO.A['AppConfigList.Items'];

    List.Insert(ItemIndex + 1, NewItem);
    AppConfigList_ModifyRecord (NewConfigID, NewName, PluginName);

    Result := True;
    NeedSave := True;
  end;
end;

function TTDataCfgModule.AddConfig (PluginName: String; ValueLst: TValueListEditor): BOOL;
var
  List: TSuperArray;
  IsValidName: BOOL;
  Item, ArrayItem: ISuperObject;
  Index: Integer;
  ConfigID, IterName, IterVal, Name: String;
  UserInput: TStrings;
  DefaultSL, InputSL: TStringList;
begin
  Result := False;
  IsValidName := TYPE_PLUGIN = GetPluginType(PluginName);
  Name := Trim(ValueLst.Strings.Values['Name']);
  if Name = '' then Exit;

  if IsValidName then
  begin
    List := WorkSO.A['AppConfigList.Items'];
    ConfigID := CreateClassID;
        
    Item := SO;
    Item.S['ID'] := ConfigID;
    Item.S['Enable'] := 'true';
    Item.S['AppKeyInfo'] := ConfigID + '.json';
    Item.S['AppLogFile'] := ConfigID + '.log';
    Item.S['PluginName'] := PluginName;

    UserInput := ValueLst.Strings;
    DefaultSL := GetParamValueList(PluginName);
    InputSL := MakeRealInputSL (UserInput, DefaultSL);

    for Index := 0 to InputSL.Count - 1 do
    begin
      IterName := InputSL.Names[Index];
      IterVal := InputSL.ValueFromIndex[Index];

      if (IterName = 'PluginLib') or (IterName = 'PrivacyField') then
      begin
        ArrayItem := StringToSOArray (IterVal);
        Item.O[IterName] := ArrayItem;
      end else
      begin
        Item.S[IterName] := IterVal;
      end;
    end;

    List.Add(Item);
    AppConfigList_ModifyRecord (ConfigID, Name, PluginName);

    InputSL.Free;
    DefaultSL.Free;
    Result := True;
    NeedSave := True;
  end;
end;

Procedure SLMoveToFirst (SL: TStrings; Name: String);
var
  Index: Integer;
begin
  Index := SL.IndexOfName(Name);
  if Index > 0 then
    SL.Move(Index, 0);
end;

Procedure SLMoveToLast (SL: TStrings; Name: String);
var
  Index, MaxIndex: Integer;
begin
  Index := SL.IndexOfName(Name);
  if Index = -1 then exit;

  MaxIndex := SL.Count - 1;
  if Index < MaxIndex then
    SL.Move(Index, MaxIndex);
end;

Function TTDataCfgModule.ViewConfig (ConfigID: String; ValueLst: TValueListEditor; ViewEnable: BOOL = False): BOOL;
var
  Item: ISuperObject;
  ItemProp: TSuperAvlEntry;
  IterName, IterVal, PluginName: String;
  ViewConst: BOOL;
  VarParamSL, PrivateSL: TStringList;
  StorePtr: PChar;
begin
  PrivateSL := NIL;
  Result := False;
  ViewConst := GetIsViewConstField;

  ValueLst.Strings.Clear;
  if ValueLst.Tag > 0 then
  begin
    StorePtr := Pointer(ValueLst.Tag);
    FreeMem (StorePtr);
  end;

  StorePtr := AllocMem (Length(ConfigID) + 1);
  StrCopy (StorePtr, PChar(ConfigID));
  ValueLst.Tag := Integer(StorePtr);

  if FindConfig (ConfigID, Item) then
  begin
    for ItemProp in Item.AsObject do
    begin
      IterName := ItemProp.Name;

      if IsSystemField (IterName) then
      begin
        if ViewEnable then
          if IterName = 'Enable' then
          begin
            IterVal := ItemProp.Value.AsString;
            ValueLst.Values[IterName] := IterVal;
          end;
      end else
      begin
         if IsConstField (IterName) then
         begin
           if ViewConst then
           begin
             if (IterName = 'PluginLib') or (IterName = 'PrivacyField')  then
               IterVal := SOArrayToString (ItemProp.Value.AsArray)
             else
               IterVal := ItemProp.Value.AsString;
             ValueLst.Values[IterName] := IterVal;
           end; 
         end else
         begin
           IterVal := ItemProp.Value.AsString;
           ValueLst.Values[IterName] := IterVal;
         end;

         if IterName = 'PrivacyField' then
           PrivateSL := SOArrayToStringList (ItemProp.Value.AsArray);
      end;
    end;

    if ViewConst then
      for IterName in FConstFields do
        SLMoveToLast(ValueLst.Strings, IterName);

    PluginName := Item.S['PluginName'];  
    VarParamSL := GetParamKeyNameList (PluginName);

    for IterName in VarParamSL do
      SLMoveToLast(ValueLst.Strings, IterName);
    VarParamSL.Free;

    SLMoveToFirst(ValueLst.Strings, 'AppRight');
    SLMoveToFirst(ValueLst.Strings, 'AppCmdLine');
    SLMoveToFirst(ValueLst.Strings, 'Name');

    if ViewEnable then
      SLMoveToFirst(ValueLst.Strings, 'Enable');

    if Assigned (PrivateSL) then
    begin
      if PrivateSL.Count > 0 then
        if not ViewPrivateField then
           for IterName in PrivateSL do
             ValueLst.Values[IterName] := '********';
      PrivateSL.Free;
    end;

    Result := True;
  end;
end;

function IsAllStartString (Input: String): BOOL;
var
  Index: Integer;
begin
  Result := False;
  if Length(Input) > 0 then
  begin       
    for Index := 1 to length(Input) do
      if Input[Index] <> '*' then Exit;
    Result := True;
  end;
end;

function TTDataCfgModule.ModifyConfig (ConfigID: String; ValueLst: TValueListEditor): BOOL;
var
  IsValidID: BOOL;
  Item, ArrayItem: ISuperObject;
  Index: Integer;
  IterName, IterVal, PluginName, Name: String;
  InputSL: TStrings;
  PrivateSL: TStringList;
begin
  Result := False;
  ConfigID := Trim(ConfigID);
  IsValidID := Length(ConfigID) = Length('{1A489DC3-D005-4C50-BA8C-3DEFA94CCC09}');

  PrivateSL := TStringList.Create;

  if IsValidID then
  begin           
    if FindConfig (ConfigID, Item) then
    begin          
      PrivateSL := SOArrayToStringList (Item.A['PrivacyField']);

      InputSL := ValueLst.Strings;
      for Index := 0 to InputSL.Count - 1 do
      begin
        IterName := InputSL.Names[Index];
        IterVal := InputSL.ValueFromIndex[Index];
        if (IterName = 'PluginLib') or (IterName = 'PrivacyField') then
        begin
          ArrayItem := StringToSOArray (IterVal);
          Item.O[IterName] := ArrayItem;
        end else
        begin
          Repeat
            if PrivateSL.IndexOf(IterName) <> -1 then
              if IsAllStartString (IterVal) then Break;
            Item.S[IterName] := IterVal;
          until True;
        end;
      end;
      Name := Item.S['Name'];
      PluginName := Item.S['PluginName'];

      IterName := Item.S['Enable'];
      if UpperCase(IterName) <> 'TRUE' then
        Item.S['Enable'] := 'false'; 
      
      AppConfigList_ModifyRecord (ConfigID, Name, PluginName);
      NeedSave := True;
      Result := True;
    end;
  end;

  PrivateSL.Free;
end;


end.
