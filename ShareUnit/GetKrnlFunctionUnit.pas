unit GetKrnlFunctionUnit;

interface

uses windows, sysUtils, classes;

function Get_KeStartThread (var ntoskrnlOffset, ntkrnlpaOffset: Integer): BOOL;


implementation

uses madShell, madDisasm, DLLLoader, FindAddress;

function GetLenOfFirstRet(FuncEntry: Pointer; var RetMval: Integer): Integer;
var
  CodeInfo: TCodeInfo;
  IterCode: PByte;
  asmStr: String;
  ValLen: Integer;
  ValBase:Pointer;
begin
  RetMval := 0;

  IterCode := FuncEntry;
  Repeat
    Inc (IterCode);
    Inc (Result);
    if IsBadReadPtr (IterCode, 4) then Exit;
  until (IterCode^ = $C2) or (IterCode^ = $C3);

  try
  CodeInfo := ParseCode (Pointer(IterCode));
  except
    exit;
  end;
  if CodeInfo.Opcode = $C2 then
  begin
    ValLen := Integer (CodeInfo.Next) - Integer(CodeInfo.This) - 1;
    ValBase := Pointer (Integer(CodeInfo.This) + 1);
    if ValLen = 1 then
      RetMval := PByte(ValBase)^
    else if ValLen = 2 then
      RetMval := PWORD(ValBase)^;
  end;
end;


function  FindRetOpValue (CodeBegin: Pointer; out CodeSize: Integer): BOOL;
var
  CodeInfo: TCodeInfo;
  IterCode: Pointer;
  ValLen: Integer;
  ValBase:Pointer;
  RetValue: Integer;
begin
  Result := False;

  CodeSize := 0;
  IterCode := CodeBegin;
  Repeat
    Inc (DWORD(IterCode));
    Inc (CodeSize);
    if CodeSize > 500 then Exit;
    if IsBadReadPtr (IterCode, 4) then Exit;  
    if PWORD(IterCode)^ = $C3C9 then Exit;
    if PWORD(IterCode)^ = $90C3 then Exit;

    if PByte(IterCode)^ = $C2 then
    begin
      RetValue := PWORD(DWORD(IterCode) + 1)^;
      if RetValue = 4 then
      begin
        Inc (CodeSize, 3);
        Result := True;
        Exit;
      end else
      if RetValue <= $28 then Exit;
    end;
  until False;
end;


function GetDisAsm (CodeBegin: Pointer; CodeLen: Integer): String;
var
  CodeInfo: TCodeInfo;
  IterCode: Pointer;
  ResultSL: TStringList;
  DisAsmStr: String;
begin
  ResultSL := TStringList.Create;
  IterCode := CodeBegin;
  Repeat
    if IsBadReadPtr (IterCode, 4) then Break;
    if PWORD(IterCode)^ = $15FF then
    begin
      Inc (DWORD(IterCode), 6);
      Continue;
    end;
    Try
      CodeInfo := ParseCode (IterCode, DisAsmStr);
    Except
      Break;
    end;
    if not CodeInfo.IsValid then break;

    ResultSL.Add(DisAsmStr);
    IterCode := CodeInfo.Next;
  until Integer(IterCode) - Integer(CodeBegin) >= CodeLen;
  Result := ResultSL.Text;
  ResultSL.Free;
end;

function GetCallListUntilRet (FuncEntry: Pointer; RetStep: Integer = 1): TList;
var
  CodeInfo: TCodeInfo;
  IterCode: Pointer;
  RunStep: Integer;
begin
  Result := TList.Create;

  IterCode := FuncEntry;
  RunStep := 0;
  Repeat
    CodeInfo := ParseCode (IterCode);
    if CodeInfo.Call then
        Result.Add(CodeInfo.Target);
    IterCode := CodeInfo.Next;
    if CodeInfo.Opcode = $C2 then
      Inc (RunStep);
  until RunStep = RetStep;
end;

Type
  LPTCodeItem = ^TCodeItem;
  TCodeItem = record
    Address: Pointer;
    Offset: Integer;
    Size: Integer;
    DisAsm: PChar;
  end;

function GetKeStartThread (PePath: String; var offset: Integer): BOOL;
label
  ClearExit;
var
  MS: TMemoryStream;
  CodeList: TList;
  CodeItem: LPTCodeItem;
  KrnlPE: TDLLLoaderEx;
  AimEntry: Pointer;
  CallList: TList;
  DisAsmStr: String;
  Index: Integer;
  CodeSize: Integer;
  FuncInfo: TFunctionInfo;
begin
  Result := False;
  MS := TMemoryStream.Create;
  MS.LoadFromFile(PePath);
  CodeList := TList.Create;
  CallList := NIL;

  OutputDebugString (PChar(PePath));

  KrnlPE := TDLLLoaderEx.Create;
  KrnlPE.IsSkipDLLProc := True;
  KrnlPE.IsSkipRelocation := True;
  KrnlPE.IsSkipImports := True;
  if not KrnlPE.Load(MS) then
  begin
    SetLastError (10000);
    goto ClearExit;
  end;

  AimEntry := KrnlPE.FindExport('PsCreateSystemThread');
  if AimEntry = nil then
  begin
    SetLastError (10001);
    goto ClearExit;
  end;

  OutputDebugString (PChar('PsCreateSystemThread $'+IntToHex(DWORD(AimEntry), 8)));

  CallList := GetCallListUntilRet (AimEntry);
  AimEntry := NIL;
  if CallList.Count = 1 then
    AimEntry := CallList[0];
  if AimEntry = NIL then
  begin
    SetLastError (10002);
    goto ClearExit;
  end;

  CallList.Free;
  CallList := GetCallListUntilRet (AimEntry, 2);

  for Index := CallList.Count - 1 downto 0 do
  begin
    AimEntry := CallList[Index];
    if FindRetOpValue (AimEntry, CodeSize) then
    begin
      CodeItem := AllocMem (SizeOf(TCodeItem));
      CodeItem.Address := AimEntry;
      CodeItem.Offset := Integer(AimEntry) - Integer (KrnlPE.ImageBase);
      CodeItem.Size := CodeSize;

      CodeList.Add(CodeItem);
    end else
      CallList.Delete(index);
  end;

  PePath := ExtractFileName (PePath);
  for CodeItem in CodeList do
  begin
      DisAsmStr := '';
      Try
        FuncInfo := ParseFunction (CodeItem.Address, DisAsmStr);
      Except
      end;

      if Length(DisAsmStr) > 1 then
      begin
        if CodeItem.Size > FuncInfo.CodeLen then
          CodeItem.Size := FuncInfo.CodeLen;

        if CodeItem.Size > 180 then
          With TStringList.Create do
          Try
            Text := DisAsmStr;
            SaveToFile (format ('.\%s %.8p %.8x %d.Txt', [PePath, CodeItem.Address, CodeItem.Offset, CodeItem.Size]));
          finally
            Free;
          end;
      end;  
  end;



//  for AimEntry in CallList do
//  begin
//    CodeItem := AllocMem (SizeOf(TCodeItem));
//
//    CodeItem.Offset := Integer(AimEntry) - Integer (KrnlPE.ImageBase);
//    CodeItem.Size := GetLenOfFirstRet (AimEntry, CodeItem.RetMval);
//
//    if CodeItem.Size > 0 then
//    begin
//      DisAsmStr := GetDisAsm (AimEntry, CodeItem.Size);
//      CodeItem.DisAsm := AllocMem (Length(DisAsmStr) + 1);
//      CopyMemory (CodeItem.DisAsm, PChar(DisAsmStr), Length(DisAsmStr));
//
//      CodeList.Add(CodeItem);
//    end else
//      FreeMem (CodeItem);
//  end;
//
//  PePath := ExtractFileName (PePath);
//  for CodeItem in CodeList do
//  begin
//    if CodeItem.RetMval = 4 then
//      With TStringList.Create do
//      Try
//        Text := StrPas (CodeItem.DisAsm);
//        SaveToFile (format ('.\%s $%.8x_%d_%d.Txt', [PePath, CodeItem.Offset, CodeItem.Size, CodeItem.RetMval]));
//      finally
//        Free;
//      end;
//  end;

  Result := True;            Exit;

ClearExit:
  if Assigned (CallList) then
    CallList.Free;

  KrnlPE.Free;

  for CodeItem in CodeList do
  begin
    if Assigned (CodeItem.DisAsm) then
      FreeMem (CodeItem.DisAsm);
    FreeMem (CodeItem);
  end;

  CodeList.Free;
  MS.Free;
end;

//goooal  15:02:44
//nt!KeSetPriorityThread+0x228
//
//0164989A    8BFF                mov edi,edi
//0164989C    55                  push ebp
//0164989D    8BEC                mov ebp,esp
//0164989F    FF75 24             push dword ptr ss:[ebp+24]
//016498A2    FF75 20             push dword ptr ss:[ebp+20]
//016498A5    FF75 1C             push dword ptr ss:[ebp+1C]
//016498A8    FF75 18             push dword ptr ss:[ebp+18]
//016498AB    FF75 14             push dword ptr ss:[ebp+14]
//016498AE    FF75 10             push dword ptr ss:[ebp+10]
//016498B1    FF75 0C             push dword ptr ss:[ebp+C]
//016498B4    FF75 08             push dword ptr ss:[ebp+8]
//016498B7    E8 A200F0FF         call 0154995E
//016498BC    85C0                test eax,eax
//016498BE    7C 0A               jl short 016498CA
//016498C0    FF75 08             push dword ptr ss:[ebp+8]
//016498C3    E8 D0CDE5FF         call 014A6698
//016498C8    33C0                xor eax,eax
//016498CA    5D                  pop ebp
//016498CB    C2 2000             retn 20

//8BECFF7524FF7520FF751CFF7518FF7514FF7510FF750CFF7508E8

function _GetKeStartThread (PePath: String; var offset: Integer): BOOL;
label
  ClearExit;
const
  AimStr = #$8B#$EC#$FF#$75#$24#$FF#$75#$20#$FF#$75#$1C#$FF#$75#$18#$FF#$75#$14#$FF#$75#$10#$FF#$75#$0C#$FF#$75#$08#$E8;
var
  MS: TMemoryStream;
  KrnlPE: TDLLLoaderEx;
  AimEntry: Pointer;
  DisAsmStr: String;
  FuncInfo: TFunctionInfo;
  TmpHanel: THandle;
  AimList: TList;
  CodeLen: Integer;
begin
  Result := False;
  MS := TMemoryStream.Create;
  MS.LoadFromFile(PePath);

  OutputDebugString (PChar(PePath));

  KrnlPE := TDLLLoaderEx.Create;
  KrnlPE.IsSkipDLLProc := True;
  KrnlPE.IsSkipRelocation := True;
  KrnlPE.IsSkipImports := True;
  if not KrnlPE.Load(MS) then
  begin
    SetLastError (10000);
    goto ClearExit;
  end;

  TmpHanel := MakeTemplate (KrnlPE.ImageBase, KrnlPE.ImageSize);
  AimList := TList.Create;
  if FineAddress (TmpHanel, PChar(AimStr), Length(AimStr), AimList) then
    if AimList.Count = 1 then
    begin
      OutputDebugString (PChar('Found: $' + IntToHex(Integer(AimList[0]), 8)));

      AimEntry := Pointer (Integer(AimList[0]) + ($016498C3 + 1 - $0164989D));
      AimEntry := Pointer (Integer(AimEntry) + PInteger(AimEntry)^ + 4);

      DisAsmStr := '';
      Try
      FuncInfo := ParseFunction (AimEntry, DisAsmStr);
      Except
      end;
      if DisAsmStr = '' then
        Try
        AimEntry := Pointer (Integer (KrnlPE.ImageBase) + Integer(AimEntry));
        FuncInfo := ParseFunction (AimEntry, DisAsmStr);
        Except
        end;


      CodeLen := FuncInfo.CodeLen;
      offset := Integer(AimEntry) - Integer (KrnlPE.ImageBase);
      PePath := ExtractFileName (PePath);
      With TStringList.Create do
      Try
        Text := DisAsmStr;
        SaveToFile (format ('.\%s %.8p %.8x %d.Txt', [PePath, AimEntry, Offset, CodeLen]));
      finally
        Free;
      end;
      result := true; Exit;
    end;

  FreeTemplate (TmpHanel);

ClearExit:
  KrnlPE.Free;
  MS.Free;
end;


function Get_KeStartThread (var ntoskrnlOffset, ntkrnlpaOffset: Integer): BOOL;
var
  SysPath: String;
begin
  Result := False;
  if not GetSpecialFolder (sfSystem, SysPath) then exit;

  if not _GetKeStartThread (SysPath + '\ntkrnlpa.exe', ntoskrnlOffset) then
  begin
    OutputDebugString(PChar(format ('GetLastError1=%d', [GetLastError])));
    Exit;
  end;

  if not _GetKeStartThread (SysPath + '\ntoskrnl.exe', ntoskrnlOffset) then
  begin
    OutputDebugString(PChar(format ('GetLastError2=%d', [GetLastError])));
    Exit;
  end;

  Result := True;
end;





end.
