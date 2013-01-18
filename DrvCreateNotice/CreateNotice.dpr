program CreateNotice;

{$R '..\Injector\KPatchRC.res' '..\Injector\KPatchRC.rc'}

uses
  Forms,
  Unit3 in 'Unit3.pas' {Form3},
  UMPE in '..\ShareUnit\UMPE.pas',
  DrvRunUnit in '..\Injector\DrvRunUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
