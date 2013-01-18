unit ModifyFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Grids, ValEdit, StdCtrls, ComCtrls, ToolWin;

type
  TModifyConfigForm = class(TForm)
    ValueListEditor1: TValueListEditor;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton6Click(Sender: TObject);
  private
    { Private declarations }
  public
    ConfigID: String;
    IsNeedSave: BOOL;
  end;

var
  ModifyConfigForm: TModifyConfigForm;

implementation

uses DataUnit;

{$R *.dfm}


procedure TModifyConfigForm.FormCreate(Sender: TObject);
begin
  IsNeedSave := False;
end;

procedure TModifyConfigForm.FormDestroy(Sender: TObject);
begin
  if IsNeedSave then
  begin
    DCM.SaveToFile();
  end;
end;

procedure TModifyConfigForm.FormShow(Sender: TObject);
begin
  self.ToolButton3Click(nil);
end;

procedure TModifyConfigForm.ToolButton1Click(Sender: TObject);
begin
  if DCM.ModifyConfig(ConfigID, ValueListEditor1) then
  begin
    IsNeedSave := True;
  end else
    ShowMessage ('–ﬁ∏ƒ≈‰÷√ ß∞‹£¨«ÎºÏ≤È ‰»Î≤Œ ˝');
  Close;
end;

procedure TModifyConfigForm.ToolButton3Click(Sender: TObject);
begin
  DCM.ViewConfig(ConfigID, ValueListEditor1);
end;

procedure TModifyConfigForm.ToolButton5Click(Sender: TObject);
var
  AppExe, PluginName: String;
  HelpTxt, SaveName: String;
begin
  if DCM.GetPluginFromConfigID (ConfigID, AppExe, PluginName) then
  begin
    SaveName := ChangeFileExt (PluginName, '.hlp.txt');
    SaveName := DCM.TempPath + SaveName;

    if not FileExists (SaveName) then
    begin
      HelpTxt := DCM.GetPluginHelp (PluginName);
      with TStringList.Create do
      try
        Text := HelpTxt;
        SaveToFile (SaveName);
      finally
        Free;
      end;
    end;

    WinExec (PChar('Notepad.exe "' + SaveName + '"'), SW_SHOW);
  end;
end;

procedure TModifyConfigForm.ToolButton6Click(Sender: TObject);
begin
  Close;
end;

end.
