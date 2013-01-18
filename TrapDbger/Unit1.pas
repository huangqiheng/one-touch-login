unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, AppEvnts, math;

Const     
  WM_MINE=WM_USER+100;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    Memo3: TMemo;
    ListBox1: TListBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    ApplicationEvents1: TApplicationEvents;
    Memo4: TMemo;
    Splitter3: TSplitter;
    Button9: TButton;
    Button10: TButton;
    Button8: TButton;
    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure Button8Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure ListBox1KeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ApplicationEvents1ShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure Button7Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    procedure Mine(var msg:TMessage);message WM_MINE;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  madDisasm, TrapDbgUnit, SyncObjs, madKernel;

//Function MakeStepTrap (StartAddr, InfoCallback: Pointer; SuspendMode: BOOL): THandle; Stdcall; external 'TrapDebug.dll' name 'MakeStepTrap';
//Function ClearStepTrap (hTrap: THandle): BOOL; Stdcall; external 'TrapDebug.dll' name 'ClearStepTrap';
//Function StepInto (hTrap: THandle): BOOL; Stdcall; external 'TrapDebug.dll' name 'StepInto';
//Function StepOver (hTrap: THandle): BOOL; Stdcall; external 'TrapDebug.dll' name 'StepOver';
//Function RunUntilRet (hTrap: THandle): BOOL; Stdcall; external 'TrapDebug.dll' name 'RunUntilRet';
//Function Run (hTrap: THandle): BOOL; Stdcall; external 'TrapDebug.dll' name 'Run';

var
  BreakEvent: TEvent;

//00453246 9C               pushfd
//00453247 60               pushad
//00453248 54               push esp
//00453249 6877777777       push $77777777
//0045324E FF1599999999     call dword ptr [$99999999]
//00453254 61               popad
//00453255 9D               popfd

Type
  LPTJmpTrapHead = ^TJmpTrapHead;
  TJmpTrapHead = packed record
    pushfd: Byte;
    pushad: Byte;
    pushEsp: Byte;
    pushTask: record
      Opt: Byte;
      Value: DWORD;
    end;
    callHook: record
      Opt: WORD;
      Value: DWORD;
    end;
    popad: Byte;
    popfd: Byte;
  end;
  
Procedure JmpTrapSample;
asm
  Pushfd
  Pushad   //把EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI依次压入堆栈.
  //-----------------------------------
  Push esp
  Push $77777777
  Call dword ptr [$99999999]
  //-----------------------------------
  popad
  Popfd
end;

function GetJmpTrapHead: LPTJmpTrapHead;
begin
  Result := @JmpTrapSample;
end;

Procedure test (parama, paramb: pointer); stdcall;
asm
  mov eax,ebx
  jmp dword ptr [$44444444]
end;

procedure SampleMaxCodeSize (parama, paramb: pointer); stdcall;
asm
  jnb @Next
  DB '1234567890123456'
  jmp dword ptr [$0]
@Next:
  DB '1234567890123456'
  jmp dword ptr [$1]     
end;

function BreakThreadA (Param: Pointer): Integer;
var
  AddValue: Integer;
begin
  form1.Caption := IntToStr(GetCurrentThreadID);
  AddValue := 0;
  InterlockedExchangeAdd (AddValue, 100);
  form1.Caption := format('tid=%d  AddValue=%d', [GetCurrentThreadID, AddValue]);
  result := 0;
end;

procedure TForm1.ApplicationEvents1ShortCut(var Msg: TWMKey;
  var Handled: Boolean);
begin
  if Msg.CharCode = VK_F7 then
    self.Button7.Click
  else if Msg.CharCode = VK_F8 then
    self.Button3.Click
  else if Msg.CharCode = VK_F9 then
  begin
    if GetKeyState(VK_SHIFT) < 0 then
      self.Button5.Click
    else
      self.Button6.Click;
  end;
end;

function BreakThread (Param: Pointer): Integer;
var
  Buffer: String;
begin
  SetLength (Buffer, 255);
  GetModuleFileName (0, @Buffer[1], 255);
  form1.Caption := Buffer;
  result := 0;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  tid: dword;
begin
   BeginThread (nil, 0, BreakThread, nil, 0, tid);
end;

Type
  LPTHistoryBlock = ^THistoryBlock;
  THistoryBlock = record
    BaseFrom: dword;
    BaseTo: dword;
  end;

var
  HistoryRun: TList;

procedure AddCodeToHistory (Addr: Pointer; CodeSize: dword);
var
  Item: LPTHistoryBlock;
  Index: Integer;
  TestValue: dword absolute Addr;
  AddSucceed: BOOL;
begin
  if not assigned (HistoryRun) then
    HistoryRun := TLIst.Create;

  AddSucceed := False;
  for Index := 0 to HistoryRun.Count - 1 do
  begin
    Item := HistoryRun[Index];

    if (TestValue > Item.BaseFrom) and (TestValue < Item.BaseTo) then
    begin
      Exit;
    end;

    if TestValue = Item.BaseTo then
    begin
      Item.BaseTo := Item.BaseTo + CodeSize;
      AddSucceed := True;
      Break;
    end;
  end;

  if not AddSucceed then
  begin
    Item := AllocMem (SizeOf(THistoryBlock));
    Item.BaseFrom := TestValue;
    Item.BaseTo := TestValue + CodeSize;
    HistoryRun.Add(Item);
  end;
end;

procedure AddToHistory (CodeInfo: TCodeInfo);
var
  Count: Integer;
begin
  Count := 0;
  Repeat
    AddCodeToHistory (CodeInfo.This, dword(CodeInfo.Next) - dword(CodeInfo.This));
    CodeInfo := ParseCode (CodeInfo.Next);
    Inc (Count);
  until Count >= 50;
end;


function GetHistoryBase (TryAddr: Pointer): Pointer;
var
  Item: LPTHistoryBlock;
  Index: Integer;
  TestValue: dword absolute TryAddr;
begin
  if not assigned (HistoryRun) then
    HistoryRun := TLIst.Create;

  Result := nil;

  for Index := 0 to HistoryRun.Count - 1 do
  begin
    Item := HistoryRun[Index];
    if (TestValue > Item.BaseFrom) and (TestValue <= Item.BaseTo) then
    begin
      Result := Pointer(Item.BaseFrom);
      Exit;
    end;
  end;         
end;


function GetDisAsmCode (EIP: Pointer; var EipIndex: Integer): TStringList;
var
  CodeInfo: TCodeInfo;
  DisAsm: String;
  ScanAddr, PreAddr: Pointer;
  Counter, AddIndex: Integer;
begin
  Result := TStringList.Create;
  PreAddr := GetHistoryBase (EIP);
  if PreAddr <> nil then
  begin
    ScanAddr := PreAddr;
    Repeat
      CodeInfo := ParseCode (ScanAddr, DisAsm);
      AddIndex := Result.AddObject(DisAsm, Pointer(0));
      if AddIndex > 10 then
        Result.Delete(0);
      ScanAddr := CodeInfo.Next;
    until DWORD(ScanAddr) >= DWORD(EIP);
  end;

  CodeInfo := ParseCode (EIP, DisAsm);
  AddToHistory (CodeInfo);
  EipIndex := Result.AddObject(DisAsm, Pointer(1));

  Counter := 0;
  Repeat
    CodeInfo := ParseCode (CodeInfo.Next, DisAsm);
    AddToHistory (CodeInfo);
    Result.AddObject(DisAsm, Pointer(0));
    Inc (Counter);
  until Counter >= 10;   
end;


Type
  LPTStackArray = ^TStackArray;
  TStackArray = Array[word] of dword;

  LPTMsgContent = ^TMsgContent;
  TMsgContent = record
    EipIndex: Integer;
    CodeSL, RegistSL, StackSL, InfoSL: TStringList;
    Tid: DWORD;
  end;

var
  hBreak: THandle;
  hBreaking: THandle;
  NewEipIndex: Integer;

procedure TForm1.Mine(var msg: TMessage);
var
  MsgContent: LPTMsgContent;
begin
  MsgContent := Pointer (msg.WParam);

//  OutputDebugStringA (PChar(MsgContent.CodeSL[MsgContent.EipIndex]));
  form1.ListBox1.Items := MsgContent.CodeSL;
  form1.ListBox1.ItemIndex := MsgContent.EipIndex;
  NewEipIndex := MsgContent.EipIndex;
  form1.Memo2.Lines := MsgContent.RegistSL;
  form1.Memo3.Lines := MsgContent.StackSL;
  MsgContent.InfoSL.Add(format('Tid=%d',[MsgContent.Tid]));
  form1.Memo4.Lines := MsgContent.InfoSL;

  Dispose (MsgContent);
end;


procedure TForm1.ListBox1DrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  with   ListBox1.Canvas   do
  begin
    FillRect(Rect);

    if Index = NewEipIndex  Then
    if Index = form1.ListBox1.ItemIndex  Then
    begin
      Font.Color   :=   Clred;
    end;
    TextOut(Rect.Left+1, Rect.Top+1, ListBox1.Items[Index]);
  end;
end;


function IsRetCode (Addr: Pointer): BOOL;
var
  RetSign: PByte absolute Addr;
begin
  Result := RetSign^ in [$C2,$C3,$CA,$CB];
end;


Procedure InfoCallback (hTrap: THandle; EIP: Pointer; RegInfo: LPTRegister; DisAsm: PChar); Stdcall;
var
  StackArray: LPTStackArray;
  Index: Integer;
  PrintStr: String;
  WRet: TWaitResult;
  CodeInfo: TCodeInfo;
  EipIndex: Integer;
  CodeSL, RegistSL, StackSL, InfoSL: TStringList;
  MsgContent: LPTMsgContent;
begin
  hBreaking := hTrap;

  //显示代码区
  CodeSL := GetDisAsmCode (EIP, EipIndex);

  //显示寄存器区
  RegistSL := TStringList.Create;
  RegistSL.Add('EAX  ' + IntToHex(RegInfo.EAX, 8));
  RegistSL.Add('ECX  ' + IntToHex(RegInfo.ECX, 8));
  RegistSL.Add('EDX  ' + IntToHex(RegInfo.EDX, 8));
  RegistSL.Add('EBX  ' + IntToHex(RegInfo.EBX, 8));
  RegistSL.Add('ESP  ' + IntToHex(RegInfo.ESP, 8));
  RegistSL.Add('EBP  ' + IntToHex(RegInfo.EBP, 8));
  RegistSL.Add('ESI  ' + IntToHex(RegInfo.ESI, 8));
  RegistSL.Add('EDI  ' + IntToHex(RegInfo.EDI, 8));
  RegistSL.Add('');
  RegistSL.Add('EIP  ' + IntToHex(DWORD(EIP), 8));
  RegistSL.Add('');
  RegistSL.Add('EFLAGS  ' + IntToHex(RegInfo.EFLAGS, 8));


  //显示堆栈区
  StackSL := TStringList.Create;
  StackArray := Pointer(RegInfo.ESP);
  for Index := 0 to 15 do
  begin
    PrintStr := format ('%.8p  %.8x', [@StackArray[Index], StackArray[Index]]);
    StackSL.Add(PrintStr);
  end;

  //显示指令信息
  InfoSL := TStringList.Create;
  CodeInfo := ParseCode (EIP);
  InfoSL.Clear;
  PrintStr := '';
  if CodeInfo.Call then
  begin
    PrintStr := 'Call ';
    OutputDebugStringA (DisAsm);
  end else
  if CodeInfo.Jmp then
    PrintStr := 'Jmp ';

  if IsRetCode (CodeInfo.This) then
    OutputDebugStringA (DisAsm);

  InfoSL.Add(format(PrintStr + 'Opcode=%.2x  ModRm=%x', [CodeInfo.Opcode, CodeInfo.ModRm]));
  InfoSL.Add(
        format('RelTarget=%d  Target=%x  PTarget=%x  PPTarget=%x  TargetSize=%d',
        [Integer(CodeInfo.RelTarget), DWORD(CodeInfo.Target), DWORD(CodeInfo.PTarget), DWORD(CodeInfo.PPTarget), CodeInfo.TargetSize]));

  //显示在VCL中
//  OutputDebugStringA (DisAsm);
  New (MsgContent);
  MsgContent.EipIndex := EipIndex;
  MsgContent.CodeSL := CodeSL;
  MsgContent.RegistSL := RegistSL;
  MsgContent.StackSL := StackSL;
  MsgContent.InfoSL := InfoSL;
  MsgContent.Tid := GetCurrentThreadID;
  PostMessage (form1.Handle, WM_MINE, Integer(MsgContent), 0);

  //等待用户命令
  Repeat
    Application.ProcessMessages;
    WRet := BreakEvent.WaitFor(100);
  until WRet <> wrTimeout;

  if WRet <> wrSignaled then
    TrapDbgRun (hBreaking);
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  FucAddr: Pointer;
begin         
  FucAddr := GetProcAddress (LoadLibrary(kernel32), 'GetModuleFileNameA');
//  FucAddr := GetProcAddress (LoadLibrary(kernel32), 'InterlockedIncrement');
  hBreak := TrapDbgSet (FucAddr, @InfoCallback, False);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  TrapDbgStepOver (hBreaking);
  BreakEvent.SetEvent;
end;

procedure sss;
asm
  push $45454545
  jmp dword ptr [$55]
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  sss;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  TrapDbgRunUntilRet (hBreaking);
  BreakEvent.SetEvent;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  TrapDbgRun (hBreaking);
  BreakEvent.SetEvent;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  TrapDbgStepInto (hBreaking);
  BreakEvent.SetEvent;
end;

function GetHeadLeftAddr (Line: String): Pointer;
begin
  Result := NIL;
  if Length(Line) < 8 then exit;
  
  SetLength (Line, 8);
  Result := Pointer (StrToInt('$'+Line));
end;

procedure TForm1.Button8Click(Sender: TObject);
var
  AimAddr: Pointer;
  Line: String;
  Index: Integer;
begin
  Index := self.ListBox1.ItemIndex;
  if Index = -1 then exit;
  Line := self.ListBox1.Items[Index]; 

  AimAddr := GetHeadLeftAddr (Line);
  if Assigned (AimAddr) then
  begin
    TrapDbgRunUntilAddr (hBreaking, AimAddr);
    BreakEvent.SetEvent;
  end;
end;

var
  HistoryAccessList: TList;
  CurrentIndex: Integer = 0;

Procedure AccessRecord (Item: Pointer);
begin
  if not assigned (HistoryAccessList) then
    HistoryAccessList := TList.Create;

  CurrentIndex := HistoryAccessList.Add(Item);
end;

function NextAccess: Pointer;
begin
  if not assigned (HistoryAccessList) then
    HistoryAccessList := TList.Create;

  if HistoryAccessList.Count = 0 then
    AccessRecord (Module($00400000).EntryPoint);

  Inc (CurrentIndex);
  CurrentIndex := Min (CurrentIndex, HistoryAccessList.Count - 1);
  Result := HistoryAccessList[CurrentIndex];
end;

function PreAccess: Pointer;
begin
  if not assigned (HistoryAccessList) then
    HistoryAccessList := TList.Create;

  if HistoryAccessList.Count = 0 then
    AccessRecord (Module($00400000).EntryPoint);

  dec (CurrentIndex);
  if CurrentIndex < 0 then
    CurrentIndex := 0;
  Result := HistoryAccessList[CurrentIndex];
end;



procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  BreakEvent.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  BreakEvent := TEvent.Create(nil, false, false, '');
end;


procedure TForm1.ListBox1KeyPress(Sender: TObject; var Key: Char);
var
  Index: Integer;
  LineStr, AddrStr, DisAsm: String;
  FuncEntry: Pointer;
  FuncInfo: TFunctionInfo;
  CodeInfo: TCodeInfo;
begin
  if Key = #13 then
  begin
    Index := self.ListBox1.ItemIndex;
    if Index >= 0 then
    begin
      LineStr := self.ListBox1.Items[Index];
      AddrStr := Copy(LineStr, 1, 8);
      FuncEntry := Pointer(StrToInt('$'+AddrStr));
      CodeInfo := ParseCode (FuncEntry);

      if CodeInfo.IsValid then
      if CodeInfo.Call or CodeInfo.Jmp then
      begin
        FuncEntry := CodeInfo.Target;
        FuncInfo := ParseFunction (FuncEntry, DisAsm);
        if FuncInfo.IsValid then
        begin
          form1.ListBox1.Items.Text := DisAsm;
          if Pos ('function entry point', DisAsm) >= 0 then
            AccessRecord (FuncEntry);
        end;
      end;
    end;
  end;
end;

procedure TForm1.Button9Click(Sender: TObject);
var
  DisAsm: String;
begin
  ParseFunction (PreAccess, DisAsm);
  form1.ListBox1.Items.Text := DisAsm;
end;
procedure TForm1.Button10Click(Sender: TObject);
var
  DisAsm: String;
begin
  ParseFunction (NextAccess, DisAsm);
  form1.ListBox1.Items.Text := DisAsm;
end;

end.
