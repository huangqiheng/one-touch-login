unit Unit4;
        
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Tabs, DockTabSet, CategoryButtons, ButtonGroup;

type
  TForm4 = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Memo1: TMemo;
    procedure Button3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

uses
  HiddenInjectDLL, DLLDatabase, DLLLoader, SimpleDLLLoader,
  winsock2, winsock, NotifyingClient, AndIpcServer;

function GetCallingImage: THandle; Register;
asm
    mov eax, ebp
    add eax, 4
    mov eax, [eax]
    and eax, $FFFFF000
    jmp @CmpImage
  @NextAddr:
    sub eax, $1000
  @CmpImage:
    cmp word ptr [eax], $5A4D
    jnz @NextAddr
end;

function GetImageBase (Param: Pointer): Pointer; Stdcall;
begin
  Result := Pointer (GetCallingImage);     
end;


function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

function GetAppExeFromCmdLine (CmdLine: String): String;
var
  ExtStr: String;
  ExtSL: TStringList;
begin                      
  Result := '';
  if Length (CmdLine) < 7 then exit;

  ExtStr := ExtractFileExt (CmdLine);
  if Length (ExtStr) < 2 then exit;

  Result := Copy (CmdLine, 1, Length(CmdLine) - Length(ExtStr));

  ExtSL := GetSplitBlankList (ExtStr);
  ExtStr := ExtSL[0];
  Result := Result + ExtStr;
end;


Procedure DbgFmt (const FmtStr: string; const Args: array of const);
var
  dbgstr: string;
begin
  Try
  dbgstr := Format (FmtStr, Args);
  OutputDebugStringA (@dbgstr[1]);
  Except
  End;
end;

var
  ProgWin: THandle = 0;
  ProgVal: Integer;

procedure TForm4.Button10Click(Sender: TObject);
begin
  CloseProgressWindow (ProgWin);
end;

procedure TForm4.Button11Click(Sender: TObject);
begin
  Inc (ProgVal);
  if ProgVal > 100 then
    ProgVal := 1;

  if ProgWin > 0 then
    ReportProgress (ProgWin, Format('Progress is %d percent',[ProgVal]), ProgVal);
end;

procedure TForm4.Button8Click(Sender: TObject);
begin
  ProgWin := OpenProgressWindow ('WOW自动登录进度');
end;

procedure TForm4.Button12Click(Sender: TObject);
var
  MsgSL: TStringList;
begin
  MsgSL := TStringList.Create;
  MsgSL.Add('Test message');
  MsgSL.Add('Test message');
  MsgSL.Add('Test message');
  ShowUserMessage (MsgSL);
  MsgSL.Free;
end;

procedure TForm4.Button1Click(Sender: TObject);
begin                 
//  DebugBreak;
//  SendDefaultMsg (@SendDefaultMsg);
  GetImageBase (NIL);
end;

procedure TForm4.Button2Click(Sender: TObject);
begin
  if OpenDialog1.Execute() then
  Edit1.Text := OpenDialog1.FileName;
end;

type
  LPTIntArray = ^TIntArray;
  TIntArray = array[0..10] of integer;

procedure TForm4.Button3Click(Sender: TObject);
var
  IntArray: TIntArray;
  Iter: PChar;
begin
  IntArray[0] := 1;
  IntArray[1] := 2;
  IntArray[2] := 4;
  IntArray[3] := 8;

  Iter := @IntArray[0];
  Memo1.Lines.Add(IntToHex(PInt(Iter)^, 8));

  Inc(Iter);
  Memo1.Lines.Add(IntToHex(PInt(Iter)^, 8));

  Inc(Iter);
  Memo1.Lines.Add(IntToHex(PInt(Iter)^, 8));

  Inc(Iter);
  Memo1.Lines.Add(IntToHex(PInt(Iter)^, 8));
end;

procedure IpcCmdRecver (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
var
  OldTick: DWORD;
begin
  OldTick := GetTickCount;
  EchoIpcCommand (hClient, Buffer, Size);
  form4.Memo1.Lines.Add(StrPas(Buffer) + ' ' + IntToStr(GetTickCount-OldTick));
end;

var
  IpcServer: String = '{FB335333-BF2F-424C-87CD-9A55355D3847}';
  hServer: THandle;

procedure TForm4.Button4Click(Sender: TObject);
begin
  hServer := CreateIpcServer (PChar(IpcServer));
  AddIpcCommand (hServer, 'TestCmd', @IpcCmdRecver);
end;

procedure TForm4.Button5Click(Sender: TObject);
begin
  DestroyIpcServer (hServer);
end;

var
  test: string = 'just a test message';

procedure SetTestMsg(Param: Pointer); stdcall;
var
  outBuffer: PChar;
  outSize: dword;
  outTest: String;
  count: integer;
begin
  count := 0;
  repeat
    outTest := test + IntToStr (GetTickCount);
    if SendIpcCommand (PChar(IpcServer), PChar('TestCmd'), 3000, @outTest[1], Length(outTest),
                    Pointer(outBuffer), outSize) then
      form4.Memo1.Lines.Add (Strpas (outBuffer));
    inc (count);
  until count > 5;
end;

procedure TForm4.Button6Click(Sender: TObject);
var
  tid: dword;
begin
  CreateThread (nil, 0, @SetTestMsg, nil, 0, tid);
  CreateThread (nil, 0, @SetTestMsg, nil, 0, tid);
end;

function GetUpperDir (FilePath:String): String;
begin
  if FilePath [Length(FilePath)] = '\' then
    Delete (FilePath, Length(FilePath), 1)
  else begin
    if DirectoryExists (FilePath) then
      FilePath := FilePath + '..';
  end;
  Result := ExtractFilePath (FilePath);
end;

end.
