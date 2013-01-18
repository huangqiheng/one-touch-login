unit HandlerUnit;

interface

uses
  Windows, forms, SysUtils, Classes, ActnList, StdActns, ExtActns, IniFiles,
  Controls, ValEdit, ComCtrls, CategoryButtons, Menus, ImgList, Graphics,
  Base64Unit;

type
  TDataModuleBase = class(TDataModule)
    ActionList1: TActionList;
    Bar_StayOnTop: TControlAction;
    Bar_ViewConst: TControlAction;
    Bar_ViewPrivacy: TControlAction;
    Bar_CheckPlugins: TControlAction;
    Bar_UninstallDriver: TControlAction;
    Bar_Helper: TControlAction;
    ImageList1: TImageList;
    DynImageList: TImageList;
    procedure Bar_UninstallDriverExecute(Sender: TObject);
    procedure Bar_ViewPrivacyExecute(Sender: TObject);
    procedure Bar_ViewConstExecute(Sender: TObject);
    procedure Bar_StayOnTopExecute(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
  Protected
    FIniFileName: String;
    FCacheIcoIndex: TStringList;
    function NewIniObject(): TCustomIniFile;
    function NewIniObjectMem(): TCustomIniFile;
    function GetImageIndex (AppName: String; IsActive: BOOL = True): Integer;
  public
    Procedure ReadMainPos (Main: TForm);
    Procedure SaveMainPos (Main: TForm);
    procedure SaveCollapsed (CategoryButtons: TCategoryButtons);
    procedure ReadCollapsed (CategoryButtons: TCategoryButtons);
    Procedure SetViewBool (const SystemField, PrivacyField, StayOnTop: BOOL);
    Procedure GetViewBool (Out SystemField, PrivacyField, StayOnTop: BOOL);
    function  GetSystemField (PlugFile: String; IncludeValue: BOOL = False): TStringList;
    function  GetInputField (PlugFile: String): TStringList;
    function  IsSystemField (PlugFile, FieldName: String): BOOL;
    Procedure LoadConfigLst (ConfigList: TCategoryButtons);
    function  InitConfigItem (PlugFile: String; LoadTo: TStrings): BOOL;
    function  SaveConfigItem (PlugFile: String; ToSave: TStrings): BOOL; overload;
    function  SaveConfigItem (IndexA, IndexB: Integer; ToSave: TStrings): BOOL; overload;
    function  CloneConfigItem (IndexA, IndexB: Integer): BOOL;
    function  MoveConfigItem (IndexA, IndexB, Offset: Integer): BOOL;
    function  ReadConfigItem (IndexA, IndexB: Integer; ReadTo: TStrings): BOOL; overload;
    function  ReadConfigItem (IndexA, IndexB: Integer): TStringList; overload;
    function  DeleteConfigItem (IndexA, IndexB: Integer): BOOL;
    function  ClearConfigItem (IndexA: Integer): BOOL;
    function  GetUsesApps(): TStringList;
    function  GetUsesPlugins(): TStringList;
  end;



var
  DataModule: TDataModuleBase;

implementation

{$R *.dfm}

uses IcoFromPE, PlugKernelLib, SpecialFolderUnit;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

const
  Def_Collapsed = 'Collapsed';                        
  Def_MainStyle = 'ViewStyle';
  Def_Categorys = 'Categorys';
  Def_TitleCaptions = 'TitleCaptions';
  Def_CategoryHead = 'Category';


//MakeFileNameByExt('.ini');
function MakeFileNameByExt (Ext: String): String;
var
  temp: string;
begin
  Result := GetModuleName(0);
  temp := ExtractFileExt (Result);
  setlength (Result, Length(result)-Length(temp));
  result := result + Ext;
end;

procedure TDataModuleBase.Bar_StayOnTopExecute(Sender: TObject);
var
  Aim: TToolButton;
  SystemField, PrivacyField, StayOnTop: BOOL;
begin
  Aim := TControlAction(Sender).ActionComponent as TToolButton;
  self.GetViewBool(SystemField, PrivacyField, StayOnTop);
  self.SetViewBool(SystemField, PrivacyField, Aim.Down);

  With Aim.Owner as TForm do
    if Aim.Down then
      FormStyle := fsStayOnTop
    else
      FormStyle := fsNormal;
end;

procedure TDataModuleBase.Bar_UninstallDriverExecute(Sender: TObject);
begin
  if EnsureDriver(False) then
  begin
    Application.MessageBox('已经成功卸载注射驱动程序', '提示');
  end;
end;

procedure TDataModuleBase.Bar_ViewConstExecute(Sender: TObject);
var
  Aim: TToolButton;
  SystemField, PrivacyField, StayOnTop: BOOL;
begin
  Aim := TControlAction(Sender).ActionComponent as TToolButton;
  self.GetViewBool(SystemField, PrivacyField, StayOnTop);
  self.SetViewBool(Aim.Down, PrivacyField, StayOnTop);
end;

procedure TDataModuleBase.Bar_ViewPrivacyExecute(Sender: TObject);
var
  Aim: TToolButton;
  SystemField, PrivacyField, StayOnTop: BOOL;
begin
  Aim := TControlAction(Sender).ActionComponent as TToolButton;
  self.GetViewBool(SystemField, PrivacyField, StayOnTop);
  self.SetViewBool(SystemField, Aim.Down, StayOnTop);
end;

procedure TDataModuleBase.DataModuleCreate(Sender: TObject);
begin
  FIniFileName := MakeFileNameByExt('.ini');
  if Not FileExists (FIniFileName) then
    FileClose (FileCreate(FIniFileName));
end;

function TDataModuleBase.NewIniObject(): TCustomIniFile;
begin
  Result := TIniFile.Create(FIniFileName);
end;

function TDataModuleBase.NewIniObjectMem(): TCustomIniFile;
begin
  Result := TMemIniFile.Create(FIniFileName);
end;


procedure TDataModuleBase.ReadMainPos (Main: TForm);
var
  Def_Left, Def_Top: Integer;
begin
  Def_Left := Screen.WorkAreaWidth div 4 * 3;
  Def_Top := Screen.WorkAreaWidth div 12;

  With NewIniObjectMem do
  Try
    Main.Left := ReadInteger(Def_MainStyle, 'Left', Def_Left);
    Main.Top := ReadInteger(Def_MainStyle, 'Top', Def_Top);
    Main.Width := ReadInteger(Def_MainStyle, 'Width', Main.Width);
    Main.Height := ReadInteger(Def_MainStyle, 'Height', Main.Height);
  finally
    Free;
  end;

  if Main.Left > (Screen.WorkAreaWidth - Main.Width) then
    Main.Left := Screen.WorkAreaWidth - Main.Width;
  if Main.Top > (Screen.WorkAreaHeight - Main.Height) then
    Main.Top := Screen.WorkAreaHeight - Main.Height;
  if Main.Top < 0 then Main.Top := 0;
  if Main.Left < 0 then Main.Left := 0;
end;

procedure TDataModuleBase.SaveMainPos (Main: TForm);
begin
  With NewIniObject do
  Try
    WriteInteger (Def_MainStyle, 'Left', Main.Left);
    WriteInteger (Def_MainStyle, 'Top', Main.Top);
    WriteInteger (Def_MainStyle, 'Width', Main.Width);
    WriteInteger (Def_MainStyle, 'Height', Main.Height);
  finally
    Free;
  end;
end;


function GetCollapseds (ConfigList: TCategoryButtons): TStringList;
var
  Index: integer;
  BtnCategory: TButtonCategory;
begin
  Result := TStringList.Create;
  for Index := 0 to ConfigList.Categories.Count - 1 do
  begin
    BtnCategory := ConfigList.Categories.Items[Index];
    if BtnCategory.Collapsed then
      Result.Add(BtnCategory.Caption);
  end;
end;


procedure TDataModuleBase.SaveCollapsed (CategoryButtons: TCategoryButtons);
var
  SaveLst: TStringList;
begin
  SaveLst := GetCollapseds (CategoryButtons);

  With NewIniObject() do
  Try
    WriteString (Def_MainStyle, Def_Collapsed, EncodeBase64(SaveLst.Text));
  finally
    Free;
  end;

  SaveLst.Free;
end;

procedure TDataModuleBase.ReadCollapsed (CategoryButtons: TCategoryButtons);
var
  ReadLst: TStringList;     
  Index: Integer;
begin
  ReadLst := TStringList.Create;

  With NewIniObjectMem() do
  Try
    ReadLst.Text :=DecodeBase64(ReadString (Def_MainStyle, Def_Collapsed, ''));
  finally
    Free;
  end;   

  With CategoryButtons.Categories do
    for Index := 0 to Count - 1 do
      if ReadLst.IndexOf(Items[Index].Caption) >= 0 then
        Items[Index].Collapsed := True;

  ReadLst.Free;
end;

procedure TDataModuleBase.SetViewBool (const SystemField, PrivacyField, StayOnTop: BOOL);
begin
  With NewIniObject do
  Try
    WriteBool (Def_MainStyle, 'SystemField', SystemField);
    WriteBool (Def_MainStyle, 'PrivacyField', PrivacyField);
    WriteBool (Def_MainStyle, 'StayOnTop', StayOnTop);
  finally
    Free;
  end;
end;

procedure TDataModuleBase.GetViewBool (Out SystemField, PrivacyField, StayOnTop: BOOL);
begin
  With NewIniObjectMem do
  Try
    SystemField := ReadBool (Def_MainStyle, 'SystemField', False);
    PrivacyField := ReadBool (Def_MainStyle, 'PrivacyField', False);
    StayOnTop := ReadBool (Def_MainStyle, 'StayOnTop', False);
  finally
    Free;
  end;
end;

function TDataModuleBase.GetSystemField (PlugFile: String; IncludeValue: BOOL = False): TStringList;
var
  IniMem: TMemIniFile;
  PluginIni: String;
begin
  Result := TStringList.Create;
  PluginIni := ChangeFileExt (PlugFile, '.ini');
  if not FileExists (PluginIni) then exit;

  IniMem := TMemIniFile.Create(PluginIni);
  if IncludeValue then
    IniMem.ReadSectionValues(INI_SECTION_SYSTEM, Result)
  else
    IniMem.ReadSection(INI_SECTION_SYSTEM, Result);
  IniMem.Free;
end;

function TDataModuleBase.GetInputField (PlugFile: String): TStringList;
var
  IniMem: TMemIniFile;
  PluginIni: String;
begin
  Result := TStringList.Create;
  PluginIni := ChangeFileExt (PlugFile, '.ini');
  if not FileExists (PluginIni) then exit;

  IniMem := TMemIniFile.Create(PluginIni);
  IniMem.ReadSection(INI_SECTION_INPUT, Result);
  IniMem.Free;
end;


function TDataModuleBase.IsSystemField (PlugFile, FieldName: String): BOOL;
var
  SysField: TStringList;
begin
  Result := False;
  SysField := GetSystemField (PlugFile);
  if SysField.Count = 0 then
  begin
    SysField.Free;
    Exit;
  end;
  
  Result := SysField.IndexOf(FieldName) >= 0;
  SysField.Free;
end;


function TDataModuleBase.InitConfigItem (PlugFile: String; LoadTo: TStrings): BOOL;
var
  IniMem: TMemIniFile;
  PluginIni, KeyName: String;
  SystemField, PrivacyField, StayOnTop: BOOL;
  ReadSL: TStringList;
begin
  Result := False;
  PluginIni := ChangeFileExt (PlugFile, '.ini');
  if not FileExists (PluginIni) then exit;

  GetViewBool (SystemField, PrivacyField, StayOnTop);
  ReadSL := TStringList.Create;

  IniMem := TMemIniFile.Create(PluginIni);
  
  IniMem.ReadSection(INI_SECTION_INPUT, ReadSL);
  for KeyName in ReadSL do
    LoadTo.Add(KeyName+'=');

  if SystemField then
  begin
    IniMem.ReadSectionValues(INI_SECTION_SYSTEM, ReadSL);
    LoadTo.AddStrings(ReadSL);
  end;
  IniMem.Free;

  ReadSL.Free;
  Result := LoadTo.Count > 0;
end;


function GetSLValueFromList (Src: TStringList; Key: String): TStringList;
begin
  Result := TStringList.Create;
  Result.Text := DecodeBase64(Src.Values[Key]);
end;


function GetCaptionFormPlugFile (PlugFile: String): String;
var
  IniMem: TMemIniFile;
  PluginIni: String;
begin
  Result := '';
  PluginIni := ChangeFileExt (PlugFile, '.ini');
  if not FileExists (PluginIni) then exit;

  IniMem := TMemIniFile.Create(PluginIni);
  Result := IniMem.ReadString('main', 'Caption', '');
  IniMem.Free;
end;

function IsAllStartChar (Field: String): BOOL;
var
  IterChar: Char;
begin
  Result := True;
  for IterChar in Field do
    if IterChar <> '*' then
    begin
      Result := False;
      Exit;
    end;       
end;

function TDataModuleBase.SaveConfigItem (IndexA, IndexB: Integer; ToSave: TStrings): BOOL;
var
  CategoryID, ReadSrc, WriteStr, NameStr, PrivateStr: String;
  PlugSL, BeRead, FieldNames: TStringList;
  Index: Integer;
begin
  Result := False;
  if IndexA = -1 then exit;
  if IndexB = -1 then exit;

  BeRead := self.ReadConfigItem(IndexA, IndexB);
  if BeRead.Count > 0 then
  begin
    ReadSrc := BeRead.Values[INI_KEY_PRIVACYFIELDS];
    FieldNames := GetSplitBlankList (ReadSrc, [',']);

    for Index := 0 to BeRead.Count - 1 do
    begin
      NameStr := BeRead.Names[Index];
      ReadSrc := BeRead.ValueFromIndex[Index];

      //如果ToSave里有缺，则追加上
      if ToSave.IndexOfName(NameStr) = -1 then
      begin
        ToSave.Values[NameStr] := ReadSrc;
      end;

      //如果这个是保密字段
      if FieldNames.IndexOf(NameStr) >= 0 then
      begin
        PrivateStr := ToSave.Values[NameStr];
        if IsAllStartChar (PrivateStr) then
           ToSave.Values[NameStr] := ReadSrc;
      end;
    end;
    FieldNames.Free;
  end else
  begin
    BeRead.Free;
    Exit;
  end;
  BeRead.Free;

  With NewIniObject do
  Try
    CategoryID := Def_CategoryHead + IntToStr(IndexA);
    ReadSrc := ReadString(Def_Categorys, CategoryID, '');
    if ReadSrc <> '' then
    begin
      ReadSrc := DecodeBase64 (ReadSrc);
      PlugSL := TStringList.Create;
      PlugSL.Text := ReadSrc;
      if PlugSL.Count > IndexB then
      begin
        NameStr := ToSave.Values[INI_KEY_NAME];
        WriteStr := EncodeBase64(ToSave.Text);
        PlugSL[IndexB] := NameStr+'='+WriteStr;

        WriteStr := EncodeBase64 (PlugSL.Text);
        WriteString(Def_Categorys, CategoryID, WriteStr);  
        Result := True;
      end;
      PlugSL.Free;
    end;
  finally
    Free;
  end;
end;

function TDataModuleBase.SaveConfigItem (PlugFile: String; ToSave: TStrings): BOOL;
var
  ReadStr, SectionRead, WriteVal: String;
  SaveName: String;
  CategorysSL, CaptionSL, ItemSL, SysField: TStringList;
  Index, IndexA, IndexB: Integer;
begin
  SaveName := ToSave.Values[INI_KEY_NAME];
  CategorysSL := TStringList.Create;
  With NewIniObject do
  Try
    ReadSectionValues (Def_Categorys, CategorysSL);
    CaptionSL := GetSLValueFromList (CategorysSL, Def_TitleCaptions);

    IndexA := -1;
    for Index := 0 to CaptionSL.Count - 1 do
    begin
      ReadStr := CaptionSL.ValueFromIndex[Index];
      if UpperCase(ReadStr) = UpperCase(PlugFile) then
      begin
        IndexA := Index;
        Break;
      end;
    end;

    if IndexA = -1 then
    begin
      IndexA := CaptionSL.Count;
      WriteVal := GetCaptionFormPlugFile (PlugFile);
      CaptionSL.Values[WriteVal] := PlugFile;
      WriteVal := EncodeBase64(CaptionSL.Text);
      WriteString(Def_Categorys, Def_TitleCaptions, WriteVal);
    end;

    SectionRead := Def_CategoryHead + IntToStr(IndexA);
    ItemSL := GetSLValueFromList (CategorysSL, SectionRead);

    Index := ItemSL.IndexOfName(SaveName);
    if Index = -1 then
    begin
      SysField := GetSystemField (PlugFile, True);
      WriteVal := EncodeBase64(SysField.Text);
      SysField.Free;
      IndexB := ItemSL.Add(SaveName+'='+WriteVal);

      WriteVal := EncodeBase64(ItemSL.Text);
      WriteString(Def_Categorys, SectionRead, WriteVal);
    end else
    begin
      IndexB := Index;
    end;

    ItemSL.Free;
    CaptionSL.Free;
  finally
    Free;
  end;
  CategorysSL.Free;           

  Result := SaveConfigItem (IndexA, IndexB, ToSave);
end;

function TDataModuleBase.CloneConfigItem (IndexA, IndexB: Integer): BOOL;
var
  CategoryID, KeyStr, ReadSrc: String;
  PlugSL, ReadTo: TStringList;
begin
  Result := False;
  if IndexA = -1 then exit;
  if IndexB = -1 then exit;
  
  With NewIniObject do
  Try
    CategoryID := Def_CategoryHead + IntToStr(IndexA);
    ReadSrc := ReadString(Def_Categorys, CategoryID, '');
    if ReadSrc <> '' then
    begin
      ReadSrc := DecodeBase64 (ReadSrc);
      PlugSL := TStringList.Create;
      PlugSL.Text := ReadSrc;
      if PlugSL.Count > IndexB then
      begin
        ReadSrc := Trim(PlugSL.ValueFromIndex[IndexB]);
        if ReadSrc <> '' then
        begin
          //先全部读入配置
          ReadTo := TStringList.Create;
          ReadSrc := DecodeBase64 (ReadSrc);
          ReadTo.Text := ReadSrc;

          KeyStr := PlugSL.Names[IndexB];
          KeyStr := KeyStr + ' 复件';
          ReadTo.Values[INI_KEY_NAME] := KeyStr;

          ReadSrc := EncodeBase64(ReadTo.Text);
          if IndexB = PlugSL.Count - 1 then
            PlugSL.Add(KeyStr+'='+ReadSrc)
          else
            PlugSL.Insert(IndexB + 1, KeyStr+'='+ReadSrc);

          ReadSrc := EncodeBase64 (PlugSL.Text);
          WriteString(Def_Categorys, CategoryID, ReadSrc);

          Result := True;
        end;
      end;
      PlugSL.Free;
    end;
  finally
    Free;
  end;     
end;

function TDataModuleBase.MoveConfigItem (IndexA, IndexB, Offset: Integer): BOOL;
var
  CategoryID, ReadSrc: String;
  PlugSL: TStringList;
begin
  Result := False;
  if IndexA = -1 then exit;
  if IndexB = -1 then exit;
  if Offset = 0 then exit;

  With NewIniObject do
  Try
    CategoryID := Def_CategoryHead + IntToStr(IndexA);
    ReadSrc := ReadString(Def_Categorys, CategoryID, '');
    if ReadSrc <> '' then
    begin
      ReadSrc := DecodeBase64 (ReadSrc);
      PlugSL := TStringList.Create;
      PlugSL.Text := ReadSrc;
      if PlugSL.Count > IndexB then
      begin
        Offset := IndexB + Offset;
        if Offset >= PlugSL.Count then
          Offset := PlugSL.Count - 1;
        if Offset < 0 then
          Offset := 0;

        if IndexB <> Offset then
        begin
          PlugSL.Move(IndexB, Offset);
        end;

        ReadSrc := EncodeBase64 (PlugSL.Text);
        WriteString(Def_Categorys, CategoryID, ReadSrc);
        Result := True;
      end;
      PlugSL.Free;
    end;
  finally
    Free;
  end;     
end;


function  TDataModuleBase.ReadConfigItem (IndexA, IndexB: Integer): TStringList;
var
  CategoryID, ReadSrc, NameStr: String;
  PlugSL, FieldNames: TStringList;
  PrivacyField: Bool;
  Index: Integer;
begin
  Result := TStringList.Create;
  if IndexA < 0 then exit;
  if IndexB < 0 then exit;

  With NewIniObjectMem do
  Try
    CategoryID := Def_CategoryHead + IntToStr(IndexA);
    ReadSrc := ReadString(Def_Categorys, CategoryID, '');
    if ReadSrc <> '' then
    begin
      ReadSrc := DecodeBase64 (ReadSrc);
      PlugSL := TStringList.Create;
      PlugSL.Text := ReadSrc;
      if PlugSL.Count > IndexB then
      begin
        ReadSrc := Trim(PlugSL.ValueFromIndex[IndexB]);
        if ReadSrc <> '' then
        begin
          ReadSrc := DecodeBase64 (ReadSrc);
          Result.Text := ReadSrc;

          PrivacyField := ReadBool (Def_MainStyle, 'PrivacyField', False);
          if not PrivacyField then
          begin
            ReadSrc := Result.Values[INI_KEY_PRIVACYFIELDS];
            FieldNames := GetSplitBlankList (ReadSrc, [',']);
            for Index := 0 to Result.Count - 1 do
            begin
              NameStr := Result.Names[Index];
              if FieldNames.IndexOf(NameStr) >= 0 then
              begin
                Result.ValueFromIndex[Index] := '********';
              end;
            end;
            FieldNames.Free;
          end;

        end;
      end;
      PlugSL.Free;
    end;
  finally
    Free;
  end;     
end;

function  TDataModuleBase.ReadConfigItem (IndexA, IndexB: Integer; ReadTo: TStrings): BOOL;
var
  ReadSrc: String;
  SysField, CaptionSL: TStringList;
  PlugFile: String;
  SystemField, PrivacyField, StayOnTop: Bool;
  Index: Integer;
  ReadSL: TStringList;
begin
  Result := False;
  if IndexA = -1 then exit;         
  if IndexB = -1 then exit;
  ReadSL := ReadConfigItem (IndexA, IndexB);

  if ReadSL.Count > 0 then
  begin
    Result := True;
    //如果不显示系统配置，则删除之
    GetViewBool (SystemField, PrivacyField, StayOnTop);
    
    if not SystemField then
      With NewIniObjectMem do
      Try
        ReadSrc := ReadString (Def_Categorys, Def_TitleCaptions, '');
        ReadSrc := DecodeBase64 (ReadSrc);
        CaptionSL := TStringList.Create;
        CaptionSL.Text := ReadSrc;
        if CaptionSL.Count > IndexA then
          PlugFile := CaptionSL.ValueFromIndex[IndexA];
        CaptionSL.Free;
        if PlugFile = '' then Exit;

        SysField := GetSystemField (PlugFile);   

        for Index := ReadSL.Count - 1 downto 0 do
        begin
          ReadSrc := ReadSL.Names[Index];
          if SysField.IndexOf(ReadSrc) >= 0 then
            ReadSL.Delete(Index);
        end;
        SysField.Free;
      finally
        Free;
      end;
  end;

  ReadTo.AddStrings(ReadSL);  
  ReadSL.Free;
end;

function TDataModuleBase.DeleteConfigItem (IndexA, IndexB: Integer): BOOL;
var
  CategoryID,  ReadSrc: String;
  PlugSL: TStringList;
begin
  Result := False;
  if IndexA = -1 then exit;
  if IndexB = -1 then exit;

  With NewIniObject do
  Try
    CategoryID := Def_CategoryHead + IntToStr(IndexA);
    ReadSrc := ReadString(Def_Categorys, CategoryID, '');
    if ReadSrc <> '' then
    begin
      ReadSrc := DecodeBase64 (ReadSrc);
      PlugSL := TStringList.Create;
      PlugSL.Text := ReadSrc;
      if PlugSL.Count > IndexB then
      begin
        PlugSL.Delete(IndexB); 
        ReadSrc := EncodeBase64 (PlugSL.Text);
        WriteString(Def_Categorys, CategoryID, ReadSrc);
        Result := True;
      end;
      PlugSL.Free;
    end;
  finally
    Free;
  end;     
end;

function TDataModuleBase.ClearConfigItem (IndexA: Integer): BOOL;
var
  CategoryID, ReadSrc: String;
  CaptionSL: TStringList;
  Index: Integer;
begin
  Result := False;
  if IndexA < 0 then
  begin
    With NewIniObject do
    Try
      EraseSection (Def_Categorys);
    finally
      Free;
    end;
    Result := True;
    Exit;
  end;

  With NewIniObject do
  Try
    ReadSrc := ReadString (Def_Categorys, Def_TitleCaptions, '');
    CaptionSL := TStringList.Create;
    CaptionSL.Text := DecodeBase64(ReadSrc);
    if CaptionSL.Count > IndexA then
    begin
      CaptionSL.Delete(IndexA);
      ReadSrc := EncodeBase64(CaptionSL.Text);
      WriteString(Def_Categorys, Def_TitleCaptions, ReadSrc);

      CategoryID := Def_CategoryHead + IntToStr(IndexA);
      DeleteKey (Def_Categorys, CategoryID);

      for Index := IndexA to CaptionSL.Count do
      begin                                           
        CategoryID := Def_CategoryHead + IntToStr(Index + 1);
        ReadSrc := ReadString (Def_Categorys, CategoryID, '');
        CategoryID := Def_CategoryHead + IntToStr(Index);
        WriteString(Def_Categorys, CategoryID, ReadSrc);
      end;
      Result := True;   
    end;
    CaptionSL.Free;
  finally
    Free;
  end;     
end;


function TDataModuleBase.GetUsesApps(): TStringList;
var
  PlugSL, ItemSL, CfgSL: TStringList;
  Index, IndexB: Integer;
  SectionName, ReadStr: String;
  AppFile: String;
begin          
  Result := TStringList.Create;
  ItemSL := TStringList.Create;
  CfgSL := TStringList.Create;
  PlugSL := GetUsesPlugins;

  With NewIniObjectMem do
  Try
    for Index := 0 to PlugSL.Count - 1 do
    begin
      SectionName := Def_CategoryHead + IntToStr(Index);
      ReadStr := ReadString(Def_Categorys, SectionName, '');
      ReadStr := DecodeBase64(ReadStr);
      ItemSL.Text := ReadStr;
      for IndexB := 0 to ItemSL.Count - 1 do
      begin
        ReadStr := ItemSL.ValueFromIndex[IndexB];
        ReadStr := DecodeBase64(ReadStr);
        CfgSL.Text := ReadStr;
        AppFile := CfgSL.Values[INI_KEY_APPCMDLINE];
        AppFile := GetAppExeFromCmdLine (AppFile);
        if FileExists(AppFile) then
          if Result.IndexOf(AppFile) = -1 then
            Result.Add(AppFile);
      end;
    end;
  finally

  end;
  PlugSL.Free;
  ItemSL.Free;
  CfgSL.Free;
end;

function TDataModuleBase.GetUsesPlugins(): TStringList;
var
  CaptionSL: TStringList;
  PlugFile, ReadSrc: String;
  Index: Integer;
begin
  Result := TStringList.Create;

  With NewIniObjectMem do
  Try
    ReadSrc := ReadString (Def_Categorys, Def_TitleCaptions, '');
    CaptionSL := TStringList.Create;
    CaptionSL.Text := DecodeBase64 (ReadSrc);

    for Index := 0 to CaptionSL.Count - 1 do
    begin
      PlugFile := CaptionSL.ValueFromIndex[Index];
      if FileExists (PlugFile) then
        if Result.IndexOf(PlugFile) = -1 then
          Result.Add(PlugFile);
    end;   
    CaptionSL.Free;
  finally
    Free;
  end;
end;

function TDataModuleBase.GetImageIndex (AppName: String; IsActive: BOOL = True): Integer;
var
  KeyIcoName: String;
  AddIndex: Integer;
begin
  if FCacheIcoIndex = nil then
    FCacheIcoIndex := TStringList.Create;

  AppName := UpperCase (AppName);

  if IsActive then
    KeyIcoName := AppName + '.TRUE'
  else
    KeyIcoName := AppName + '.FALSE';

  AddIndex := FCacheIcoIndex.IndexOf(KeyIcoName);
  if AddIndex = -1 then
  begin
    if IsActive then
      Result := LoadIconToImageList (AppName, self.DynImageList)
    else
      Result := LoadIconToImageList (AppName, self.DynImageList, 50);
    FCacheIcoIndex.AddObject(KeyIcoName, Pointer(Result));
  end else
  begin
    Result := Integer (FCacheIcoIndex.Objects[AddIndex]);
  end;
end;

function GetSelectPos (Selected: TButtonItem): DWORD;
var
  FirstIndex, SecondIndex: Integer;
begin
  Result := 0;
  if not Assigned (Selected) then exit;

  FirstIndex := Selected.Category.Index;
  SecondIndex := Selected.Index;
  Result := MakeLong (FirstIndex, SecondIndex);  //低位，高位
end;

Procedure SetSelectPos (ConfigList: TCategoryButtons; PosVal: DWORD);
var
  FirstIndex, SecondIndex: Integer;
  Selected: TButtonItem;
begin
  FirstIndex := WORD(PosVal);
  SecondIndex := HiWord(PosVal);

  if ConfigList.Categories.Count > FirstIndex then
    if ConfigList.Categories.Items[FirstIndex].Items.Count > SecondIndex then
    begin
      Selected := ConfigList.Categories.Items[FirstIndex].Items[SecondIndex];
      if Assigned (Selected) then
        ConfigList.SelectedItem := Selected;
    end;           
end;

Procedure ClearCategoriesData (ConfigList: TCategoryButtons);
var
  IndexA, IndexB: Integer;
  ItemPtr: Pointer;
begin
  for IndexA := 0 to ConfigList.Categories.Count - 1 do
  begin
    ItemPtr := ConfigList.Categories.Items[IndexA].Data;
    if Assigned (ItemPtr) then
      FreeMem (ItemPtr);
      
    for IndexB := 0 to ConfigList.Categories.Items[IndexA].Items.Count - 1 do
    begin
      ItemPtr := ConfigList.Categories.Items[IndexA].Items[IndexB].Data;
      if Assigned (ItemPtr) then
        FreeMem (ItemPtr);
    end;
  end;
  ConfigList.Categories.Clear;
end;


function MakeAStringCopy (Src: String): PChar;
begin
  Result := nil;
  if Src = '' then exit;
  Result := AllocMem (Length(Src) + 1);
  StrCopy(Result, PChar(Src));
end;

Procedure TDataModuleBase.LoadConfigLst (ConfigList: TCategoryButtons);
var
  PosVal: DWORD;
  ReadCategorys, CaptionSL, ReadButtons: TStringList;
  IndexA, IndexB: Integer;
  CollapseSL, ItemSL: TStringList;
  CategoryID, AppFile, PlugFile: String;
  BtnCategory: TButtonCategory;
  IterItem: TButtonItem;
begin
  //主动设置显示图标
  if Not Assigned (ConfigList.Images) then
    ConfigList.Images := self.DynImageList;

  //记录按钮组的折叠状态
  CollapseSL := GetCollapseds (ConfigList);
  //记录选中状态
  PosVal := GetSelectPos (ConfigList.SelectedItem);
  //清空原来数据
  ClearCategoriesData (ConfigList);   

  With NewIniObjectMem() do
  try
    ReadCategorys := TStringList.Create;
    ItemSL := TStringList.Create;
    ReadSectionValues (Def_Categorys, ReadCategorys);

    CaptionSL := GetSLValueFromList (ReadCategorys, Def_TitleCaptions);

    for IndexA := 0 to CaptionSL.Count - 1 do
    begin                   
      BtnCategory := ConfigList.Categories.Add;
      BtnCategory.Caption := CaptionSL.Names[IndexA];  //插件标签
      PlugFile := CaptionSL.ValueFromIndex[IndexA]; //插件文件名
      BtnCategory.Data := MakeAStringCopy(PlugFile);
      BtnCategory.Color := clSkyBlue;
      BtnCategory.GradientColor := clWebAliceBlue;
      //取出各分栏内容
      CategoryID := Def_CategoryHead + IntToStr(IndexA);
      ReadButtons := GetSLValueFromList (ReadCategorys, CategoryID);

      for IndexB := 0 to ReadButtons.Count - 1 do
      begin
        IterItem := BtnCategory.Items.Add;
        IterItem.Caption := ReadButtons.Names[IndexB];   //配置名称
        ItemSL.Text := DecodeBase64(ReadButtons.ValueFromIndex[IndexB]);
        AppFile := ItemSL.Values[INI_KEY_APPCMDLINE];
        AppFile := GetAppExeFromCmdLine (AppFile);
        IterItem.Data := MakeAStringCopy (AppFile);
        if FileExists(AppFile) then
        begin
          if FileExists(PlugFile) then
            IterItem.ImageIndex := GetImageIndex (AppFile)
          else
            IterItem.ImageIndex := GetImageIndex (AppFile, False);
        end else
          IterItem.ImageIndex := GetImageIndex (GetModuleName (0), False);
      end;
      ReadButtons.Free;


      if not FileExists (PlugFile) then
      begin
        BtnCategory.Caption := BtnCategory.Caption + ' [插件不存在]';
        BtnCategory.TextColor := clGray;
        BtnCategory.Collapsed := True;
      end else
        BtnCategory.Collapsed := CollapseSL.IndexOf(BtnCategory.Caption) >= 0;
    end;

    CaptionSL.Free;
    ReadCategorys.Free;
    ItemSL.Free;
  finally
    Free;
  end;

  //还原状态
  SetSelectPos (ConfigList, PosVal);
  CollapseSL.Free;
end;


end.
