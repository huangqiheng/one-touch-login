unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus;

type
  TForm2 = class(TForm)
    HistoryList: TListBox;
    Button1: TButton;
    ComboBox1: TComboBox;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    ToInjectList: TListBox;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    StatusBar1: TStatusBar;
    Splitter1: TSplitter;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    TrackBar1: TTrackBar;
    PopupMenu2: TPopupMenu;
    N6: TMenuItem;
    N7: TMenuItem;
    procedure N7Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ToInjectListMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure N3Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure Panel4Click(Sender: TObject);
  private
    { Private declarations }
  public
    function InjectThemToHost: BOOL;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

uses MainExeINI, CodeProxy;

function TForm2.InjectThemToHost: BOOL;
var
  MM: TMemoryStream;
  Host: String;
  Index: Integer;
begin
  Result := False;
  self.ComboBox1.Text := Trim (self.ComboBox1.Text);
  Host := self.ComboBox1.Text;

  if not FileExists (Host) then
  begin
    ShowMessage ('注射目标程序不存在，请从新设置！');
    Exit;
  end;

  for Host in self.ToInjectList.Items do
  begin
    if not FileExists (Host) then
    begin
      ShowMessage (Host + '不存在，请从新设置！');
      Exit;
    end;
  end;

  MM := TMemoryStream.Create;

  MM.Seek(0, soFromBeginning);
  MM.LoadFromFile(self.ToInjectList.Items[0]);
  AddMainDLL (MM, '');

  for Index := 1 to self.ToInjectList.Count - 1 do
  begin
    Host := self.ToInjectList.Items[Index];
    MM.Clear;
    MM.LoadFromFile(Host);
    AddSubDLL (MM);
  end;

  Result := InjectThemALL (ComboBox1.Text, TrackBar1.Position * 1000, False);

  MM.Free;
end;

procedure TForm2.Button1Click(Sender: TObject);
var
  Index: Integer;
  ReadStr: String;
begin
  if InjectThemToHost then
  begin
    if self.ComboBox1.Items.IndexOf(self.ComboBox1.Text) = -1 then
      self.ComboBox1.Items.Insert(0, self.ComboBox1.Text);

    for Index := 0 to self.ToInjectList.Count - 1 do
    begin
      ReadStr := self.ToInjectList.Items[Index];
      if self.HistoryList.Items.IndexOf(ReadStr) = -1 then
        self.HistoryList.Items.Insert(0, ReadStr);
    end;
  end;
end;

Procedure GetKernelFunction (Panels: TStatusPanels); Stdcall;
var
  hDev: THandle;
  CodeBase: Pointer;
  CodeSize, Writed: DWORD;
begin
  if not TestMakeSpyCode (CodeBase, CodeSize) then
  begin
    Panels.Items[0].Text := '代码生成错误';
    Exit;
  end;

	hDev := CreateFileA('\\.\KPatch',	GENERIC_READ or GENERIC_WRITE, 0, NIL, CREATE_ALWAYS,	FILE_ATTRIBUTE_NORMAL, 0);
	if hDev = INVALID_HANDLE_VALUE then
	begin
    Panels.Items[0].Text := format('驱动异常: %d', [GetLastError]);
    FreeMem (CodeBase);
		Exit;
	end;                                     

  if WriteFile(hDev, CodeBase^, CodeSize, Writed, nil) then
    Panels.Items[0].Text := '驱动准备完毕'
  else
    Panels.Items[0].Text := '驱动写入错误';

  FreeMem (CodeBase);
  CloseHandle(hDev);
end;

procedure TForm2.FormCreate(Sender: TObject);
var
  Index: Integer;
  ReadStr: String;
  tid: Dword;
begin
  for Index := 0 to 100 do
  begin
    ReadStr := ReadConfig ('HostList', IntToStr(Index), '');
    ReadStr := Trim(ReadStr);
    if ReadStr = '' then Break;
    self.ComboBox1.Items.Add(ReadStr);
  end;

  for Index := 0 to 100 do
  begin
    ReadStr := ReadConfig ('LastDLLs', IntToStr(Index), '');
    ReadStr := Trim(ReadStr);
    if ReadStr = '' then Break;
    self.ToInjectList.Items.Add(ReadStr);
  end;

  for Index := 0 to 100 do
  begin
    ReadStr := ReadConfig ('HistoryList', IntToStr(Index), '');
    ReadStr := Trim(ReadStr);
    if ReadStr = '' then Break;
    self.HistoryList.Items.Add(ReadStr);
  end;

  self.ComboBox1.Text := ReadConfig ('LastHost', 'Host', '', True);

  self.TrackBar1.Position := StrToInt (ReadConfig('Config', 'TimeOut', '10'));
  self.Left := StrToInt (ReadConfig('Config', 'Left', '20'));
  self.Top := StrToInt (ReadConfig('Config', 'Top', '30'));
  self.Width := StrToInt (ReadConfig('Config', 'Width', '463'));
  self.Height := StrToInt (ReadConfig('Config', 'Height', '412'));
  self.ToInjectList.Height := StrToInt (ReadConfig('Config', 'DllBoxHeight', '129'));

  self.StatusBar1.Panels.Items[0].Width := self.Panel6.Width;
  self.StatusBar1.Panels.Items[1].Width := self.StatusBar1.Panels.Items[0].Width;

  CreateThread (NIL, 0, @GetKernelFunction, self.StatusBar1.Panels, 0, tid);
end;

procedure TForm2.FormDestroy(Sender: TObject);
var
  Index: Integer;
begin
  for Index := 0 to self.ComboBox1.Items.Count - 1 do
    WriteConfig ('HostList', IntToStr(Index), self.ComboBox1.Items[Index]);

  EraseSection ('LastDLLs');
  for Index := 0 to self.ToInjectList.Items.Count - 1 do
    WriteConfig ('LastDLLs', IntToStr(Index), self.ToInjectList.Items[Index]);

  for Index := 0 to self.HistoryList.Items.Count - 1 do
    WriteConfig ('HistoryList', IntToStr(Index), self.HistoryList.Items[Index]);

  EraseSection ('LastHost');
  WriteConfig ('LastHost', 'Host', self.ComboBox1.Text);

  WriteConfig ('Config', 'TimeOut', IntToStr (self.TrackBar1.Position));
  WriteConfig ('Config', 'Left', IntToStr (self.Left));
  WriteConfig ('Config', 'Top', IntToStr (self.Top));
  WriteConfig ('Config', 'Width', IntToStr (self.Width));
  WriteConfig ('Config', 'Height', IntToStr (self.Height));
  WriteConfig ('Config', 'DllBoxHeight', IntToStr (self.ToInjectList.Height));
end;

procedure TForm2.N1Click(Sender: TObject);
begin
  self.OpenDialog1.Filter := '动态链接库DLL|*.dll';
  if self.OpenDialog1.Execute then
  begin
    self.ToInjectList.Items.Add (self.OpenDialog1.FileName);
  end;
end;

procedure TForm2.N2Click(Sender: TObject);
begin
  self.ToInjectList.DeleteSelected;
end;

procedure TForm2.N3Click(Sender: TObject);
begin
  self.ToInjectList.Clear;
end;

procedure TForm2.N4Click(Sender: TObject);
var
  Index: Integer;
begin
  Index := self.ToInjectList.ItemIndex;
  if Index = -1 then exit;
  if Index = 0 then exit;
  self.ToInjectList.Items.Move(Index, Index - 1);
end;

procedure TForm2.N5Click(Sender: TObject);
var
  Index: Integer;
begin
  Index := self.ToInjectList.ItemIndex;
  if Index = -1 then exit;
  if Index = self.ToInjectList.Items.Count - 1 then exit;
  self.ToInjectList.Items.Move(Index, Index + 1);
end;

procedure TForm2.N6Click(Sender: TObject);
var
  Index: Integer;
begin
  Index := self.HistoryList.ItemIndex;
  if Index = -1 then exit;
  self.ToInjectList.Items.Add(self.HistoryList.Items[Index]);
end;

procedure TForm2.N7Click(Sender: TObject);
begin
  self.HistoryList.DeleteSelected;
end;

procedure TForm2.Panel4Click(Sender: TObject);
begin
  self.OpenDialog1.Filter := '可执行文件|*.exe';
  if self.OpenDialog1.Execute then
  begin
    self.ComboBox1.Text := self.OpenDialog1.FileName;
  end;
end;

var
  LastUpTime: DWORD;

procedure TForm2.ToInjectListMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
  AtPtr: TPoint;
begin
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

    Index := ToInjectList.ItemAtPos(AtPtr, True);
    if Index = -1 then
      self.N1Click(NIL);
  end;
end;

procedure TForm2.TrackBar1Change(Sender: TObject);
begin
  self.TrackBar1.Hint := '设置注射超时为：' + IntToStr(self.TrackBar1.Position) + ' 秒钟';
end;

end.
