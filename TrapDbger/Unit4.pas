unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, Menus, ActnList;

type
  TMDIMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Edit1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Break1: TMenuItem;
    N4: TMenuItem;
    Set1: TMenuItem;
    N5: TMenuItem;
    ActionList1: TActionList;
    File_OpenAimExe: TAction;
    File_CloseAimExe: TAction;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    File_CloseApp: TAction;
    N9: TMenuItem;
    procedure N3Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure CreateMDIChild(frm : TFormClass);
  end;

var
  MDIMain: TMDIMain;

implementation

uses BreakForm, MemExplorerForm, PlugKernelLib;

{$R *.dfm}

procedure CreateBreakForm;
var
  BreakPointForm: TBreakPointForm;
begin
  Application.CreateForm(TBreakPointForm, BreakPointForm);
end;


procedure TMDIMain.N3Click(Sender: TObject);
begin
  CreateMDIChild (TMemExplorer);
end;

procedure TMDIMain.CreateMDIChild(frm : TFormClass);
var
  i:integer;
  Aim:TForm;
begin
  Aim:=NIL;
  for i:= 0 to Self.MDIChildCount-1 do
  begin
    if Self.MDIChildren[i] is frm then
    begin
      Aim:=Self.MDIChildren[i] as frm ;
      Break;
    end;
  end;

  if Assigned (Aim) then
  begin
    Aim.Perform(wm_SysCommand, SC_RESTORE, 0);
    Aim.Show;
  end else
  begin
    frm.Create(Application);
  end;
end;


end.
