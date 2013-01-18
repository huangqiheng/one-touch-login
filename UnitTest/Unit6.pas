unit Unit6;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Menus, TDBinTre;

type
  TForm6 = class(TForm)
    ListBox2: TListBox;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Panel1: TPanel;
    ListBox4: TListBox;
    Splitter3: TSplitter;
    Panel2: TPanel;
    Splitter4: TSplitter;
    ListBox1: TListBox;
    ListBox5: TListBox;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    Panel3: TPanel;
    StaticText3: TStaticText;
    ListBox3: TListBox;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox2Click(Sender: TObject);
    procedure ListBox2DblClick(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
  private

  public
    procedure ViewANode (Node: Pointer);
    procedure PrintCount;
  end;

var
  Form6: TForm6;

 
var
  NodeList: TList;

implementation

{$R *.dfm}

uses madDisAsm, GetCodeAreaList, FindAddress;


function GetAddrByLineItem (Line: String): Pointer;
var
  Val64: Int64;
  Index: Integer;
begin
  Result := nil;
  Index := Pos('$',Line);
  Line := Copy(Line, Index, Length(line) - Index + 1);
  SetLength (Line, 9);

  if TryStrToInt64 (Line, Val64) then
    Result := Pointer(Val64);
end;

procedure TForm6.ListBox1Click(Sender: TObject);
var
  Index: Integer;
  Line, DisAsm: String;
  CallTo: Pointer;
  FNode: LPTFuncNode;
begin
  if NodeList = nil then exit;

  self.ListBox5.Items.Clear;
  Index := self.ListBox1.ItemIndex;
  if Index = -1 then exit;

  Line := self.ListBox1.Items[Index]; 
  CallTo := GetAddrByLineItem (Line);
  if CallTo = nil then exit;
  
  FNode := FindNodeByAddress (NodeList, CallTo);
  if Assigned (FNode) then
  begin
    ParseFunction (FNode.EntryPoint, DisAsm);
    self.ListBox5.Items.Text := DisAsm;
  end;                       
end;

procedure TForm6.ListBox1DblClick(Sender: TObject);
var
  Index: Integer;
  Line: String;
  CallFrom: Pointer;
  FNode: LPTFuncNode;
begin
  if NodeList = nil then exit;
  Index := self.ListBox1.ItemIndex;
  if Index = -1 then exit;

  Line := self.ListBox1.Items[Index];
  CallFrom := GetAddrByLineItem (Line);
  if CallFrom = nil then exit;

  FNode := FindNodeByAddress (NodeList, CallFrom);
  if Assigned (FNode) then
    ViewANode (FNode);
end;

procedure TForm6.ListBox2Click(Sender: TObject);
var
  Index: Integer;
  Line, DisAsm: String;
  CallTo: Pointer;
  FNode: LPTFuncNode;
begin
  if NodeList = nil then exit;
  Index := self.ListBox2.ItemIndex;
  if Index = -1 then exit;

  Line := self.ListBox2.Items[Index];
  CallTo := GetAddrByLineItem (Line);
  if CallTo = nil then exit;

  FNode := FindNodeByEntry (NodeList, CallTo);
  if Assigned (FNode) then
  begin
    ParseFunction (FNode.EntryPoint, DisAsm);
    self.ListBox4.Items.Text := DisAsm;
  end;           
end;

procedure TForm6.ListBox2DblClick(Sender: TObject);
var
  Index: Integer;
  Line: String;
  CallTo: Pointer;
  FNode: LPTFuncNode;
begin
  if NodeList = nil then exit;
  Index := self.ListBox2.ItemIndex;
  if Index = -1 then exit;

  Line := self.ListBox2.Items[Index];
  CallTo := GetAddrByLineItem (Line);
  if CallTo = nil then exit;

  FNode := FindNodeByEntry (NodeList, CallTo);
  if Assigned (FNode) then
    ViewANode (FNode);
end;

function ExtractLibName (ModHandle: THandle): String;
begin
  Result := ExtractFileName(GetModuleName (ModHandle));
  SetLength (Result, Length(Result) - Length(ExtractFileExt(Result)));
end;

procedure TForm6.ViewANode (Node: Pointer);
var
  FNode: LPTFuncNode absolute Node;
  ScanNode: LPTFuncNode;
  Item: Pointer;
  ModuleName, DisAsm: String;
  ModHandle: THandle;
begin
  if NodeList = nil then exit;
  self.ListBox1.Clear;
  for Item in FNode.CallFroms do
  begin
    ScanNode := FindNodeByAddress (NodeList, Item);
    if Assigned (ScanNode) then
    begin
      ModHandle := ScanNode.Module;
    end else
      ModHandle := THandle (GetImageBase(Item));

    ModuleName := ExtractLibName(ModHandle);
    self.ListBox1.Items.Add(ModuleName + '.$'+IntToHex(DWORD(Item), 8));
  end;

  ParseFunction (FNode.EntryPoint, DisAsm);
  self.ListBox3.Items.Text := DisAsm;
  self.StaticText3.Caption := ExtractFileName(GetModuleName (FNode.Module));

  self.ListBox2.Clear;
  for Item in FNode.CallToTarget do
  begin
    ScanNode := FindNodeByEntry (NodeList, Item);
    if Assigned (ScanNode) then
    begin
      ModHandle := ScanNode.Module;
    end else
      ModHandle := THandle (GetImageBase(Item));

    ModuleName := ExtractLibName(ModHandle);
    self.ListBox2.Items.Add(ModuleName + '.$'+IntToHex(DWORD(Item), 8));
  end;
end;


procedure TForm6.N2Click(Sender: TObject);
var
  Input: String;
  Address: Pointer;
  FNode: LPTFuncNode;
  OutVal: Int64;
begin
  if NodeList = nil then exit;
  Input := InputBox ('请输入一个要显示的函数地址', '十六进制地址：', '');
  if Input <> '' then
  begin
    if Input[1] <> '$' then
      Input := '$' + Input;
    if TryStrToInt64 (Input, OutVal) then
    begin
      Address := Pointer(OutVal);
      FNode := AddNodeToList (NodeList, nil, Address);
      if Assigned (FNode) then
        ViewANode (FNode);
      PrintCount;
    end;
  end;
end;


procedure TForm6.PrintCount;
begin
  Caption := 'Total functions : ' + IntToStr(NodeList.Count); 
end;


function IsImmediateReloc (RelocAddr: Pointer; RelocVal: Pointer): BOOL;
var
  imLen, imVal: integer;
  Count: Integer;
begin
  Result := False;
  Count := 0;
  Repeat
    Dec(DWORD(RelocAddr));
    if ParseCode (RelocAddr, imLen, imVal).IsValid then
    begin
      if imLen = 4 then
      if imVal = Integer(RelocVal) then
      begin
        Result := True;
        Exit;
      end;
    end;
    Inc(Count);
  until Count = 6;
end;

Type
  LPTSenderLst = ^TSenderLst;
  TSenderLst = record
    OkList: TList;
    NoList: TList;
  end;

procedure TForm6.Button1Click(Sender: TObject);
var
  FNode: LPTFuncNode;
  Tick: DWORD;
  LibHandle: THandle;
  FlatNodeLst: LPTFlatNodeLst;
begin
  LIbHandle := LoadLibrary (Kernel32);
  Tick := GetTickCount;
  FNode := AddImageNodeToList (NodeList, 0);
  ViewANode (FNode);
  Tick := GetTickCount - Tick;
  PrintCount;
  Caption := Caption  + ' - ' + IntToStr(Tick);

  FlatNodeLst := ExtractFlatData (NodeList);
  ClearNodeList (NodeList);
  LoadFromFlatData (NodeList, FlatNodeLst);   
  Caption := Caption  + ' - ' + IntToStr(NodeList.Count);
  FreeMem (FlatNodeLst);
end;

var
  LonelyEntry: TList;
  Index: Integer;

procedure TForm6.Button2Click(Sender: TObject);
var
  FNode: LPTFuncNode;

begin
  if NodeList = nil then exit;
  self.ListBox5.Clear;

  if Assigned (LonelyEntry) then
  begin
    if Index < LonelyEntry.Count then
    begin
      FNode := LonelyEntry[Index];
      self.ViewANode(FNode);
    end;
    Inc (Index);
    Exit;
  end;

  LonelyEntry := TList.Create;
  for FNode in NodeList do
    if FNode.CallToTarget.Count = 0 then
      if FNode.CallFroms.Count = 0 then
          LonelyEntry.Add(FNode);

  self.ListBox5.Items.Add ('LonelyEntry Count = ' + IntToStr( LonelyEntry.Count));

end;

var
  OkEntryLst: TList;
  EntryIndex: Integer;

procedure TForm6.Button3Click(Sender: TObject);
var
  FNode: LPTFuncNode;
begin
  if NodeList = nil then exit;
  self.ListBox5.Clear;

  if Assigned (OkEntryLst) then
  begin
    if EntryIndex < OkEntryLst.Count then
    begin
      FNode := OkEntryLst[EntryIndex];
      self.ViewANode(FNode);
    end;
    Inc (EntryIndex);
    Exit;
  end;

  OkEntryLst := TList.Create;
  for FNode in NodeList do
    if FNode.CallFroms.Count = 0 then
      if FNode.CallToTarget.Count > 0 then
        OkEntryLst.Add(FNode);

  self.ListBox5.Items.Add ('OkEntryLst Count = ' + IntToStr( OkEntryLst.Count));

end;



procedure TForm6.Button4Click(Sender: TObject);
var
  FNode: LPTFuncNode;
  List: TList;
begin
  if NodeList = nil then exit;
  List := Tlist.Create;
  self.ListBox5.Clear;
  for FNode in NodeList do
    if FNode.CallFroms.Count = 0 then
    if FNode.CallToTarget.Count = 0 then
        List.Add(FNode);

  self.ListBox5.Items.Add ('1Area Count = ' + IntToStr( List.Count));

  List.Free;
end;

procedure TForm6.FormCreate(Sender: TObject);
begin
  NodeList := Tlist.Create;
end;

procedure TForm6.FormDestroy(Sender: TObject);
begin
  ClearNodeList (NodeList);
  NodeList.Free;
end;

end.
