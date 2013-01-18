library IEGuard;

uses
  SysUtils, Windows, Classes;

{$I PlugBase.inc}




////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////  

var
  lpvReserved: PPointer;
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  OnAppData: function (DataBuff: PChar; DataSize: Integer): BOOL; Stdcall;
  OnProgress: function (OpType: Integer; Caption, Hint: PChar; Progress: Integer): BOOL; Stdcall;
  OnConfig: function (Key: PChar; Value: PChar): BOOL; Stdcall;
  OnKeyData: function (Key: PChar; Value: PChar): BOOL; Stdcall;
  OnMsgSystem: function (Msg: PChar): BOOL; Stdcall;
  OnMsgError: function (Msg: PChar): BOOL; Stdcall;
  OnMsgDebug: function (Msg: PChar): BOOL; Stdcall;
  OnMsgLog: function (Msg: PChar): BOOL; Stdcall;
  OnMsgNotice: function (Msg: PChar): BOOL; Stdcall;



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

      @OnAppData := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnAppData);
      @OnProgress := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnProgress);
      @OnConfig := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnConfig);
      @OnKeyData := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnKeyData);
      @OnMsgSystem := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgSystem);
      @OnMsgError := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgError);
      @OnMsgDebug := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgDebug);
      @OnMsgLog := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgLog);
      @OnMsgNotice := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgNotice);

      OnMsgDebug ('Null plugin started!');
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
