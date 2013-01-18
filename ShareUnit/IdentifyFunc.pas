unit IdentifyFunc;

interface
uses windows, sysUtils, tlhelp32, md5, StrUtils;

function GetTargetChannelName (): String; overload;
function GetTargetChannelName (PID: DWORD): String; overload;
function GetTargetChannelName (PID: DWORD; ProcName: String): String; overload;

function ProcIDToProcName(PID: DWORD): String;
function GetSystemBootTime: String;     
function GetComputerName : string;

implementation


function NetWkstaGetInfo(servername: LPWSTR; level: DWORD;
  bufptr: Pointer): DWORD; stdcall; external 'netapi32.dll' name 'NetWkstaGetInfo';

const
  NERR_Success = 0;

type
  PWkstaInfo100 = ^TWkstaInfo100;
  _WKSTA_INFO_100 = record
    wki100_platform_id: DWORD;
    wki100_computername: LPWSTR;
    wki100_langroup: LPWSTR;
    wki100_ver_major: DWORD;
    wki100_ver_minor: DWORD;
  end;
  TWkstaInfo100 = _WKSTA_INFO_100;
  WKSTA_INFO_100 = _WKSTA_INFO_100;
  
function GetNetParam(AParam : integer) : string;
Var
  PBuf  : PWkstaInfo100;
  Res   : LongInt;
begin 
  result := ''; 
  Res := NetWkstaGetInfo (Nil, 100, @PBuf); 
  If Res = NERR_Success Then 
    begin 
      case AParam of 
       0:   Result := string(PBuf^.wki100_computername); 
       1:   Result := string(PBuf^.wki100_langroup); 
      end;
    end; 
end;        

function GetComputerName : string;
begin
  Result := GetNetParam(0);
end;

function GetSystemBootTime: String;
var
  T1: Int64;
  T2,T3: Comp;
  T4: TDateTime;
begin
  T1 := GetTickCount;                               {从开机到现在的毫秒数}
  T2 := TimeStampToMSecs(DateTimeToTimeStamp(Now)); {从 0001-1-1 到当前时间的毫秒数}
  T3 := T2 - T1;                                    {从 0001-1-1 到开机时刻的毫秒数}
  T4 := TimeStampToDateTime(MSecsToTimeStamp(T3));  {从 0001-1-1 到开机时刻的时间}
  Result := DateTimeToStr(T4);                   {显示开机时间}
end;

function ProcIDToProcName(PID: DWORD): String;
var
    hProcSnap:   THandle;
    pe32:   TProcessEntry32;
begin
  Result := '';
  hProcSnap := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS,   0);
  if hProcSnap = INVALID_HANDLE_VALUE then Exit;
  try
    pe32.dwSize := SizeOf(ProcessEntry32);
    if Process32First (hProcSnap, pe32) then
    Repeat          
      if pe32.th32ProcessID = PID then
      begin
        Result := ExtractFileName (pe32.szExeFile);
        Exit;
      end;
    until not Process32Next (hProcSnap, pe32);
  finally
    CloseHandle(hProcSnap);
  end;
end;

function MakeMd5Identify (Src: String): String;
var
  HalfCount: Integer;
  StrA, StrB: String;
begin
  HalfCount := Length(Src) div 2;
  if HalfCount = 0 then
  begin
    Result := Src;
    Exit;
  end;        

  StrA := ReverseString (Src);
  StrB := StuffString (Src, HalfCount + 1, 0, StrA);
  Result := StrB + StrA;
  Result := DupeString (Result, 3);
  Result := StringMD5Str (Result);
end;

//计算机名——计算机启动时间——进程名——进程ID
function GetTargetChannelName (PID: DWORD): String;
begin
  Result := GetSystemBootTime;
  Result := GetComputerName + '_' + Result  + '_' + ProcIDToProcName(PID)+ '_' + IntToStr(PID);
  Result := MakeMd5Identify (Result);
end;

function GetTargetChannelName (PID: DWORD; ProcName: String): String;
begin
  Result := GetSystemBootTime;
  ProcName := ExtractFileName (ProcName);
  Result := GetComputerName + '_' + Result  + '_' + ProcName+ '_' + IntToStr(PID);
  Result := MakeMd5Identify (Result);
end;

function GetTargetChannelName (): String;
var
  PID: DWORD;
  ProcName: String;
begin
  PID := GetCurrentProcessID;
  ProcName := GetModuleName (0);
  Result := GetTargetChannelName (PID, ProcName);
end;

end.
