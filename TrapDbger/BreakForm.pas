unit BreakForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, ExtCtrls, Grids, ValEdit, StdCtrls;

type
  TBreakPointLstForm = class(TForm)
    Panel1: TPanel;
    StaticText1: TStaticText;
    ListBox1: TListBox;
    Panel2: TPanel;
    StaticText2: TStaticText;
    ListBox2: TListBox;
    Panel3: TPanel;
    StaticText3: TStaticText;
    ListBox3: TListBox;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    procedure ListBox3DblClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
  end;

Function SetBreakPoint (Address: Pointer): BOOL; Overload;
Function SetBreakPoint (LibName, FuncName: String): BOOL; Overload;

Procedure OnStandbyEvent (hTrap: THandle; BreakAddr: Pointer);
Procedure OnActiveEvent (hTrap: THandle);
Procedure OnDeActiveEvent (hTrap: THandle);
Procedure OnDbgAimReset;

implementation

uses TrapDbgLibUnit, ModuleFuncList, MdiMainForm, MainExeIni, DbgInfoForm;

{$R *.dfm}

var
  RecentBSL: TStringList;
  StandByBSL: TStringList;
  WorkingBSL: TStringList;

  
procedure TBreakPointLstForm.FormActivate(Sender: TObject);
begin
  self.ListBox3.Clear;
  if RecentBSL.Count > 0 then
    self.ListBox3.Items.AddStrings (RecentBSL);

  self.ListBox2.Clear;
  if StandByBSL.Count > 0 then
    self.ListBox2.Items.AddStrings (StandByBSL);

  self.ListBox1.Clear;
  if WorkingBSL.Count > 0 then
    self.ListBox1.Items.AddStrings (WorkingBSL);
end;

Procedure OnStandbyEvent (hTrap: THandle; BreakAddr: Pointer);
var
  Index: Integer;
  Title: String;
begin
  Index := RecentBSL.IndexOfObject(Pointer(hTrap));
  if Index = -1 then
  begin
    Title := ExtractFileName (GetAimModule);
    Title := Format ('$%p - %s', [BreakAddr, Title]);
  end else
    Title := RecentBSL[Index];

  StandByBSL.InsertObject(0, Title, Pointer(hTrap));
end;

Procedure OnActiveEvent (hTrap: THandle);
var
  Index: Integer;
  Title: String;
begin
  Index := StandByBSL.IndexOfObject(Pointer(hTrap));
  if Index >= 0 then
  begin
    Title := StandByBSL[Index];
    StandByBSL.Delete(Index);
    if WorkingBSL.IndexOf(Title) = -1 then
      WorkingBSL.InsertObject(0, Title, Pointer(hTrap));
  end;
end;

Procedure OnDbgAimReset;
begin
  WorkingBSL.Clear;
  StandByBSL.Clear;
end;

Procedure OnDeActiveEvent (hTrap: THandle);
var
  Index: Integer;
begin
  Index := WorkingBSL.IndexOfObject(Pointer(hTrap));
  if Index >= 0 then
    WorkingBSL.Delete(Index);

  Index := StandByBSL.IndexOfObject(Pointer(hTrap));
  if Index >= 0 then
    StandByBSL.Delete(Index);
end;
           
Function SetBreakPoint (Address: Pointer): BOOL;
var
  PrintTitle: String;
  hTrap: THandle;
  Index: Integer;
begin
  Result := false;
  if Address = nil then exit;
  hTrap := Cmd_TrapDbgSetup (Address, False);
  Result := hTrap > 0;

  if Result then
  begin
    PrintTitle := ExtractFileName (GetAimModule);
    PrintTitle := Format ('$%p - %s', [Address, PrintTitle]);
    Index := RecentBSL.IndexOf(PrintTitle);

    if Index = -1 then
    begin
      RecentBSL.InsertObject (0, PrintTitle, Pointer(hTrap));
    end else   
    begin
      RecentBSL.Objects[Index] := Pointer(hTrap);
      if Index > 0 then
        RecentBSL.Move(Index, 0);
    end;
  end;
end;

Function SetBreakPoint (LibName, FuncName: String): BOOL;
var
  Address: Pointer;
  PrintTitle: String;
  hTrap: THandle;
  Index: Integer;
begin
  Result := false;
  Address := GetAddressForSetBreak (LibName, FuncName);
  if Address = nil then exit;
  hTrap := Cmd_TrapDbgSetup (Address, False);
  Result := hTrap > 0;

  if Result then
  begin
    PrintTitle := Format ('%s - %s', [FuncName, LibName]);
    Index := RecentBSL.IndexOf(PrintTitle);

    if Index = -1 then
    begin
      RecentBSL.InsertObject (0, PrintTitle, Pointer(hTrap));
    end else   
    begin
      RecentBSL.Objects[Index] := Pointer(hTrap);
      if Index > 0 then
        RecentBSL.Move(Index, 0);
    end;
  end else
  begin
    DbgPrinter ('Cmd_TrapDbgSetup Error£º%s - %s', [LibName, FuncName]);
  end;
end;

const
  RECENT_BREAK =  'RecentBreak';



procedure TBreakPointLstForm.FormCreate(Sender: TObject);
var
  RecentSL: TStringList;
  Index: Integer;
  Title: String;
begin
  RecentSL := ReadSectionValues (RECENT_BREAK, True);
  for Index := RecentSL.Count - 1 downto 0 do
  begin
    Title := RecentSL.ValueFromIndex[Index];
    if RecentBSL.IndexOf(Title) = -1 then
      RecentBSL.Add (Title);
  end;
  RecentSL.Free;  
end;

procedure TBreakPointLstForm.FormDestroy(Sender: TObject);
var
  Index: Integer;
begin
  EraseSection (RECENT_BREAK);
  for Index := 0 to RecentBSL.Count - 1 do
  begin
    if Index = 50 then Break;
    WriteConfig (RECENT_BREAK, IntToStr(Index), RecentBSL[Index]);
  end;         
end;

function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

procedure TBreakPointLstForm.ListBox3DblClick(Sender: TObject);
var
  Index: Integer;
  line: string;
  GotSL: TStringList;
  FuncName, LibName: String;
begin
  Index := self.ListBox3.ItemIndex;
  if Index = -1 then exit;
  line := self.ListBox3.Items[index];

  GotSL := GetSplitBlankList (line, ['-']);
  if GotSL.Count = 2 then
  begin
    FuncName := Trim(GotSL[0]);
    LibName := Trim(GotSL[1]);
    
    SetBreakPoint (LibName, FuncName);
  end else
    self.ListBox3.Items.Delete(Index);
  GotSL.Free;
end;

initialization
RecentBSL := TStringList.Create;
StandByBSL := TStringList.Create;
WorkingBSL := TStringList.Create;

finalization

RecentBSL.Free;
StandByBSL.Free;
WorkingBSL.Free;


end.
