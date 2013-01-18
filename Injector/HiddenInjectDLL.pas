unit HiddenInjectDLL;

interface
uses windows, classes, SysUtils;

const
  DEFAULT_INJECT_TIMEOUT = 18*1000;

function InjectDLL (ProcID: DWORD; ImageBase: PChar; ImageSize: Integer; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall; overload;
function InjectDLL (ProcID: DWORD; ImageFile: PChar; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall; overload;

function InjectDLL2 (ProceHandle: THandle; ImageBase: PChar; ImageSize: Integer; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall; overload;
function InjectDLL2 (ProceHandle: THandle; ImageFile: PChar; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall; overload;
  
function _AddMainDLL (ImageBase: Pointer; ImageSize: DWORD; ParmaBase: Pointer; ParmaSize: DWORD): BOOL; STDCALL;
function _AddSubDLL (ImageBase: Pointer; ImageSize: DWORD): BOOL; stdcall;
function _InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD): THandle; Stdcall;


function AddMainDLL (Image: String; ParmaBase: Pointer; ParmaSize: DWORD): BOOL; STDCALL; overload;
function AddMainDLL (Image: TMemoryStream; ParmaStr: WideString): BOOL; STDCALL; overload;
function AddSubDLL (Image: String): BOOL; stdcall; overload;
function AddSubDLL (Image: TMemoryStream): BOOL; stdcall; overload;
function AddSubDLLs (Images: TStringList): BOOL; stdcall; overload;
function AddSubDLLs (Images: Array Of TMemoryStream): BOOL; stdcall; overload;
function InjectThemALL (AppCmdLine: String; WaitExit: BOOL): BOOL; Stdcall; overload;
function InjectThemALL (ProceHandle: THandle; TimeOut: DWORD = DEFAULT_INJECT_TIMEOUT): BOOL; Stdcall; overload;

implementation

uses madCHook, dll2funcUnit, formatfunction, DropMyRights;

function InjectDLL (ProcID: DWORD; ImageBase: PChar; ImageSize: Integer; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall; overload;
var
  Handle: THandle;
begin
  Handle := OpenProcess (PROCESS_ALL_ACCESS, False, ProcID);
  Result := InjectDLL2 (Handle, ImageBase, ImageSize, ParmaBase, ParmaSize);
  CloseHandle (Handle);
end;

function InjectDLL (ProcID: DWORD; ImageFile: PChar; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall; overload;
var
  Handle: THandle;
begin
  Handle := OpenProcess (PROCESS_ALL_ACCESS, False, ProcID);
  Result := InjectDLL2 (Handle, ImageFile, ParmaBase, ParmaSize);
  CloseHandle (Handle);
end;

function InjectDLL2 (ProceHandle: THandle; ImageFile: PChar; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall;
var
  MM: TMemoryStream;
begin
  MM := TMemoryStream.Create;
  MM.LoadFromFile(StrPas(ImageFile));
  Result := InjectDLL2 (ProceHandle, MM.Memory, MM.Size, ParmaBase, ParmaSize);
  MM.Free;
end;

function InjectDLL2 (ProceHandle: THandle; ImageBase: PChar; ImageSize: Integer; ParmaBase: Pointer; ParmaSize: Integer): THandle; stdcall;
var
  FuncEntry, RemoteFuncEntry: Pointer;
  FuncSize: DWORD;
  RemoteParma: Pointer;
  ByteWriten: DWORD;
  TID: DWORD;
  hThread: THandle;
  ExitCode: DWORD;
begin
  Result := 0;

  if Dll2Function (ImageBase, ImageSize, FuncEntry, FuncSize) then
  begin
    //写参数
    RemoteParma := ParmaBase;
    if (ParmaBase <> NIL) and (ParmaSize > 0) then
    begin
      RemoteParma := AllocMemEx (ParmaSize, ProceHandle);
      WriteProcessMemory (ProceHandle, RemoteParma, ParmaBase, ParmaSize, ByteWriten);
    end;      

    //写函数体
    RemoteFuncEntry := AllocMemEx (FuncSize, ProceHandle);
    WriteProcessMemory (ProceHandle, RemoteFuncEntry, FuncEntry, FuncSize, ByteWriten);

    //执行
    hThread := CreateRemoteThreadEx (ProceHandle, nil, 0, RemoteFuncEntry, RemoteParma, 0, TID);
    WaitForSingleObject( hThread, INFINITE );
    ExitCode := 0;
    if GetExitCodeThread (hThread, ExitCode) then
      Result := ExitCode;
  end;

  FreeMem (FuncEntry);
end;

//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 引导头
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

const
  THREAD_ENTRY = 0;
  THREAD_PARAM = 1;
  PARAM_HEAD = 'ANDX';

type
  LPTHookHeaderParam = ^THookHeaderParam;
  THookHeaderParam = packed record
    SIGN: Array[0..3] of Char;
    Count: Integer;
    FuncArray: Array[WORD] of Array[THREAD_ENTRY..THREAD_PARAM] of Pointer;
  end;


function HookHeadThread (Param: Pointer): BOOL; Stdcall;
var
  HookHeader: LPTHookHeaderParam;
  Index: Integer;
  ThreadCall: function (Param: Pointer): Pointer; Stdcall;
  MainResult: Pointer;
  DeltaOffset: Integer;
  RealMeBase, ScanBase: Pointer;
  FuncEntry,FuncParam: Pointer;
  ScanValue: Integer;
  AimSign: Array[0..3] of Char;
begin
  //寻找本函数实际内存地址
  asm
    push eax
    Call @AimMark
  @AimMark:
    Pop eax
    sub eax, OFFSET @AimMark
    mov DeltaOffset, eax
    pop eax
  end;
  RealMeBase := Pointer (Integer(@HookHeadThread) + DeltaOffset);

  //寻找本函数附带的参数的实际内存地址
  AimSign[0] := 'A';
  AimSign[1] := 'N';
  AimSign[2] := 'D';
  AimSign[3] := 'X';
  ScanValue := PInteger(@AimSign[0])^;

  HookHeader := NIL;
  for Index := 1 to $1000 do
  begin
    ScanBase := @PChar(RealMeBase)[Index];
    if PInteger(ScanBase)^ = ScanValue then
    begin
      HookHeader := ScanBase;
      Break;
    end;
  end;

  //查看参数是否正常
  Result := False;
  if HookHeader = NIL then Exit;
  if HookHeader.Count = 0 then exit;

  //修正所有的偏移值
  for Index := 0 to HookHeader.Count - 1 do
  begin
    //修正函数线程入口
    FuncEntry := HookHeader.FuncArray[Index][THREAD_ENTRY];
    HookHeader.FuncArray[Index][THREAD_ENTRY] := Pointer (DWORD(RealMeBase) + DWORD(FuncEntry));

    //修正线程函数的参数
    FuncParam := HookHeader.FuncArray[Index][THREAD_PARAM];
    if FuncParam <> Pointer(0) then
      HookHeader.FuncArray[Index][THREAD_PARAM] := Pointer (DWORD(RealMeBase) + DWORD(FuncParam));
  end;

  //调用主DLL
  ThreadCall := HookHeader.FuncArray[0][THREAD_ENTRY];
  MainResult := ThreadCall (HookHeader.FuncArray[0][THREAD_PARAM]);

  Result := MainResult <> nil;
  if HookHeader.Count = 1 then exit;

  //调用各从属DLL
  for Index := 1 to HookHeader.Count - 1 do
  begin
    ThreadCall := HookHeader.FuncArray[Index][THREAD_ENTRY];
    ThreadCall (MainResult);
  end;          
end;

procedure HookHeadThread_End;
begin
end;

//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 连续注射有从属关系的DLLs
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Type
  LPTHookDLLInfo = ^THookDLLInfo;
  THookDLLInfo = packed record
    ImageBase: Pointer;
    ImageSize: DWORD;
    ParmaBase: Pointer;
    ParmaSize: DWORD;
    Buffer: Array[WORD] of char;
  end;

var
  DLLsList: TList;


function AddHookDll (ImageBase: Pointer; ImageSize: DWORD; ParmaBase: Pointer = nil; ParmaSize: DWORD = 0): Integer; STDCALL;
var
  HookDLLInfo: LPTHookDLLInfo;
begin
  if (ImageBase = NIL) or (ImageSize = 0) then
  begin
    Result := -1;
    Exit;
  end;

  HookDLLInfo := AllocMem (ImageSize + ParmaSize + SizeOf(THookDLLInfo));

  HookDLLInfo.ImageBase := @HookDLLInfo.Buffer[0];
  HookDLLInfo.ImageSize := ImageSize;
  CopyMemory (HookDLLInfo.ImageBase, ImageBase, ImageSize);

  HookDLLInfo.ParmaBase := nil;
  HookDLLInfo.ParmaSize := 0;
  Result := DLLsList.Add(HookDLLInfo);

  if ParmaBase = nil then exit;
  if ParmaSize = 0 then exit;

  HookDLLInfo.ParmaBase := @HookDLLInfo.Buffer[ImageSize];
  HookDLLInfo.ParmaSize := ParmaSize;
  CopyMemory (HookDLLInfo.ParmaBase, ParmaBase, ParmaSize);
end;

function _AddMainDLL (ImageBase: Pointer; ImageSize: DWORD; ParmaBase: Pointer; ParmaSize: DWORD): BOOL; STDCALL;
var
  ToFree: Pointer;
begin
  //初始化
  if not assigned (DLLsList) then
    DLLsList := TList.Create;
  for ToFree in DLLsList do
    FreeMem (ToFree);
  DLLsList.Clear;

  Result := AddHookDll (ImageBase, ImageSize, ParmaBase, ParmaSize) = 0;  
end;

function AddMainDLL (Image: TMemoryStream; ParmaStr: WideString): BOOL; STDCALL;
begin
  if Image = NIL then
  begin
    Result := False;
    Exit;
  end;

  ParmaStr := ParmaStr + #0;
  Result := _AddMainDLL (Image.Memory, Image.Size, PWideChar(ParmaStr), Length(ParmaStr)*2);
end;

function _AddSubDLL (ImageBase: Pointer; ImageSize: DWORD): BOOL; stdcall;
begin
  Result := False;
  if not assigned (DLLsList) then exit;
  if DLLsList.Count = 0 then Exit;
  
  Result := AddHookDll (ImageBase, ImageSize) > 0;
end;                      

function InjectThemALL (ProceHandle: THandle; TimeOut: DWORD = DEFAULT_INJECT_TIMEOUT): BOOL; Stdcall;
var
  HookHeaderParam: LPTHookHeaderParam;
  HookHeaderSize: DWORD;
  HookHeaderParamSize: DWORD;
  HookHeaderParamOffset: DWORD;
  HookDLLInfo: LPTHookDLLInfo; 
  Index: Integer;
  FuncEntry: Pointer;
  FuncSize, AimOffset, WriteCount, TotalMayBeSize: DWORD;
  ToCopyMM: TMemoryStream;
  RemoteBase: Pointer;
  hThread: THandle;
  TID, ExitCode: DWORD;
begin
  Result := False;
  if not assigned (DLLsList) then exit;
  if DLLsList.Count = 0 then exit;

  //将DLL转化成函数，原地存放
  for HookDLLInfo in DLLsList do
  begin
    if Dll2Function (HookDLLInfo.ImageBase, HookDLLInfo.ImageSize, FuncEntry, FuncSize) then
    begin
      HookDLLInfo.ImageBase := FuncEntry;
      HookDLLInfo.ImageSize := FuncSize;
    end;
  end;

  //计算引导代码和参数的大小
  HookHeaderSize := DWORD(@HookHeadThread_End) - DWORD(@HookHeadThread);
  HookHeaderParamSize := 4 + SizeOf(Integer) + (SizeOf(Pointer)*2 * (DLLsList.Count + 1));

  //估计总大小
  TotalMayBeSize := HookHeaderSize + HookHeaderParamSize;
  for HookDLLInfo in DLLsList do
    Inc (TotalMayBeSize, HookDLLInfo.ImageSize);
  HookDLLInfo := DLLsList[0];
  Inc (TotalMayBeSize, HookDLLInfo.ParmaSize);

  //复制引导代码，开始制作远程copy模板
  ToCopyMM := TMemoryStream.Create;
  ToCopyMM.SetSize(TotalMayBeSize);
  ToCopyMM.Seek(0, soFromBeginning);
  AimOffset := ToCopyMM.Write(PChar(@HookHeadThread)^, HookHeaderSize);
  HookHeaderParamOffset := AimOffset;

  //复制引导代码的参数
  HookHeaderParam := AllocMem (HookHeaderParamSize);
  WriteCount :=  ToCopyMM.Write(HookHeaderParam^, HookHeaderParamSize);
  FreeMem (HookHeaderParam);
  HookHeaderParam := Pointer (DWORD(ToCopyMM.Memory) + HookHeaderParamOffset);

  //记录主DLL的偏移地址
  Inc (AimOffset, WriteCount);

  //复制主DLL
  HookHeaderParam.SIGN := PARAM_HEAD;
  HookHeaderParam.Count := DLLsList.Count;
  HookDLLInfo := DLLsList[0];
  WriteCount := ToCopyMM.Write (HookDLLInfo.ImageBase^, HookDLLInfo.ImageSize);
  HookHeaderParam.FuncArray[0][THREAD_ENTRY] := Pointer(AimOffset);
  Inc (AimOffset, WriteCount);

  //复制主DLL参数
  WriteCount := ToCopyMM.Write (HookDLLInfo.ParmaBase^, HookDLLInfo.ParmaSize);
  HookHeaderParam.FuncArray[0][THREAD_PARAM] := Pointer(AimOffset);
  Inc (AimOffset, WriteCount);

  //复制其他从属DLL，它们没有参数的
  for Index := 1 to DLLsList.Count - 1 do
  begin
      HookDLLInfo := DLLsList[Index];
      WriteCount := ToCopyMM.Write (HookDLLInfo.ImageBase^, HookDLLInfo.ImageSize);

      HookHeaderParam.FuncArray[Index][THREAD_ENTRY] := Pointer(AimOffset);
      HookHeaderParam.FuncArray[Index][THREAD_PARAM] := Pointer(0);
      Inc (AimOffset, WriteCount);
  end;

  //申请远程内存 注入目标进程
  RemoteBase := AllocMemEx (ToCopyMM.Size, ProceHandle);
  WriteProcessMemory (ProceHandle, RemoteBase, ToCopyMM.Memory, ToCopyMM.Size, DWORD(WriteCount));

  //创建远线程执行
  hThread := CreateRemoteThreadEx (ProceHandle, nil, 0, RemoteBase, NIL, 0, TID);
  WaitForSingleObject( hThread, TimeOut);
  ExitCode := 0;
  if GetExitCodeThread (hThread, ExitCode) then
    Result := BOOL (ExitCode);

  //回收资源
  for HookDLLInfo in DLLsList do
  begin
    FreeMem (HookDLLInfo.ImageBase);
    FreeMem (HookDLLInfo);
  end;
  DLLsList.Clear;

  ToCopyMM.Free;
end;


function AddMainDLL (Image: String; ParmaBase: Pointer; ParmaSize: DWORD): BOOL; STDCALL;
begin
  With TMemoryStream.Create do
  try
    LoadFromFile (Image);
    Result := _AddMainDLL (Memory, Size, ParmaBase, ParmaSize);
  finally
    Free;
  end;
end;

function AddSubDLL (Image: String): BOOL; stdcall;
begin
  With TMemoryStream.Create do
  try
    LoadFromFile (Image);
    Result := _AddSubDLL (Memory, Size);
  finally
    Free;
  end;
end;

function AddSubDLL (Image: TMemoryStream): BOOL; stdcall;
begin
  Result := False;
  if Not Assigned (Image) then Exit;
  Result := _AddSubDLL (Image.Memory, Image.Size);
end;

function AddSubDLLs (Images: TStringList): BOOL; stdcall;
var
  Image: String;
begin
  Result := False;
  for Image in Images do
  begin
    if FileExists (Image) then
      if not AddSubDLL (Image) then Exit;
  end;
  Result := True;
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

function _InjectThemALL (AppCmdLine: String; RightLevel, TimeOut: DWORD): THandle; Stdcall;
var
  ProcessInfo : TProcessInformation;
begin
  Result := 0;

  if DropMeSuspend(RightLevel, AppCmdLine, ProcessInfo) then
  begin
     if InjectThemALL (ProcessInfo.hProcess, TimeOut) then
     begin
       ResumeThread (ProcessInfo.hThread);
       Result := ProcessInfo.hProcess;
     end else
     begin
       TerminateProcess (ProcessInfo.hThread, 0);
       CloseHandle (ProcessInfo.hThread);
       CloseHandle (ProcessInfo.hProcess);
       OutputDebugString ('InjectThemALL Error');
     end;
  end;
end;




function InjectThemALL (AppCmdLine: String; WaitExit: BOOL): BOOL; Stdcall;
var
  ProcHandle: THandle;
begin
  Result := False;
  ProcHandle := _InjectThemALL (AppCmdLine, SAFER_LEVELID_FULLYTRUSTED, DEFAULT_INJECT_TIMEOUT);
  if ProcHandle > 0 then
  begin
    if WaitExit then
      WaitForSingleObject (ProcHandle ,INFINITE);
    CloseHandle (ProcHandle);
    Result := True;
  end;
end;

end.
