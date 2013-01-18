program TrapDebug;

{$R 'TrapDbgDll.res' 'TrapDbgDll.rc'}

uses
  Forms,
  Classes,
  SysUtils,
  MainExeini,
  RcFuncUnit,
  MdiMainForm in 'MdiMainForm.pas' {MDIMain},
  BreakForm in 'BreakForm.pas' {BreakPointLstForm},
  MemExplorerForm in 'MemExplorerForm.pas' {MemExplorer},
  TrapDbgLibUnit in 'TrapDbgLibUnit.pas',
  DbgInfoForm in 'DbgInfoForm.pas' {DbgPrint},
  ModuleFuncList in 'ModuleFuncList.pas' {ApiListForm},
  BreakingForm in 'BreakingForm.pas' {BreakPointForm},
  CallStructForm in 'CallStructForm.pas' {CallStructureForm},
  PlugParaForm in 'PlugParaForm.pas' {SetParamForm};

{$R *.res}

procedure ExtractTrapDebugDll;
var
  MS: TMemoryStream;
  FileName: String;
begin
  FileName := MakeFileNameByExt ('.dll');
  if not FileExists (FileName) then
  begin       
    MS := GetRCDataMMemory ('PEFILE', 'TRAPDBGDLL');
    MS.SaveToFile(FileName);
    MS.Free;
  end;
end;

begin
  ExtractTrapDebugDll;

  Application.Initialize;
  Application.CreateForm(TMDIMain, MDIMain);
  Application.CreateForm(TDbgPrint, DbgPrint);
  Application.Run;
end.
