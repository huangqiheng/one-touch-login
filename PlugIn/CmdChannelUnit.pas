unit CmdChannelUnit;

interface
uses windows, sysutils, classes;

function CMDIpcCallBack (TranSL: TStringList): Integer; Stdcall;

function CMD_ShowUserMessage (MsgSL: PChar): BOOL; Stdcall;
function CMD_OpenProgressWindow (Caption: PChar): THandle; Stdcall;
function CMD_ReportProgress (ProHandle: THandle; Hint: PChar; Progress: Integer): BOOL; Stdcall;
function CMD_CloseProgressWindow (ProHandle: THandle): BOOL; Stdcall;

var
  Default_CmdChannel: String;

implementation

uses NotifyingClient, AndIpcProcedure;

//////////////////////////////////////////////////////////
///               ipc command channel
//////////////////////////////////////////////////////////

Procedure BeginResult (TranSL: TStringList; RunResult: BOOL);
begin
  TranSL.Clear;
  if RunResult then
    TranSL.Values['Result'] := 'True'
  else
    TranSL.Values['Result'] := 'False';
end;

function CMDIpcCallBack (TranSL: TStringList): Integer; Stdcall;
var
  Index: Integer;
  CmdStr, ValueStrA, ValueStrB, ValueStrC: String;
  RunHandle: THandle;
  RunHandle64: Int64;
  RunHandle32: Integer;
begin
  Index := TranSL.IndexOfName('Command');
  if Index = -1 then
  begin
    BeginResult (TranSL, False);
    Result := TranSL.Count;
    Exit;
  end;
  CmdStr := TranSL.ValueFromIndex[Index];
  TranSL.Delete(Index);

  if CmdStr = 'ReportProgress' then
  begin
    ValueStrA := TranSL.Values['ProHandle'];
    ValueStrB := TranSL.Values['Hint'];
    ValueStrC := TranSL.Values['Progress'];

    if TryStrToInt64 (ValueStrA, RunHandle64) and
       TryStrToInt   (ValueStrC, RunHandle32) then
    begin
      BeginResult (TranSL, ReportProgress (RunHandle64, ValueStrB, RunHandle32));
    end else
    begin
      BeginResult (TranSL, False);
      TranSL.Values['Error'] := 'Invalid ProHandle or Progress';
    end;
  end else

  if CmdStr = 'OpenProgressWindow' then
  begin
    ValueStrA := TranSL.Values['Caption'];
    RunHandle := OpenProgressWindow (ValueStrA);
    BeginResult (TranSL, RunHandle > 0);
    TranSL.Values['ProHandle'] := IntToStr(RunHandle);
  end else

  if CmdStr = 'CloseProgressWindow' then
  begin
    ValueStrA := TranSL.Values['ProHandle'];
    if not TryStrToInt64 (ValueStrA, RunHandle64) then
    begin
      BeginResult (TranSL, False);
      TranSL.Values['Error'] := 'Invalid ProHandle';
    end else begin
      BeginResult (TranSL, CloseProgressWindow (RunHandle64));
    end;
  end else

  if CmdStr = 'ShowUserMessage' then
  begin
    BeginResult (TranSL, ShowUserMessage (TranSL));
  end;

  Result := TranSL.Count;
end;

function SendCmd (TranSL: TStringList): BOOL;
begin
  Result := False;
  if IpcProcedure (Default_CmdChannel, TranSL) then
    Result := TranSL.Values['Result'] = 'True';
end;

function CMD_ShowUserMessage (MsgSL: PChar): BOOL; Stdcall;
var
  TranSL: TStringList;
begin
  Result := False;
  if Default_CmdChannel = '' then Exit;

  TranSL := TStringList.Create;
  TranSL.Text := StrPas (MsgSL);
  TranSL.Values['Command'] := 'ShowUserMessage';
  Result := SendCmd (TranSL);
  TranSL.Free;
end;

function CMD_OpenProgressWindow (Caption: PChar): THandle; Stdcall;
var
  TranSL: TStringList;
  RunHandle: Int64;
  HandleStr: String;
begin
  Result := 0;
  if Default_CmdChannel = '' then Exit;

  TranSL := TStringList.Create;
  TranSL.Values['Command'] := 'OpenProgressWindow';
  TranSL.Values['Caption'] := Caption;
  if SendCmd (TranSL) then
  begin
    HandleStr := TranSL.Values['ProHandle'] ;
    if TryStrToInt64 (HandleStr, RunHandle) then
      Result := RunHandle;
  end;
  TranSL.Free;
end;

function CMD_ReportProgress (ProHandle: THandle; Hint: PChar; Progress: Integer): BOOL; Stdcall;
var
  TranSL: TStringList;
begin
  Result := False;
  if Default_CmdChannel = '' then Exit;

  TranSL := TStringList.Create;
  TranSL.Values['Command'] := 'ReportProgress';
  TranSL.Values['ProHandle'] := IntToStr(ProHandle);
  TranSL.Values['Hint'] := Hint;
  TranSL.Values['Progress'] := IntToStr(Progress);
  Result := SendCmd (TranSL);           
  TranSL.Free;
end;

function CMD_CloseProgressWindow (ProHandle: THandle): BOOL; Stdcall;
var
  TranSL: TStringList;
begin
  Result := False;
  if Default_CmdChannel = '' then Exit;

  TranSL := TStringList.Create;
  TranSL.Values['Command'] := 'CloseProgressWindow';
  TranSL.Values['ProHandle'] := IntToStr(ProHandle);
  Result := SendCmd (TranSL);
  TranSL.Free;
end;

end.
