unit NotifyingClient;

interface
uses Windows, SysUtils, Classes, AndIpcProcedure, RunAsUserUnit;

function ShowUserMessage (MsgSL: TStringList): BOOL;

function OpenProgressWindow (Caption: String): THandle;
function ReportProgress (ProHandle: THandle; Hint: String; Progress: Integer): BOOL;
function CloseProgressWindow (ProHandle: THandle): BOOL;

implementation

uses ComObj;

function GetAppPaths (DirName: String): String;
begin
  Result := GetModuleName (0);
  Result := ExtractFilePath (Result) + DirName + '\';
end;


Function SendCmdMessage (Channel: String; TranSL: TStringList; TimeOut: DWORD = 9*1000): BOOL;
var                             
  BeginTick: DWORD;
begin
  Result := False;
  BeginTick := GetTickCount;
  Repeat
    if IpcProcedure (Channel, TranSL) then
    begin
      Result := TranSL.Values['Result'] = 'OK';
      Break;
    end;
    Sleep (100);
  until GetTickCount - BeginTick > TimeOut;
end;

function ShowUserMessage (MsgSL: TStringList): BOOL;
var
  ChannelName: String;
  NotifyExe, AppCmdLine: String;
  TranSL: TStringList;
  AimAppHandle: THandle;
begin
  Result := False;
  ChannelName := CreateClassID;
  NotifyExe := GetAppPaths ('Data') + 'Notifying.exe';
  AppCmdLine := NotifyExe + ' Message ' + ChannelName;
  AimAppHandle := NewApp (AppCmdLine);
  if AimAppHandle > 0 then
  begin
    TranSL := TStringList.Create;
    TranSL.AddStrings(MsgSL);
    Result := SendCmdMessage (ChannelName, TranSL);
    TranSL.Free;
  end;
  CloseHandle (AimAppHandle);
end;

Type
  LpTProgressWinInfo = ^TProgressWinInfo;
  TProgressWinInfo = record
    AimAppHandle: THandle;
    CreateTickTime: DWORD;
    Caption: String;
    ChannelName: String;
  end;


function OpenProgressWindow (Caption: String): THandle;
var
  ProgWin: LpTProgressWinInfo;
  NotifyExe, AppCmdLine: String;
  TranSL: TStringList;
begin
  Result := 0;
  New (ProgWin);
  ProgWin.Caption := Caption;
  ProgWin.ChannelName := CreateClassID;
  ProgWin.CreateTickTime := GetTickCount;

  NotifyExe := GetAppPaths ('Data') + 'Notifying.exe';
  AppCmdLine := NotifyExe + ' Progress ' + ProgWin.ChannelName;
  ProgWin.AimAppHandle := NewApp (AppCmdLine);

  if ProgWin.AimAppHandle > 0 then
  begin
    TranSL := TStringList.Create;
    TranSL.Values['Caption'] := Caption;
    if SendCmdMessage (ProgWin.ChannelName, TranSL) then
      Result := THandle (ProgWin);
    TranSL.Free;
  end;
end;

function ReportProgress (ProHandle: THandle; Hint: String; Progress: Integer): BOOL;
var
  ProgWin: LpTProgressWinInfo absolute ProHandle;
  TranSL: TStringList;
begin
  TranSL := TStringList.Create;
  TranSL.Values['Hint'] := Hint;
  TranSL.Values['Progress'] := IntToStr(Progress);
  Result := SendCmdMessage (ProgWin.ChannelName, TranSL);
  TranSL.Free;
end;

function CloseProgressWindow (ProHandle: THandle): BOOL;
var
  ProgWin: LpTProgressWinInfo absolute ProHandle;
begin
  Result := TerminateProcess(ProgWin.AimAppHandle, 0);
  Dispose (ProgWin);
end;

end.
