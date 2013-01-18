unit BreakingForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, StdCtrls, ExtCtrls, TrapDbgLibUnit, AppEvnts, math,
  Menus, FormatFunction;
         
type
  TBreakPointForm = class(TForm)
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    Splitter2: TSplitter;
    ListBox1: TListBox;
    ListBox2: TListBox;
    Panel2: TPanel;
    Splitter3: TSplitter;
    ToolBar1: TToolBar;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton8: TToolButton;
    ToolButton4: TToolButton;
    ToolButton9: TToolButton;
    ToolButton5: TToolButton;
    ToolButton10: TToolButton;
    ToolButton6: TToolButton;
    ToolButton11: TToolButton;
    ToolButton7: TToolButton;
    ListBox3: TListBox;
    ListBox4: TListBox;
    ApplicationEvents1: TApplicationEvents;
    PopupMenu1: TPopupMenu;
    PopupMenu2: TPopupMenu;
    PopupMenu3: TPopupMenu;
    PopupMenu4: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    DWORD1: TMenuItem;
    DWORD2: TMenuItem;
    DWORD3: TMenuItem;
    DWORD4: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    arget1: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    Panel3: TPanel;
    ListBox5: TListBox;
    InputEditor: TEdit;
    procedure InputEditorKeyPress(Sender: TObject; var Key: Char);
    procedure ListBox4MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListBox4DblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListBox3DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ApplicationEvents1ShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure ToolButton7Click(Sender: TObject);
    procedure ToolButton6Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton4Click(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
  private
    { Private declarations }
  public
    hTask: THandle;
    Start: Pointer;
    NewEipIndex: Integer;
    ViewCodeList: TList;
    StackMem, DataMem: LPTMemBuffer;
    LastEBP: DWORD;
    AimDataSections: LPTSectionInfo;
    BpDetailBak: TBreakDetail;
    AimDataSectionCount: Integer;
    Procedure SetMemoryEditText (Address, MemBase: Pointer; MemSize: Integer);
    procedure ScrollMiddle (ListBox: TListBox; Index: Integer);
    procedure SetRegistText (BpDetail: LPTBreakDetail);
    procedure SetDisasmText (CodeAddr: Pointer);
    procedure SetStackLineText (ESP, EBP, StackLimit, StackBase: DWORD); overload;
    procedure SetStackLineText (StackMM: LPTMemBuffer; Ebp: DWORD; FullView: BOOL = False); overload;
    procedure OnDbgCmdSend (Sender: TObject; SendResult: BOOL);
  public
    procedure SetBreakDetail (BpDetail: LPTBreakDetail);
    procedure UpdateDisasmText;
    procedure UpdateStackLineText;
    procedure UpdateRegistText (Force: BOOL = False);
    procedure UpdateMemoryEditText;
  end;

implementation

uses CallStructForm, DbgInfoForm, PlugKernelLib;

{$R *.dfm}

procedure TBreakPointForm.ApplicationEvents1ShortCut(var Msg: TWMKey;
  var Handled: Boolean);
begin
  case Msg.CharCode of
    VK_F7: ToolButton3.Click;
    VK_F8: ToolButton4.Click;
    VK_F9: ToolButton5.Click;
    VK_F3: ToolButton6.Click;
    VK_F4: ToolButton7.Click;
  end;
end;


procedure TBreakPointForm.FormCreate(Sender: TObject);
begin
  ViewCodeList := TList.Create;
end;

procedure TBreakPointForm.FormDestroy(Sender: TObject);
begin
  ViewCodeList.Free;
end;

procedure TBreakPointForm.FormShow(Sender: TObject);
var
  SectionInfo: LPTSectionInfo;
  TotalSize: Integer;
  GotMem: Pointer;
begin
  GotMem := Cmd_GetDataSectionMemory (0);
  
  TotalSize := 0;
  AimDataSectionCount := 0;
  SectionInfo := GotMem;
  While Assigned (SectionInfo.CodeBase) do
  begin
    Inc (TotalSize, SizeOf(TSectionInfo));
    Inc (SectionInfo);
    Inc (AimDataSectionCount);
  end;
  if TotalSize = 0 then exit;    
  Inc (TotalSize, SizeOf(TSectionInfo));

  self.AimDataSections := AllocMem (TotalSize);
  CopyMemory (self.AimDataSections, GotMem, TotalSize);

  With self.AimDataSections^ do
  begin
    GotMem := Cmd_GetMemBuffer (CodeBase, CodeSize);
    if GotMem = nil then exit;
    SetMemoryEditText (CodeBase, GotMem, CodeSize);
  end;

  Panel3.Height := 2 + self.ListBox1.ItemHeight * 10 + self.ListBox1.BevelWidth * 2 + self.Panel3.BevelWidth * 2 + self.Panel3.BorderWidth * 2;

end;

procedure TBreakPointForm.ListBox3DrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  SrcListBox: TListBox absolute Control;
begin
  with SrcListBox.Canvas do
  begin
    FillRect(Rect);

    if Index = NewEipIndex  Then
    begin
      Font.Color := Clred;
    end;
    TextOut (Rect.Left, Rect.Top, SrcListBox.Items[Index]);
  end;
end;

procedure TBreakPointForm.ListBox4DblClick(Sender: TObject);
var
  SrcListBox: TListBox absolute Sender;
  Index: Integer;
  SrcLine: String;
  ItemPos: TRect;
  CanEdited: BOOL;
begin
  Index := SrcListBox.ItemIndex;      
  if Index = -1 then exit;
  CanEdited := BOOL(SrcListBox.Items.Objects[Index]);
  if not CanEdited then exit;
  SrcLine := SrcListBox.Items[Index];
           
  ItemPos := SrcListBox.ItemRect(Index);
  self.InputEditor.Parent := SrcListBox;
  self.InputEditor.Left := ItemPos.Left;
  self.InputEditor.Top := ItemPos.Top;
  self.InputEditor.Width := SrcListBox.Width;
  self.InputEditor.Height := SrcListBox.ItemHeight;
  self.InputEditor.Text := SrcLine;
  self.InputEditor.Tag := Index;
  self.InputEditor.AutoSelect := False;
  
  self.InputEditor.Visible := True;
  self.InputEditor.BringToFront;
  self.InputEditor.SetFocus;
end;

procedure TBreakPointForm.ListBox4MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  SrcListBox: TListBox absolute Sender;
  Index: Integer;
begin
  Repeat
    if SrcListBox <> TListBox(InputEditor.Parent) then Break;
    Index := SrcListBox.ItemAtPos(Point(X,Y), False);
    if InputEditor.Tag <> Index then Break;
    Exit;
  until True;
  InputEditor.Visible := False;
end;


function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

function GetRegistValue (RegStr: String; RegInfo: LPTRegister): DWORD;
begin
  RegStr := LowerCase(RegStr);
  if      RegStr = 'eax' then  Result := RegInfo.EAX
  else if RegStr = 'ecx' then  Result := RegInfo.ECX
  else if RegStr = 'edx' then  Result := RegInfo.EDX
  else if RegStr = 'ebx' then  Result := RegInfo.EBX
  else if RegStr = 'esp' then  Result := RegInfo.ESP
  else if RegStr = 'ebp' then  Result := RegInfo.EBP
  else if RegStr = 'esi' then  Result := RegInfo.ESI
  else if RegStr = 'edi' then  Result := RegInfo.EDI
  else Result := 0;
end;

var
  RegSample: TRegister;

function GetRegistOffset (RegStr: String): DWORD;
begin                       
  RegStr := LowerCase(RegStr);
  if      RegStr = 'eax' then  Result := Integer(@RegSample.EAX) - Integer(@RegSample)
  else if RegStr = 'ecx' then  Result := Integer(@RegSample.ECX) - Integer(@RegSample)
  else if RegStr = 'edx' then  Result := Integer(@RegSample.EDX) - Integer(@RegSample)
  else if RegStr = 'ebx' then  Result := Integer(@RegSample.EBX) - Integer(@RegSample)
  else if RegStr = 'esp' then  Result := Integer(@RegSample.ESP) - Integer(@RegSample)
  else if RegStr = 'ebp' then  Result := Integer(@RegSample.EBP) - Integer(@RegSample)
  else if RegStr = 'esi' then  Result := Integer(@RegSample.ESI) - Integer(@RegSample)
  else if RegStr = 'edi' then  Result := Integer(@RegSample.EDI) - Integer(@RegSample)
  else if RegStr = 'eflags' then  Result := Integer(@RegSample.EFLAGS) - Integer(@RegSample)
  else Raise Exception.Create('GetRegistOffset ERROR!');
end;

function HexToDword (HexStr: String; ValWhenErr: DWORD): DWORD;
var
  Val64: Int64;
begin
  Result := ValWhenErr;
  if HexStr[1] <> '$' then
    HexStr := '$' + HexStr;
  
  if TryStrToInt64 (HexStr, Val64) then
    Result := DWORD(Val64);  
end;

function WriteValueToAddr (Addr: Pointer; Value: DWORD): BOOL;
begin
  Result := False;
  if Addr = nil then exit;
  Result := Cmd_SetMemBuffer (Addr, @Value, SizeOf(Value));
end;

Const
  X86_EFLAGS_CF: DWORD    = $00000001; //* Carry Flag */
  X86_EFLAGS_PF: DWORD    = $00000004; //* Parity Flag */
  X86_EFLAGS_AF: DWORD	  = $00000010; //* Auxillary carry Flag */
  X86_EFLAGS_ZF: DWORD	  = $00000040; //* Zero Flag */
  X86_EFLAGS_SF: DWORD	  = $00000080; //* Sign Flag */
  X86_EFLAGS_TF: DWORD	  = $00000100; //* Trap Flag */
  X86_EFLAGS_IF: DWORD	  = $00000200; //* Interrupt Flag */
  X86_EFLAGS_DF: DWORD	  = $00000400; //* Direction Flag */
  X86_EFLAGS_OF: DWORD	  = $00000800; //* Overflow Flag */
  X86_EFLAGS_IOPL: DWORD	= $00003000; //* IOPL mask */
  X86_EFLAGS_NT: DWORD	  = $00004000; //* Nested Task */
  X86_EFLAGS_RF: DWORD	  = $00010000; //* Resume Flag */
  X86_EFLAGS_VM: DWORD	  = $00020000; //* Virtual Mode */
  X86_EFLAGS_AC: DWORD	  = $00040000; //* Alignment Check */
  X86_EFLAGS_VIF: DWORD	  = $00080000; //* Virtual Interrupt Flag */
  X86_EFLAGS_VIP: DWORD	  = $00100000; //* Virtual Interrupt Pending */
  X86_EFLAGS_ID: DWORD	  = $00200000; //* CPUID detection flag */

function SetFlagValue (EFLAGS: DWORD; SetStr: String): DWORD;
var
  InputSL: TStringList;
  Flag: String;
  IsSetup: BOOL;
begin
  Result := EFLAGS;
  InputSL := GetSplitBlankList (SetStr);
  if InputSL.Count = 2 then
  begin
    Flag := InputSL[0];
    if InputSL[1] = '0' then
      IsSetup := False
    else
      IsSetup := True;

    if IsSetup then
    begin
      if Flag = 'CF' then Result := EFLAGS OR X86_EFLAGS_CF else
      if Flag = 'PF' then Result := EFLAGS OR X86_EFLAGS_PF else
      if Flag = 'AF' then Result := EFLAGS OR X86_EFLAGS_AF else
      if Flag = 'ZF' then Result := EFLAGS OR X86_EFLAGS_ZF else
      if Flag = 'SF' then Result := EFLAGS OR X86_EFLAGS_SF else
      if Flag = 'TF' then Result := EFLAGS OR X86_EFLAGS_TF else
      if Flag = 'IF' then Result := EFLAGS OR X86_EFLAGS_IF else
      if Flag = 'OF' then Result := EFLAGS OR X86_EFLAGS_OF;
    end else
    begin
      if Flag = 'CF' then Result := EFLAGS AND (NOT X86_EFLAGS_CF) else
      if Flag = 'PF' then Result := EFLAGS AND (NOT X86_EFLAGS_PF) else
      if Flag = 'AF' then Result := EFLAGS AND (NOT X86_EFLAGS_AF) else
      if Flag = 'ZF' then Result := EFLAGS AND (NOT X86_EFLAGS_ZF) else
      if Flag = 'SF' then Result := EFLAGS AND (NOT X86_EFLAGS_SF) else
      if Flag = 'TF' then Result := EFLAGS AND (NOT X86_EFLAGS_TF) else
      if Flag = 'IF' then Result := EFLAGS AND (NOT X86_EFLAGS_IF) else
      if Flag = 'OF' then Result := EFLAGS AND (NOT X86_EFLAGS_OF);
    end;
  end;
  InputSL.Free;
end;

//切割字符串
//00400000 12 12 12 12 12 12 12 12 12    e5235432324
function GetMemEditParam (Line: String; var Addr: DWORD; var Buffer: String): BOOL;
var
  KeyStr: String;
  Val64: Int64;
  CutPos, Val32: Integer;
begin
  Buffer := '';
  Result := False;
  Line := Trim (Line);
  if Length(Line) < 10 then exit;

  //获取地址值
  CutPos := Pos ('  ', Line);
  KeyStr := Copy(Line, 1, CutPos - 1);
  if KeyStr[1] <> '$' then
    KeyStr := '$' + KeyStr;
  if not TryStrToInt64 (KeyStr, Val64)then Exit;
  Addr := DWORD(Val64);

  Delete (Line, 1, CutPos);
  Line := Trim (Line);
  if Length(Line) < 2 then exit;

  //获取缓冲区值
  CutPos := Pos ('  ', Line);
  if CutPos < 2 then exit;
  Line := Copy (Line, 1, CutPos);
  Line := Trim (Line);

  while Length (Line) >= 2 do
  begin
    KeyStr := Copy (Line, 1, 2);
    if not TryStrToInt ('$'+KeyStr, Val32) then Exit;
    Buffer := Buffer + Char(Val32);
    Delete (Line, 1, 2);
    Line := TrimLeft (Line);
  end;
  
  Result := Length (Buffer) > 0; 
end;

function MakeJmpOffsetStr (Address, JmpToAddr: DWORD; var OffsetStr: String): BOOL;
var
  CodeInfos: LPTCodeInfos;
  JmpOffset: integer;
begin
  Result := False;
  CodeInfos := Cmd_GetCodeDisAsm (Pointer(Address), 0);
  if Assigned (CodeInfos) then
  begin
    JmpOffset := Integer(JmpToAddr) - Integer(CodeInfos.Next);
    if JmpOffset > 0 then
    begin
      OffsetStr := LowerCase(IntToHex(JmpOffset, 0));
      OffsetStr := '+' + OffsetStr;
    end else
    begin
      JmpOffset := Abs (JmpOffset);
      OffsetStr := LowerCase(IntToHex(JmpOffset, 0));
      OffsetStr := '-' + OffsetStr;
    end;
    Result := True;
  end;
end;

function PreFormatDisasmInput (Input: String; var Address: DWORD; var Formated: String): BOOL;
const
  ToDeleteA = 'dword ptr';
  Def_Call = 'call ';
var
  Val64: Int64;
  Key: String;
  PosIndex: Integer;
  PosLeft, PosRight: Integer;
  JmpToAddr: DWORD;
begin
  Result := False;
  Address := 0;
  Formated := '';
  if Length(Input) < 9 then exit;

  //取代码地址
  Key := Copy (Input, 1, 8);
  if Key[1] <> '$' then
    Key := '$' + Key;

  if not TryStrToInt64 (Key, Val64) then exit;
  Address := DWORD(Val64);

  Delete (Input, 1, 8);
  Input := TrimLeft (Input);

  //去掉注释
  PosIndex := Pos (';', Input);
  if PosIndex > 0 then
    Delete (Input, PosIndex, Length(Input));
  Input := TrimRight (Input);

  //删除多余标签标志如，dword ptr
  PosIndex := Pos (ToDeleteA, Input);
  if PosIndex > 0 then
    Delete (Input, PosIndex, Length(ToDeleteA));

  //删除$符号
  for PosIndex := Length(Input) downto 1 do
    if Input[PosIndex] = '$' then
      Delete (Input, PosIndex, 1);

  //删除括号内内容
  PosLeft := Pos ('(', Input);
  PosRight := Pos (')', Input);
  if (PosLeft > 0) and (PosRight > 0) then
  begin
    Delete (Input, PosLeft, PosRight - PosLeft + 1);
  end;

  //转换loc_00450000标签   jmp处理
  PosIndex := Pos ('j', Input);
  if PosIndex > 0 then
  begin
    PosIndex := Pos ('loc_', Input);
    if PosIndex > 0 then
    begin
      Key := Copy (Input, PosIndex + 4, 8);
      Delete (Input, PosIndex, 12);
      Key := '$' + Key;
      if TryStrToInt64 (Key, Val64) then
      begin
        JmpToAddr := DWORD(Val64);
        if MakeJmpOffsetStr (Address, JmpToAddr, Key) then
          Insert (Key, Input, PosIndex);
      end;
    end else
    begin  
      PosIndex := Pos (' ', Input);
      if PosIndex > 0 then
      begin
        Key := Copy (Input, PosIndex + 1, Length(Input));
        Key := Trim(Key);

        Repeat
          if Key[1] = '+' then Break;
          if Key[1] = '-' then Break;
          if Key[1] <> '$' then Key := '$' + Key;
          if not TryStrToInt64 (Key, Val64) then Break;
          if not MakeJmpOffsetStr (Address, DWORD(Val64), Key) then Break;
          SetLength (Input, PosIndex);
          Input := Input + ' ' + Key;
        until True;
      end;
    end;
  end;

  //转换call标签    call处理
  PosIndex := Pos (Def_Call, Input);
  if PosIndex > 0 then
  begin
    Key := Copy (Input, PosIndex + Length(Def_Call), Length(Input));
    Key := Trim(Key);

    Repeat
      if Key[1] = '+' then Break;
      if Key[1] = '-' then Break;
      if Key[1] <> '$' then Key := '$' + Key;
      if not TryStrToInt64 (Key, Val64) then Break; 
      if not MakeJmpOffsetStr (Address, DWORD(Val64), Key) then Break;
      Input := 'call ' + Key;
    until True;
  end;

  Formated := Input;
  Result := True;
end;

procedure TBreakPointForm.InputEditorKeyPress(Sender: TObject; var Key: Char);
var
  SrcEdit: TEdit absolute Sender;
  SrcListBox: TListBox;
  Index: Integer;
  OriLine, NowLine, MemBuff, DisasmInput: String;
  InputSL: TStringList;
  OriVal, NowVal: DWORD;
  CodeLen, NeedLen: Integer;
  AddrToWrite: DWORD;
  bytes, ToWriteCodes: Array of byte;
  GotResult: Pointer;
  CodeInfos: LPTCodeInfos;
begin
  if Ord(Key) = VK_RETURN then
  begin
    SrcListBox := InputEditor.Parent as TListBox;
    Index := InputEditor.Tag;
    OriLine := SrcListBox.Items[Index];
    NowLine := SrcEdit.Text;

    if SrcListBox = self.ListBox1 then  //寄存器区
    begin
      InputSL := GetSplitBlankList (NowLine);
      if InputSL.Count = 2 then
      begin
        OriVal := GetRegistValue (InputSL[0], @BpDetailBak.RegInfo);
        NowVal := HexToDword (InputSL[1], OriVal);
        if OriVal <> NowVal then
        begin
          AddrToWrite := DWORD(BpDetailBak.RegInfoReal) + GetRegistOffset (InputSL[0]);
          if WriteValueToAddr (Pointer(AddrToWrite), NowVal) then
          begin
            self.UpdateRegistText(True);
            DbgPrinter ('%s -> %s', [OriLine, NowLine]);
          end;
        end;
      end;
      InputSL.Free;
    end else

    if SrcListBox = self.ListBox2 then  //线程栈区
    begin
      InputSL := GetSplitBlankList (NowLine);
      if InputSL.Count = 2 then
      begin
        AddrToWrite := HexToDword (InputSL[0], 0);
        NowVal := HexToDword (InputSL[1], 0);
        if WriteValueToAddr (Pointer(AddrToWrite), NowVal) then
        begin
          self.UpdateStackLineText();
          DbgPrinter ('%s -> %s', [OriLine, NowLine]);
        end;
      end;
      InputSL.Free;
    end else

    if SrcListBox = self.ListBox3 then  //反汇编区
    begin
      if PreFormatDisasmInput (NowLine, AddrToWrite, DisasmInput) then
      begin
        GotResult := GetCodeAssemble (AddrToWrite, PChar(DisasmInput), CodeLen);
        if Assigned (GotResult) then
        begin
          SetLength (bytes, CodeLen);
          CopyMemory (@bytes[0], GotResult, CodeLen);

          CodeInfos := Cmd_GetCodeDisAsm (Pointer(AddrToWrite), 16);
          NeedLen := 0;
          SetLength (ToWriteCodes, NeedLen);
          While Assigned (CodeInfos) and (NeedLen < CodeLen) do
          begin
            OriVal := Length(ToWriteCodes);
            NeedLen := DWORD(CodeInfos.CodeLen) + OriVal;
            SetLength (ToWriteCodes, NeedLen);
            CopyMemory (@ToWriteCodes[OriVal], @CodeInfos.Code[0], CodeInfos.CodeLen);
            Inc (CodeInfos);
          end;

          Repeat
            if NeedLen < CodeLen then
            begin
              DbgPrinter ('获取代码失败！');
              Break;
            end;

            if CodeLen = NeedLen then
              if CompareMem (@bytes[0], @ToWriteCodes[0], CodeLen) then
              begin
                DbgPrinter ('代码相同，不需写入!');
                Break;
              end;

            DbgPrinter ('Asm: ' + DisasmInput);
            DbgPrinter ('  Src: ' + PcharToPacketStr (@ToWriteCodes[0], Length(ToWriteCodes)));
            DbgPrinter ('  New: ' + PcharToPacketStr (@bytes[0], Length(bytes)));

            FillChar (ToWriteCodes[0], NeedLen, $90);
            CopyMemory (@ToWriteCodes[0], @bytes[0], CodeLen);

            if not Cmd_SetMemBuffer (Pointer(AddrToWrite), @ToWriteCodes[0], NeedLen) then
              DbgPrinter ('写入代码 Cmd_SetMemBuffer Error!');

            ClearCacheDisasmText(Pointer(AddrToWrite));
            self.ViewCodeList.Clear;
            self.UpdateDisasmText;
          until True;
        end;
      end;
    end else

    if SrcListBox = self.ListBox4 then  //数据区
    begin
      if GetMemEditParam (NowLine, AddrToWrite, MemBuff) then
      if Cmd_SetMemBuffer (Pointer(AddrToWrite), @MemBuff[1], Length(MemBuff)) then
      begin
        self.UpdateMemoryEditText;    
        ScrollMiddle (SrcListBox, Index);
      end else
        DbgPrinter ('写入数据 Cmd_SetMemBuffer Error!');
    end else

    if SrcListBox = self.ListBox5 then  //标志寄存器区
    begin
      OriVal := BpDetailBak.RegInfo.EFLAGS;
      NowVal := SetFlagValue (OriVal, NowLine);
      if NowVal <> OriVal then
      begin
        AddrToWrite := DWORD(BpDetailBak.RegInfoReal) + GetRegistOffset ('eflags');
        if WriteValueToAddr (Pointer(AddrToWrite), NowVal) then
        begin
          self.UpdateRegistText(True);
          DbgPrinter ('%s -> %s', [OriLine, NowLine]);
        end;
      end;
    end;
    
    SrcListBox.ItemIndex := Index;
    InputEditor.Visible := False;
  end;
end;

procedure TBreakPointForm.N1Click(Sender: TObject);
begin
  SetStackLineText (StackMem, LastEBP, True);
end;

function HowManyCount (Listbox: TListbox): Integer;
begin
  Result := (Listbox.Height - Listbox.BevelWidth * 4) div (listbox.ItemHeight);
end;

procedure TBreakPointForm.ScrollMiddle (ListBox: TListBox; Index: Integer);
var
  ScrollCount: Integer;
  Para: WPARAM;
begin
  ScrollCount := Index - HowManyCount(ListBox) div 2;

  if ScrollCount > 0 then
  begin
    Para := MAKELONG(SB_THUMBPOSITION, ScrollCount);
    ListBox.Perform(WM_VSCROLL, Para, 0);
  end;
end;

Procedure PreHandleDisasmText (SL: TStrings; CodeList: TList);
var
  Index: Integer;
  Line, AddrStr: String;
  Val64: Int64;
  CodeAddr: Pointer;
  CanEditIndex: Integer;
begin
  CodeList.Clear;
  for Index := 0 to SL.Count - 1 do
  begin
    Line := SL.Strings[Index];
    if Length(Line) >= 8 then
    begin
      AddrStr := '$' + Copy (Line, 1, 8);
      if TryStrToInt64 (AddrStr, Val64) then
      begin
        CodeAddr := Pointer(Val64);
        if CodeList.IndexOf(CodeAddr) = -1 then
        begin
          CodeList.Add (CodeAddr);
          CanEditIndex := FoundCodeIndex (SL, CodeAddr, Index);
          if CanEditIndex >= 0 then
            SL.Objects[CanEditIndex] := Pointer(True);
        end;
      end;
    end;
  end;
end;

procedure TBreakPointForm.SetDisasmText (CodeAddr: Pointer);
var
  Index: Integer;
  CodeText: String;
begin
  Index := ViewCodeList.IndexOf(CodeAddr);   

  if Index = -1 then
  begin
    CodeText := GetCodeAddrDisasm (CodeAddr);
    ListBox3.Items.Text := CodeText;
    PreHandleDisasmText (ListBox3.Items, ViewCodeList);
  end;

  NewEipIndex := FoundCodeIndex (ListBox3.Items, CodeAddr);
  ListBox3.ItemIndex := NewEipIndex;

  ScrollMiddle (ListBox3, NewEipIndex);
  ListBox3.Repaint;
end;

procedure TBreakPointForm.SetStackLineText (StackMM: LPTMemBuffer; EBP: DWORD; FullView: BOOL = False);
var
  ViewBase, ViewMax: DWORD;
  ViewScan: PDWORD;
  ViewCount: Integer;
  Index: Integer;
  CmpStr: String;
begin
  ViewBase := DWORD(StackMM.Address);
  ViewScan := @StackMM.Buffer[0];
  ViewMax := ViewBase + DWORD(StackMM.BuffSize);

  With ListBox2.Items do
  begin
    BeginUpdate;
    Clear;

    if FullView then
    begin
      Repeat
        AddObject(IntToHex(ViewBase, 8) + '  ' + IntToHex(ViewScan^, 8), Pointer(True));
        Inc (ViewBase, SizeOf(Pointer));
        Inc (ViewScan);
      until ViewBase >= ViewMax;
    end else
    begin
      ViewCount := HowManyCount (ListBox2);
      Repeat
        AddObject(IntToHex(ViewBase, 8) + '  ' + IntToHex(ViewScan^, 8), Pointer(True));
        Inc (ViewBase, SizeOf(Pointer));
        Inc (ViewScan);
        Dec (ViewCount);
      until (ViewCount <= 0) or (ViewBase >= ViewMax);
    end;

    CmpStr := IntToHex (ebp, 8);
    for Index := 0 to ListBox2.Items.Count - 1 do
      if PInt64(@CmpStr[1])^ = Pint64(@ListBox2.Items[Index][1])^ then
      begin
        ListBox2.ItemIndex := Index;
        Break;
      end;

    if FullView then
      ScrollMiddle (ListBox2, ListBox2.ItemIndex);

    EndUpdate;
  end;
end;

function GetNeedMemory (esp, StackLimit, StackBase: DWORD; var CopyBase: Pointer; var CopySize: Integer): BOOL;
var
  LowValue: DWORD;
  ModVal: Integer;
begin
  LowValue := Max (Esp, StackLimit);
  CopyBase := Pointer(LowValue);
  CopySize := StackBase - DWORD(CopyBase);

  ModVal := CopySize mod 4;
  if ModVal > 0 then
  begin
    CopyBase := Pointer (DWORD(CopyBase) + DWORD(ModVal));
    Dec (CopySize, ModVal);
  end;  

  Result := CopySize > 0;
end;    

procedure TBreakPointForm.SetStackLineText (ESP, EBP, StackLimit, StackBase: DWORD);
var
  CopyBase: Pointer;
  CopySize: Integer;
  StackMM: Pointer;
begin
  if not GetNeedMemory (esp, StackLimit, StackBase, CopyBase, CopySize) then exit;
  StackMM := Cmd_GetMemBuffer (CopyBase, CopySize);
  if StackMM = nil then exit;

  if Assigned (StackMem) then
    FreeMem (StackMem);

  StackMem := AllocMem (CopySize + SizeOf(TMemBuffer));
  StackMem.Address := CopyBase;
  StackMem.BuffSize := CopySize;
  CopyMemory (@StackMem.Buffer[0], StackMM, CopySize);

  LastEBP := ebp;
  SetStackLineText (StackMem, ebp);
end;

Procedure TBreakPointForm.SetMemoryEditText (Address, MemBase: Pointer; MemSize: Integer);
var
  SL: TStringList;
  Index: Integer;
begin
  if Assigned (DataMem) then
    FreeMem (DataMem);
  GetMem (DataMem, MemSize + SizeOf(TMemBuffer));
  DataMem.Address := Address;
  DataMem.BuffSize := MemSize;
  CopyMemory (@DataMem.Buffer[0], MemBase, MemSize);

  SL := TStringList.Create;
  PcharToFormatedViewBoth (MemBase, MemSize, DWORD(Address), SL);

  With self.ListBox4.Items do
  begin
    Text := SL.Text;
    for Index  := 0 to Count - 1 do
      Objects[Index] := Pointer(True);
  end;

  SL.Free;
end;

function FlagSetValue (EFLAGS: DWORD; Flag: DWORD): String;
begin    
  if EFLAGS AND Flag = Flag then
    Result := '1'
  else
    Result := '0';
end;

procedure TBreakPointForm.SetRegistText (BpDetail: LPTBreakDetail);
begin
  With BpDetail.RegInfo do
  begin
    With self.ListBox1.Items do
    begin
      BeginUpdate;
      Clear;
      AddObject('EAX  ' + IntToHex(EAX, 8), Pointer(True));
      AddObject('ECX  ' + IntToHex(ECX, 8), Pointer(True));
      AddObject('EDX  ' + IntToHex(EDX, 8), Pointer(True));
      AddObject('EBX  ' + IntToHex(EBX, 8), Pointer(True));
      AddObject('ESP  ' + IntToHex(ESP, 8), Pointer(True));
      AddObject('EBP  ' + IntToHex(EBP, 8), Pointer(True));
      AddObject('ESI  ' + IntToHex(ESI, 8), Pointer(True));
      AddObject('EDI  ' + IntToHex(EDI, 8), Pointer(True));
      Add('');
      Add('EIP  ' + IntToHex(DWORD(BpDetail.EIP), 8));
      EndUpdate;
    end;

    With self.ListBox5.Items do
    begin
      BeginUpdate;
      Clear;
      AddObject('CF ' + FlagSetValue(EFLAGS, X86_EFLAGS_CF), Pointer(True));
      AddObject('PF ' + FlagSetValue(EFLAGS, X86_EFLAGS_PF), Pointer(True));
      AddObject('AF ' + FlagSetValue(EFLAGS, X86_EFLAGS_AF), Pointer(True));
      AddObject('ZF ' + FlagSetValue(EFLAGS, X86_EFLAGS_ZF), Pointer(True));
      AddObject('SF ' + FlagSetValue(EFLAGS, X86_EFLAGS_SF), Pointer(True));
      AddObject('TF ' + FlagSetValue(EFLAGS, X86_EFLAGS_TF), Pointer(True));
      AddObject('IF ' + FlagSetValue(EFLAGS, X86_EFLAGS_IF), Pointer(True));
      AddObject('OF ' + FlagSetValue(EFLAGS, X86_EFLAGS_OF), Pointer(True));
      EndUpdate;
    end;
  end;
end;
                          
procedure TBreakPointForm.OnDbgCmdSend (Sender: TObject; SendResult: BOOL);
begin                         
  BpDetailBak.EIP := NIL;
  BpDetailBak.RegInfoReal := NIL;
end;

procedure TBreakPointForm.ToolButton3Click(Sender: TObject);
begin
  OnDbgCmdSend (Sender, Cmd_TrapDbgStepInto (hTask));
end;

procedure TBreakPointForm.ToolButton4Click(Sender: TObject);
begin
  OnDbgCmdSend (Sender, Cmd_TrapDbgStepOver (hTask));
end;

procedure TBreakPointForm.ToolButton5Click(Sender: TObject);
begin
  OnDbgCmdSend (Sender, Cmd_TrapDbgRelease (hTask));
end;

procedure TBreakPointForm.ToolButton6Click(Sender: TObject);
begin
  OnDbgCmdSend (Sender, Cmd_TrapDbgRunUntilRet (hTask));
end;

procedure TBreakPointForm.ToolButton7Click(Sender: TObject);
begin
//  OnDbgCmdSend (Sender, Cmd_TrapDbgRunUntilAddr (hTask));
end;


procedure TBreakPointForm.SetBreakDetail (BpDetail: LPTBreakDetail);
begin
  if Assigned (BpDetail) then
    BpDetailBak := BpDetail^;
end;

procedure TBreakPointForm.UpdateDisasmText;
begin
  if BpDetailBak.EIP = nil then exit;     
  SetDisasmText (BpDetailBak.EIP);
end;

procedure TBreakPointForm.UpdateStackLineText;
begin
  if BpDetailBak.EIP = nil then exit;
  SetStackLineText(BpDetailBak.RegInfo.ESP, BpDetailBak.RegInfo.EBP, DWORD(BpDetailBak.StackLimit), DWORD(BpDetailBak.StackBase));
end;

procedure TBreakPointForm.UpdateRegistText (Force: BOOL = False);
var
  RmRegist: LPTRegister;
begin
  if BpDetailBak.EIP = nil then exit;
  if BpDetailBak.RegInfoReal = nil then exit;
  if Force then
  begin
    RmRegist := Cmd_GetMemBuffer (BpDetailBak.RegInfoReal, SizeOf(TRegister));
    if Assigned (RmRegist) then
      BpDetailBak.RegInfo := RmRegist^;
  end;
  SetRegistText(@BpDetailBak);
end;


procedure TBreakPointForm.UpdateMemoryEditText;
var
  GotMem: Pointer;
begin
  GotMem := Cmd_GetMemBuffer (DataMem.Address, DataMem.BuffSize);
  if GotMem = nil then exit;
  SetMemoryEditText (DataMem.Address, GotMem, DataMem.BuffSize);
end;



end.
