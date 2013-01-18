unit AddModifyForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, Grids, ValEdit, StdCtrls, ExtCtrls;

type
  TRunMode = (rmNone, rmModify, rmAddNew);

type
  TModifyForm = class(TForm)
    ComboBox1: TComboBox;
    Panel1: TPanel;
    Panel2: TPanel;
    ValueListEditor1: TValueListEditor;
    Panel3: TPanel;
    ComboBox2: TComboBox;
    Panel4: TPanel;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    Panel5: TPanel;
    Panel6: TPanel;
    Button2: TButton;
    Button3: TButton;
    Panel7: TPanel;
    Panel8: TPanel;
    Label1: TLabel;
    Button5: TButton;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ValueListEditor1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FMemList: TList;
    Function UseTempMemory (TempStr: String): PChar;
    Procedure ClearTempMemory;
  public
    RunMode: TRunMode;
    RunParam: String;
    Procedure UpdatePluginList (AppCombobox, PlugCombobox: TCombobox);
    Procedure PrepareParamList (AppExe, KeyName: String; ParamEdt: TValueListEditor);
    function AddConfigAppsTo (Combo: TComboBox) : BOOL;
    Procedure ReflashView;
  end;

var
  ModifyForm: TModifyForm;

implementation

uses DataUnit, DLLLoader;

{$R *.dfm}


procedure TModifyForm.Button3Click(Sender: TObject);
begin
  PrepareParamList (ComboBox1.Text, ComboBox2.Text, self.ValueListEditor1);
end;

procedure TModifyForm.Button4Click(Sender: TObject);
var
  HelpTxt, SaveName: String;
begin       
  SaveName := ChangeFileExt (ComboBox2.Text, '.hlp.txt');
  SaveName := DCM.TempPath + SaveName;

  if not FileExists (SaveName) then
  begin
    HelpTxt := DCM.GetPluginHelp (ComboBox2.Text);
    with TStringList.Create do
    try
      Text := HelpTxt;
      SaveToFile (SaveName);
    finally
      Free;
    end;
  end;

  WinExec (PChar('Notepad.exe "' + SaveName + '"'), SW_SHOW);
end;

procedure TModifyForm.Button5Click(Sender: TObject);
begin
  Close;
end;

function TModifyForm.AddConfigAppsTo (Combo: TComboBox) : BOOL;
var
  AppList: TStringList;
begin
  Result := False;
  AppList := DCM.GetConfigAppList;
  if AppList.Count > 0 then
  begin
    Combo.Items.AddStrings(AppList);
    Combo.ItemIndex := 0;
    Result := True;
  end;
  AppList.Free;
end;

procedure TModifyForm.FormShow(Sender: TObject);
var
  AppExe, PluginName: String;
begin  
  repeat
    RunParam := Trim(RunParam);

    if FileExists (RunParam)  then
    if IsPeFile (RunParam) then
    begin
      RunMode := rmAddNew;
      Break;
    end;

    if Length(RunParam) = Length('{76B68A2D-9A87-4512-A550-88DCA52687ED}') then
    if DCM.GetPluginFromConfigID (RunParam, AppExe, PluginName) then
    begin
      RunMode := rmModify;
      Break;
    end;

    RunMode := rmNone;
  until True;

  case RunMode of
    rmNone: ComboBox1.Text := '';
    rmAddNew: ComboBox1.Text := RunParam;
    rmModify: begin
      ComboBox1.Text := AppExe;
      ComboBox2.Text := PluginName;
      Panel1.Visible := False;
      Panel3.Visible := False;
      DCM.UpdateConfig (RunParam, self.ValueListEditor1);
      Exit;
    end;
  end;

  ReflashView;
end;


procedure TModifyForm.FormCreate(Sender: TObject);
begin
  FMemList := TList.Create;
end;


procedure TModifyForm.FormDestroy(Sender: TObject);
begin
  ClearTempMemory;
  FMemList.Free;
end;

Procedure TModifyForm.ReflashView;
begin
  UpdatePluginList (ComboBox1, ComboBox2);
  if ComboBox2.Text = '' then
    ShowMessage ('抱歉，你所选择的程序没有相应的插件可用！');
  PrepareParamList (ComboBox1.Text, ComboBox2.Text, self.ValueListEditor1);
end;

procedure TModifyForm.Button1Click(Sender: TObject);
begin
  OpenDialog1.Title := '请选择要打上插件的程序';
  OpenDialog1.Filter := 'EXE|*.exe';
  if OpenDialog1.Execute then
    self.ComboBox1.Text := OpenDialog1.FileName;

  ReflashView;
end;


Procedure TModifyForm.UpdatePluginList (AppCombobox, PlugCombobox: TCombobox);
var
  PlugList: TStringList;
begin
  AppCombobox.Text := Trim (AppCombobox.Text);

  if AppCombobox.Text = '' then
    if not AddConfigAppsTo (AppCombobox) then
    begin
      OpenDialog1.Title := '请选择要打上插件的程序';
      OpenDialog1.Filter := 'EXE|*.exe';
      if OpenDialog1.Execute then
        AppCombobox.Text := OpenDialog1.FileName;
    end;

  PlugList := DCM.GetMainPluginList(AppCombobox.Text);
  PlugCombobox.Clear;
  PlugCombobox.Items.AddStrings(PlugList);
  PlugCombobox.Text := DCM.GetLastRunPlugin (PlugList);
  PlugList.Free;
end;

Procedure ExtractHitAndConst (Source: String; var ConstStr,HitStr: String);
var
  LeftIndex, RightIndex: Integer;
  Found: BOOL;
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

  if RightIndex - LeftIndex > 1 then
  begin
    ConstStr := Copy (Source, LeftIndex + 1, RightIndex - LeftIndex - 1);
    HitStr := Source;
    Delete (HitStr, LeftIndex, RightIndex - LeftIndex + 1);
  end;
end;


Procedure TModifyForm.ClearTempMemory;
var
  Item: Pointer;
begin
  for Item in FMemList do
    FreeMem (Item);
  FMemList.Clear;
end;

Function TModifyForm.UseTempMemory (TempStr: String): PChar;
begin
  Result := AllocMem (Length(TempStr) + 1);
  StrCopy (Result, Pchar(TempStr));
  FMemList.Add(Result);
end;



Procedure TModifyForm.PrepareParamList (AppExe, KeyName: String; ParamEdt: TValueListEditor);
var
  ParamList: TStringList;
  ParamKey, ParamValue: String;
  Index: Integer;
  ConstStr, HitStr: String;
  StoreHit: Pointer;
  ViewConst: BOOL;
begin
  ParamEdt.Strings.Clear;
  if KeyName = '' then exit;

  StoreHit := UseTempMemory ('此配置的名称。请输入一个容易理解，又能区别于其他配置的名字');
  ParamEdt.Strings.AddObject('Name=', StoreHit);

  StoreHit := UseTempMemory ('目标程序的命令行表达方式，有个别程序要求带参数调用');
  ParamEdt.Strings.AddObject('AppCmdLine=' + AppExe, StoreHit);

  ParamList := DCM.GetParamList (KeyName);
  ViewConst := DCM.ViewConstField;
  for Index := 0 to ParamList.Count - 1 do
  begin
    ParamKey := ParamList.Names[Index];

    if DCM.IsConstField (ParamKey) then
      if not ViewConst then
        Continue;

    ParamValue := ParamList.ValueFromIndex[Index];
    ExtractHitAndConst (ParamValue, ConstStr, HitStr);

    if HitStr <> '' then
    begin
      StoreHit := UseTempMemory (HitStr);
      ParamEdt.Strings.AddObject(ParamKey+'='+ConstStr, StoreHit);
    end else
      ParamEdt.Strings.Values[ParamKey] := ConstStr;
  end;
  ParamList.Free;
end;


procedure TModifyForm.ValueListEditor1SelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
var
  HitIndex: Integer;
  HitStr: String;
  HitStore: PChar;
begin
  HitStr := '';       

  if (ACol = 1) and (aRow > 0) then
  begin
    HitIndex := aRow - 1;

    if (HitIndex >= 0) and (HitIndex < ValueListEditor1.Strings.Count) then
    begin
      HitStore := Pointer(ValueListEditor1.Strings.Objects[HitIndex]);
      if Assigned (HitStore) then
        HitStr := StrPas (HitStore);
    end;
  end;

  self.Label1.Caption := HitStr;
end;


end.
