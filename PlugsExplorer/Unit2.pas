unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Grids, ValEdit, ComCtrls, ToolWin, Menus;

type
  TForm2 = class(TForm)
    ListBox1: TListBox;
    Panel1: TPanel;
    Splitter1: TSplitter;
    ValueListEditor1: TValueListEditor;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    PlugIns1: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    Help1: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    RestoreHistory1: TMenuItem;
    N10: TMenuItem;
    N71: TMenuItem;
    AutoDownload1: TMenuItem;
    N11: TMenuItem;
    Download1: TMenuItem;
    N12: TMenuItem;
    Run1: TMenuItem;
    RunTheSetting1: TMenuItem;
    RunforDebug1: TMenuItem;
    Splitter2: TSplitter;
    PopupMenu1: TPopupMenu;
    N13: TMenuItem;
    N14: TMenuItem;
    N15: TMenuItem;
    N16: TMenuItem;
    N17: TMenuItem;
    N18: TMenuItem;
    N19: TMenuItem;
    MoveUpSelected1: TMenuItem;
    MoveDownSelected1: TMenuItem;
    SorttheList1: TMenuItem;
    Panel3: TPanel;
    Panel4: TPanel;
    Memo1: TMemo;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    AllwaysOnTop1: TMenuItem;
    procedure AllwaysOnTop1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}



procedure TForm2.AllwaysOnTop1Click(Sender: TObject);
begin
  self.AllwaysOnTop1.Checked := not self.AllwaysOnTop1.Checked;
  if self.AllwaysOnTop1.Checked then
    self.FormStyle := fsStayOnTop
  else
    self.FormStyle := fsNormal; 
end;

end.
