program LoginDaemonTest;

uses
  Forms,
  Unit4 in 'Unit4.pas' {Form4},
  NotifyingClient in '..\PlugIn\NotifyingClient.pas',
  AndIpcServer in '..\ShareUnit\AndIpcServer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
