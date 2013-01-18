unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ButtonGroup, Menus, AppEvnts, ComCtrls, ImgList, ToolWin,
  StdCtrls, CategoryButtons, Tabs, XPMan, DropMyRights;

type
  TForm2 = class(TForm)
    Splitter1: TSplitter;
    ScrollBox1: TScrollBox;
    ImageList1: TImageList;
    Panel3: TPanel;
    Button1: TButton;
    Button4: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Memo1: TMemo;
    Button5: TButton;
    XPManifest1: TXPManifest;
    ComboBox1: TComboBox;
    Button2: TButton;
    Button3: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    GLastHotIndex: Integer;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

uses shellapi, UGBBig5Convert, StrUtils, WideStrings, formatfunction, GlobalType,
  dll2funcUnit, SimpleDLLLoader, PeHead, MemoryStream, Simarray;

function GetAppPaths (DirName: String): String;
begin
  Result := GetModuleName (0);
  Result := ExtractFilePath (Result) + DirName + '\';
end;

procedure GrayBitmap(ABitmap: TBitmap; Value: integer);
var
  Pixel: PRGBTriple;
  w, h: Integer;
  x, y: Integer;
  avg: integer;
begin
  ABitmap.PixelFormat := pf24Bit;
  w := ABitmap.Width;
  h := ABitmap.Height;
  for y := 0 to h - 1 do
  begin
    Pixel := ABitmap.ScanLine[y];
    for x := 0 to w - 1 do
    begin
      avg := ((Pixel^.rgbtRed + Pixel^.rgbtGreen + Pixel^.rgbtBlue) div 3)
        + Value;
      if avg > 240 then avg := 240;
      Pixel^.rgbtRed := avg;
      Pixel^.rgbtGreen := avg;
      Pixel^.rgbtBlue := avg;
      Inc(Pixel);
    end;
  end;
end;


function LoadIconToImageList (PeFile: String; ImageList: TCustomImageList; GragValue: Integer = 0): Integer;
var
  ico: TIcon;
  Bitmap : TBitmap;
begin
  ico := TIcon.Create;
  ico.Handle := ExtractIcon (HInstance, PChar(PeFile), 0);   
  Result := ImageList.AddIcon(ico);
  ico.Free;

  if GragValue > 0 then
  begin
    Bitmap := TBitmap.Create;
    ImageList.GetBitmap(Result, Bitmap);
    ImageList.Delete(Result);
    GrayBitmap (Bitmap, GragValue);
    Result := ImageList.Add(Bitmap, nil);
    Bitmap.Free;
  end;          
end;



procedure TForm2.Button1Click(Sender: TObject);
var
  pi: PROCESS_INFORMATION;
  LevelStr: String;
  Level: DWORD;
begin
  LevelStr := self.ComboBox1.Text;

  if LevelStr = 'SAFER_LEVELID_FULLYTRUSTED' then
    Level := SAFER_LEVELID_FULLYTRUSTED
  else if LevelStr = 'SAFER_LEVELID_NORMALUSER' then
    Level := SAFER_LEVELID_NORMALUSER
  else if LevelStr = 'SAFER_LEVELID_CONSTRAINED' then
    Level := SAFER_LEVELID_CONSTRAINED
  else if LevelStr = 'SAFER_LEVELID_UNTRUSTED' then
    Level := SAFER_LEVELID_UNTRUSTED
  else if LevelStr = 'SAFER_LEVELID_DISALLOWED' then
    Level := SAFER_LEVELID_DISALLOWED
  else exit;

  if DropMeSuspend (Level, 'C:\Program Files\Internet Explorer\IEXPLORE.EXE', pi) then
  begin
    caption := 'true';
    ResumeThread (pi.hThread);
  end
  else
    caption := 'false';

end;

function SimpleRemoteFunc (ImageBase, lpReserved: Pointer; ImageSize: Integer): Pointer; stdcall;
var
  Loader: PDLLLoadedObject;
  m_Peb   :PPeb;
  ListEntry :PListEntry;
  hKernel32: THandle;
begin
  asm
      mov eax,fs:[$30]
      mov m_Peb, eax
  end;
  ListEntry := m_Peb.Ldr.InInitializationOrderModuleList.Flink.Flink;
  hKernel32 := PDWORD ( DWORD(ListEntry) + SizeOf(TListEntry))^;

  Loader :=  DLLLoader_Load (hKernel32, ImageBase, ImageSize, lpReserved);
  Result := Pointer (Loader.DLLResult);
end;



procedure TForm2.Button3Click(Sender: TObject);
begin
  with TMemoryStream.Create do
  begin
    LoadFromFile ('.\TestDLL.dll');
    SimpleRemoteFunc (Memory, nil, Size);
  end;
end;

Type
  TSimpleRemoteFunc= function (lpReserved: Pointer): Pointer; stdcall;


procedure TForm2.Button2Click(Sender: TObject);
var
  FuncEntry, NewFuncEntry: Pointer;
  FuncSize: DWORD;
begin     
  if Dll2Function ('.\TestDLL.dll', FuncEntry, FuncSize) then
  begin
    NewFuncEntry := VirtualAlloc(nil, FuncSize, MEM_COMMIT,PAGE_EXECUTE_READWRITE);
    CopyMemory (NewFuncEntry, FuncEntry, FuncSize);
    TSimpleRemoteFunc(NewFuncEntry)(nil);
  end;
end;

function BIG5ToGB2312(GBStr: string): AnsiString;
{进行GBK繁体转简体}
var
Len: integer;
pGBCHTChar: PChar;
pGBCHSChar: PChar;
begin
pGBCHTChar := PChar(GBStr);
Len := MultiByteToWideChar(936, 0, pGBCHTChar, -1, nil, 0);
GetMem(pGBCHSChar, Len * 2 + 1);
ZeroMemory(pGBCHSChar, Len * 2 + 1);
//GB CHS -> GB CHT
LCMapString($804, LCMAP_SIMPLIFIED_CHINESE, pGBCHTChar, -1, pGBCHSChar, Len * 2);
result := string(pGBCHSChar);
//FreeMem(pGBCHTChar);
FreeMem(pGBCHSChar);
end;

function   GB2312ToBIG5(GB2312Str:   string):   AnsiString;
  var
      iLen:   Integer;
      PGBCHSStr:   PChar;   //GB编码的简体字符
      PGBCHTStr:   PChar;   //GB编码的繁体字符
      PUnicodeChar:   PWideChar;   //Unicode编码的字符
      PBIG5Str:   PChar;   //BIG5编码的字符
  begin
      PGBCHSStr:=PChar(GB2312Str);
      iLen:=MultiByteToWideChar(936,0,PGBCHSStr,-1,nil,0);   //计算转换的字符数
      GetMem(PGBCHTStr,iLen*2+1);   //分配内存
      LCMapString($0804,LCMAP_TRADITIONAL_CHINESE,PGBCHSStr,-1,PGBCHTStr,iLen*2);   //转换GB码简体到GB码繁体
      GetMem(PUnicodeChar,iLen*2);   //分配内存
      MultiByteToWideChar(936,0,PGBCHTStr,-1,PUnicodeChar,iLen);   //转换GB码到Unicode码
      iLen:=WideCharToMultiByte(950,0,PUnicodeChar,-1,nil,0,nil,nil);
      GetMem(PBIG5Str,iLen);
      WideCharToMultiByte(950,0,PUnicodeChar,-1,PBIG5Str,iLen,nil,nil);

  //     Result:=string(PBIG5Str);
      Result:=string(PGBCHTStr);

      FreeMem(PBIG5Str);
      FreeMem(PUnicodeChar);
      FreeMem(PGBCHTStr);
  end;


function _GBToBIG5(GBStr : String): AnsiString;
var
  Len: Integer;
  pGBCHTChar: PChar;
  pGBCHSChar: PChar;
  pUniCodeChar: PWideChar;
  pBIG5Char: PChar;
begin
  pGBCHSChar := PChar(GBStr);
  Len := MultiByteToWideChar(936,0,pGBCHSChar,-1,nil,0);
  GetMem(pGBCHTChar,Len*2+1);
  ZeroMemory(pGBCHTChar,Len*2+1);
  //GB CHS -> GB CHT
  LCMapString($804,LCMAP_TRADITIONAL_CHINESE,pGBCHSChar,-1,pGBCHTChar,Len*2);
  GetMem(pUniCodeChar,Len*2);
  ZeroMemory(pUniCodeChar,Len*2);
  //GB CHT -> UniCode
  MultiByteToWideChar(936,0,pGBCHTChar,-1,pUniCodeChar,Len*2);
  Len := WideCharToMultiByte(950,0,pUniCodeChar,-1,nil,0,nil,nil);
  GetMem(pBIG5Char,Len);
  ZeroMemory(pBIG5Char,Len);
  //UniCode -> Big5
  WideCharToMultiByte(950,0,pUniCodeChar,-1,pBIG5Char,Len,nil,nil);
  Result := String(pBIG5Char);
  FreeMem(pBIG5Char);
  FreeMem(pGBCHTChar);
  FreeMem(pUniCodeChar);
end; 
 

 

function _BIG5ToGB(BIG5Str : String): AnsiString;
var
 Len: Integer;
 pBIG5Char: PChar;
 pGBCHSChar: PChar;
 pGBCHTChar: PChar;
 pUniCodeChar: PWideChar;
begin
 //String -> PChar
  pBIG5Char := PChar(BIG5Str);
  Len := MultiByteToWideChar(950,0,pBIG5Char,-1,nil,0);
  GetMem(pUniCodeChar,Len*2);
  ZeroMemory(pUniCodeChar,Len*2);
  //Big5 -> UniCode
  MultiByteToWideChar(950,0,pBIG5Char,-1,pUniCodeChar,Len);
  Len := WideCharToMultiByte(936,0,pUniCodeChar,-1,nil,0,nil,nil);
  GetMem(pGBCHTChar,Len*2);
  GetMem(pGBCHSChar,Len*2);
  ZeroMemory(pGBCHTChar,Len*2);
  ZeroMemory(pGBCHSChar,Len*2);
  //UniCode->GB CHT
  WideCharToMultiByte(936,0,pUniCodeChar,-1,pGBCHTChar,Len,nil,nil);
  //GB CHT -> GB CHS
  LCMapString($804,LCMAP_SIMPLIFIED_CHINESE,pGBCHTChar,-1,pGBCHSChar,Len);
  Result := String(pGBCHSChar);
  FreeMem(pGBCHTChar);
  FreeMem(pGBCHSChar);
  FreeMem(pUniCodeChar);
end;


const
  server_str : array [0..15] of byte = ($E6,$92,$92,$E7,$88,$BE,$E8,$96,$A9,$E9,$87,$8C,$E5,$AE,$89,$00);


function SetRealmNameNewFile (Source, Distin: String; RealmName:String): BOOL;
const
  KeyHead = 'SET realmName ';
var
  SL: TStringList;
  Index: Integer;
  Item: String;
begin
  Result := False;
  SL := TStringList.Create;
  SL.LineBreak := #10;
  SL.LoadFromFile(Source);

  for Index := 0 to SL.Count - 1 do
  begin
    Item := SL[Index];
    if CompareMem (PChar(Item), PChar(KeyHead), Length(KeyHead)) then
    begin
      RealmName := AnsiToUtf8 (RealmName);
      Item := KeyHead + '"' + RealmName + '"';
      SL.Delete(Index);
      SL.Insert(Index, Item);
      SL.SaveToFile(Distin);
      Result := True;
      Exit;
    end;
  end;
end;


//E6 92 92 E7 88 BE E8 96 A9 E9 87 8C E5 AE 89 00
procedure TForm2.Button4Click(Sender: TObject);
var
  HexStr: String;
  Buffer: PChar;
  BufLen: Integer;              
begin
  HexStr := self.Edit1.Text;

  Buffer := PacketStrToPchar (HexStr, BufLen);
  SetString (HexStr, Buffer, BufLen);
//  FreeMem (Buffer);

  self.Memo1.Text := PcharToPacketViewStr (PChar(HexStr), Length(HexStr), 0);

  self.Edit3.Text := HexStr;

  self.Edit2.Text := Utf8ToAnsi (HexStr);
end;


end.
