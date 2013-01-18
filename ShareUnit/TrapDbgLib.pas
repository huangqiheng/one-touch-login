unit TrapDbgLib;

interface
uses windows, sysUtils, classes;

var
 DBTaskCreate: Function (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall;
 DBTaskDestroy: Function (Task: THandle; AppExit: BOOL): BOOL; Stdcall;
 DBTaskConfig: Function (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall;
 DBTaskPlugin: Function (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall;
 DBTaskRun: Function (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall;
 DBTaskRunning: Function (Task: THandle): BOOL; Stdcall;
 DBTaskAppData: Function (Task: THandle; DataBuff: PChar; DataSize: Integer): BOOL; Stdcall;
 DBTaskCopy: Function (Task: THandle): THandle; Stdcall;

var
  IsDbgOK: BOOL = False;

implementation

const
  LibName = 'TrapDebug.dll';

var
  LibHandle: THandle;

initialization
  LibHandle := LoadLibraryA (LibName);
  if LibHandle > 0 then
  begin
    @DBTaskCreate := GetProcAddress(LibHandle, 'TaskCreate');
    @DBTaskDestroy := GetProcAddress(LibHandle, 'TaskDestroy');
    @DBTaskConfig := GetProcAddress(LibHandle, 'TaskConfig');
    @DBTaskPlugin := GetProcAddress(LibHandle, 'TaskPlugin');
    @DBTaskRun := GetProcAddress(LibHandle, 'TaskRun');
    @DBTaskRunning := GetProcAddress(LibHandle, 'TaskRunning');
    @DBTaskAppData := GetProcAddress(LibHandle, 'TaskAppData');
    @DBTaskCopy := GetProcAddress(LibHandle, 'TaskCopy');
    IsDbgOK := True;
  end;

end.
