unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Menus;

type
  TForm3 = class(TForm)
    ListBox1: TListBox;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    OpenDialog1: TOpenDialog;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Panel3: TPanel;
    StaticText1: TStaticText;
    ComboBox1: TComboBox;
    Button3: TButton;
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

uses UMPE, DrvRunUnit, MainExeIni;

{$R *.dfm}

procedure TForm3.Button1Click(Sender: TObject);
var
  CodeBase: Pointer;
  CodeSize: DWORD;
  DllToLoad: String;
  MsgTextSL: TStringList;
  MsgCaption: String;
begin                  
  DllToLoad := Trim(Self.ComboBox1.Text);       
  if self.ListBox1.Items.Count < 1 then exit;
  if not fileexists (DllToLoad) then
    DllToLoad := '';

  MsgTextSL := TStringList.Create;

  if DllToLoad = '' then
  begin
    MsgTextSL.Add('请问是否允许运行：');
    MsgTextSL.Add('  选择“是”：将继续运行本进程。');
    MsgTextSL.Add('  选择“取消”：退出本进程。');
  end else
  begin
    MsgTextSL.Add('请问是否加载DLL：');
    MsgTextSL.Add('  选择“是”：加载DLL，继续运行本进程。');
    MsgTextSL.Add('  选择“否”：不加载DLL，继续运行本进程。');
    MsgTextSL.Add('  选择“取消”：退出本进程。');
  end;

  MsgCaption := '关键进程创建提示';
  if MakeSpyCode (self.ListBox1.Items, DllToLoad, MsgCaption, MsgTextSL, CodeBase, CodeSize) then
  begin
    DirverInitial (CodeBase, CodeSize);
    if DllToLoad <> '' then
      if self.ComboBox1.Items.IndexOf(DllToLoad) = -1 then
        self.ComboBox1.Items.Add(DllToLoad);
  end;

  MsgTextSL.Free;

  self.Label1.Caption := format ('SpyCodeSize = %d bytes', [CodeSize]);
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
  EnsureDriver (False);
end;

procedure TForm3.Button3Click(Sender: TObject);
begin
  self.OpenDialog1.Filter := 'DLL动态链接库|*.dll';
  if self.OpenDialog1.Execute then
    self.ComboBox1.Text := self.OpenDialog1.FileName;
end;


procedure TForm3.FormShow(Sender: TObject);
var
  Index: Integer;
  ReadStr: String;
begin
  SubDirectory := 'Data\';

  for Index := 0 to 100 do
  begin
    ReadStr := ReadConfig ('AimAppList', IntToStr(Index), '');
    if ReadStr = '' then Break;
    if FileExists (ReadStr) then
      self.ListBox1.Items.Add(ReadStr);
  end;

  for Index := 0 to 100 do
  begin
    ReadStr := ReadConfig ('DllList', IntToStr(Index), '');
    if ReadStr = '' then Break;
    if FileExists (ReadStr) then
      self.ComboBox1.Items.Add(ReadStr);
  end;

  if self.ComboBox1.Items.Count > 0 then
    self.ComboBox1.Text := self.ComboBox1.Items[0];

  ReadConfig ('DllList', IntToStr(Index), '', True);
end;

var
  LastUpTime: DWORD;

procedure TForm3.ListBox1DblClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := self.ListBox1.ItemIndex;
  if Index = -1 then exit;
  self.N2Click(NIL);     
end;

procedure TForm3.ListBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
  AtPtr: TPoint;
begin
  if self.ListBox1.ItemIndex <> -1 then exit;

  if Button = mbLeft then
  begin
    if GetTickCount - LastUpTime > 300 then
    begin
      LastUpTime := GetTickCount;
      Exit;
    end;
    LastUpTime := GetTickCount;

    AtPtr.X := X;
    AtPtr.Y := Y;

    Index := self.ListBox1.ItemAtPos(AtPtr, True);
    if Index = -1 then
      self.N1Click(NIL);
  end;
end;      

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Index: Integer;
  WriteStr: String;
begin
  EraseSection ('AimAppList');
  for Index := 0 to self.ListBox1.Count - 1 do
  begin
    WriteStr := self.ListBox1.Items[Index];
    if FileExists (WriteStr) then
      WriteConfig ('AimAppList', IntToStr(Index), WriteStr);
  end;

  Index := self.ComboBox1.Items.IndexOf(self.ComboBox1.Text);
  if Index > 0 then
    self.ComboBox1.Items.Move(Index, 0);

  EraseSection ('DllList');
  for Index := 0 to self.ComboBox1.Items.Count - 1 do
  begin
    WriteStr := self.ComboBox1.Items[Index];
    if FileExists (WriteStr) then
      WriteConfig ('DllList', IntToStr(Index), WriteStr);
  end;

  ReadConfig ('DllList', '0', '', True);
end;
procedure TForm3.N1Click(Sender: TObject);
var
  ToHandle:String;
begin
  self.OpenDialog1.Filter := '';
  if self.OpenDialog1.Execute then
  begin
    ToHandle := UpperCase (self.OpenDialog1.FileName);
    Self.ListBox1.Items.Add (ToHandle);
  end;
    
end;

procedure TForm3.N2Click(Sender: TObject);
begin
  self.ListBox1.DeleteSelected;
end;

end.
