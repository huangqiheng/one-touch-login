unit PlugKernelLib;

interface
uses windows, sysUtils, classes;

{$I ..\Plugin\PlugKernelDef.inc}

function Version (): PChar; Stdcall;

Function TaskCreate (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall;
Function TaskDestroy (Task: THandle; AppExit: BOOL): BOOL; Stdcall;
Function TaskConfig (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall;
Function TaskPlugin (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall;
Function TaskRun (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall;
Function TaskRunning (Task: THandle): BOOL; Stdcall;
Function TaskAppData (Task: THandle; DataBuff: PChar; DataSize: Integer): BOOL; Stdcall;
Function TaskCopy (Task: THandle): THandle; Stdcall;


Type
  TMsgCallBack = Procedure (Sender: Pointer; MsgBuf: Pointer; MsgSize: Integer); Stdcall;

function CreateMsgServer (IpcName: PChar; MsgCallBack, Sender: Pointer): BOOL; Stdcall;
function CreateMsgServerEx (IpcName: PChar; MsgCallBack, Sender: Pointer; MaxMsgSize, MaxPushTime: Integer): BOOL; Stdcall; 
function SendMsgToServer (IpcName: PChar; MsgBuf: Pointer; MsgSize: Integer): BOOL; Stdcall;
function SendMsgToServerEx (IpcName: PChar; MsgBuf: Pointer; MsgSize: Integer): BOOL; Stdcall;
function CloseMsgServer (IpcName: PChar): BOOL; Stdcall;

type
  TSyncQueueProcedure = procedure (Sender:Pointer; Buffer:Pointer; Size:Integer; var Rollback: BOOL); Stdcall;

function  MakeSyncQueue (Handler: TSyncQueueProcedure; DurationIdleTime: DWORD = 10000): THandle; Stdcall;
Procedure PushSyncQueue (Handle: THandle; Sender, Buffer: Pointer; Size: Integer); Stdcall;
function  GetSyncQueueCount (Handle: THandle): Integer; Stdcall;
Procedure FreeSyncQueue (Handle: THandle); Stdcall;

function WriteMemory(pAddress:pointer; pBuf:pointer; dwLen:dword):LongBool; stdcall;
function GetCallingImage: THandle; Register;
function GetCallingAddr: Pointer; Register;
function SetHook (HookAddress, JumpBackAddress, fnCallBack, fnCanBeHook : Pointer): LongBool; stdcall;
function UnHook (HookAddress: pointer): LongBool; stdcall;

function SMHookApi (FuncEntry, Hooker: Pointer): Pointer; stdcall;
function UnSMHookApi (FuncEntry: Pointer): LongBool; stdcall;

type
  TReportProc = Procedure (Sender: Pointer; Index: Integer; Size: Integer; var BreakReport: BOOL); Stdcall;
  TReportAddress = Procedure (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;
  TCodeSectionCallback = procedure (Sender: Pointer; CodeBase: Pointer; CodeSize: Integer); Stdcall;
  TRelocEnumProc = function (Sender: Pointer; RelocType: DWORD; RelocAddr: Pointer): BOOL; Stdcall;
  TExportEnumProc = function (Sender: Pointer; Name: PChar; Index: Integer; Entry: Pointer): BOOL; Stdcall;

function MakeTemplate (Base: Pointer; Size: Integer): THandle; stdcall;
function FreeTemplate (TmpHandle: THandle): LongBool; Stdcall;
function CompareTemplate (Sender: Pointer; TmpA, TmpB: THandle; Report: TReportProc): LongBool; Stdcall;
function FineAddress (TmpHandle: THandle; ToFind: PChar; ToFindSize: Integer; var List: TList): LongBool; Stdcall;
function SearchAddress (TmpHandle: THandle; Sender: Pointer; ToFind: PChar; ToFindSize: Integer; Report: TReportAddress): LongBool; Stdcall;

Function GetCodeSectionMemory (Handle: THandle; CallBack, Sender: Pointer):LongBool;stdcall;
Function GetSectionMemory (Handle: THandle; SectionName: PChar; var CodeBase: Pointer; var CodeSize: Integer):LongBool;stdcall;
function GetEntryPoint (Handle: THandle): Pointer; Stdcall;
function GetModuleSize (Handle: THandle): Integer; Stdcall;
function GetImageNtHeaders (Handle: THandle): PImageNtHeaders; Stdcall;
function GetSectionHeaders(Handle: THandle; var NumberOfSection: Integer):PImageSectionHeader;
function GetImageBase(CodeAddr: Pointer):Pointer; Stdcall;
function EnumRelocations (Handle: THandle; EnumProc, Sender: Pointer):BOOLEAN; STDCALL;
function EnumExports (Handle: THandle; EnumProc, Sender: Pointer):BOOLEAN; STDCALL;

Type
  LPTCodeInfos = ^TCodeInfos;
  TCodeInfos = packed record
    This        : pointer;   // where does this instruction begin?
    Opcode      : word;      // Opcode, one byte ($00xx) or two byte ($0fxx)
    ModRm       : byte;      // ModRm byte, if available, otherwise 0
    Call        : boolean;   // is this instruction a call?
    Jmp         : boolean;   // is this instruction a jmp?
    RelTarget   : boolean;   // is this target relative (or absolute)?
    Target      : pointer;   // absolute target address
    PTarget     : pointer;   // pointer to the target information in the code
    PPTarget    : PPointer; // pointer to pointer to the target information
    TargetSize  : integer;   // size of the target information in bytes (1/2/4)
    Next        : pointer;   // next code location
    CodeLen     : Integer;
    Code        : array[0..$F] of char;
    AsmStr      : array[0..$7F] of char;
  end;

type
  LPTFarCallData = ^TFarCallData;
  TFarCallData = packed record
    Call          : boolean;  // is it a CALL or a JMP?
    CodeAddr1     : pointer;  // beginning of call instruction
    CodeAddr2     : pointer;  // beginning of next instruction
    Target        : pointer;
    RelTarget     : boolean;
    PTarget       : pointer;
    PPTarget      : PPointer;
  end;

  LPTFuncInfos = ^TFuncInfos;
  TFuncInfos = packed record
    Size           : integer;
    EntryPoint      : pointer;
    CodeBegin      : pointer;
    CodeLen        : integer;
    FarCallsCount  : integer;
    FarCallsOffset : integer;
    AsmStr         : Array[0..0] of char;
  end;

function GetCodeDisAsm (Address: Pointer): LPTCodeInfos; Stdcall;
function GetCodeStruct (Entry: Pointer): LPTCodeInfos; Stdcall;
function GetFuncDisAsm (Entry: Pointer): LPTFuncInfos; Stdcall;
function GetFuncStruct (Entry: Pointer): LPTFuncInfos; Stdcall;
function GetCodeAssemble (Address: DWORD; OpCode: PChar; var CodeLen: Integer): Pointer; Stdcall;
         

Type
  LPTRegister = ^TRegister;
  TRegister = packed record
    EFLAGS: DWORD;
    EDI,
    ESI,
    EBP,
    ESP,
    EBX,
    EDX,
    ECX,
    EAX: DWORD;  
  end;

  TInfoCallback = Procedure (hTrap: THandle; EIP: Pointer; RegInfo: LPTRegister; DisAsm: PChar); Stdcall;

Function TrapDbgSetup (StartAddr, InfoCallback: Pointer; SuspendMode: BOOL): THandle; Stdcall;
Function TrapDbgWait (hTrap: THandle): BOOL; Stdcall;
Function TrapDbgStepInto (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;
Function TrapDbgStepOver (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;
Function TrapDbgRunUntilRet (hTrap: THandle): BOOL; Stdcall;
Function TrapDbgRunUntilAddr (hTrap: THandle; Addr: Pointer): BOOL; Stdcall;
Function TrapDbgRelease (hTrap: THandle): BOOL; Stdcall;

Type
  TIpcCmdRecver = procedure (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;


function CreateIpcServer (IpcName: PChar): THandle; Stdcall;
function AddIpcCommand (hServer: THandle; Cmd: PChar; Handler: Pointer): BOOL; Stdcall;
function EchoIpcCommand (hClient: THandle; Buffer: Pointer; Size: Integer): BOOL; Stdcall;
function DestroyIpcServer (hServer: THandle): BOOL; Stdcall;
function SendIpcCommand (IpcName, Cmd: PChar; TimeOut: DWORD; InBuffer: Pointer; InSize: DWORD; out OutBuffer: Pointer; out OutSize: DWORD): BOOL; Stdcall;


implementation

const
  LibName = 'PlugKernel.dll';

function Version (): PChar; Stdcall; external LibName name 'Version';

Function TaskCreate (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall; external LibName name 'TaskCreate';
Function TaskDestroy (Task: THandle; AppExit: BOOL): BOOL; Stdcall; external LibName name 'TaskDestroy';
Function TaskConfig (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall; external LibName name 'TaskConfig';
Function TaskPlugin (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall; external LibName name 'TaskPlugin';
Function TaskRun (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall; external LibName name 'TaskRun';
Function TaskRunning (Task: THandle): BOOL; Stdcall; external LibName name 'TaskRunning';
Function TaskAppData (Task: THandle; DataBuff: PChar; DataSize: Integer): BOOL; Stdcall; external LibName name 'TaskAppData';
Function TaskCopy (Task: THandle): THandle; Stdcall; external LibName name 'TaskCopy';

function CreateMsgServer (IpcName: PChar; MsgCallBack, Sender: Pointer): BOOL; Stdcall; external LibName name 'CreateMsgServer';
function CreateMsgServerEx (IpcName: PChar; MsgCallBack, Sender: Pointer; MaxMsgSize, MaxPushTime: Integer): BOOL; Stdcall; external LibName name 'CreateMsgServerEx';
function SendMsgToServer (IpcName: PChar; MsgBuf: Pointer; MsgSize: Integer): BOOL; Stdcall; external LibName name 'SendMsgToServer';
function SendMsgToServerEx (IpcName: PChar; MsgBuf: Pointer; MsgSize: Integer): BOOL; Stdcall; external LibName name 'SendMsgToServerEx';
function CloseMsgServer (IpcName: PChar): BOOL; Stdcall; external LibName name 'CloseMsgServer';

function  MakeSyncQueue (Handler: TSyncQueueProcedure; DurationIdleTime: DWORD = 10000): THandle; Stdcall; external LibName name 'MakeSyncQueue';
Procedure PushSyncQueue (Handle: THandle; Sender, Buffer: Pointer; Size: Integer); Stdcall; external LibName name 'PushSyncQueue';
function  GetSyncQueueCount (Handle: THandle): Integer; Stdcall; external LibName name 'GetSyncQueueCount';
Procedure FreeSyncQueue (Handle: THandle); Stdcall; external LibName name 'FreeSyncQueue';

function WriteMemory(pAddress:pointer; pBuf:pointer; dwLen:dword):LongBool; stdcall; external LibName name 'WriteMemory';
function GetCallingImage: THandle; Register;  external LibName name 'GetCallingImage';
function GetCallingAddr: Pointer; Register;  external LibName name 'GetCallingAddr';
function SetHook (HookAddress, JumpBackAddress, fnCallBack, fnCanBeHook : Pointer): LongBool; stdcall;  external LibName name 'SetHook';
function UnHook (HookAddress: pointer): LongBool; stdcall; external LibName name 'UnHook';

function SMHookApi (FuncEntry, Hooker: Pointer): Pointer; stdcall; external LibName name 'SMHookApi';
function UnSMHookApi (FuncEntry: Pointer): LongBool; stdcall; external LibName name 'UnSMHookApi';

function MakeTemplate (Base: Pointer; Size: Integer): THandle; stdcall; external LibName name 'MakeTemplate';
function FreeTemplate (TmpHandle: THandle): LongBool; Stdcall; external LibName name 'FreeTemplate';
function CompareTemplate (Sender: Pointer; TmpA, TmpB: THandle; Report: TReportProc): LongBool; Stdcall; external LibName name 'CompareTemplate';
function FineAddress (TmpHandle: THandle; ToFind: PChar; ToFindSize: Integer; var List: TList): LongBool; Stdcall; external LibName name 'FineAddress';
function SearchAddress (TmpHandle: THandle; Sender: Pointer; ToFind: PChar; ToFindSize: Integer; Report: TReportAddress): LongBool; Stdcall; external LibName name 'SearchAddress';

Function GetCodeSectionMemory (Handle: THandle; CallBack, Sender: Pointer):LongBool;stdcall; external LibName name 'GetCodeSectionMemory';
Function GetSectionMemory (Handle: THandle; SectionName: PChar; var CodeBase: Pointer; var CodeSize: Integer):LongBool;stdcall; external LibName name 'GetSectionMemory';
function GetEntryPoint (Handle: THandle): Pointer; Stdcall; external LibName name 'GetEntryPoint';
function GetModuleSize (Handle: THandle): Integer; Stdcall; external LibName name 'GetModuleSize';
function GetImageNtHeaders (Handle: THandle): PImageNtHeaders; Stdcall; external LibName name 'GetImageNtHeaders';
function GetSectionHeaders(Handle: THandle; var NumberOfSection: Integer):PImageSectionHeader; external LibName name 'GetSectionHeaders';
function GetImageBase(CodeAddr: Pointer):Pointer; Stdcall; external LibName name 'GetImageBase';
function EnumRelocations (Handle: THandle; EnumProc, Sender: Pointer):BOOLEAN; STDCALL; external LibName name 'EnumRelocations';
function EnumExports (Handle: THandle; EnumProc, Sender: Pointer):BOOLEAN; STDCALL; external LibName name 'EnumExports';

function GetCodeStruct (Entry: Pointer): LPTCodeInfos; Stdcall; external LibName name 'GetFuncStruct';
function GetCodeDisAsm (Address: Pointer): LPTCodeInfos; Stdcall; external LibName name 'GetCodeDisAsm';
function GetFuncDisAsm (Entry: Pointer): LPTFuncInfos; Stdcall; external LibName name 'GetFuncDisAsm';
function GetFuncStruct (Entry: Pointer): LPTFuncInfos; Stdcall; external LibName name 'GetFuncStruct';
function GetCodeAssemble (Address: DWORD; OpCode: PChar; var CodeLen: Integer): Pointer; Stdcall; external LibName name 'GetCodeAssemble';
                                   
Function TrapDbgSetup (StartAddr, InfoCallback: Pointer; SuspendMode: BOOL): THandle; Stdcall; external LibName name 'TrapDbgSetup';
Function TrapDbgWait (hTrap: THandle): BOOL; Stdcall; external LibName name 'TrapDbgWait';
Function TrapDbgStepInto (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;  external LibName name 'TrapDbgStepInto';
Function TrapDbgStepOver (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall; external LibName name 'TrapDbgStepOver';
Function TrapDbgRunUntilRet (hTrap: THandle): BOOL; Stdcall; external LibName name 'TrapDbgRunUntilRet';
Function TrapDbgRunUntilAddr (hTrap: THandle; Addr: Pointer): BOOL; Stdcall; external LibName name 'TrapDbgRunUntilAddr';
Function TrapDbgRelease (hTrap: THandle): BOOL; Stdcall; external LibName name 'TrapDbgRelease';
              
function CreateIpcServer (IpcName: PChar): THandle; Stdcall; external LibName name 'CreateIpcServer';
function AddIpcCommand (hServer: THandle; Cmd: PChar; Handler: Pointer): BOOL; Stdcall; external LibName name 'AddIpcCommand';
function EchoIpcCommand (hClient: THandle; Buffer: Pointer; Size: Integer): BOOL; Stdcall; external LibName name 'EchoIpcCommand';
function DestroyIpcServer (hServer: THandle): BOOL; Stdcall; external LibName name 'DestroyIpcServer';
function SendIpcCommand (IpcName, Cmd: PChar; TimeOut: DWORD; InBuffer: Pointer; InSize: DWORD; out OutBuffer: Pointer; out OutSize: DWORD): BOOL; Stdcall; external LibName name 'SendIpcCommand';

end.
