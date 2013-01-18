unit DrvRunUnit;

interface
uses windows, sysUtils, Classes;

function EnsureDriver (Enable: BOOL = True): BOOL; Stdcall;
function DirverInitial (CodeBase: Pointer; CodeSize: DWORD): BOOL;

implementation

uses ServiceMan, SpecialFolderUnit, RcFuncUnit, md5;

const
  FServName = 'APatchService';
  FDispName = '通用插件系统驱动程序';
  FServPath = 'AppPatcher.SYS';

Procedure ShutDowmDriver;
begin
  with TServiceMan.Create do
  try
    ServiceStop (FServName);
    ServiceUnInstall (FServName);
  finally
    Free;
  end;
end;

function BootUpDriver (DriverPath: String): BOOL;
begin
  Result := False;

  if not FileExists (DriverPath) then
  begin
    SetLastError (1000);
    Exit;
  end;

  with TServiceMan.Create do
  try
    ServiceInstall (FServName, FDispName, PChar(DriverPath));
    Case ServiceStart (FServName) of
    0: SetLastError (1001);
    1,2: Result := True;
    3: SetLastError (1002);
    end;
  finally
    Free;
  end;
end;

function EnsureDriver (Enable: BOOL = True): BOOL; Stdcall;
var
  DriverPath: String;
  MS: TMemoryStream;
  DiskMd5, RcMd5: String;
begin
  DriverPath := GetSpecialFolder (sfSystem) + '\' + FServPath;

  if Enable then
  begin        
    Repeat
      MS := GetRCDataMMemory ('PEFILE', 'SYS_MODULE');
      if FileExists (DriverPath) then
      begin
        DiskMd5 := FileMD5Str (DriverPath);
        RcMd5 := BufferMD5Str (MS.Memory, MS.Size);
        if DiskMd5 = RcMd5 then Break;

        ShutDowmDriver;
        DeleteFile (DriverPath);
      end;
      MS.SaveToFile(DriverPath);
      MS.Free;
    until True;

    Result := BootUpDriver (DriverPath);
  end else
  begin
    ShutDowmDriver;
    DeleteFile (DriverPath);
    Result := True;
  end;             
end;


function DirverInitial (CodeBase: Pointer; CodeSize: DWORD): BOOL;
var
  hDev: THandle;
  Writed: DWORD;
  Times: Integer;
begin
  Result := False;

  Times := 0;
  Repeat
    hDev := CreateFileA('\\.\KPatch',	GENERIC_READ or GENERIC_WRITE, 0, NIL, CREATE_ALWAYS,	FILE_ATTRIBUTE_NORMAL, 0);
    if hDev = INVALID_HANDLE_VALUE then
    begin
      if Times = 0 then
        if not EnsureDriver then
        begin
          SetLastError (10001);
          FreeMem (CodeBase);
          Exit;
        end;
      Sleep(1000);
    end else
      Break;

    Inc (Times);
    if Times = 3 then
    begin
      SetLastError (10002);
      Exit;
    end;
  until False;

  if WriteFile(hDev, CodeBase^, CodeSize, Writed, nil) then
  begin
    Result := true;
  end else begin
    SetLastError (10003);
  end;

  CloseHandle(hDev);
end;


end.
