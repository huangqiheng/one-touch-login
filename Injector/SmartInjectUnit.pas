unit SmartInjectUnit;

interface

uses windows, sysutils, classes;

const
  DEFAULT_INJECT_TIMEOUT = 18*1000;

Type
  TInjectType = (ijDriver, ijRemoteThread, ijAuto);

function InjectMode (InjectType: TInjectType = ijAuto): BOOL;

function AddMainDLL (Image: TMemoryStream; ParmaStr: WideString): BOOL; STDCALL; overload;
function AddMainDLL (Image: TMemoryStream; ParmaStr: String): BOOL; STDCALL; overload;
function AddSubDLL (Image: TMemoryStream): BOOL; stdcall;
function AddSubDLLs (Images: Array Of TMemoryStream): BOOL; stdcall;
function InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD): THandle; Stdcall; overload;
function InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD; WaitExit: BOOL): BOOL; Stdcall; overload;
function ScanInjectThem (AppCmdLines: TStringList; TimeOut: DWORD): BOOL; Stdcall;


implementation

uses CodeProxy, HiddenInjectDLL, SPGetSid;

var
  s_AddMainDLL: function (ImageBase: Pointer; ImageSize: DWORD; ParmaBase: Pointer; ParmaSize: DWORD): BOOL; STDCALL;
  s_AddSubDLL: function (ImageBase: Pointer; ImageSize: DWORD): BOOL; stdcall;
  s_InjectThemALL: function (AppCmdLine: String; RightLevel, TimeOut: DWORD): THandle; Stdcall;
  s_ScanInjectThem: function (AppCmdLines: TStringList; TimeOut: DWORD): BOOL; Stdcall;

  BeenInitDriver: BOOL = False;
  RunEnable: BOOL = False;

Procedure SetDriverFunctions;
begin
  @s_AddMainDLL := @CodeProxy._AddMainDLL;
  @s_AddSubDLL := @CodeProxy._AddSubDLL;
  @s_InjectThemALL := @CodeProxy._InjectThemALL;
  @s_ScanInjectThem := @CodeProxy._ScanInjectThem;
end;

Procedure SetRemoteThreadFunctions;
begin
  @s_AddMainDLL := @HiddenInjectDLL._AddMainDLL;
  @s_AddSubDLL := @HiddenInjectDLL._AddSubDLL;
  @s_InjectThemALL := @HiddenInjectDLL._InjectThemALL;
  @s_ScanInjectThem := NIL;
end;

function InjectMode (InjectType: TInjectType = ijAuto): BOOL;
begin
  Result := False;

  if ijAuto = InjectType then
  begin
    InjectType := ijRemoteThread;
    if IsAdmin then
      InjectType := ijDriver;
  end;

  if ijDriver = InjectType then
  begin
    if BeenInitDriver then
    begin
          SetDriverFunctions;
          Result := True;
          OutputDebugString ('使用驱动注射！');
    end else
    begin
      if IsAdmin then
        if DirverInitial then
        begin
          SetDriverFunctions;
          BeenInitDriver := True;
          Result := True;
          OutputDebugString ('使用驱动注射！');
        end else
        begin
          OutputDebugString (PChar(format('驱动加载出错： GetLastError = %d', [GetLastError])));
        end;
    end;
  end else

  if ijRemoteThread = InjectType then
  begin
    SetRemoteThreadFunctions;
    Result := True;
    OutputDebugString ('使用常规注射！');
  end;

  if Result then
    RunEnable := True;
end;

function AddMainDLL (Image: TMemoryStream; ParmaStr: String): BOOL; STDCALL;
begin
  Result := False;
  if not RunEnable then exit;     
  if Image = NIL then Exit;

  ParmaStr := ParmaStr + #0;
  Result := s_AddMainDLL (Image.Memory, Image.Size, PChar(ParmaStr), Length(ParmaStr));
end;

function AddMainDLL (Image: TMemoryStream; ParmaStr: WideString): BOOL; STDCALL;
begin
  Result := False;
  if not RunEnable then exit;     
  if Image = NIL then Exit;

  ParmaStr := ParmaStr + #0;
  Result := s_AddMainDLL (Image.Memory, Image.Size, PWideChar(ParmaStr), Length(ParmaStr)*2);
end;

function AddSubDLL (Image: TMemoryStream): BOOL; stdcall;
begin
  Result := False;
  if not RunEnable then exit;
  if Not Assigned (Image) then Exit;
  Result := s_AddSubDLL (Image.Memory, Image.Size);
end;

function AddSubDLLs (Images: Array Of TMemoryStream): BOOL; stdcall;
var
  Index: Integer;
  IterMM: TMemoryStream;
begin
  Result := False;

  for Index := 0 to Length(Images) - 1 do
  begin
    IterMM := Images[Index];
    if not AddSubDLL (IterMM) then Exit;
  end;
  Result := True;
end;

function InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD): THandle; Stdcall;
begin
  if not RunEnable then
  begin
    result := 0;
    exit;
  end;
  Result:= s_InjectThemALL (AppCmdLine, RightLevel, TimeOut);
end;

function ScanInjectThem (AppCmdLines: TStringList; TimeOut: DWORD): BOOL; Stdcall;
begin
  Result := False;
  if not RunEnable then exit;
  if not assigned (s_ScanInjectThem) then Exit;

  Result:= s_ScanInjectThem (AppCmdLines, TimeOut);
end;

function InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD; WaitExit: BOOL): BOOL; Stdcall;
var
  ProcHandle: THandle;
begin
  Result := False;
  if not RunEnable then exit;
  
  ProcHandle := s_InjectThemALL (AppCmdLine, RightLevel, TimeOut);
  if ProcHandle > 0 then
  begin                                 
    if WaitExit then
      WaitForSingleObject (ProcHandle ,INFINITE);
    CloseHandle (ProcHandle);
    Result := True;
  end;
end;

Initialization

end.
