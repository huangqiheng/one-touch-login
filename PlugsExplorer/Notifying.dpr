program Notifying;

uses
  Forms,
  SysUtils,
  Classes,
  AndIpcProcedure,
  SyncObjs,
  Windows,
  NofityForm in 'NofityForm.pas' {Form1},
  ProgressForm in 'ProgressForm.pas' {Form3};

{$R *.res}

var
  ChannelName, RunMode: String;

function IpcCallBack_MESSAGE (TranSL: TStringList): Integer; Stdcall;
begin
  if TranSL.Count > 0 then
  begin
    Form1.RichEdit1.Lines.Clear;
    Form1.RichEdit1.Lines.AddStrings(TranSL);
    TranSL.Clear;
    TranSL.Values['Result'] := 'OK';
  end;
  Result := TranSL.Count;
end;

function IpcCallBack_PROGRESS (TranSL: TStringList): Integer; Stdcall;
var
  Caption, Hint, Progress: String;
  ProgValue: Integer;
begin
  Caption := TranSL.Values['Caption'];
  Hint := TranSL.Values['Hint'];
  Progress := TranSL.Values['Progress'];

  if Caption <> '' then
  begin
    Form3.StaticText2.Caption := Caption;
  end;

  if Hint <> '' then
    Form3.StaticText1.Caption := Hint;

  if Progress <> '' then
  begin
    if TryStrToInt (Progress, ProgValue) then
    begin
      if ProgValue > 100 then
        ProgValue := 100;
      if ProgValue < 0 then
        ProgValue := 0;
      Form3.ProgressBar1.Position := ProgValue;
    end;
  end;

  TranSL.Clear;
  TranSL.Values['Result'] := 'OK';
  Result := TranSL.Count;
end;

begin
  if ParamCount <> 2 then Exit;
  RunMode := UpperCase(ParamStr(1));
  ChannelName := ParamStr(2);
  if Length (ChannelName) <> Guid_Name_Length then Exit;

  if RunMode = 'MESSAGE' then
  begin
    Application.Initialize;
    Application.CreateForm(TForm1, Form1);
    if CreateIpcProcedure (ChannelName, IpcCallBack_MESSAGE, 8, 1024, 1) then
      Application.Run;
  end else
  if RunMode = 'PROGRESS' then
  begin
    Application.Initialize;      
    Application.CreateForm(TForm3, Form3);
    Form3.ProgressBar1.Position := 0;
    Form3.FormStyle := fsStayOnTop;
    Form3.StaticText1.Caption := '正在初始化......';
    if CreateIpcProcedure (ChannelName, IpcCallBack_PROGRESS, 8, 1024, 1) then
      Application.Run;
  end;

  DestroyIpcProcedure (ChannelName);
end.
