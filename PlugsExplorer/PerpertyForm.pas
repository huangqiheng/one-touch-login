unit PerpertyForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, Grids, ValEdit, ExtCtrls, ImgList;

type
  TPropertyForm = class(TForm)
    ValueListEditor1: TValueListEditor;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton3: TToolButton;
    ToolButton5: TToolButton;
    ToolButton9: TToolButton;
    ToolButton7: TToolButton;
    ToolButton2: TToolButton;
    ToolButton4: TToolButton;
    ImageList1: TImageList;
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
    procedure ToolButton9Click(Sender: TObject);
    procedure ToolButton7Click(Sender: TObject);
  private
    { Private declarations }
  public
    AimIndexA, AimIndexB: Integer;
    FPlugFile: String;
    Procedure ResetPosition (LeftPosition, RightPosition: TPoint);
  end;

var
  PropertyForm: TPropertyForm;

implementation

uses MainForm, HandlerUnit, PlugKernelLib;

{$R *.dfm}

Procedure TPropertyForm.ResetPosition (LeftPosition, RightPosition: TPoint);
var
  Index: Integer;
  TotalHeigh: Integer;
begin
  TotalHeigh := 0;
  for Index := 0 to self.ValueListEditor1.RowCount - 1 do
    Inc (TotalHeigh, self.ValueListEditor1.RowHeights[Index]);

  Inc (TotalHeigh, self.ValueListEditor1.GridLineWidth * (self.ValueListEditor1.RowCount+1));

  ClientHeight := ToolBar1.Height + TotalHeigh;

  if LeftPosition.X - self.Width > 0 then
  begin
    self.Left := LeftPosition.X - self.Width;
  end else
  begin
    self.Left := RightPosition.X;
  end;

  self.Top := LeftPosition.Y;
end;

procedure TPropertyForm.ToolButton1Click(Sender: TObject);
var
  Name: String;
begin
  Name := Trim(ValueListEditor1.Strings.Values['Name']);
  if Trim(Name) = '' then
  begin
    ShowMessage ('Name字段不能为空，请重填');
    Exit;
  end;

  if DataModule.SaveConfigItem(AimIndexA, AimIndexB, self.ValueListEditor1.Strings) then
  begin                                               
  end else
    ShowMessage ('添加配置失败，请检查输入参数');

  MainManage.ConfigReflashClick(Sender);
  self.ValueListEditor1.Strings.Clear;
  DataModule.ReadConfigItem(AimIndexA, AimIndexB, self.ValueListEditor1.Strings);
end;

procedure TPropertyForm.ToolButton3Click(Sender: TObject);
begin
  ValueListEditor1.Strings.Clear;
  DataModule.ReadConfigItem(AimIndexA, AimIndexB, ValueListEditor1.Strings);
end;

procedure TPropertyForm.ToolButton5Click(Sender: TObject);
begin
  if DataModule.DeleteConfigItem(AimIndexA, AimIndexB) then
    MainManage.ConfigReflashClick(Sender);
  Close;
end;

procedure TPropertyForm.ToolButton7Click(Sender: TObject);
var
  CfgSL: TStringList;
begin
  CfgSL := DataModule.ReadConfigItem (AimIndexA, AimIndexB);
  if CfgSL.Count > 0 then
    MainManage.StartTheTask (FPlugFile, CfgSL, RUN_MODE_NORMAL);
  CfgSL.Free;
  Close;
end;
              

procedure TPropertyForm.ToolButton9Click(Sender: TObject);
var
  CfgSL: TStringList;
begin
  CfgSL := DataModule.ReadConfigItem (AimIndexA, AimIndexB);
  if CfgSL.Count > 0 then
    MainManage.StartTheTask (FPlugFile, CfgSL, RUN_MODE_NORMAL);
  CfgSL.Free;       
  Close;
end;

end.
