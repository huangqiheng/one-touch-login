unit ModuleFuncList;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus;

type
  TApiListForm = class(TForm)
    ComboBox1: TComboBox;
    ListBox1: TListBox;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    FontDialog1: TFontDialog;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    procedure N4Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure N1Click(Sender: TObject);
  private
  public  
  end;


Procedure ClearUpModuleAndCache;  
procedure ClearCacheList;
function GetAddressForSetBreak (LibName, FuncName: String): Pointer;
function GetModuleExports (ModPath: string; ModHandle: THandle): TStringList;
function GetAimModule(): String;

function UpdateModuleLst: TStringList;
function GetModuleLst (Reflash: BOOL = False): TStringList;

implementation

{$R *.dfm}

uses DLLExports, TrapDbgLibUnit, MdiMainForm, BreakForm, CallStructForm;

var
  CacheList: TStringList;
  ModuleList: TStringList;


function GetAimModule(): String;
begin
  Result := '';
  if ModuleList.Count < 2 then exit;
  Result := Trim(ModuleList.ValueFromIndex[1]);
end;

function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

procedure ClearCacheList;
var
  Index: Integer;
  Item: TStringList;
begin
  for Index := 0 to CacheList.Count - 1 do
  begin
    Item := Pointer(CacheList.Objects[Index]);
    if Assigned (Item) then
      Item.Free;
  end;
  CacheList.Clear;
end;

Procedure ClearUpModuleAndCache;
begin
  ClearCacheList;
  ModuleList.Clear;
end;


Type
  LPTListSender = ^TListSender;
  TListSender = record
    ItemSL: TStringList;
    ModName: String;
    ModHandle: THandle;
  end;

function  ExportCallback (Sender: Pointer; const name: String; ordinal: Integer; address: Pointer): Boolean;
var
  Param: LPTListSender absolute Sender;
  PrintStr, FuncBase: String;
begin
  FuncBase := '$' + IntToHex (Param.ModHandle + dword(Address), 8);
  PrintStr := format ('%-60s %-18s %s', [name, Param.ModName, FuncBase]);
  Param.ItemSL.Add(PrintStr);
  Result := True;
end;

function IsShortPath (AimPath: String): BOOL;
var
  BPath: String;
begin
  AimPath := Trim(AimPath);
  BPath := ExtractFileName(AimPath);
  Result := Length(AimPath) = Length(BPath);
end;

function GetModuleExports (ModPath: string; ModHandle: THandle): TStringList;
var
  Index, I: Integer;
  ListSender: LPTListSender;
  AimPath: String;
begin
  Index := -1;
  if IsShortPath (ModPath) then
  begin                        
    for I := 0 to CacheList.Count - 1 do
    begin
      AimPath := CacheList[I];
      AimPath := ExtractFileName (AimPath);
      if AimPath = ModPath then
      begin
        Index := I;
        Break;
      end;
    end;
  end else
    Index := CacheList.IndexOf(ModPath);

  
  if Index = -1 then
  begin
    Result := TStringList.Create;
    New (ListSender);
    ListSender.ItemSL := Result;
    ListSender.ModName := ExtractFileName (ModPath);
    ListSender.ModHandle := ModHandle;
    Try
      ListDLLExports (ModPath, ExportCallback, Pointer(ListSender));
    Except
    end;
    CacheList.AddObject(ModPath, Pointer(Result));
    Dispose (ListSender);
  end else
  begin
    Result := Pointer(CacheList.Objects[Index]);
  end;
end;

function UpdateModuleLst: TStringList;
var
  NewSL, OldSL: TStringList;
begin
  NewSL := Cmd_GetModuleList;
  OldSL := ModuleList;

  ModuleList := NewSL;
  OldSL.Free;
  Result := ModuleList;
end;

function GetModuleLst (Reflash: BOOL = False): TStringList;
begin  
  if (ModuleList.Count = 0) or Reflash then
    UpdateModuleLst;

  Result := TStringList.Create;
  Result.AddStrings(ModuleList); 
end;


function GetAddressForSetBreak (LibName, FuncName: String): Pointer;
var
  ShortLib, ItemLib, sLibHandle, IterLine: String;
  OutValue: Int64;
  Index: Integer;
  LibHandle: THandle;
  CopyModuleList, ParamSL: TStringList;
  IsShortInput: BOOL;
  FuncList: TStrings;
begin
  Result := nil;

  CopyModuleList := GetModuleLst (True);

  if CopyModuleList.Count >= 3 then
  begin
    if FuncName[1] = '$' then
    begin
      if TryStrToInt64 (FuncName, OutValue) then
        Result := Pointer(OutValue);
    end else
    begin
      LibHandle := 0;
      LibName := Trim(LibName);
      ShortLib := ExtractFileName (LibName);
      IsShortInput := Length(ShortLib) = Length(LibName);

      for Index := 0 to CopyModuleList.Count - 1 do
      begin
        ItemLib := Trim(CopyModuleList.ValueFromIndex[Index]);
        if IsShortInput then
          ItemLib := ExtractFileName (ItemLib);

        if ItemLib = LibName then
        begin
          sLibHandle := Trim(CopyModuleList.Names[Index]);
          if TryStrToInt64 (sLibHandle, OutValue) then
          begin
            LibName := Trim(CopyModuleList.ValueFromIndex[Index]);
            LibHandle := OutValue;
            Break;
          end;
        end;
      end;

      if LibHandle > 0 then
      begin
        FuncList := GetModuleExports (LibName, LibHandle);
        if FuncList.Count > 0 then
        begin
          for IterLine in FuncList do
          begin
            ParamSL := GetSplitBlankList (IterLine);
            if ParamSL.Count = 3 then
              if ParamSL[0] = FuncName then
                if TryStrToInt64 (ParamSL[2], OutValue) then
                begin
                  Result := Pointer(OutValue);
                  Break;
                end;
            ParamSL.Free;
          end;
        end;
      end;
    end;
  end;

  CopyModuleList.Free;

  if not assigned (Result) then
  begin

  end;
end;

////////////////////////////////////
////////////////////////////////////
////////////////////////////////////


procedure TApiListForm.ComboBox1Select(Sender: TObject);
var
  Index: Integer;
  BaseAddr: String;
  ModPath: String;
  ModHandle: THandle;
  ItemSL: TStringList;
begin
  Index := self.ComboBox1.ItemIndex;
  if Index = -1 then exit;
  BaseAddr := Trim(self.ComboBox1.Items.Names[Index]);
  ModPath := Trim(self.ComboBox1.Items.ValueFromIndex[Index]);
  ModHandle := StrToInt (BaseAddr);

  self.ListBox1.Font.Pitch := fpFixed;

  if ModPath = 'AllModules' then
  begin
    self.ListBox1.Items.Clear;
    for ModPath in CacheList do
      if FileExists (ModPath) then
      begin
        ItemSL := GetModuleExports (ModPath, ModHandle);
        self.ListBox1.Items.AddStrings(ItemSL);
      end;
    Exit;
  end;              

  if FileExists (ModPath) then
  begin
    self.ListBox1.Items.Clear;
    ItemSL := GetModuleExports (ModPath, ModHandle);
    self.ListBox1.Items.AddStrings(ItemSL);
  end;
end;

procedure TApiListForm.FormShow(Sender: TObject);
begin
  N1Click(Sender);
end;

procedure TApiListForm.N1Click(Sender: TObject);
begin
  UpdateModuleLst;

  self.ComboBox1.Items.Clear;
  self.ComboBox1.Items.AddStrings(ModuleList);

  ClearCacheList;
  self.ListBox1.Clear;
end;

procedure TApiListForm.N2Click(Sender: TObject);
begin
  if self.FontDialog1.Execute then
  begin
    self.ListBox1.Font := self.FontDialog1.Font;
  end;
end;

function GetFuncDetail (Line: String; var FunName, LibName: String; var Entry: Pointer): BOOL;
var
  ValSL: TStringList;
  Val64: Int64;
begin
  Result := False;
  ValSL := GetSplitBlankList (Line);
  if ValSL.Count = 3 then
    if TryStrToInt64 (Trim (ValSL[2]), Val64) then
    begin
      FunName := Trim (ValSL[0]);
      LibName := Trim (ValSL[1]);
      Entry := Pointer (Val64);
      Result := True;
    end;
  ValSL.Free;
end;

procedure TApiListForm.N3Click(Sender: TObject);
var
  Index: Integer;
  Item:String;
  FunName, LibName: String;
  Entry: Pointer;
begin
  index := self.ListBox1.ItemIndex;
  if Index = -1 then exit;
  Item := self.ListBox1.Items[index];

  if GetFuncDetail (Item, FunName, LibName, Entry) then
    SetBreakPoint (LibName, FunName);
end;

procedure TApiListForm.N4Click(Sender: TObject);
var
  CallStruct: TCallStructureForm;
  Index: Integer;
  Item:String;
  FunName, LibName: String;
  Entry: Pointer;
begin
  index := self.ListBox1.ItemIndex;
  if Index = -1 then exit;
  Item := self.ListBox1.Items[index];

  if GetFuncDetail (Item, FunName, LibName, Entry) then
  begin
    CallStruct := MDIMain.ShowMDIChild (TCallStructureForm) as TCallStructureForm;
    CallStruct.ViewAAddress(Entry);
  end;
end;

initialization
  CacheList := TStringList.Create;
  ModuleList:= TStringList.Create;

finalization
  ClearCacheList;
  CacheList.Free;
  ModuleList.Free;

end.
