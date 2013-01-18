library DefaultDaemon;

uses
  SysUtils, Windows, Classes, GlobalObject;

{$I PlugsHolder.inc}

var
  lpvReserved: PPointer;
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  DebugPrint: Procedure (Msg: PChar); stdcall;

////////////////////////////////////////////////////////////////////////////////
///                     函数库初始化
////////////////////////////////////////////////////////////////////////////////

function Usage: PChar; Stdcall;
begin
  Result := '这是 TYPE_DAEMON DefaultDaemon.dll插件的使用帮助';
end;

function PluginType: PChar; Stdcall;
begin
  Result := TYPE_DAEMON;
end;

Exports
  Usage name 'Help',
  PluginType name 'Type';



////////////////////////////////////////////////////////////////////////////////
///                     DLL 入口
////////////////////////////////////////////////////////////////////////////////

Function GetReservedParam: Pointer; Register;
asm
  mov eax,[ebp+16]       //[ebp+16] lpvReserved
end;

procedure DLLEntryPoint(dwReason : DWord);
begin
  case dwReason of
    DLL_PROCESS_ATTACH: begin
      if Assigned (lpvReserved^) then
      begin
        @FindFuncEntry := lpvReserved^;
        @DebugPrint := FindFuncEntry (HASH_DaemonLibrary, HASH_DebugPrint);
        DebugPrint ('DefaultDaemon DLLEntryPoint');
      end else
        Raise Exception.Create('非法方式加载模块');
    end;
    DLL_PROCESS_DETACH: begin
 
    end;
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



