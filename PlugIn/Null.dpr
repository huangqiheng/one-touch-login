library Null;

uses
  SysUtils, Windows, Classes, GlobalObject;

{$I PlugBase.inc}

const
  //ϵͳҪ��
  Param_Depend_Daemon     = 'Daemon=<>�벻Ҫ�ı��Ĭ��ֵ';    //�ڲ�����ʱ������Ĭ��ֵ
  Param_Depend_PlugBase   = 'PlugBase=<DefaultPlugBase.dll>�벻Ҫ�ı��Ĭ��ֵ';  //�ڲ�����ʱ������Ĭ��ֵ
  Param_Depend_Library    = 'PluginLib=<>��ҪԤ�ȼ��صĿ�,����趺�Ÿ���';
  Param_PrivacyField      = 'PrivacyField=<>���ܸı��Ĭ��ֵ��������������������,����趺�Ÿ���'; //��PasswordFieldΪ��ʱ����������Ϸ�������롣


function GetParamList: PChar; Stdcall;
var
  ResultTmp: String;
begin
  With TStringList.Create do
  try
    Append(Param_Depend_Daemon);
    Append(Param_Depend_PlugBase);
    Append(Param_Depend_Library);
    Append(Param_PrivacyField);
    ResultTmp := Text;
    Result := PChar(ResultTmp);
  finally
    Free;
  end;     
end;

function IsTargetApp (AppPath: PChar): BOOL; Stdcall;
begin
  Result := True;
end;

function IsAutoSet: BOOL; Stdcall;
begin
  Result := False;
end;

function Usage: PChar; Stdcall;
begin
  Result := '����TYPE_PLUGIN Null.dll�����ʹ�ð���';
end;

function PluginType: PChar; Stdcall;
begin
  Result := TYPE_PLUGIN;
end;

Exports
  IsAutoSet name 'IsAutoSet',
  IsTargetApp  name 'IsTarget',
  GetParamList name 'ParamList',
  Usage name 'Help',
  PluginType name 'Type';

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////  

var
  lpvReserved: PPointer;
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  DebugPrint: Procedure (Msg: PChar); stdcall;

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
//      @DebugPrint := FindFuncEntry (HASH_PlugBaseLibrary, HASH_DebugPrint);
//      DebugPrint ('Null plugin started!');
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
