library SilkRoadDaemon;

uses
  SysUtils, Windows, Classes;

{$I PlugsHolder.inc}

var
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  lpvReserved: Pointer;


////////////////////////////////////////////////////////////////////////////////
///                     �������ʼ��
////////////////////////////////////////////////////////////////////////////////

Procedure InitialLibrary (lpvReserved: Pointer);
begin
  FindFuncEntry := PPointer(lpvReserved)^;
end;

////////////////////////////////////////////////////////////////////////////////
///                     DLL ���
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
        Raise Exception.Create('�Ƿ���ʽ����ģ��');
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



