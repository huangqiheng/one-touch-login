unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus, SyncObjs, DropMyRights;

type
  TForm2 = class(TForm)
    HistoryList: TListBox;
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
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    PopupMenu2: TPopupMenu;
    N6: TMenuItem;
    N7: TMenuItem;
    Button2: TButton;
    Button1: TButton;
    TrackBar1: TTrackBar;
    StaticText3: TStaticText;
    Bevel1: TBevel;
    StaticText4: TStaticText;
    Button3: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
    Procedure PackagePluginDLL;
    function InjectThemToHost: BOOL;
    function IsParamInputedValid: BOOL;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

uses MainExeINI, SmartInjectUnit, DrvRunUnit, ServiceMan, tlhelp32;

Procedure TForm2.PackagePluginDLL;
var
  Index: Integer;
  MM: TMemoryStream;
  DllName: String;
begin
  MM := TMemoryStream.Create;         

  MM.Seek(0, soFromBeginning);
  MM.LoadFromFile(self.ToInjectList.Items[0]);
  SmartInjectUnit.AddMainDLL (MM, '');

  for Index := 1 to self.ToInjectList.Count - 1 do
  begin
    DllName := self.ToInjectList.Items[Index];
    MM.Clear;
    MM.LoadFromFile(DllName);
    SmartInjectUnit.AddSubDLL (MM);
  end;

  MM.Free;
end;

function TForm2.IsParamInputedValid: BOOL;
var
  Host: String;
begin        
  Result := False;

  self.ComboBox1.Text := Trim (self.ComboBox1.Text);
  Host := self.ComboBox1.Text;

  if not FileExists (Host) then
  begin
    ShowMessage ('注射失败：目标程序不存在，请从新设置！');
    Exit;
  end;

  for Host in self.ToInjectList.Items do
  begin
    if not FileExists (Host) then
    begin
      ShowMessage ('注射失败：' + Host + '不存在，请从新设置！');
      Exit;
    end;
  end;

  Result := True;
end;

function TForm2.InjectThemToHost: BOOL;
begin
  PackagePluginDLL;
  Result := SmartInjectUnit.InjectThemALL (ComboBox1.Text, SAFER_LEVELID_CONSTRAINED, TrackBar1.Position * 1000, False);
end;

procedure TForm2.Button1Click(Sender: TObject);
var
  Index: Integer;
  ReadStr: String;
begin
  if IsParamInputedValid then
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
begin           
  Init ();
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  if EnsureDriver (False) then
    self.StatusBar1.Panels.Items[0].Text := '驱动卸载成功'
  else
    self.StatusBar1.Panels.Items[0].Text := '驱动卸载失败';
end;


const
  Start_Caption = '启动扫描';
  Stop_Caption = '停止扫描';

procedure TForm2.Button3Click(Sender: TObject);
var
  AppList: TStringList;
begin
  if self.Button3.Caption = Start_Caption then
  begin
    if IsParamInputedValid then
    begin     
      self.Button1.Enabled := False;
      self.TrackBar1.Enabled := False;
      self.StaticText4.Enabled := False;
      self.ComboBox1.Enabled := False;
      self.ToInjectList.Enabled := False;
      self.HistoryList.Enabled := False;
      self.Button2.Enabled := False;
      self.Panel4.Enabled := false;
      self.Button3.Caption := Stop_Caption;

      AppList := TStringList.Create;
      AppList.Add(self.ComboBox1.Text);

      PackagePluginDLL;
      if not ScanInjectThem (AppList, DEFAULT_INJECT_TIMEOUT) then
        self.StatusBar1.Panels.Items[0].Text := '启动扫描失败';
    end;
  end else
  begin
    self.Panel6.Enabled := False;

    self.Button1.Enabled := True;
    self.TrackBar1.Enabled := True;
    self.StaticText4.Enabled := True;
    self.ComboBox1.Enabled := True;
    self.ToInjectList.Enabled := True;
    self.HistoryList.Enabled := True;
    self.Button2.Enabled := True;
    self.Panel4.Enabled := True;
    self.Button3.Caption := Start_Caption;
    ScanInjectThem (NIL, 0);
    self.Panel6.Enabled := True;
  end;
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

  self.ComboBox1.Text := ReadConfig ('LastHost', 'Host', '');

  self.TrackBar1.Position := StrToInt (ReadConfig('Config', 'TimeOut', '10'));
  self.Left := StrToInt (ReadConfig('Config', 'Left', '20'));
  self.Top := StrToInt (ReadConfig('Config', 'Top', '30'));
  self.Width := StrToInt (ReadConfig('Config', 'Width', '463'));
  self.Height := StrToInt (ReadConfig('Config', 'Height', '412'));
  self.ToInjectList.Height := StrToInt (ReadConfig('Config', 'DllBoxHeight', '129', True));

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
  WriteConfig ('Config', 'DllBoxHeight', IntToStr (self.ToInjectList.Height), True);
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
