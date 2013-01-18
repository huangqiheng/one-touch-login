unit TrapDbgUnit;

interface

uses windows, sysutils, classes;

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


//1）创建一个断点任务
Function TrapDbgSetup (StartAddr, InfoCallback: Pointer; SuspendMode: BOOL): THandle; Stdcall;

//2）断点回调函数里等待用
Function TrapDbgWait (hTrap: THandle): BOOL; Stdcall;

//3）步进，当遇到call时，就会进入函数体内
Function TrapDbgStepInto (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;

//4）步过，当遇到call时，执行函数后返回
Function TrapDbgStepOver (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;

//5）运行到返回，一直StepOver步过，直到遇到ret指令
Function TrapDbgRunUntilRet (hTrap: THandle): BOOL; Stdcall;

//6）运行到指定地址返回，一直StepOver步过，
Function TrapDbgRunUntilAddr (hTrap: THandle; Addr: Pointer): BOOL; Stdcall;

//7）结束本次单步跟踪，放行线程，销毁一个断点任务，从断点列表中删除
Function TrapDbgRelease (hTrap: THandle): BOOL; Stdcall;


var
  DbgOut: Procedure (Msg: String); 

implementation

uses madDisasm, SyncObjs, TCodeEventNotify, TDStkQue;

Procedure DbgMsg (Msg: String);
begin
  if Assigned (DbgOut) then
    DbgOut (Msg);
end;

Function TrapDbgSetEvent (hTrap: THandle): BOOL; Stdcall; forward;

Type
  TUserCmd = (ucNone, ucStepInto, ucStepOver, ucRunUntilRet, ucRunUntilAddr, ucRun);

  LPTJmpCode = ^TJmpCode; 
  TJmpCode = packed record
    JmpOpt: WORD;  //FF25 44444444
    JmpAim: Pointer; //jmp dword ptr [$44444444]
  end;

  LPTCallCode = ^TCallCode;
  TCallCode = packed record
    CallOpt: WORD;   //FF1504000000
    CallAim: Pointer;   //call dword ptr [$00000004]
  end;

  LPTCallInCode = ^TCallInCode;
  TCallInCode = packed record
    push: Byte;  //6845454545
    pushAddr: Pointer;   //push $45454545
    CallTo: TJmpCode;  //jmp dword ptr [$00000055]
  end;

  LPTBreakInfo = ^TBreakInfo;
  TBreakInfo = packed record
    Task: THandle;      
    BreakAddr: Pointer;
    SaveReg: TRegister;
    UserCmd: TUserCmd;
    WhoJmp2Me: LPTBreakInfo;
    WhoBrother: LPTBreakInfo;
    Jmp2MeCode, Jmp2NextCode: Pointer;
    JmpTrapHeadSize: Integer;
    JmpTrapCode: Array[0..0] of char;
  end;

  LPTBreakPointTask = ^TBreakPointTask;
  TBreakPointTask = packed record
    Active: BOOL;
    StartAddr: Pointer;
    StartCode: Array[0..SizeOf(TJmpCode) - 1] of char; 
    SyncBreak: TCriticalSection;
    Wait: TEvent;
    Finish: TEvent;
    InfoCallback: TInfoCallback;
    SuspendMode: BOOL;
    ThreadCount: Integer;
    RunUntilAddr: Pointer;
    WaittingCmd: BOOL;
    Breaking: LPTBreakInfo;
  end;

Function TrapDbgCmd (hTrap: THandle; UserCmd: TUserCmd): BOOL; forward;
Function TrapDbgBegin (hTrap: THandle): BOOL; forward;
Procedure TrapDbgEnd (hTrap: THandle; CodeInfo: TCodeInfo; RegInfo: LPTRegister); forward;
function IsTaskValid (hTrap: THandle): BOOL; Stdcall; forward;
function GetExecMemory (Size: Integer): Pointer; forward;
procedure FreeExecMemory (Mem: Pointer); forward;
function GetBreakCode (): LPTBreakInfo; forward;
Procedure BreakPointHandler (Sender: LPTBreakInfo; RegInfo: LPTRegister); Stdcall; forward;



Var
  BreakCrisn: TCriticalSection;
  BreakList: TThreadList;
  BreakPointHandlerVar: Pointer;

Procedure Initial;
begin
  if not assigned (BreakCrisn) then
    BreakCrisn := TCriticalSection.Create;
  if not assigned (BreakList) then
    BreakList := TThreadList.Create;
  BreakPointHandlerVar := @BreakPointHandler;
end;

Function CanBeSetTrapStarter (hTrap: THandle): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := CompareMem (@BreakTask.StartCode[0], BreakTask.StartAddr, SizeOf(TJmpCode));
end;

Procedure BackupJmpTrapStarter (hTrap: THandle); Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  CopyMemory (@BreakTask.StartCode[0], BreakTask.StartAddr, SizeOf(TJmpCode));
end;

Procedure ResumeJmpTrapStarter (hTrap: THandle); Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  if not CompareMem (BreakTask.StartAddr, @BreakTask.StartCode[0], SizeOf(TJmpCode)) then
  begin
    WriteMemory (BreakTask.StartAddr, @BreakTask.StartCode[0], SizeOf(TJmpCode));
  end;
end;


 
Type
  LPTJmpTrapHead = ^TJmpTrapHead;
  TJmpTrapHead = packed record
    pushfd: Byte;
    pushad: Byte;
    pushEsp: Byte;
    pushTask: record
      Opt: Byte;
      Value: Pointer;
    end;
    callHook: record
      Opt: WORD;
      Value: Pointer;
    end;
    popad: Byte;
    popfd: Byte;
  end;
  
//00453246 9C               pushfd
//00453247 60               pushad
//00453248 54               push esp
//00453249 6877777777       push $77777777
//0045324E FF1599999999     call dword ptr [$99999999]
//00453254 61               popad
//00453255 9D               popfd
//00453258 C3               ret
Procedure JmpTrapSample;
asm
  Pushad   //把EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI依次压入堆栈.
  Pushfd   //吧EFLAGS标志寄存器压入栈
  //-----------------------------------
  Push esp //LPTRegister
  Push $77777777
  Call dword ptr [$99999999]
  //-----------------------------------
  Popfd
  popad
end;

function GetJmpTrapHead: LPTJmpTrapHead;
begin
  Result := @JmpTrapSample;
end;

function MakeABreakCode (Task: THandle; BreakAddr: Pointer; InitUserCmd: TUserCmd):LPTBreakInfo;
var
  JmpTrapHead: LPTJmpTrapHead;
  BreakTask: LPTBreakPointTask absolute Task;
begin
  Result := GetBreakCode();
  Result.Task := Task;
  Result.BreakAddr := BreakAddr;
  Result.WhoJmp2Me := BreakTask.Breaking;
  Result.WhoBrother := nil;
  Result.UserCmd := InitUserCmd;
  Result.JmpTrapHeadSize := SizeOf(TJmpTrapHead);
  JmpTrapHead := @Result.JmpTrapCode[0];
  CopyMemory (JmpTrapHead, GetJmpTrapHead(), Result.JmpTrapHeadSize);

  JmpTrapHead.pushTask.Value := Result;
  JmpTrapHead.callHook.Value := @BreakPointHandlerVar;
end;

function MakeABreakCodeJumper (FromAddr: Pointer; BreakInfo: LPTBreakInfo; ForceWrite: BOOL): BOOL;
var
  JmpCode: TJmpCode;
begin
  BreakInfo.Jmp2MeCode := @BreakInfo.JmpTrapCode[0];
  JmpCode.JmpOpt := $25FF;
  JmpCode.JmpAim := @BreakInfo.Jmp2MeCode;
  if ForceWrite then
    Result := WriteMemory (FromAddr, @JmpCode, SizeOf(TJmpCode))
  else
  begin
    CopyMemory (FromAddr, @JmpCode, SizeOf(TJmpCode));
    Result := True;
  end;
end;

function MakeBreakCodeTrain (Task: THandle; JmpFromAddr, BreakAddr: Pointer; InitUserCmd: TUserCmd; ForceWrite: BOOL = False): LPTBreakInfo;
begin
  Result := MakeABreakCode (Task, BreakAddr, InitUserCmd);
  MakeABreakCodeJumper (JmpFromAddr, Result, ForceWrite);
end;

function MakeBreakCodeTrainB (Task: THandle; WriteInTarget, BreakAddr: Pointer; InitUserCmd: TUserCmd): LPTBreakInfo;
begin
  Result := MakeABreakCode (Task, BreakAddr, InitUserCmd);
  Result.Jmp2MeCode := @Result.JmpTrapCode[0];
  PPointer(WriteInTarget)^ := @Result.Jmp2MeCode;
end;

function MakeBreakCodeTrainC (Task: THandle; WriteInTarget, BreakAddr: Pointer; InitUserCmd: TUserCmd): LPTBreakInfo;
begin
  Result := MakeABreakCode (Task, BreakAddr, InitUserCmd);
  PPointer(WriteInTarget)^ := @Result.JmpTrapCode[0];
end;

function CheckActiveTask (StartAddr: Pointer): THandle;
var
  Items: TList;
  BreakTask: LPTBreakPointTask;
  Index: Integer;
begin
  Result := 0;
  Items := BreakList.LockList;
  for Index := 0 to Items.Count - 1 do
  begin
    BreakTask := Items[Index];
    if BreakTask.StartAddr = StartAddr then
      if BreakTask.Active then
      begin
        Result := THandle(BreakTask);
        Break;
      end;
  end;
  BreakList.UnlockList;
end;

//1）创建一个断点任务
Function TrapDbgSetup (StartAddr, InfoCallback: Pointer; SuspendMode: BOOL): THandle; Stdcall;
var
  BreakTask: LPTBreakPointTask;
  CheckHandle: THandle;
begin
  Initial;

  CheckHandle := CheckActiveTask (StartAddr);
  if CheckHandle > 0 then
    if not CanBeSetTrapStarter (CheckHandle) then
    begin
      Result := 0;
      Exit;
    end;

  BreakTask := AllocMem (SizeOf(TBreakPointTask));
  BreakTask.StartAddr := StartAddr;
  BreakTask.Breaking := NIL;
  BreakTask.RunUntilAddr := NIL;
  @BreakTask.InfoCallback := InfoCallback;
  BreakTask.SuspendMode := SuspendMode;
  BreakTask.ThreadCount := 0;
  BreakTask.SyncBreak := TCriticalSection.Create;
  BreakTask.Wait := TEvent.Create;
  BreakTask.Finish := TEvent.Create;
  Result := THandle (BreakTask);
  BreakList.Add(BreakTask);

  BackupJmpTrapStarter (Result);
  MakeBreakCodeTrain (Result, StartAddr, StartAddr, ucNone, True);

  BreakTask.Active := True;
end;

Function TrapDbgCmd (hTrap: THandle; UserCmd: TUserCmd): BOOL;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := False;
  if Assigned (BreakTask) then
    if Assigned (BreakTask.Breaking) then
    begin
      BreakTask.Breaking.UserCmd := UserCmd;
      Result := True;
    end;
end;

//6）结束本次单步跟踪，放行线程，从断点列表中删除
Function TrapDbgRelease (hTrap: THandle): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := IsTaskValid (hTrap);
  if Result then
  begin
    ResumeJmpTrapStarter (hTrap);
    TrapDbgCmd (hTrap, ucRun);
    BreakTask.Active := False;

    BreakTask.Wait.SetEvent;
    BreakTask.Finish.ResetEvent;
    BreakTask.Finish.WaitFor(180);

    FreeAndNil (BreakTask.SyncBreak);
    FreeAndNil (BreakTask.Wait);
    FreeAndNil (BreakTask.Finish);
    Result := True;    
  end;       
end;

Function TrapDbgSetEvent (hTrap: THandle): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := False;
  if Assigned (BreakTask.Wait) then
  begin
    BreakTask.Wait.SetEvent;
    Result := True;
  end;
end;

Function TrapDbgWait (hTrap: THandle): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := False;
  if Assigned (BreakTask.Wait) then
  begin
    BreakTask.Wait.WaitFor(INFINITE);
    Result := True;
  end;
end;

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////

function GetExecMemory (Size: Integer): Pointer;
begin
  Result := VirtualAlloc(nil, Size, MEM_COMMIT,PAGE_EXECUTE_READWRITE);
end;

procedure FreeExecMemory (Mem: Pointer);
begin
  VirtualFree (Mem, 0, MEM_RELEASE);
end;


procedure SampleMaxCodeSize;
asm
  jmp dword ptr [$0]
  jmp dword ptr [$2]
  jmp dword ptr [$3]
end;
procedure SampleMaxCodeSize_End; begin end;

var
  MemQueue: TtdQueue;

function GetBreakCode (): LPTBreakInfo;
var
  GuestSize: Integer;
begin
  if not assigned (MemQueue) then
    MemQueue := TtdQueue.Create(nil);

  if MemQueue.IsEmpty then
  begin
    GuestSize := Integer(@SampleMaxCodeSize_End) - Integer(@SampleMaxCodeSize);
    GuestSize := SizeOf(TBreakInfo) + SizeOf(TJmpTrapHead) + GuestSize;
    GuestSize := (GuestSize shr 5 + 1) shl 5;
    Result := GetExecMemory (GuestSize);
  end else
  begin
    Result := MemQueue.Dequeue;
  end;    
end;

procedure RecycleBreakCode (Used: LPTBreakInfo);
begin
  if not assigned (MemQueue) then
    MemQueue := TtdQueue.Create(nil);
  MemQueue.Enqueue(Used);
end;


//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////

function IsRetCode (Addr: Pointer): BOOL;
var
  RetSign: PByte absolute Addr;
begin
  Result := RetSign^ in [$C2,$C3,$CA,$CB];
end;

function IsNeedReport (BreakTask: LPTBreakPointTask): BOOL;
var
  BreakInfo: LPTBreakInfo;
begin
  BreakInfo := BreakTask.Breaking;

  case BreakInfo.UserCmd of
    ucRunUntilRet:  Result := IsRetCode (BreakInfo.BreakAddr);
    ucRunUntilAddr: Begin
      Result := BreakInfo.BreakAddr = BreakTask.RunUntilAddr;
      if Result then
        BreakTask.RunUntilAddr := NIL;
    end
    else Result := True;
  end;
end;

function IsTaskValid (hTrap: THandle): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
  ItemList: TList;
begin
  Result := False;
  if hTrap = 0 then Exit;
  if IsBadReadPtr (Pointer(hTrap), SizeOf(TBreakPointTask)) then Exit;
  if not assigned (BreakTask.StartAddr) then Exit;
  if not assigned (BreakTask.InfoCallback) then Exit;
  if not BreakTask.Active then Exit;      

  ItemList := BreakList.LockList;  
  Result := ItemList.IndexOf(Pointer(hTrap)) >= 0;
  BreakList.UnlockList;
end;

//3）步进，当遇到call时，就会进入函数体内
Function TrapDbgStepInto (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  if NoWait then
  begin
    Result := TrapDbgCmd (hTrap, ucStepInto);
    Exit;
  end;

  Result := IsTaskValid (hTrap);
  if Result then
  begin
    Result := TrapDbgCmd (hTrap, ucStepInto);
    TrapDbgSetEvent (hTrap);
  end;
end;


//4）步过，当遇到call时，执行函数后返回
Function TrapDbgStepOver (hTrap: THandle; NoWait: BOOL): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  if NoWait then
  begin
    Result := TrapDbgCmd (hTrap, ucStepOver);
    Exit;
  end;

  Result := IsTaskValid (hTrap);
  if Result then
  begin
    Result := TrapDbgCmd (hTrap, ucStepOver);
    TrapDbgSetEvent (hTrap);
  end;
end;


//5）运行到返回，一直StepOver步过，直到遇到ret指令
Function TrapDbgRunUntilRet (hTrap: THandle): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := IsTaskValid (hTrap);
  if Result then
  begin
    TrapDbgCmd (hTrap, ucRunUntilRet);
    TrapDbgSetEvent (hTrap);
  end;
end;

Function TrapDbgRunUntilAddr (hTrap: THandle; Addr: Pointer): BOOL; Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := IsTaskValid (hTrap);
  if Result then
  begin
    TrapDbgCmd (hTrap, ucRunUntilAddr);
    BreakTask.RunUntilAddr := Addr;
    TrapDbgSetEvent (hTrap);
  end;
end;


Procedure SuspendOtherThread (hTrap: THandle); Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  if BreakTask.SuspendMode then
  begin

  end;
end;

Procedure ResumeOtherThread (hTrap: THandle); Stdcall;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  if BreakTask.SuspendMode then
  begin

  end;
end;

function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

function GetOperateList (InputStr: String): String;
var
  Iter: Char;
begin
  Result := '';
  for Iter in InputStr do
    if (Iter = '-') or (Iter = '+') then
      Result := Result + Iter;
end;

function GetRegistValue (RegStr: String; RegInfo: LPTRegister): DWORD;
var
  var64: Int64;
begin
  Result := 0;
  if      RegStr = 'eax' then  Result := RegInfo.EAX
  else if RegStr = 'ecx' then  Result := RegInfo.ECX
  else if RegStr = 'edx' then  Result := RegInfo.EDX
  else if RegStr = 'ebx' then  Result := RegInfo.EBX
  else if RegStr = 'esp' then  Result := RegInfo.ESP
  else if RegStr = 'ebp' then  Result := RegInfo.EBP
  else if RegStr = 'esi' then  Result := RegInfo.ESI
  else if RegStr = 'edi' then  Result := RegInfo.EDI
  else if TryStrToInt64(RegStr, var64) then Result := DWORD(var64);
end;

procedure CodeInfoCheckpoint (var CodeInfo: TCodeInfo; DisAsm: String; RegInfo: LPTRegister);
var
  ValStr: String;
  PosLeft, PosRight: Integer;
  RegSL: TSTringList;
  OptList: String;
  Index: Integer;
  TotalVal, RegValue: DWORD;
begin
  if CodeInfo.Call or CodeInfo.Jmp then
    if CodeInfo.Target = nil then
    begin
      PosLeft := Pos('[', DisAsm);
      PosRight := Pos(']', DisAsm);
      if PosRight - PosLeft > 2 then
      begin
        ValStr := Copy (DisAsm, PosLeft + 1, PosRight - PosLeft - 1);
        RegSL := GetSplitBlankList (ValStr, ['-','+']);
        OptList := GetOperateList (ValStr);

        if RegSL.Count - Length(OptList) = 1 then
        begin
          TotalVal := GetRegistValue (RegSL[0], RegInfo);
          for Index := 1 to RegSL.Count - 1 do
          begin
            RegValue := GetRegistValue (RegSL[Index], RegInfo);
            if OptList[Index] = '+' then
              Inc (TotalVal, RegValue)
            else 
              Dec (TotalVal, RegValue);
          end;

          if not IsBadReadPtr (Pointer(TotalVal), 4) then
            CodeInfo.Target := PPointer(TotalVal)^;
        end;     
         
        RegSL.Free;
      end;
       
    end;
end;


//1）断点进入同步模式
Function TrapDbgBegin (hTrap: THandle): BOOL;
var
  BreakTask: LPTBreakPointTask absolute hTrap;
begin
  Result := True;
  if BreakTask.StartAddr = BreakTask.Breaking.BreakAddr then
  begin
    if Assigned (BreakTask.SyncBreak) then
      BreakTask.SyncBreak.Enter;

    ResumeJmpTrapStarter (hTrap);
    Inc (BreakTask.ThreadCount);
    Result := BreakTask.ThreadCount = 1;

    if Assigned (BreakTask.SyncBreak) then
      BreakTask.SyncBreak.Leave;

    if Result then
    begin
      SuspendOtherThread (hTrap);
    end;
  end else
  begin
    RecycleBreakCode (BreakTask.Breaking.WhoJmp2Me);
    if Assigned (BreakTask.Breaking.WhoBrother) then
      RecycleBreakCode (BreakTask.Breaking.WhoBrother);   
  end;                     
end;


//断点处理函数
Procedure BreakPointHandler (Sender: LPTBreakInfo; RegInfo: LPTRegister); Stdcall;
var
  BreakTask: LPTBreakPointTask;
  CodeInfo: TCodeInfo;
  DisAsm: String;
Begin
  Sender.SaveReg := RegInfo^;
  BreakTask := Pointer(Sender.Task);
  BreakTask.Breaking := Sender;

  if TrapDbgBegin (Sender.Task) then
  begin
    CodeInfo := ParseCode (BreakTask.Breaking.BreakAddr, DisAsm);
    if IsNeedReport (BreakTask) then
    begin  
      BreakTask.Wait.ResetEvent;
      CodeInfoCheckpoint (CodeInfo, DisAsm, RegInfo);
      BreakTask.WaittingCmd := True;
      BreakTask.InfoCallback (Sender.Task, Sender.BreakAddr, RegInfo, PChar(DisAsm));
      BreakTask.WaittingCmd := False;
    end;
  end else
  begin  //如果遇到多线程从入，则略过用户干预直接退出
    CodeInfo := ParseCode (BreakTask.Breaking.BreakAddr);
    BreakTask.Breaking.UserCmd := ucNone;
  end;
  TrapDbgEnd (Sender.Task, CodeInfo, RegInfo);
End;


//2）断点退出同步模式
Procedure TrapDbgEnd (hTrap: THandle; CodeInfo: TCodeInfo; RegInfo: LPTRegister);
var
  BreakTask: LPTBreakPointTask absolute hTrap;
  UserCmd: TUserCmd;
  CodeSize: Integer;
  BreakInfo, BrotherA, BrotherB: LPTBreakInfo;
  EqualCodeBase: PChar;
  JmpCode: LPTJmpCode;
  CallCode: LPTCallCode;
  CallInCode: LPTCallInCode;
  JmpTarget, ModifyTarget: Pointer;
begin
  BreakInfo := BreakTask.Breaking;
  EqualCodeBase := @PChar(@BreakInfo.JmpTrapCode[0])[BreakInfo.JmpTrapHeadSize];
  UserCmd := BreakInfo.UserCmd;
  CodeSize := Integer(CodeInfo.Next) - Integer(CodeInfo.This);

  if UserCmd = ucStepInto then
    if not CodeInfo.Call then
      UserCmd := ucStepOver;

  case UserCmd of
    ucNone, ucRun: Begin  //写入返回Jmp指令，退出调试流程
      JmpCode := @EqualCodeBase[0];
      JmpCode.JmpOpt := $25FF;
      JmpCode.JmpAim := @BreakInfo.BreakAddr;
    end;
    ucStepInto: Begin  //进入函数体
      CallInCode := @EqualCodeBase[0];
      CallInCode.push := $68;
      CallInCode.pushAddr := CodeInfo.Next;
      CallInCode.CallTo.JmpOpt :=  $25FF;
      MakeBreakCodeTrainB (hTrap, @CallInCode.CallTo.JmpAim, CodeInfo.Target, UserCmd);
    end;
    ucStepOver, ucRunUntilRet, ucRunUntilAddr: Begin  //步过指令
      if CodeInfo.Call then
      begin
        if CodeInfo.RelTarget then
        begin
          CallCode := @EqualCodeBase[0];
          CallCode.CallOpt := $15FF;
          BreakInfo.Jmp2NextCode := CodeInfo.Target;
          CallCode.CallAim := @BreakInfo.Jmp2NextCode;

          JmpCode := @EqualCodeBase[SizeOf(TCallCode)];
          MakeBreakCodeTrain (hTrap, Pointer(JmpCode), CodeInfo.Next, UserCmd);
        end else
        begin
          CopyMemory (EqualCodeBase, BreakInfo.BreakAddr, CodeSize);
          JmpCode := @EqualCodeBase[CodeSize];
          MakeBreakCodeTrain (hTrap, Pointer(JmpCode), CodeInfo.Next, UserCmd);
        end;
      end else
      if CodeInfo.Jmp then
      begin
        if CodeInfo.RelTarget then
        begin
          CopyMemory (EqualCodeBase, BreakInfo.BreakAddr, CodeSize);
          JmpTarget := @EqualCodeBase[CodeSize - CodeInfo.TargetSize];
          case CodeInfo.TargetSize of
          1: PByte(JmpTarget)^ := 6;
          2: PWORD(JmpTarget)^ := 6;
          4: PDWORD(JmpTarget)^ := 6;
          else Exception.Create('Jmp TargetSize = ?');
          end;

          JmpCode := @EqualCodeBase[CodeSize];
          BrotherA := MakeBreakCodeTrain (hTrap, Pointer(JmpCode), CodeInfo.Next, UserCmd);

          JmpCode := @EqualCodeBase[CodeSize + SizeOf(TJmpCode)];
          BrotherB := MakeBreakCodeTrain (hTrap, Pointer(JmpCode), CodeInfo.Target, UserCmd);

          BrotherA.WhoBrother := BrotherB;
          BrotherB.WhoBrother := BrotherA;
        end else
        begin
          CopyMemory (EqualCodeBase, BreakInfo.BreakAddr, CodeSize);
          JmpTarget := @EqualCodeBase[CodeSize - CodeInfo.TargetSize];  
          BrotherA := MakeBreakCodeTrainB (hTrap, JmpTarget, CodeInfo.Target, UserCmd);

          JmpCode := @EqualCodeBase[CodeSize];
          BrotherB := MakeBreakCodeTrain (hTrap, Pointer(JmpCode), CodeInfo.Next, UserCmd);

          BrotherA.WhoBrother := BrotherB;
          BrotherB.WhoBrother := BrotherA;          
        end;
      end else
      begin
        if IsRetCode (BreakInfo.BreakAddr) then
        begin
          CopyMemory (EqualCodeBase, BreakInfo.BreakAddr, CodeSize);
          ModifyTarget := Pointer(RegInfo.ESP);
          JmpTarget := PPointer(ModifyTarget)^;
          MakeBreakCodeTrainC (hTrap, ModifyTarget, JmpTarget, UserCmd);
        end else
        begin
          CopyMemory (EqualCodeBase, BreakInfo.BreakAddr, CodeSize);
          JmpCode := @EqualCodeBase[CodeSize];
          MakeBreakCodeTrain (hTrap, Pointer(JmpCode), CodeInfo.Next, UserCmd);
        end;    
      end;
    end;
  end;

  if UserCmd in [ucNone,ucRun]  then
  begin
    ResumeOtherThread (hTrap);
    BreakTask.Finish.SetEvent;
  end;
end;


end.
