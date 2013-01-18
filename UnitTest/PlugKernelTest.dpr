program PlugKernelTest;

{$R '..\Injector\KPatchRC.res' '..\Injector\KPatchRC.rc'}


uses
  Forms,
  Unit5 in 'Unit5.pas' {Form2},
  PlugKernelUnit in '..\PlugIn\PlugKernelUnit.pas',
  Unit6 in 'Unit6.pas' {Form6},
  GetCodeAreaList in '..\PlugIn\GetCodeAreaList.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm6, Form6);
  Application.Run;
end.
