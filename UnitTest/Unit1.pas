unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Edit1: TEdit;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    ListBox1: TListBox;
    Button9: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    Edit2: TEdit;
    Edit3: TEdit;
    Button10: TButton;
    Edit4: TEdit;
    Edit5: TEdit;
    Button11: TButton;
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses CodeProxy, DLlLoader, SPGetSid;

{$R *.dfm}

procedure TForm1.Button10Click(Sender: TObject);
var
  Value, ScanValue: String;
  Index: integer;
begin
  Edit5.Text := '';
  Value := Edit2.Text;
  With self.ListBox1.Items do
    for Index := 0 to Count - 1 do
      if Value = ValueFromIndex[Index] then
      begin
        Edit5.Text := Names[Index];
        Break;
      end;
end;

procedure TForm1.Button11Click(Sender: TObject);
begin
  Edit4.Text := self.ListBox1.Items.Values[Edit3.Text];
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  CodeBase: Pointer;
  CodeSize: DWORD;
begin                             
  if TestMakeSpyCode (CodeBase, CodeSize) then
  begin
    With TMemoryStream.Create do
    try
      WriteBuffer (CodeBase^, CodeSize);
      SaveToFile ('.\SpyCode.mem');
    finally
      Free;
    end;

    FreeMem (CodeBase);
    Caption := 'OK';
  end else
    Caption := 'False';
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  CodeEntry: Procedure();
begin
    With TMemoryStream.Create do
    try                
      LoadFromFile ('.\SpyCode.mem');
      Caption := IntToStr (Size);
      CodeEntry := Memory;
      CodeEntry;
    finally
      Free;
    end;
end;

function StrEnd(const Str: PChar): PChar; inline;
var
  I: Integer;
begin
  I := 0;
  Repeat
    Result := @Str[I];
    Inc (I);
  until Result^ = #0;
end;

function ExtractFileNameA (FileName: PChar): PChar;  inline;
begin
  Result := StrEnd (FileName);
  repeat
    Dec (Result);
  Until (Result^ = '\') or (Result^ = ':');
  Inc (Result);
end;


//00455D84 8B0424           mov eax,[esp]
//00455D87 C3               ret
Function GetMeCodeSegment(): Pointer;
asm
  mov eax, [esp]
end;


//  asm
//    Call @Next
//  @Next:
//    pop Result
//  end;
//  Repeat
//    Dec (PChar(Result));
//  until PDWORD(Result)^ = $45504D55;
//end;

type
  TStackGetPointer= Function(): Pointer;

function GetNextCodeAddr: Pointer; inline;
var
  CodeBuffer: DWORD;
begin                         
  CodeBuffer := $C324048B;
  Result := TStackGetPointer (@CodeBuffer)();
  Repeat
    Dec (PChar(Result));
  until PDWORD(Result)^ = $45504D55;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  meCode: Pointer;
begin
  meCode := GetNextCodeAddr;    
  self.Edit1.Text := IntToHex (DWORD(meCode), 8);
end;


procedure TForm1.Button5Click(Sender: TObject);
begin
  if IsAdmin then
    Caption := 'admin'
  else
    Caption := 'not admin';
end;


procedure TForm1.Button7Click(Sender: TObject);
var
  MM: TMemoryStream;
begin
  MM := TMemoryStream.Create;

  MM.Seek(0, soFromBeginning);
  MM.LoadFromFile('D:\OneTouch\Release\TestDLL.dll');
  AddMainDLL (MM, '');

  MM.Clear;
  MM.LoadFromFile('D:\OneTouch\Release\TestDLL.dll');
  AddSubDLL (MM);

  MM.Clear;
  MM.LoadFromFile('D:\OneTouch\Release\TestDLL.dll');
  AddSubDLL (MM);

  if InjectThemALL ('D:\OneTouch\Release\Host.exe', 10*1000, False) then
    ShowMessage ('InjectThemALL OK')
  else
    ShowMessage ('InjectThemALL Failure');

  MM.Free;
end;


FUNCTION EnumProc (Sender:POINTER; Name:STRING; Index:INTEGER; FunctionPointer:POINTER):BOOLEAN;
var
  Items: TStrings absolute Sender;
  PrintStr: String;
begin
//  Items.Values[Name] := IntToHex (DWORD(FunctionPointer), 8);
  PrintStr := Format ('%s=%.8X', [Name, DWORD(FunctionPointer)]);
  Items.Add(PrintStr);
end;

var
  ntoskrnl_exe: TDLLLoaderEx = NIL;

procedure TForm1.Button8Click(Sender: TObject);
begin
  if Assigned (ntoskrnl_exe) then
    ntoskrnl_exe.Free;

  ntoskrnl_exe := TDLLLoaderEx.Create;
  ntoskrnl_exe.IsSkipDLLProc := True;
  ntoskrnl_exe.IsSkipRelocation := True;
  ntoskrnl_exe.LoadDLL('C:\WINDOWS\system32\ntoskrnl.exe');

  self.ListBox1.Items.Clear;
  self.ListBox1.Sorted := True;
  ntoskrnl_exe.EnumExportList(self.ListBox1.Items, EnumProc);
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  if Assigned (ntoskrnl_exe) then
    ntoskrnl_exe.Free;

  ntoskrnl_exe := TDLLLoaderEx.Create;
  ntoskrnl_exe.IsSkipDLLProc := True;
  ntoskrnl_exe.IsSkipRelocation := True;
  ntoskrnl_exe.LoadDLL('C:\WINDOWS\system32\ntkrnlpa.exe');

  self.ListBox1.Items.Clear;
  self.ListBox1.Sorted := True;
  ntoskrnl_exe.EnumExportList(self.ListBox1.Items, EnumProc);
end;

function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

procedure TForm1.ListBox1Click(Sender: TObject);
var
  Index: Integer;
  Item: String;
  ResultList: TStringList;
begin
  Index := self.ListBox1.ItemIndex;
  if Index = 1 then exit;
  
  Item := self.ListBox1.Items[Index];
  ResultList := GetSplitBlankList (Item, [' ', '=', '$']);

  self.Edit2.Text := ResultList[1];
  self.Edit3.Text := ResultList[0];
  ResultList.Free;
end;

//const
//  c_HexStr :array[0..$F] of char = '0123456789ABCDEF';
//
//function ByteToChr(b: byte): char;
//begin
//  result := c_HexStr[b mod 16];
//end;

procedure MakeIntToHex_(value: DWORD; var Dist);
var
  c_HexStr: PChar;
  I: Integer;
  val: byte;
  Output: PChar;
begin
  asm
    call @Next
    db  '0'
    db  '1'
    db  '2'
    db  '3'
    db  '4'
    db  '5'
    db  '6'
    db  '7'
    db  '8'
    db  '9'
    db  'A'
    db  'B'
    db  'C'
    db  'D'
    db  'E'
    db  'F'
  @Next:
    pop c_HexStr
  end;

  Output := @Dist;
  Output^ := '$';
  Inc(Output);
  for I := 7 downto 0 do
  begin
    val := Value and $0000000F;
    Output[I] := c_HexStr[val];
    value := value shr 4;
  end;
  Output[8] := #0;
end;


procedure MakeIntToHex(value: DWORD; var Dist); inline;
var
  c_HexStr: Array[0..$F] of char;
  I: Integer;
  val: byte;
  Output: PChar;
begin
  for I := $0 to $F do
  begin
    if I = 0 then
    begin
      c_HexStr[I] := '0';
      Continue;
    end;

    if I = $A then
    begin
      c_HexStr[I] := 'A';
      Continue;
    end;

    c_HexStr[I] := Char(Byte(c_HexStr[I-1]) + 1);
  end;

  Output := @Dist;
  Output^ := '$';
  Inc(Output);
  for I := 7 downto 0 do
  begin
    val := Value and $0000000F;
    Output[I] := c_HexStr[val];
    value := value shr 4;
  end;
  Output[8] := #0;
end;


end.
