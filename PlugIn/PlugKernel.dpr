library PlugKernel;

{$R '..\Injector\KPatchRC.res' '..\Injector\KPatchRC.rc'}

uses
  SysUtils,
  Classes,
  TCodeEventNotify,
  AndQueMessages,
  TrapApiHook,
  FindAddress,
  SyncQueueHandler,
  DrvRunUnit,
  PlugKernelUnit,
  TrapDbgUnit,
  AndIpcServer,
  DisAsmStr,
  CEAssembler;

function Version (): PChar; Stdcall;
begin
  Result := 'PlugKernel 1.01, Driver 1.00';
end;

Exports
  {$I PlugKernelExp.inc}
  EnsureDriver,
  Version,

  TaskCreate,
  TaskDestroy,
  TaskConfig,
  TaskPlugin,
  TaskRun,
  TaskRunning,
  TaskAppData,
  TaskCopy;

begin
end.
