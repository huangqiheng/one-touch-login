unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, TrapDbgUnit, Grids;

type
  TForm2 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    Button3: TButton;
    Button4: TButton;
    OpenDialog1: TOpenDialog;
    Button5: TButton;
    Button6: TButton;
    Edit1: TEdit;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    procedure Button12Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

uses PlugKernelUnit, SyncQueueHandler, FindAddress, madDisAsm,
  GetCodeAreaList, Unit6, ShareMapMemory;

{$R *.dfm}

Procedure OnMessage (Task: THandle; MsgType: Integer; MsgBuff: PChar; MsgSize: Integer); Stdcall;
var
  MsgHead: String;
begin
  if MsgSize <= 0 then Exit;

  case MsgType of
    MESSAGE_TYPE_SYSTEM: MsgHead := '[System] ';
    MESSAGE_TYPE_ERROR : MsgHead := '[Error] ';
    MESSAGE_TYPE_DEBUG : MsgHead := '[Debug] ';
    MESSAGE_TYPE_LOG   : MsgHead := '[LogMsg] ';
    MESSAGE_TYPE_NOTICE: MsgHead := '[Notice] ';
    ELSE MsgHead := '[UnKnow] ';
  end;

  Form2.Memo1.Lines.Add(MsgHead + StrPas(MsgBuff));
end;

Procedure OnAppData (Task: THandle; DataBuff: PChar; DataSize: Integer); Stdcall;
begin

end;

Procedure OnProgress (Task: THandle; OpType: Integer; Caption, Hint: PChar; Progress: Integer); Stdcall;
begin

end;

Procedure OnConfig (Task: THandle; Key: PChar; Value: PChar); Stdcall;
begin

end;

Procedure OnKeyData (Task: THandle; Key: PChar; Value: PChar); Stdcall;
begin

end;

Function DB_TaskCreate (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall; external 'TrapDebug.dll' name 'TaskCreate';
Function DB_TaskDestroy (Task: THandle; AppExit: BOOL): BOOL; Stdcall; external 'TrapDebug.dll' name 'TaskDestroy';
Function DB_TaskConfig (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall; external 'TrapDebug.dll' name 'TaskConfig';
Function DB_TaskPlugin (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall; external 'TrapDebug.dll' name 'TaskPlugin';
Function DB_TaskRun (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall; external 'TrapDebug.dll' name 'TaskRun';
Function DB_TaskRunning (Task: THandle): BOOL; Stdcall; external 'TrapDebug.dll' name 'TaskRunning';
Function DB_TaskAppData (Task: THandle; DataBuff: PChar; DataSize: Integer): BOOL; Stdcall; external 'TrapDebug.dll' name 'TaskAppData';
Function DB_TaskCopy (Task: THandle): THandle; Stdcall; external 'TrapDebug.dll' name 'TaskCopy';

Procedure DB_SetPluginMS (Task: THandle; FileName: String; PlugType: Integer);
var
  MS: TMemoryStream;
begin
  if not FileExists (FileName) then exit;
  
  MS := TMemoryStream.Create;
  Try
    MS.LoadFromFile(FileName);
    DB_TaskPlugin (Task, MS.Memory, MS.Size, PlugType);
  finally
    MS.Free;
  end;      
end;

var
  IETask: THandle;

procedure TForm2.Button1Click(Sender: TObject);
var
  RunRet: Integer;
begin
  IETask := DB_TaskCreate (@OnMessage, @OnProgress, @OnAppData, @OnConfig, @OnKeyData);
  DB_SetPluginMS (IETask, 'D:\OneTouch\Release\PlugIn\PlugBase.dll', PLUGIN_TYPE_PLUGBASE);
  DB_SetPluginMS (IETask, 'D:\OneTouch\Release\PlugIn\Empty.dll', PLUGIN_TYPE_PLUGIN);

  RunRet := DB_TaskRun (IETask,
            'C:\Program Files\Internet Explorer\IEXPLORE.EXE',
            SAFER_LEVELID_FULLYTRUSTED,//SAFER_LEVELID_NORMALUSER,
            INJECT_MODE_DRIVER,
            RUN_MODE_NORMAL);

  if RunRet <> 0 then
    ShowMessage ('创建任务失败了！');
end;

procedure TForm2.Button2Click(Sender: TObject);
var
  IsTerminateAim: BOOL;
begin
  if DB_TaskRunning (IETask) then
  begin
    IsTerminateAim := IDYES = MessageBoxA (self.Handle, '是否关闭被调试程序？', '关闭提示', MB_YESNO);
    if not DB_TaskDestroy (IETask, IsTerminateAim) then
      ShowMessage ('关闭任务失败了！');
  end;
end;

function GetSystemBootTime: String;
var
  T1: Int64;
  T2,T3: Comp;
  T4: TDateTime;
begin
  T1 := GetTickCount;                               {从开机到现在的毫秒数}
  T2 := TimeStampToMSecs(DateTimeToTimeStamp(Now)); {从 0001-1-1 到当前时间的毫秒数}
  T3 := T2 - T1;                                    {从 0001-1-1 到开机时刻的毫秒数}
  T4 := TimeStampToDateTime(MSecsToTimeStamp(T3));  {从 0001-1-1 到开机时刻的时间}
  Result := DateTimeToStr(T4);                   {显示开机时间}
end;

procedure TForm2.Button3Click(Sender: TObject);
begin
  caption := GetSystemBootTime;
end;

function ExportEnumProc (Memo: TMemo; Name: PChar; Index: Integer; Entry: Pointer): BOOL; Stdcall;
begin
  Result := True;
  Memo.Lines.Add(StrPas(Name));  
end;


procedure TForm2.Button4Click(Sender: TObject);
var
  libHandle: THandle;
begin
  self.OpenDialog1.Filter := '动态连接库|*.dll|可执行程序|*.exe';
  if self.OpenDialog1.Execute then
  begin
    LibHandle := LoadLibrary (PChar(self.OpenDialog1.FileName));
    self.Memo1.Clear;
    EnumExports (LibHandle, @ExportEnumProc, self.Memo1);
  end;
end;

procedure TForm2.Button5Click(Sender: TObject);
var
  Image: THandle;
  NodeList: TList;
  FlatNodeLst: LPTFlatNodeLst;
  _GetImageFlatNodeLst: function  (Image: THandle): LPTFlatNodeLst;
begin
  Image := LoadLibrary('TestDLL3.dll');
  @_GetImageFlatNodeLst := GetProcAddress(Image, 'GetImageFlatNodeLst');

  FlatNodeLst := _GetImageFlatNodeLst (0);
  Caption := IntToStr(FlatNodeLst.Count);
  Exit;

  NodeList := TList.Create;
  
  Image := LoadLibrary('C:\WINDOWS\system32\ntdll.dll');
  AddImageNodeToList (NodeList, Image);

  OutputDebugString (PChar(IntToStr(NodeList.count)));
  
  Image := LoadLibrary('C:\WINDOWS\system32\kernel32.dll');
  AddImageNodeToList (NodeList, Image);

  OutputDebugString (PChar(IntToStr(NodeList.count)));

  Image := LoadLibrary('C:\WINDOWS\system32\oleaut32.dll');
  AddImageNodeToList (NodeList, Image);

  OutputDebugString (PChar(IntToStr(NodeList.count)));

  Image := LoadLibrary('C:\WINDOWS\system32\msvcrt.dll');
  AddImageNodeToList (NodeList, Image);

  OutputDebugString (PChar(IntToStr(NodeList.count)));

  NodeList.Free;
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
            CodeInfo.Target := Pointer(TotalVal);
        end;     
         
        RegSL.Free;
      end;
       
    end;
end;

procedure TForm2.Button6Click(Sender: TObject);
var
  RegInfo: TRegister;
  CodeInfo: TCodeInfo;
  DisAsm: String;
begin
  DisAsm := self.Edit1.Text;
  CodeInfo.Call := True;
  CodeInfo.Target := nil;
  RegInfo.EBX := $00400000;
  RegInfo.ESI := $00001000;

  CodeInfoCheckpoint (CodeInfo, DisAsm, @RegInfo);

  Caption := IntToHex (DWORD(CodeInfo.Target), 8);
end;


function GetStackBase: Pointer;
asm
  mov eax,fs:[4]
end;

function GetStackLimit: Pointer;
asm
  mov eax,fs:[8]
end;

Procedure ThreadTester (Form: TForm2); Stdcall;
begin
  Form.Memo1.Lines.Add('GetStackLimit $' + IntToHex(DWORD(GetStackLimit), 8));
  Form.Memo1.Lines.Add('GetStackBase $' + IntToHex(DWORD(GetStackBase), 8));
end;

procedure TForm2.Button7Click(Sender: TObject);
begin
  Caption := IntToHex (12, 0);
end;

const
  def_name = '{0CF17DDE-DF40-4DC5-A5E5-CF2D041B218D}';

procedure TForm2.Button8Click(Sender: TObject);
var
  InputStr: String;
begin
  InputStr := edit1.Text;
  if nil <> CreateTheShare (def_name, PChar(InputStr), Length (InputStr)) then
    caption := 'true'
  else
    caption := 'false';
end;


procedure TForm2.Button10Click(Sender: TObject);
begin
  DestroyTheShare (def_name);
end;


procedure TForm2.Button9Click(Sender: TObject);
var
  DataSize: integer;
  Data: Pointer; 
begin
  Data := OpenTheShare (def_name, DataSize);
  if Data = nil then
    Memo1.Lines.Add('false')
  else
    memo1.Lines.Add(StrPas(Data));
end;


procedure TForm2.Button11Click(Sender: TObject);
begin
  CloseTheShare (def_name);
end;

function GetFatherDir(Dir: String): String;
begin
  SetLength(Dir, Length(Dir) - 1);
  Result := ExtractFilePath(Dir);
end;

var
  SampleDir: String = 'D:\OneTouch\Release\PlugIn\and.exe';

procedure TForm2.Button12Click(Sender: TObject);
begin
  SampleDir := GetFatherDir (SampleDir);
  Memo1.Lines.Add(SampleDir);
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
//  AppTerminated := True;
end;

end.
