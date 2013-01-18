library SilkRoadDaemon;

uses
  SysUtils, Windows, Classes;

{$I PlugsHolder.inc}

var
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  lpvReserved: Pointer;


////////////////////////////////////////////////////////////////////////////////
///                     函数库初始化
////////////////////////////////////////////////////////////////////////////////

Procedure InitialLibrary (lpvReserved: Pointer);
begin
  FindFuncEntry := PPointer(lpvReserved)^;
end;

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
      if Assigned (lpvReserved) then
      begin
        InitialLibrary (lpvReserved);
      end else
        Raise Exception.Create('非法方式加载模块');
    end;
    DLL_PROCESS_DETACH: begin
 
    end;
  end;
end;

begin
  lpvReserved := GetReservedParam;
  DLLProc := @DLLEntryPoint;
  DLLEntryPoint(DLL_PROCESS_ATTACH);
end.



