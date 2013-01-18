unit RcGetProcAddr;

interface
uses windows;

function Get_VirtualAlloc (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
function Get_OutputDebugStringA (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
function Get_CreateThread (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
function Get_GetCurrentProcessId (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
function Get_GetModuleFileNameA (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;

implementation

Type
  TGetProcAddress = function (hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall;
  TVirtualAlloc = function (lpvAddress: Pointer; dwSize, flAllocationType, flProtect: DWORD): Pointer; stdcall;
  TCreateThread = function (lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: TFNThreadStartRoutine; lpParameter: Pointer; dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle; stdcall;
  TOutputDebugStringA = procedure (lpOutputString: PAnsiChar); stdcall;
  TGetCurrentProcessId = function () : DWORD; stdcall;
  TGetModuleFileNameA = function (hModule: HINST; lpFilename: PAnsiChar; nSize: DWORD): DWORD; stdcall;

function Get_GetModuleFileNameA (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
var
  Buffer :array[0..19] of char;
  I: Integer;
begin
  I := 0;
  Buffer[I] := 'G'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'M'; Inc(I);
  Buffer[I] := 'o'; Inc(I);
  Buffer[I] := 'd'; Inc(I);
  Buffer[I] := 'u'; Inc(I);
  Buffer[I] := 'l'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'F'; Inc(I);
  Buffer[I] := 'i'; Inc(I);
  Buffer[I] := 'l'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'N'; Inc(I);
  Buffer[I] := 'a'; Inc(I);
  Buffer[I] := 'm'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'A'; Inc(I);
  Buffer[I] := #0;
  Result := TGetProcAddress (fnGetProcAddr) (hLib, Buffer);
end;

function Get_GetCurrentProcessId (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
var
  Buffer :array[0..19] of char;
  I: Integer;
begin
  I := 0;
  Buffer[I] := 'G'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'C'; Inc(I);
  Buffer[I] := 'u'; Inc(I);
  Buffer[I] := 'r'; Inc(I);
  Buffer[I] := 'r'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'n'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'P'; Inc(I);
  Buffer[I] := 'r'; Inc(I);
  Buffer[I] := 'o'; Inc(I);
  Buffer[I] := 'c'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 's'; Inc(I);
  Buffer[I] := 's'; Inc(I);
  Buffer[I] := 'I'; Inc(I);
  Buffer[I] := 'd'; Inc(I);
  Buffer[I] := #0;
  Result := TGetProcAddress (fnGetProcAddr) (hLib, Buffer);
end;

function Get_VirtualAlloc (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
var
  Buffer :array[0..15] of char;
  I: Integer;
begin
  I := 0;
  Buffer[I] := 'V'; Inc(I);
  Buffer[I] := 'i'; Inc(I);
  Buffer[I] := 'r'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'u'; Inc(I);
  Buffer[I] := 'a'; Inc(I);
  Buffer[I] := 'l'; Inc(I);
  Buffer[I] := 'A'; Inc(I);
  Buffer[I] := 'l'; Inc(I);
  Buffer[I] := 'l'; Inc(I);
  Buffer[I] := 'o'; Inc(I);
  Buffer[I] := 'c'; Inc(I);
  Buffer[I] := #0;
  Result := TGetProcAddress (fnGetProcAddr) (hLib, Buffer);
end;

function Get_OutputDebugStringA (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
var
  Buffer :array[0..19] of char;
  I: Integer;
begin
  I := 0;
  Buffer[I] := 'O'; Inc(I);
  Buffer[I] := 'u'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'p'; Inc(I);
  Buffer[I] := 'u'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'D'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'b'; Inc(I);
  Buffer[I] := 'u'; Inc(I);
  Buffer[I] := 'g'; Inc(I);
  Buffer[I] := 'S'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'r'; Inc(I);
  Buffer[I] := 'i'; Inc(I);
  Buffer[I] := 'n'; Inc(I);
  Buffer[I] := 'g'; Inc(I);
  Buffer[I] := 'A'; Inc(I);
  Buffer[I] := #0;
  Result := TGetProcAddress (fnGetProcAddr) (hLib, Buffer);
end;

function Get_CreateThread (fnGetProcAddr: Pointer; hLib: THandle): Pointer; inline;
var
  Buffer :array[0..15] of char;
  I: Integer;
begin
  I := 0;
  Buffer[I] := 'C'; Inc(I);
  Buffer[I] := 'r'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'a'; Inc(I);
  Buffer[I] := 't'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'T'; Inc(I);
  Buffer[I] := 'h'; Inc(I);
  Buffer[I] := 'r'; Inc(I);
  Buffer[I] := 'e'; Inc(I);
  Buffer[I] := 'a'; Inc(I);
  Buffer[I] := 'd'; Inc(I);
  Buffer[I] := #0;
  Result := TGetProcAddress (fnGetProcAddr) (hLib, Buffer);
end;



end.
