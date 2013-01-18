library Empty;

uses
  SysUtils, Windows, Classes;

{$I PlugBase.inc}

var
  lpvReserved: PPointer;
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  OnMsgLog: function (Msg: PChar): BOOL; Stdcall;

////////////////////////////////////////////////////////////////////////////////  

Function GetReservedParam: Pointer; Register;
asm
  mov eax,[ebp+16]       //[ebp+16] lpvReserved
end;

procedure DLLEntryPoint(dwReason : DWord);
begin
  case dwReason of
    DLL_PROCESS_ATTACH:
    begin
      @FindFuncEntry := lpvReserved^;
      @OnMsgLog := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgLog);
      OnMsgLog('Empty plugin start.');
    end;
    DLL_PROCESS_DETACH:;
  end;
end;

begin
  lpvReserved := GetReservedParam;
  if Assigned (lpvReserved) then
  if Assigned (lpvReserved^) then
  begin
    DLLProc := @DLLEntryPoint;
    DLLEntryPoint(DLL_PROCESS_ATTACH);
  end;
end.
