unit ImportUnit;

interface
uses windows, sysutils, classes;

{$I PlugBase.inc}

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
  TMsgCallBack = Procedure (Sender: Pointer; MsgBuf: Pointer; MsgSize: Integer); Stdcall;
  TIpcCmdRecver = procedure (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;

  LPTMemBlock = ^TMemBlock;
  TMemBlock = packed record
    Address: Pointer;
    Size: Integer;
  end;

  LPTMemBuffer = ^TMemBuffer;
  TMemBuffer = packed record
    Address: Pointer;
    BuffSize: DWORD;
    Buffer: Array[0..0] of char;
  end;

  LPTReport = ^TReport;
  TReport = packed record
    ReportType: Integer;
    hAimHandle: THandle;
  end;

  LPTBreakStart = ^TBreakStart;
  TBreakStart = packed record
    Report: TReport;
    Start: Pointer;
  end;

  LPTBreakEnd = ^TBreakEnd;
  TBreakEnd = TReport;

  LPTBreakDetail = ^TBreakDetail;
  TBreakDetail = packed record
    Report: TReport;
    EIP: Pointer;
    StackBase: Pointer;
    StackLimit: Pointer;
    RegInfoReal: Pointer; //线程中真正的LPTRegister内容
    RegInfo: TRegister;   //这是复制到内容
    DisAsm: Array[Byte] of char;
  end;

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

  LPTFunctionMap = ^TFunctionMap;
  TFunctionMap = packed record
    Report: TReport;
    ImageBase: Pointer;
    ImageSize: Integer;
    EntryAddr: Pointer;
    FuncCount: WORD;
    Buffer: Array[0..0] of char;
  end;

  LPTFuncNode = ^TFuncNode;
  TFuncNode = record
    Base: Pointer;
    Size: Integer;
    DisAsm: String;
    CallTos: Array of pointer;
    CallFroms: Array of pointer;
  end;

  LPTFuncNodeStore = ^TFuncNodeStore;
  TFuncNodeStore = packed record
    Size: Integer;
    CodeBase: Pointer;
    CodeSize: Integer;
    CallTosOffset: Integer;
    CallTosCount: Integer;
    CallFromsOffset: Integer;
    CallFromsCount: Integer;
    AsmStrOffset: Integer;
    Buffer: Array[0..0] of char;
  end;

type
  TReportProc = Procedure (Sender: Pointer; Index: Integer; Size: Integer; var BreakReport: BOOL); Stdcall;
  TReportAddress = Procedure (Sender: Pointer; Found: Pointer; var BreakReport: BOOL); Stdcall;
  TSectionCallback = procedure (Sender: Pointer; CodeBase: Pointer; CodeSize: Integer); Stdcall;
  TRelocEnumProc = function (Sender: Pointer; RelocType: DWORD; RelocAddr: Pointer): BOOL; Stdcall;
  TExportEnumProc = function (Sender: Pointer; Name: PChar; Index: Integer; Entry: Pointer): BOOL; Stdcall;



var
  FindFuncEntry: function (LibNameCRC, FuncNameCRC: LongWord): POINTER; stdcall;
  TrapDbgSetup: Function (StartAddr, InfoCallback: Pointer; SuspendMode: BOOL): THandle; Stdcall;
  TrapDbgWait: Function (hTrap: THandle): BOOL; Stdcall;
  TrapDbgStepInto: Function (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;
  TrapDbgStepOver: Function (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;
  TrapDbgRunUntilRet: Function (hTrap: THandle): BOOL; Stdcall;
  TrapDbgRunUntilAddr: Function (hTrap: THandle; Addr: Pointer): BOOL; Stdcall;
  TrapDbgRelease: Function (hTrap: THandle): BOOL; Stdcall;
  CreateMsgServer: function (IpcName: PChar; MsgCallBack, Sender: Pointer): BOOL; Stdcall;
  SendMsgToServer: function (IpcName: PChar; MsgBuf: Pointer; MsgSize: Integer): BOOL; Stdcall;
  CloseMsgServer: function (IpcName: PChar): BOOL; Stdcall;
  GetConfig: function (Key: PChar): PChar; Stdcall;
  OnMsgError: function (Msg: PChar): BOOL; Stdcall;
  OnMsgDebug: function (Msg: PChar): BOOL; Stdcall;
  OnMsgLog: function (Msg: PChar): BOOL; Stdcall;
  OnMsgNotice: function (Msg: PChar): BOOL; Stdcall;
  CreateIpcServer: function (IpcName: PChar): THandle; Stdcall;
  AddIpcCommand: function (hServer: THandle; Cmd: PChar; Handler: Pointer): BOOL; Stdcall;
  EchoIpcCommand: function (hClient: THandle; Buffer: Pointer; Size: Integer): BOOL; Stdcall;
  DestroyIpcServer: function (hServer: THandle): BOOL; Stdcall;
  SendIpcCommand: function (IpcName, Cmd: PChar; TimeOut: DWORD; InBuffer: Pointer; InSize: DWORD; out OutBuffer: Pointer; out OutSize: DWORD): BOOL; Stdcall;
  WriteMemory: function (pAddress:pointer; pBuf:pointer; dwLen:dword):LongBool; stdcall;
  GetCodeStruct: function  (Address: Pointer): LPTCodeInfos; Stdcall;
  GetCodeDisAsm: function (Address: Pointer): LPTCodeInfos; Stdcall;
  GetFuncDisAsm: function (Entry: Pointer): LPTFuncInfos; Stdcall;
  GetEntryPoint: function (Handle: THandle): Pointer; Stdcall;
  GetFuncStruct: function (Entry: Pointer): LPTFuncInfos; Stdcall;
  GetModuleSize: function (Handle: THandle): Integer; Stdcall;
  GetImageBase: function (CodeAddr: Pointer):Pointer; Stdcall;
  GetCodeSectionMemory: Function (Handle: THandle; CallBack, Sender: Pointer):LongBool;stdcall;
  GetDataSectionMemory: Function (Handle: THandle; CallBack, Sender: Pointer):LongBool;stdcall;
  GetSectionHeaders: function (Handle: THandle; var NumberOfSection: Integer):PImageSectionHeader; STDCALL;
  EnumRelocations: function (Image: THandle; EnumProc, Sender: Pointer):BOOLEAN; STDCALL;
  EnumExports: function (Handle: THandle; EnumProc, Sender: Pointer):BOOLEAN; STDCALL;


  
Procedure ImportLib (lpReserved: Pointer);

implementation

Procedure ImportLib (lpReserved: Pointer);
begin
  @FindFuncEntry := lpReserved;
  @GetConfig := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetConfig);

  @TrapDbgSetup := FindFuncEntry (HASH_PlugBaseLibrary, HASH_TrapDbgSetup);
  @TrapDbgRelease := FindFuncEntry (HASH_PlugBaseLibrary, HASH_TrapDbgRelease);
  @TrapDbgWait := FindFuncEntry (HASH_PlugBaseLibrary, HASH_TrapDbgWait);

  @TrapDbgStepInto := FindFuncEntry (HASH_PlugBaseLibrary, HASH_TrapDbgStepInto);
  @TrapDbgStepOver := FindFuncEntry (HASH_PlugBaseLibrary, HASH_TrapDbgStepOver);
  @TrapDbgRunUntilRet := FindFuncEntry (HASH_PlugBaseLibrary, HASH_TrapDbgRunUntilRet);
  @TrapDbgRunUntilAddr := FindFuncEntry (HASH_PlugBaseLibrary, HASH_TrapDbgRunUntilAddr);

  @CreateMsgServer := FindFuncEntry (HASH_PlugBaseLibrary, HASH_CreateMsgServer);
  @SendMsgToServer := FindFuncEntry (HASH_PlugBaseLibrary, HASH_SendMsgToServer);
  @CloseMsgServer := FindFuncEntry (HASH_PlugBaseLibrary, HASH_CloseMsgServer);

  @OnMsgError := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgError);
  @OnMsgDebug := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgDebug);
  @OnMsgLog := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgLog);
  @OnMsgNotice := FindFuncEntry (HASH_PlugBaseLibrary, HASH_OnMsgNotice);

  @CreateIpcServer := FindFuncEntry (HASH_PlugBaseLibrary, HASH_CreateIpcServer);
  @AddIpcCommand := FindFuncEntry (HASH_PlugBaseLibrary, HASH_AddIpcCommand);
  @EchoIpcCommand := FindFuncEntry (HASH_PlugBaseLibrary, HASH_EchoIpcCommand);
  @DestroyIpcServer := FindFuncEntry (HASH_PlugBaseLibrary, HASH_DestroyIpcServer);
  @SendIpcCommand := FindFuncEntry (HASH_PlugBaseLibrary, HASH_SendIpcCommand);

  @WriteMemory := FindFuncEntry (HASH_PlugBaseLibrary, HASH_WriteMemory);
  @GetCodeDisAsm:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetCodeDisAsm);
  @GetCodeStruct:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetCodeStruct);
  @GetFuncDisAsm:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetFuncDisAsm);
  @GetFuncStruct:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetFuncStruct);

  @GetImageBase := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetImageBase);
  @GetEntryPoint:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetEntryPoint);
  @GetModuleSize:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetModuleSize);
  @GetCodeSectionMemory := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetCodeSectionMemory);
  @GetDataSectionMemory := FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetDataSectionMemory);
  @GetSectionHeaders:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_GetSectionHeaders);
  @EnumRelocations:= FindFuncEntry (HASH_PlugBaseLibrary, HASH_EnumRelocations);
  @EnumExports := FindFuncEntry (HASH_PlugBaseLibrary, HASH_EnumExports);


end;

end.
