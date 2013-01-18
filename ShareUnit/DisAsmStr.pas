unit DisAsmStr;

interface

uses windows, classes;

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
function GetCodeStruct (Address: Pointer): LPTCodeInfos; Stdcall;
function GetFuncDisAsm (Entry: Pointer): LPTFuncInfos; Stdcall;
function GetFuncStruct (Entry: Pointer): LPTFuncInfos; Stdcall;


implementation

uses madDisasm, SyncObjs, ThreadTempMemory;
                                          

function GetCodeDisAsm (Address: Pointer): LPTCodeInfos; Stdcall;
var
  OutPut: TCodeInfos;
  CodeInfo: TCodeInfo;
  AsmStr: String;
begin
  Result := nil;
  CodeInfo := ParseCode (Address, AsmStr);
  if CodeInfo.IsValid then
  begin
    OutPut.This := CodeInfo.This;
    OutPut.Opcode := CodeInfo.Opcode;
    OutPut.ModRm := CodeInfo.ModRm;
    OutPut.Call := CodeInfo.Call;
    OutPut.Jmp := CodeInfo.Jmp;
    OutPut.RelTarget := CodeInfo.RelTarget;
    OutPut.Target := CodeInfo.Target;
    OutPut.PTarget := CodeInfo.PTarget;
    OutPut.PPTarget := PPointer(CodeInfo.PPTarget);
    OutPut.TargetSize := CodeInfo.TargetSize;
    OutPut.Next := CodeInfo.Next;
    Output.CodeLen := Integer(OutPut.Next)-Integer(OutPut.This);
    CopyMemory (@OutPut.Code[0], Output.This, Output.CodeLen);
    CopyMemory (@OutPut.AsmStr[0], PChar(AsmStr), Length(AsmStr));
    OutPut.AsmStr[Length(AsmStr)] := #0;
    Result := @OutPut;
  end;
end;

function GetCodeStruct (Address: Pointer): LPTCodeInfos; Stdcall;
var
  OutPut: TCodeInfos;
  CodeInfo: TCodeInfo;
begin
  Result := nil;
  CodeInfo := ParseCode (Address);
  if CodeInfo.IsValid then
  begin
    OutPut.This := CodeInfo.This;
    OutPut.Opcode := CodeInfo.Opcode;
    OutPut.ModRm := CodeInfo.ModRm;
    OutPut.Call := CodeInfo.Call;
    OutPut.Jmp := CodeInfo.Jmp;
    OutPut.RelTarget := CodeInfo.RelTarget;
    OutPut.Target := CodeInfo.Target;
    OutPut.PTarget := CodeInfo.PTarget;
    OutPut.PPTarget := PPointer(CodeInfo.PPTarget);
    OutPut.TargetSize := CodeInfo.TargetSize;
    OutPut.Next := CodeInfo.Next;
    Output.CodeLen := Integer(OutPut.Next)-Integer(OutPut.This);
    Result := @OutPut;
  end;
end;


function GetFunctionData (Entry: Pointer; WithStr: BOOL): LPTFuncInfos; Stdcall;
var
  FuncInfo: TFunctionInfo;
  AsmStr: String;
  AllocSize: Integer;
  Index: Integer;
  Item: LPTFarCallData;
begin
  Result := nil;

  AsmStr := '';
  if WithStr then
    FuncInfo := ParseFunction (Entry, AsmStr)
  else
    FuncInfo := ParseFunction (Entry);

  if FuncInfo.IsValid then
  begin
    AllocSize := SizeOf(TFuncInfos) + Length(AsmStr) + SizeOf(TFarCallData) * Length(FuncInfo.FarCalls);
    Result := GetThreadMem (AllocSize);
    Result.Size := AllocSize;
    Result.EntryPoint := FuncInfo.EntryPoint;
    Result.CodeBegin := FuncInfo.CodeBegin;
    Result.CodeLen := FuncInfo.CodeLen;
    Result.FarCallsCount := Length(FuncInfo.FarCalls);
    Result.FarCallsOffset := SizeOf(TFuncInfos) + Length(AsmStr);

    if Length(AsmStr) > 0 then
      CopyMemory (@Result.AsmStr[0], PChar(AsmStr), Length(AsmStr));
    Result.AsmStr[Length(AsmStr)] := #0;

    Item := Pointer(Integer(Result) + Result.FarCallsOffset);
    for Index := 0 to Result.FarCallsCount - 1 do
    with FuncInfo.FarCalls[Index] do
    begin
      Item.Call := Call;
      Item.CodeAddr1 := CodeAddr1;
      Item.CodeAddr2 := CodeAddr2;
      Item.Target := Target;
      Item.RelTarget := RelTarget;
      Item.PTarget := PTarget;
      Item.PPTarget := PPointer(PPTarget);
      Inc (Item);
    end;
  end;
end;


function GetFuncDisAsm (Entry: Pointer): LPTFuncInfos; Stdcall;
begin
  Result := GetFunctionData (Entry, True);
end;

function GetFuncStruct (Entry: Pointer): LPTFuncInfos; Stdcall;
begin
  Result := GetFunctionData (Entry, False);
end;

end.