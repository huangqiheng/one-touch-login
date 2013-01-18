unit AddFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, Grids, ValEdit, StdCtrls, ExtCtrls;


type
  TAddConfigForm = class(TForm)
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
    Button6: TButton;
    procedure ComboBox2Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure ComboBox2DropDown(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ValueListEditor1SelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
  private
  public
    ToAddAppExe: String;
    ToAddPlugin: String;
    Procedure PrepareParamList (AppCmdLine, PlugFile: String; ParamEdt: TValueListEditor);
  end;

var
  AddConfigForm: TAddConfigForm = nil;

implementation

uses HandlerUnit;


{$R *.dfm}


procedure TAddConfigForm.Button5Click(Sender: TObject);
begin
  Close;
end;

procedure TAddConfigForm.Button1Click(Sender: TObject);
begin
  OpenDialog1.Title := '请选择要打上插件的目标程序';
  OpenDialog1.Filter := 'EXE|*.exe';
  if OpenDialog1.Execute then
  begin
    self.ComboBox1.Text := OpenDialog1.FileName;
    self.ComboBox2Change(sender);
  end;
end;

procedure TAddConfigForm.Button6Click(Sender: TObject);
begin
  OpenDialog1.Title := '请选择插件DLL';
  OpenDialog1.Filter := 'DLL|*.dll';
  if OpenDialog1.Execute then
  begin
    self.ComboBox2.Text := OpenDialog1.FileName;
    self.ComboBox2Change(sender);
  end;
end;

procedure TAddConfigForm.FormShow(Sender: TObject);
begin
  self.ValueListEditor1.Strings.Clear;

  if ToAddAppExe <> '' then
    ComboBox1.Text := ToAddAppExe;
  if ToAddPlugin <> '' then
  begin
    self.ComboBox2.Text := ToAddPlugin;
    self.ComboBox2Change(sender);
  end;
end;
           
procedure TAddConfigForm.Button2Click(Sender: TObject);
var
  Name: String;
  PlugFile, PluginIni: String;
begin
  Name := Trim(ValueListEditor1.Strings.Values['Name']);
  if Trim(Name) = '' then
  begin
    ShowMessage ('Name字段不能为空，请重填');
    Exit;
  end;

  PlugFile := self.ComboBox2.Text;
  PluginIni := ChangeFileExt (PlugFile, '.ini');
  if not FileExists (PluginIni) then
  begin
    ShowMessage ('插件配置文件不存在：'#13#10 + PluginIni);
    Exit;
  end;

  if DataModule.SaveConfigItem(PlugFile, self.ValueListEditor1.Strings) then
  begin
    ToAddAppExe := '';
  end else
    ShowMessage ('添加配置失败，请检查输入参数');
  Close;
end;

procedure TAddConfigForm.ComboBox1DropDown(Sender: TObject);
var
  ReadSL: TStringList;
begin
  if self.ComboBox1.Items.Count = 0 then
  begin
    ReadSL := DataModule.GetUsesApps;
    self.ComboBox1.Items.AddStrings(ReadSL);
    ReadSL.Free;
  end;
end;

procedure TAddConfigForm.ComboBox2Change(Sender: TObject);
begin
  if ComboBox1.Text = '' then exit;
  if ComboBox2.Text = '' then exit;
  if Not FileExists(ComboBox1.Text) then exit;
  if Not FileExists(ComboBox2.Text) then exit;

  PrepareParamList (ComboBox1.Text, ComboBox2.Text, self.ValueListEditor1);
end;

procedure TAddConfigForm.ComboBox2DropDown(Sender: TObject);
var
  ReadSL: TStringList;
begin
  if self.ComboBox2.Items.Count = 0 then
  begin
    ReadSL := DataModule.GetUsesPlugins;
    self.ComboBox2.Items.AddStrings(ReadSL);
    ReadSL.Free;
  end;
end;

Procedure TAddConfigForm.PrepareParamList (AppCmdLine, PlugFile: String; ParamEdt: TValueListEditor);
begin
  ParamEdt.Strings.Clear;
  if PlugFile = '' then exit;

  ParamEdt.Strings.Add('Name=');
  ParamEdt.Strings.Add('AppCmdLine=' + AppCmdLine);
  DataModule.InitConfigItem(PlugFile, ParamEdt.Strings);
end;


procedure TAddConfigForm.ValueListEditor1SelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
var
  HitIndex: Integer;
  KeyStr, HitStr: String;
begin
  HitStr := '';       

  if (ACol = 1) and (aRow > 0) then
  begin
    HitIndex := aRow - 1;

    if (HitIndex >= 0) and (HitIndex < ValueListEditor1.Strings.Count) then
    begin
      KeyStr := ValueListEditor1.Strings.Names[HitIndex];
      if KeyStr = 'Name' then
      begin
        HitStr := '此配置的名称。请输入一个容易理解，又能区别于其他配置的名字';
      end else
      if KeyStr = 'AppCmdLine' then
      begin
        HitStr := '目标程序的命令行表达方式，有个别程序要求带参数调用';
      end;
    end;
  end;

  self.Label1.Caption := HitStr;
end;


end.
