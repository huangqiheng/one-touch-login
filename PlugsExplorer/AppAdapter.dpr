program AppAdapter;

{$R 'PluginLib.res' 'PluginLib.rc'}

uses
  Forms,
  SysUtils,
  DLLLoader,
  MainForm in 'MainForm.pas' {MainManage},
  AddFormUnit in 'AddFormUnit.pas' {AddConfigForm},
  PerpertyForm in 'PerpertyForm.pas' {PropertyForm},
  HandlerUnit in 'HandlerUnit.pas' {DataModuleBase: TDataModule};

{$R *.res}


begin
  Application.Initialize;

  Application.CreateForm(TDataModuleBase, DataModule);
  Application.CreateForm(TMainManage, MainManage);
  Application.CreateForm(TPropertyForm, PropertyForm);
  Application.CreateForm(TAddConfigForm, AddConfigForm);
  Application.Run;

end.
