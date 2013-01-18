unit PlugParaForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Grids, ValEdit, StdCtrls, IniFiles, Menus, MdiMainForm;

type
  TSetParamForm = class(TForm)
    ValueListEditor1: TValueListEditor;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    PopupMenu1: TPopupMenu;
    procedure FormDestroy(Sender: TObject);
    procedure ValueListEditor1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure Button2Click(Sender: TObject);
  private
    FPluginFile: String;
    FPluginIniFile: String;
    FPluginCfgFile: String;
    MemIni: TMemIniFile;
    ResultSL: TStringList;
    procedure OptionPopClick(Sender: TObject);
    procedure OnPopItemClick(Sender: TObject);
    procedure OnChoosePeFile(Sender: TObject);
  public
    function InitPlugin (FileName: String): BOOL;
    procedure ReadSystems(ConfigSL: TStrings);
    procedure ReadInputs(ConfigSL: TStrings);
  end;

const
  Def_AppPath = '����·��';
  Def_MainPlugin = '�����';
  Def_DbgAim = 'DbgAim';

implementation

uses DbgInfoForm, PlugKernelLib;

{$R *.dfm}

Const
  Def_Browser = 2;
  Def_Select = 1;


Procedure SLMoveToFirst (SL: TStrings; Name: String);
var
  Index: Integer;
begin
  Index := SL.IndexOfName(Name);
  if Index > 0 then
    SL.Move(Index, 0);
end;


procedure TSetParamForm.FormDestroy(Sender: TObject);
begin
  if Assigned (ResultSL) then
    ResultSL.Free;
  if Assigned (MemIni) then
    MemIni.Free;
end;

procedure TSetParamForm.ReadSystems(ConfigSL: TStrings);
var
  GetSL: TStringList;
begin
  if not Assigned (MemIni) then exit;
  GetSL := TStringList.Create;
  MemIni.ReadSectionValues(INI_SECTION_SYSTEM, GetSL);
  ConfigSL.AddStrings(GetSL);
  GetSL.Free;
end;

procedure TSetParamForm.ReadInputs(ConfigSL: TStrings);
begin
  if not Assigned (ResultSL) then exit;
  ConfigSL.AddStrings(ResultSL);
end;

function TSetParamForm.InitPlugin (FileName: String): BOOL;
var
  Index: Integer;
  KeyStr, ValStr, TypeStr: String;
  LastSL, ReadSL: TStringList;
begin
  Result := False;
  FPluginFile := FileName;
  FPluginIniFile := ChangeFileExt (FPluginFile, '.ini');
  FPluginCfgFile := ChangeFileExt (FPluginFile, '.def');

  if Assigned (MemIni) then
    FreeAndNil (MemIni);

  if not FileExists (FPluginFile) then
  begin
    ShowMessage ('��ѡ��ĵ���Ŀ�겻���ڡ�');
    Exit;
  end;

  if not FileExists (FPluginIniFile) then
  begin
    ShowMessage ('��ѡ����ԵĲ����ȱ�������ļ������顣');
    Exit;
  end;

  //�����������ļ�inputֵ, ͬʱ���ñ�־���Ƿ���ѡ����û�ѡ��
  MemIni := TMemIniFile.Create (FPluginIniFile);

  //����ǿ����������
  TypeStr := MemIni.ReadString(INI_SECTION_SYSTEM, INI_KEY_TYPE, '');
  if TypeStr = TYPE_NAME_PLUGLIB then
  begin
    self.ValueListEditor1.Strings.AddObject(Def_MainPlugin + '=' + MdiMain.FPlugPath+ 'Empty.dll', Pointer(Def_Browser));
    self.Caption := '��Ҫ���Ե��ǡ��������������������';
  end else
  if TypeStr = TYPE_NAME_PLUGIN then
  begin
    self.Caption := '��Ҫ���Ե��ǡ���������������������';
  end else
  begin
    ShowMessage ('��ѡ����ԵĲ���������ļ�����');
    Exit;
  end;

  ReadSL := TStringList.Create;
  MemIni.ReadSectionValues(INI_SECTION_INPUT, ReadSL);
  for Index := 0 to ReadSL.Count - 1 do
  begin
    KeyStr := ReadSL.Names[Index];
    ValStr := Trim(ReadSL.ValueFromIndex [Index]);
    if Length (ValStr) > 0 then
      self.ValueListEditor1.Strings.AddObject(KeyStr + '=', Pointer(Def_Select))
    else
      self.ValueListEditor1.Strings.Add(KeyStr + '=');
  end;
  ReadSL.Free;

  //�鿴�Ƿ����ϴ�ʹ�õ������ļ�����ֵ
  if FileExists (FPluginCfgFile) then
  begin
    LastSL := TStringList.Create;
    LastSL.LoadFromFile(FPluginCfgFile);
    for Index := 0 to LastSL.Count - 1 do
      self.ValueListEditor1.Strings.Values[LastSL.Names[Index]] := LastSL.ValueFromIndex[Index];
    LastSL.Free;
  end;

  //�鿴������·���������ñ�־
  Index := self.ValueListEditor1.Strings.IndexOfName(Def_AppPath);
  if Index = -1 then
    self.ValueListEditor1.Strings.AddObject(Def_AppPath + '=', Pointer(Def_Browser))
  else
    self.ValueListEditor1.Strings.Objects[Index] := Pointer(Def_Browser);

  //�����������־
  Index := self.ValueListEditor1.Strings.IndexOfName(Def_MainPlugin);
  if Index >= 0 then
    self.ValueListEditor1.Strings.Objects[Index] := Pointer(Def_Browser);

  //����
  SLMoveToFirst (self.ValueListEditor1.Strings, Def_AppPath);
  Result := True;
end;


function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

procedure TSetParamForm.OnChoosePeFile(Sender: TObject);
var
  Index: Integer;
  KeyStr: String;
begin
  Index := TComponent(Sender).Tag;
  KeyStr := self.ValueListEditor1.Strings.Names[Index];

  if KeyStr = Def_AppPath then
  begin
    self.OpenDialog1.Filter := '��ִ�г���|*.exe';
    if self.OpenDialog1.Execute then
      self.ValueListEditor1.Strings.Values[Def_AppPath] := self.OpenDialog1.FileName;
  end else
  if KeyStr = Def_MainPlugin then
  begin
    self.OpenDialog1.Filter := '�����DLL|*.dll';
    if self.OpenDialog1.Execute then
      self.ValueListEditor1.Strings.Values[Def_MainPlugin] := self.OpenDialog1.FileName;
  end;
end;

procedure TSetParamForm.OnPopItemClick(Sender: TObject);
var
  Item: TmenuItem absolute Sender;
  Index: Integer;
begin
  Index := Item.Tag;
  self.ValueListEditor1.Strings.ValueFromIndex[Index] := StripHotkey(Item.Caption);  
end;

procedure TSetParamForm.OptionPopClick(Sender: TObject);
var
  Index: Integer;
  ValStr, KeyStr: String;
  ItemSL: TStringList;
  Item: TmenuItem;
  BeClick: TButton absolute Sender;
begin
  Index := TComponent(Sender).Tag;
  KeyStr := self.ValueListEditor1.Strings.Names[Index];

  ValStr := MemIni.ReadString(INI_SECTION_INPUT, KeyStr, '');
  if Length(ValStr) > 0 then
  begin
    ItemSL := GetSplitBlankList (ValStr, [',']);
    self.PopupMenu1.Items.Clear;
    for KeyStr in ItemSL do
    begin
      Item := TmenuItem.Create(Self);
      Item.OnClick := OnPopItemClick;
      Item.Caption := KeyStr;
      Item.Tag := BeClick.Tag;
      self.PopupMenu1.Items.Add(Item);
    end;
    ItemSL.Free;

    self.PopupMenu1.Popup(BeClick.ClientOrigin.X + BeClick.Width, BeClick.ClientOrigin.Y + BeClick.Height);
  end;
end;

procedure TSetParamForm.ValueListEditor1DrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  StoreKey: Integer;
  DynButton: TButton;
  Offset: Integer;
begin
  if ACol <> 0 then Exit;
  if ARow = 0 then Exit;

  Offset := self.BevelWidth + self.ValueListEditor1.GridLineWidth;                  
  StoreKey := Integer(self.ValueListEditor1.Strings.Objects[ARow - 1]);
  if StoreKey = 0 then Exit;

  //��һ�δ���
  if StoreKey = Def_Select then
  begin                 
    DynButton := TButton.Create(self);
    DynButton.Parent := self;
    DynButton.OnClick := OptionPopClick;
    DynButton.BringToFront;
    DynButton.Caption := 'ѡ��';
    DynButton.Tag := ARow - 1;
    self.ValueListEditor1.Strings.Objects[ARow - 1] := DynButton;
  end else
  if StoreKey = Def_Browser then
  begin
    DynButton := TButton.Create(self);
    DynButton.Parent := self;
    DynButton.OnClick := OnChoosePeFile;
    DynButton.BringToFront;
    DynButton.Caption := '���';
    DynButton.Tag := ARow - 1;
    self.ValueListEditor1.Strings.Objects[ARow - 1] := DynButton;
  end else
  begin
    DynButton := Pointer(self.ValueListEditor1.Strings.Objects[ARow - 1]);
  end;

  DynButton.Top := Offset + Rect.Top;
  DynButton.Left := Offset + Rect.Right - 30;
  DynButton.Width := 30;
  DynButton.Height := Rect.Bottom - Rect.Top;
end;

function GetRelatPath (BasePath, FileName: String): String;
begin
  if Length(FileName) >  Length(BasePath) then
    Result := Copy(FileName, Length(BasePath) + 1, Length(FileName));
end;

procedure TSetParamForm.Button2Click(Sender: TObject);
var
  AppPath: String;
  TypeStr, ValStr: String;
begin
  AppPath := self.ValueListEditor1.Values[Def_AppPath];
  if not FileExists (AppPath) then
  begin
    ShowMessage ('Ŀ����򲻴��ڣ����飡');
    Exit;
  end;

  self.ValueListEditor1.Strings.SaveToFile(FPluginCfgFile);

  ResultSL := TStringList.Create;
  ResultSL.AddStrings(self.ValueListEditor1.Strings);
  TypeStr := MemIni.ReadString(INI_SECTION_SYSTEM, INI_KEY_TYPE, '');

  if TypeStr = TYPE_NAME_PLUGIN then
  begin
    ResultSL.Values[INI_KEY_PLUGIN] := self.FPluginFile;
  end else
  begin
    ResultSL.Values[INI_KEY_PLUGIN] := self.ValueListEditor1.Strings.Values[Def_MainPlugin];

    ValStr := self.ValueListEditor1.Strings.Values[INI_KEY_PLUGLIBS];
    if Trim(ValStr) = '' then
      ValStr := GetRelatPath(MdiMain.FPlugPath, FPluginFile)
    else
      ValStr := ValStr + ',' + GetRelatPath(MdiMain.FPlugPath, FPluginFile);
    ResultSL.Values[INI_KEY_PLUGLIBS] := ValStr;
  end;

  ResultSL.Values[Def_DbgAim] := self.FPluginFile;
end;

end.
