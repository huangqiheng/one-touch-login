program DrvInjector;

{$R '..\Injector\KPatchRC.res' '..\Injector\KPatchRC.rc'}

uses
  Forms,
  Unit2 in 'Unit2.pas' {Form2},
  SmartInjectUnit in '..\Injector\SmartInjectUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
