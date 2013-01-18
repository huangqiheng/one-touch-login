unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, ValEdit, ExtCtrls;

type
  TForm1 = class(TForm)
    ValueListEditor1: TValueListEditor;
    Button1: TButton;
    Panel1: TPanel;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    FPlugFile: String;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  self.OpenDialog1.Title := '请选择插件DLL文件';
  self.OpenDialog1.Filter := '插件DLL [*.dll]|*.dll';
  if not self.OpenDialog1.Execute then Exit;
  FPlugFile := self.OpenDialog1.FileName;





end;

end.
