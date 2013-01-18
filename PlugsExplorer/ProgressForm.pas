unit ProgressForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls;

type
  TForm3 = class(TForm)
    ProgressBar1: TProgressBar;
    StaticText1: TStaticText;
    Panel1: TPanel;
    StaticText2: TStaticText;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure Panel3Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private

  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

const
 sc_DragMove:longint=$F012;


procedure TForm3.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  self.Perform(wm_SysCommand, sc_DragMove,0);
end;



procedure TForm3.Panel3Click(Sender: TObject);
begin
  Close;
end;

end.
