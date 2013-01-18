unit MdiMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ToolWin, Menus, ActnList, StdActns, Grids, ImgList,
  TlHelp32, SpecialFolderUnit, Base64Unit;

Const     
  WM_BREAK_EVENT = WM_USER + 100;
  WM_SYSTEM_MESSAGE_HANDLER = WM_USER + 101;
  WM_RUN_TASK = WM_USER + 102;
  WM_TASK_FINISH = WM_USER + 103;

type
  TMDIMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Edit1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Break1: TMenuItem;
    N4: TMenuItem;
    Set1: TMenuItem;
    N5: TMenuItem;
    ActionList1: TActionList;
    File_OpenAimExe: TAction;
    File_CloseAimExe: TAction;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    File_CloseApp: TAction;
    N9: TMenuItem;
    OpenDialog1: TOpenDialog;
    View_MemEdit: TAction;
    View_DbgView: TAction;
    Break_List: TAction;
    View_ModuleList: TAction;
    N10: TMenuItem;
    N11: TMenuItem;
    View_DisAsm: TAction;
    N12: TMenuItem;
    N13: TMenuItem;
    File_ClearUp: TAction;
    Break_ReleaseAll: TAction;
    ReleaseAllBreaks1: TMenuItem;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ImageList1: TImageList;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    PopupMenu1: TPopupMenu;
    View_CallStruct: TAction;
    N14: TMenuItem;
    ToolButton13: TToolButton;
    N15: TMenuItem;
    Plugin1: TMenuItem;
    N19: TMenuItem;
    N17: TMenuItem;
    DbgPlugin_Open: TAction;
    N18: TMenuItem;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    PopupMenu2: TPopupMenu;
    ToolButton9: TToolButton;
    DbgPlugin_ReOpen: TAction;
    N16: TMenuItem;
    procedure PopupMenu2Popup(Sender: TObject);
    procedure ToolButton15Click(Sender: TObject);
    procedure DbgPlugin_ReOpenExecute(Sender: TObject);
    procedure DbgPlugin_OpenExecute(Sender: TObject);
    procedure N15Click(Sender: TObject);
    procedure View_CallStructExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure Break_ListExecute(Sender: TObject);
    procedure Break_ReleaseAllExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure View_MemEditExecute(Sender: TObject);
    procedure View_ModuleListExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure File_CloseAppExecute(Sender: TObject);
    procedure View_DbgViewExecute(Sender: TObject);
    procedure File_ClearUpExecute(Sender: TObject);
    procedure CheckButtonState(Sender: TObject);
    procedure File_CloseAimExeExecute(Sender: TObject);
    procedure File_OpenAimExeExecute(Sender: TObject);
  private
    procedure BreakEventHandler(var msg:TMessage);message WM_BREAK_EVENT;
    procedure SyncSystemHandler(var msg:TMessage);message WM_SYSTEM_MESSAGE_HANDLER;
    procedure SyncRunTaskHandler(var msg:TMessage);message WM_RUN_TASK ;
    procedure SyncTaskFinishHandler(var msg:TMessage);message WM_TASK_FINISH ;
  public
    FPlugPath: String;
    procedure AddRecentAim (FileName: String);
    procedure AddRecentPluginAim (FileName: String);
    function ShowMDIChild(frm : TFormClass): TForm;
    procedure ClearMDIChild();
    function IsDebugTaskContinue (): BOOL;
    function DebugAimPlugin (ConfigSL: TStringList): BOOL;
    function DebugAimExe (AimExe: string;
                          PlugBase: String;
                          PluginLib: Array of string;
                          MainPlugin: String): BOOL;
    procedure File_OnRecentItemClick(Sender: TObject);
    function FindFirstForm (frm : TFormClass): TForm;
    function FindBreakListForm (Out Fmt: TForm): BOOL;
    function FindModuleListForm (Out Fmt: TForm): BOOL;
  public
    IsRemoteMode: BOOL;      
    procedure InitCmdServer;
    procedure FinalCmdSrever;
    function Remote_Terminate (AppExit: BOOL): BOOL;
    function Remote_OpenDebugAim (AppCmdLine: String;
                           ConfigSL: TStringList;
                           AuthLib, PlugBase, Plugin: TMemoryStream;
                           PlugLibs: Array of TMemoryStream;
                           RightLevel, InjectMode, RunMode: Integer): BOOL;
    function Msg_TaskStart (Buffer: PChar; Size: Integer): BOOL;
  end;

var
  MDIMain: TMDIMain;
  hDbgAimTask: THandle;    //真正的调试目标
  MsgServerName: String;   //消息回调投递
  CmdSrvChannel: THandle;  //接受命令

implementation

uses
  BreakForm, MemExplorerForm, PlugKernelLib, TrapDbgLibUnit,
   ComObj, DbgInfoForm, ModuleFuncList, BreakingForm, ShareMapMemory, 
   MainExeIni, CallStructForm, PlugParaForm, IdentifyFunc, RcFuncUnit;

{$R *.dfm}

function AddToList (List: TList; Item: Pointer): BOOL;
begin
  Result := False;
  if Assigned (List) then
    if Assigned (Item) then
      if List.IndexOf(Item) = -1 then
        Result := List.Add (Item) >= 0;
end;

procedure TMDIMain.SyncSystemHandler(var msg:TMessage);
var
  MsgBuff: PChar;
begin
  MsgBuff := Pointer (msg.WParam);

  if StrPas(MsgBuff) = SYSTEM_APP_TERMINATED then
    File_ClearUpExecute (self);

  FreeMem(MsgBuff);
end;

procedure TMDIMain.SyncRunTaskHandler(var msg:TMessage);
var
  Buffer: Pointer;
  Size: Integer;
begin
  Buffer := Pointer(msg.WParam);
  Size := msg.LParam;
  msg.Result := Integer(self.Msg_TaskStart(Buffer, Size));
end;

procedure TMDIMain.SyncTaskFinishHandler(var msg:TMessage);
var
  Buffer: Pointer;
begin
  Buffer := Pointer(msg.WParam);
  msg.Result := Integer(Remote_Terminate(PBOOL(Buffer)^));
end;



Procedure OnMessage (Task: THandle; MsgType: Integer; MsgBuff: PChar; MsgSize: Integer); Stdcall;
var
  MsgHead: String;
  PassBuff: Pointer;
begin
  if MsgSize <= 0 then Exit;

  case MsgType of
    MESSAGE_TYPE_SYSTEM: MsgHead := 'System';
    MESSAGE_TYPE_ERROR : MsgHead := 'Error';
    MESSAGE_TYPE_DEBUG : MsgHead := 'Debug';
    MESSAGE_TYPE_LOG   : MsgHead := 'LogMsg';
    MESSAGE_TYPE_NOTICE: MsgHead := 'Notice';
    ELSE MsgHead := 'UnKnow';
  end;

  if MESSAGE_TYPE_SYSTEM = MsgType then
  begin
    PassBuff := AllocMem (MsgSize);
    CopyMemory (PassBuff, MsgBuff, MsgSize);
    PostMessage (MDIMain.Handle, WM_SYSTEM_MESSAGE_HANDLER, Integer(PassBuff), 0);;
  end;             

  DbgPrinter (MsgHead, StrPas(MsgBuff));
end;

Procedure OnProgress (Task: THandle; OpType: Integer; Caption, Hint: PChar; Progress: Integer); Stdcall;
var
  MsgBody: String;
begin
  MsgBody := Format ('OpType=%d, Caption=%s, Hint=%s, Progress=%d', [OpType, Caption, Hint, Progress]);
  DbgPrinter ('Progress', MsgBody);
end;

Procedure OnAppData (Task: THandle; DataBuff: PChar; DataSize: Integer); Stdcall;
begin

end;

Procedure OnConfig (Task: THandle; Key: PChar; Value: PChar); Stdcall;
var
  MsgBody: String;
begin
  MsgBody := Format ('Key=%s, Value=%s', [Key, Value]);
  DbgPrinter ('OnConfig', MsgBody);
end;

Procedure OnKeyData (Task: THandle; Key: PChar; Value: PChar); Stdcall;
var
  MsgBody: String;
begin
  MsgBody := Format ('Key=%s, Value=%s', [Key, Value]);
  DbgPrinter ('OnKeyData', MsgBody);
end;

function FindMdiChild (hTask: THandle; out OutForm: TBreakPointForm): BOOL;
var
  i: Integer;
  BPForm: TBreakPointForm;
begin
  Result := False;
  for i:= 0 to MDIMain.MDIChildCount-1 do
  begin
    if MDIMain.MDIChildren[i] is TBreakPointForm then
    begin
      BPForm := MDIMain.MDIChildren[i] as TBreakPointForm ;
      if BPForm.hTask = hTask then
      begin
        OutForm := BPForm;
        Result := True;
      end;
    end;
  end; 
end;


Procedure OnBreakEventMsg (Data: LPTReport); stdcall;
var
  BPForm: TBreakPointForm;
begin
  case Data.ReportType of
  REPORT_BREAK_START: begin
    OnStandbyEvent (Data.hAim, LPTBreakStart (Data).Start);
    Application.CreateForm(TBreakPointForm, BPForm); 
    BPForm.FreeOnRelease;
    BPForm.hTask := Data.hAim;
    BPForm.Start := LPTBreakStart (Data).Start;
    BPForm.Show;
  end;
  REPORT_BREAK_DATA: begin
    if FindMdiChild (Data.hAim, BPForm) then
    begin
      OnActiveEvent (Data.hAim); 
      BPForm.SetBreakDetail (Pointer(Data));
      BPForm.UpdateRegistText;
      BPForm.UpdateStackLineText;
      BPForm.UpdateDisasmText;
    end else
    begin
      Cmd_TrapDbgRelease (Data.hAim);
    end;
  end;
  REPORT_BREAK_END: begin
    if FindMdiChild (Data.hAim, BPForm) then
    begin
      OnDeActiveEvent (Data.hAim);
      BPForm.Free;
    end;             
  end;
  end;
end;


procedure TMDIMain.PopupMenu1Popup(Sender: TObject);
var
  Index: Integer;
  ToAdd: TMenuItem;
begin
  self.PopupMenu1.Items.Clear;
  for Index := 0 to N2.Count - 1 do
  begin
    ToAdd := TMenuItem.Create(self.PopupMenu1.Items);
    ToAdd.OnClick := File_OnRecentItemClick;
    ToAdd.Caption := StripHotkey(N2.Items[Index].Caption);
    self.PopupMenu1.Items.Add(ToAdd);
  end;
end;

procedure TMDIMain.PopupMenu2Popup(Sender: TObject);
var
  Index: Integer;
  ToAdd: TMenuItem;
begin
  self.PopupMenu2.Items.Clear;
  for Index := 0 to N19.Count - 1 do
  begin
    ToAdd := TMenuItem.Create(self.PopupMenu2.Items);
    ToAdd.OnClick := DbgPlugin_ReOpenExecute;
    ToAdd.Caption := StripHotkey(N19.Items[Index].Caption);
    self.PopupMenu2.Items.Add(ToAdd);
  end;
end;

procedure TMDIMain.ToolButton15Click(Sender: TObject);
begin
  if N19.Count > 0 then
    with N19.Items[0] do
    begin
      Tag := Integer(True);
      Click;
      Tag := Integer(False);
    end;
end;

procedure TMDIMain.ToolButton2Click(Sender: TObject);
begin
  if N2.Count > 0 then
    N2.Items[0].Click;
end;

procedure TMDIMain.BreakEventHandler(var msg: TMessage);
var
  Data: LPTReport;
begin
  Data := Pointer (msg.WParam);
  OnBreakEventMsg (Data);
  FreeMem(Data);
end;

procedure TMDIMain.N15Click(Sender: TObject);
begin
  ClearUpLibNodeList;
end;

Procedure OnBreakEvent (Data: LPTReport); stdcall;
var
  MsgBase: Pointer;
  MsgSize: Integer;
begin
  case Data.ReportType of
    REPORT_BREAK_START: MsgSize := SizeOf(TBreakStart);
    REPORT_BREAK_DATA: MsgSize := SizeOf(TBreakDetail);
    REPORT_BREAK_END: MsgSize := SizeOf(TBreakEnd);
    ELSE Exit;
  end;

  MsgBase := AllocMem(MsgSize);
  CopyMemory (MsgBase, Data, MsgSize);
  PostMessage (MDIMain.Handle, WM_BREAK_EVENT, Integer(MsgBase), 0);
end;

Procedure SetPluginMS (Task: THandle; MS: TMemoryStream; PlugType: Integer); overload;
begin
  if MS.Size = 0 then exit;
  TaskPlugin (Task, MS.Memory, MS.Size, PlugType);
end;

Procedure SetPluginMS (Task: THandle; FileName: String; PlugType: Integer); overload;
var
  MS: TMemoryStream;
  CmpA, CmpB, CmpC, CmpD: String;
begin
  if not FileExists (FileName) then
  begin
    CmpA := UpperCase(FileName);
    CmpB := UpperCase(MdiMain.FPlugPath + 'TrapDbgLib.dll');
    CmpC := UpperCase(MdiMain.FPlugPath + 'Empty.dll');
    CmpD := UpperCase(MdiMain.FPlugPath + 'PlugBase.dll');
    if CmpA = CmpB then
    begin
      MS := GetRCDataMMemory ('PEFILE', 'TRAPDBGLIB');
    end else
    if CmpA = CmpC then
    begin
      MS := GetRCDataMMemory ('PEFILE', 'EMPTYDLL');
    end else
    if CmpA = CmpD then
    begin
      MS := GetRCDataMMemory ('PEFILE', 'PLUGBASEDLL');
    end else
      Exit;
  end else begin
    MS := TMemoryStream.Create;
    MS.LoadFromFile(FileName);
  end;

  SetPluginMS (Task, MS, PlugType);
  MS.Free;
end;     

procedure TMDIMain.CheckButtonState(Sender: TObject);
var
  InDebuging: BOOL;
begin
  if hDbgAimTask > 0 then
    if not TaskRunning (hDbgAimTask) then
    begin       
      TaskDestroy (hDbgAimTask, False);
      hDbgAimTask := 0;
      File_ClearUpExecute (Sender);
    end;

  InDebuging := hDbgAimTask > 0;

  N1.Enabled := not InDebuging;   ToolButton1.Enabled := N1.Enabled;
  N2.Enabled := not InDebuging;   ToolButton2.Enabled := N2.Enabled;
  N18.Enabled := not InDebuging;  ToolButton14.Enabled := N18.Enabled;
  N19.Enabled := not InDebuging;  ToolButton15.Enabled := N19.Enabled;
  N6.Enabled := InDebuging;       ToolButton3.Enabled := N6.Enabled;

  /////////////////

  N12.Enabled := InDebuging;  ToolButton5.Enabled := InDebuging;
  N3.Enabled := InDebuging;   ToolButton6.Enabled := InDebuging;
  N10.Enabled := InDebuging;  ToolButton7.Enabled := InDebuging;
  N14.Enabled := InDebuging;  ToolButton13.Enabled := InDebuging;

 /////////////////
 
  N4.Enabled := InDebuging;    ToolButton10.Enabled := InDebuging;
  N13.Enabled := InDebuging;   ToolButton11.Enabled := InDebuging;
  ReleaseAllBreaks1.Enabled := InDebuging;   ToolButton12.Enabled := InDebuging;
  
end;

procedure TMDIMain.File_ClearUpExecute(Sender: TObject);
begin
  OnDbgAimReset;
  ClearUpModuleAndCache;
  ClearMDIChild;
  CheckButtonState(Sender);
  hDbgAimTask := 0;
end;

procedure TMDIMain.File_CloseAimExeExecute(Sender: TObject);
var
  MsgBoxRet: Integer;
begin
  if hDbgAimTask > 0 then
  begin
    MsgBoxRet := MessageBoxA (0, '是否终止被调试的进程？', '关闭提示', MB_YESNOCANCEL);
    if MsgBoxRet <> IDCancel then
    begin
      TaskDestroy (hDbgAimTask, IDYES = MsgBoxRet);
      hDbgAimTask := 0;
      File_ClearUpExecute (Sender);
    end;
  end;
  CheckButtonState(Sender);
end;

procedure TMDIMain.File_CloseAppExecute(Sender: TObject);
begin
  File_CloseAimExeExecute (Sender);
  Close;
end;

procedure TMDIMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  MsgBoxRet: Integer;
begin
  UpdateLibNodeList (nil);
  if hDbgAimTask > 0 then
  begin
    MsgBoxRet := MessageBoxA (0, '确定要退出程序，并终止被调试的进程？', '退出提示', MB_YESNOCANCEL);
    if MsgBoxRet = IDCancel then
    begin
      Action := caNone;
    end else
    begin
      TaskDestroy (hDbgAimTask, IDYES = MsgBoxRet);
      hDbgAimTask := 0;
      File_ClearUpExecute (Sender);
    end;
  end;
end;

procedure TMDIMain.AddRecentAim (FileName: String);
var
  ToAdd: TMenuItem;
begin
  if Not FileExists (FileName) then Exit;

  if N2.Count > 0 then
    if N2.Items[0].Caption = FileName then Exit;

  ToAdd := N2.Find(FileName);
  if Assigned (ToAdd) then
  begin
    ToAdd.MenuIndex := 0;
    Exit;
  end;

  ToAdd := TMenuItem.Create(N2);
  ToAdd.OnClick := File_OnRecentItemClick;
  ToAdd.Caption := FileName;
  N2.Insert(0, ToAdd);
end;

procedure TMDIMain.AddRecentPluginAim (FileName: String);
var
  ToAdd: TMenuItem;
begin
  if Not FileExists (FileName) then Exit;

  if N19.Count > 0 then
    if N19.Items[0].Caption = FileName then Exit;

  ToAdd := N19.Find(FileName);
  if Assigned (ToAdd) then
  begin
    ToAdd.MenuIndex := 0;
    Exit;
  end;
                    
  ToAdd := TMenuItem.Create(N19);
  ToAdd.OnClick := DbgPlugin_ReOpenExecute;
  ToAdd.Caption := FileName;
  N19.Insert(0, ToAdd);
end;

const
  RecentSection = 'Recent';
  RecentDbgPlugin = 'RecentDbgPlugin';
  SettingSection = 'Setting';
  WinPosSection = 'WinPos';

procedure TMDIMain.FormCreate(Sender: TObject);
var
  RecentSL: TStringList;
  Index: Integer;
  FileName: String;
begin
  RecentSL := ReadSectionValues (RecentSection);
  for Index := RecentSL.Count - 1 downto 0 do
  begin
    FileName := RecentSL.ValueFromIndex[Index];
    AddRecentAim (FileName);
  end;
  RecentSL.Free;

  RecentSL := ReadSectionValues (RecentDbgPlugin);
  for Index := RecentSL.Count - 1 downto 0 do
  begin
    FileName := RecentSL.ValueFromIndex[Index];
    self.AddRecentPluginAim (FileName);
  end;
  RecentSL.Free;

  N5.Checked := ReadConfBool (SettingSection, 'BreakWhenStart', False);
  N11.Checked := ReadConfBool (SettingSection, 'AllwayOnTop', False);
  FPlugPath := ReadConfig (SettingSection, 'PlugPath', '');
  if not DirectoryExists (FPlugPath) then
    FPlugPath := '';
  if FPlugPath = '' then
    FPlugPath := ExtractFilePath(GetModuleName(0)) + 'PlugIn\';

  self.Left := ReadConfValue (WinPosSection, 'Left', self.Left);
  self.Top := ReadConfValue (WinPosSection, 'Top', self.Top);
  self.Width := ReadConfValue (WinPosSection, 'Width', self.Width);
  self.Height := ReadConfValue (WinPosSection, 'Height', self.Height, True);
end;

procedure TMDIMain.FormDestroy(Sender: TObject);
var
  Index: Integer;
begin
  EraseSection (RecentSection);
  for Index := 0 to N2.Count - 1 do
  begin
    if Index = 10 then Break;
    WriteConfig (RecentSection, IntToStr(Index), StripHotkey(N2.Items[Index].Caption));
  end;        

  EraseSection (RecentDbgPlugin);
  for Index := 0 to N19.Count - 1 do
  begin
    if Index = 10 then Break;
    WriteConfig (RecentDbgPlugin, IntToStr(Index), StripHotkey(N19.Items[Index].Caption));
  end;

  if wsNormal = self.WindowState then
  begin
    WriteConfValue (WinPosSection, 'Left', self.Left);
    WriteConfValue (WinPosSection, 'Top', self.Top);
    WriteConfValue (WinPosSection, 'Width', self.Width);
    WriteConfValue (WinPosSection, 'Height', self.Height);
  end;

  WriteConfig (SettingSection, 'PlugPath', FPlugPath);
  WriteConfBool (SettingSection, 'BreakWhenStart', N5.Checked);
  WriteConfBool (SettingSection, 'AllwayOnTop', N11.Checked, True);

  FinalCmdSrever;
end;


procedure TMDIMain.FormShow(Sender: TObject);
var
  RunMode: String;
begin
  CheckButtonState(Sender);

  if ParamCount > 0 then
  begin
    RunMode := ParamStr(1);
    if RunMode = 'ProxyMode' then
    begin
      DbgPrinter ('注意：这是代理调试模式。');
      InitCmdServer;
      IsRemoteMode := True;
    end;
  end;

  DbgPrinter ('注意：当前插件路径为：%s', [FPlugPath]);
  
end;

Procedure UpdateShareLibCallStructList;
var
  AimModuleList: TStringList;
  ShareList: TList;
  hModuleSnap, ModHandle: THandle;
  me32: MODULEENTRY32;
  IterKey, IterValue, CmpValue: String;
  Index: Integer;
  OutVal: Int64;
  Tid: DWORD;
  WinDir: String;
begin
    Sleep (500);
    ClearCacheList;
    AimModuleList := GetModuleLst (True);
    ShareList := TList.Create;

    for Index := 0 to AimModuleList.Count - 1 do
    begin
      IterKey := Trim(AimModuleList.Names[Index]);
      IterValue := Trim(AimModuleList.ValueFromIndex[Index]);
      AimModuleList[Index] := IterKey + '=' + IterValue;
    end;                                 

    if AimModuleList.Count > 3 then
    begin
      //产生共同列表
      hModuleSnap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, GetCurrentProcessID);
      ZeroMemory(@me32, sizeof(MODULEENTRY32));
      me32.dwSize := sizeof(MODULEENTRY32);
      
      if Module32First (hModuleSnap, me32) then
      repeat
        IterKey := '$'+ IntToHex(me32.hModule, 8);
        Index := AimModuleList.IndexOfName(IterKey);
        if Index >= 0 then
        begin
          CmpValue := UpperCase (AimModuleList.ValueFromIndex[Index]);
          IterValue := UpperCase(me32.szExePath);
          if CmpValue = IterValue then
            if TryStrToInt64(IterKey, OutVal) then
              ShareList.Add(Pointer(OutVal));
        end;
      until not Module32Next (hModuleSnap,me32);
      CloseHandle (hModuleSnap);

      //加入系统DLL列表
      SetLength(WinDir, 256);
      SetLength(WinDir, GetWindowsDirectory (@WinDir[1], 256));
      WinDir := UpperCase (WinDir);

      for Index := 0 to AimModuleList.Count - 1 do
      begin
        CmpValue := UpperCase (AimModuleList.ValueFromIndex[Index]);
        if CompareMem (@WinDir[1], @CmpValue[1], Length(WinDir)) then
        begin
          IterKey := AimModuleList.Names[Index];
          if TryStrToInt64(IterKey, OutVal) then
            if ShareList.IndexOf (Pointer(OutVal)) = -1 then
            begin
              ModHandle := LoadLibrary (PChar(CmpValue));
              if ModHandle > 0 then
              begin
                if ModHandle = THandle(OutVal) then
                  ShareList.Add(Pointer(OutVal))
                else
                  FreeLibrary (ModHandle);
              end;
            end;
        end;
      end;
    end;                 

    CloseHandle (CreateThread (nil, 0, @UpdateLibNodeList, ShareList, 0, tid));

    AimModuleList.Free;
end;

function TMDIMain.IsDebugTaskContinue (): BOOL;
var
  MsgBoxRet: Integer;
begin
  Result := False;
  if hDbgAimTask > 0 then
  begin
    Result := True;
    MsgBoxRet := MessageBoxA (0, '是否终止当前调试的进程？', '打开目标提示', MB_YESNO);
    if IDYES = MsgBoxRet then
    begin
      TaskDestroy (hDbgAimTask, True);
      hDbgAimTask := 0;
      File_ClearUpExecute (self);
      Result := False;
    end;
  end;
end;

function GetSplitBlankList (InputStr: String; Separate: TSysCharSet = [' ']): TStringList;
begin
  Result := TStringList.Create;
  if Trim(InputStr) = '' then Exit;
  ExtractStrings (Separate,[' '],PChar(InputStr),Result);
end;

function TranslateRightLevel (DropMyRights: String): Integer;
begin                  
  DropMyRights := Trim(DropMyRights);
  if DropMyRights = 'SAFER_LEVELID_FULLYTRUSTED' then Result := $40000 else
  if DropMyRights = 'SAFER_LEVELID_NORMALUSER' then Result := $20000 else
  if DropMyRights = 'SAFER_LEVELID_CONSTRAINED' then Result := $10000 else
  Result := $40000;
end;

function TranslateInjectMode (InjectMode: String): Integer;
begin
  InjectMode := Trim(InjectMode);
  if InjectMode = 'INJECT_MODE_REMOTE_THREAD' then Result := $0 else
  if InjectMode = 'INJECT_MODE_DRIVER' then Result := $1 else
  Result := $1;
end;

Type
  LPTReportMsg = ^TReportMsg;
  TReportMsg = packed record
    Size: Integer;
    nType: Integer;
  end;

  LPTOnMessageReport = ^TOnMessageReport;
  TOnMessageReport = packed record
    Reporter: TReportMsg;
    MsgType: Integer;
    MsgSize: Integer;
    MsgBuff: Array[0..0] of char;
  end;

Type
  LPTOnProgressReport = ^TOnProgressReport;
  TOnProgressReport = packed record
    Reporter: TReportMsg;
    OpType: Integer;
    Progress: Integer;
    CaptionOffset, HintOffset: Integer;
    Buffer: Array[0..0] of char;
  end;

Type
  LPTOnAppDataReport = ^TOnAppDataReport;
  TOnAppDataReport = packed record
    Reporter: TReportMsg;
    DataSize: Integer;
    DataBuff: Array[0..0] of char;
  end;

Type
  LPTOnKeyValueReport = ^TOnKeyValueReport;
  TOnKeyValueReport = packed record
    Reporter: TReportMsg;
    KeyOffset: Integer;
    ValueOffset: Integer;
    DataBuff: Array[0..0] of char;
  end;
  
function SendReporter (Report: Pointer): BOOL;
begin
  Result := SendMsgToServer (PChar(MsgServerName), Report, LPTReportMsg(Report).Size);
end;

Procedure Remote_OnMessage (Task: THandle; MsgType: Integer; MsgBuff: PChar; MsgSize: Integer); Stdcall;
var
  Report: LPTOnMessageReport;
  ReportSize: Integer;
begin
  OnMessage (Task, MsgType, MsgBuff, MsgSize);

  ReportSize := SizeOf(TOnMessageReport) + MsgSize;
  Report := AllocMem (ReportSize);
  Report.Reporter.Size := ReportSize;
  Report.Reporter.nType := 1;
  Report.MsgType := MsgType;
  Report.MsgSize := MsgSize;
  CopyMemory (@Report.MsgBuff[0], MsgBuff, MsgSize);
  SendReporter(Report);
  FreeMem (Report);
end;


Procedure Remote_OnProgress (Task: THandle; OpType: Integer; Caption, Hint: PChar; Progress: Integer); Stdcall;
var
  Report: LPTOnProgressReport;
  ReportSize: Integer;
begin
  OnProgress (Task, OpType, Caption, Hint, Progress);

  ReportSize := SizeOf(TOnProgressReport) + StrLen(Caption) + 1 + StrLen(Hint) + 1;
  Report := AllocMem (ReportSize);
  Report.Reporter.Size := ReportSize;
  Report.Reporter.nType := 2;
  Report.OpType := OpType;
  Report.Progress := Progress;
  Report.CaptionOffset := 0;
  Report.HintOffset := StrLen(Caption) + 1;
  StrCopy(@Report.Buffer[Report.CaptionOffset], Caption);
  StrCopy(@Report.Buffer[Report.HintOffset], Hint);
  
  SendReporter(Report);
  FreeMem (Report);
end;


Procedure Remote_OnAppData (Task: THandle; DataBuff: PChar; DataSize: Integer); Stdcall;
var
  Report: LPTOnAppDataReport;
  ReportSize: Integer;
begin
  OnAppData (Task, DataBuff, DataSize);

  ReportSize := SizeOf(TOnAppDataReport) + DataSize;
  Report := AllocMem (ReportSize);
  Report.Reporter.Size := ReportSize;
  Report.Reporter.nType := 3;
  Report.DataSize := DataSize;
  CopyMemory (@Report.DataBuff[0], DataBuff, DataSize);

  SendReporter(Report);
  FreeMem (Report);  
end;

function SendKeyValueReport (nType: Integer; Key: PChar; Value: PChar): BOOL;
var
  Report: LPTOnKeyValueReport;
  ReportSize: Integer;
begin
  ReportSize := SizeOf(TOnKeyValueReport) + StrLen(Key) + 1 + StrLen(Value) + 1;
  Report := AllocMem (ReportSize);
  Report.Reporter.Size := ReportSize;
  Report.Reporter.nType := nType;
  Report.KeyOffset := 0;
  Report.ValueOffset := StrLen(Key) + 1;
  StrCopy(@Report.DataBuff[Report.KeyOffset], Key);
  StrCopy(@Report.DataBuff[Report.ValueOffset], Value);
  
  Result := SendReporter(Report);
  FreeMem (Report);
end;

Procedure Remote_OnConfig (Task: THandle; Key: PChar; Value: PChar); Stdcall;
begin
  OnConfig (Task, Key, Value);
  SendKeyValueReport (4, Key, Value);
end;


Procedure Remote_OnKeyData (Task: THandle; Key: PChar; Value: PChar); Stdcall;
begin
  OnKeyData (Task, Key, Value);
  SendKeyValueReport (5, Key, Value);
end;


procedure ReplyBool (hClient: THandle; Reply: BOOL);
begin
  EchoIpcCommand (hClient, @Reply, SizeOf(BOOL));
end;

procedure CloseFixedName (Name: String);
var
  NameSL: TStringList;
  Item: String;
begin
  if Name = '' then exit;
  NameSL := GetSplitBlankList (Name, [',']);
  for Item in NameSL do
    CloseTheShare (Item);
end;

function TMDIMain.Msg_TaskStart (Buffer: PChar; Size: Integer): BOOL;
var
  InputSLText: String;
  ConfigSL, SendSL: TStringList;
  AppCmdLine, MapName: String;
  RightLevel,InjectMode,RunMode, Count: Integer;
  AuthLib,PlugBase,Plugin: TMemoryStream;
  PlugLibs: Array of TMemoryStream;
  Names: TStringList;
begin
  SetLength(InputSLText, Size);
  CopyMemory (@InputSLText[1], Buffer, Size);

  SendSL := TStringList.Create;
  ConfigSL := TStringList.Create;

  SendSL.Text := InputSLText;
  ConfigSL.Text := DecodeBase64(SendSL.Values['ConfigSL']) ;

  MsgServerName := SendSL.Values['MsgServerName'];
  AppCmdLine := SendSL.Values['AppCmdLine'] ;
  RightLevel := StrToInt (SendSL.Values['RightLevel']);
  InjectMode := StrToInt (SendSL.Values['InjectMode']);
  RunMode := StrToInt (SendSL.Values['RunMode']);

  AuthLib := OpenTheShare (SendSL.Values['AuthLib']);
  PlugBase := OpenTheShare (SendSL.Values['PlugBase']);
  Plugin := OpenTheShare (SendSL.Values['Plugin']);

  MapName := SendSL.Values['PlugLibs'];
  Names := GetSplitBlankList (MapName, [',']);
  if Names.Count > 0 then
    for MapName in Names do
    begin
      Count := Length(PlugLibs);
      SetLength (PlugLibs, Count + 1);
      PlugLibs[Count] := OpenTheShare (MapName);
    end;

  //创建被调试进程
  Result := Remote_OpenDebugAim (AppCmdLine, ConfigSL,
                    AuthLib, PlugBase, Plugin, PlugLibs,
                    RightLevel,InjectMode,RunMode);

  self.CheckButtonState(nil);

  CloseFixedName (SendSL.Values['AuthLib']);
  CloseFixedName (SendSL.Values['PlugBase']);
  CloseFixedName (SendSL.Values['Plugin']);
  CloseFixedName (SendSL.Values['PlugLibs']);
  
  SendSL.Free;
  ConfigSL.Free;          
end;

procedure Srv_TaskStart (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
var
  RunResult: Integer;
begin
  RunResult := SendMessage (MDIMain.Handle, WM_RUN_TASK, Integer(Buffer), Integer(Size));
  ReplyBool (hClient, RunResult <> 0);
end;

procedure Srv_TaskFinish (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
var
  RunResult: Integer;
begin
  RunResult := SendMessage (MDIMain.Handle, WM_TASK_FINISH, Integer(Buffer), Integer(Size));
  PostMessage (MdiMain.Handle, WM_CLOSE, 0, 0);
  ReplyBool (hClient, RunResult <> 0);
end;

procedure Srv_TaskAppData (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin
  ReplyBool (hClient, TaskAppData (hDbgAimTask, Buffer, Size));
end;

procedure Srv_TaskRunning (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin
  ReplyBool (hClient, TaskRunning (hDbgAimTask));
end;                        

procedure Srv_IsWorking (hServer, hClient: THandle; Buffer: PChar; Size: Integer); Stdcall;
begin
  ReplyBool (hClient, True);
end;



procedure TMDIMain.InitCmdServer;
var
  MeServerName: String;
begin
  MeServerName := GetTargetChannelName;
  CmdSrvChannel := CreateIpcServer (PChar(MeServerName));
  if CmdSrvChannel = 0 then
  begin
    DbgPrinter('创建命令管道失败！');
    Exit;
  end;

  AddIpcCommand (CmdSrvChannel, 'TaskStart', @Srv_TaskStart);
  AddIpcCommand (CmdSrvChannel, 'TaskFinish', @Srv_TaskFinish);
  AddIpcCommand (CmdSrvChannel, 'TaskRunning', @Srv_TaskRunning);
  AddIpcCommand (CmdSrvChannel, 'TaskAppData', @Srv_TaskAppData);
  AddIpcCommand (CmdSrvChannel, 'IsWorking', @Srv_IsWorking);
end;

procedure TMDIMain.FinalCmdSrever;
begin
  if CmdSrvChannel > 0 then
  begin
    DestroyIpcServer (CmdSrvChannel);
    CmdSrvChannel := 0;
  end;
end;


function TMDIMain.Remote_OpenDebugAim (AppCmdLine: String;
                           ConfigSL: TStringList;
                           AuthLib, PlugBase, Plugin: TMemoryStream;
                           PlugLibs: Array of TMemoryStream;
                           RightLevel, InjectMode, RunMode: Integer): BOOL;
var
  DbgEvtName, IpcCmdServer: String;
  Index: Integer;
  KeyStr, ValStr: String;
  TaskRunRet: Integer;
  IterMM: TMemoryStream;
begin
  Result := false;
  if hDbgAimTask > 0 then
    Remote_Terminate (True);

  DbgEvtName := CreateClassID;
  IpcCmdServer := CreateClassID;

  hDbgAimTask := TaskCreate (@Remote_OnMessage, @Remote_OnProgress, @Remote_OnAppData, @Remote_OnConfig, @Remote_OnKeyData);
  if hDbgAimTask > 0 then
  begin
    //设置通讯管道
    TaskConfig (hDbgAimTask, 'DbgIpcServer', PChar(IpcCmdServer));
    TaskConfig (hDbgAimTask, 'DbgEvent', PChar(DbgEvtName));

    //设置插件运行参数
    for Index := 0 to ConfigSL.Count - 1 do
    begin
      KeyStr := ConfigSL.Names[Index];
      ValStr := ConfigSL.ValueFromIndex[Index];
      TaskConfig (hDbgAimTask, PChar(KeyStr), PChar(ValStr));
    end;                          

    //设置各插件
    SetPluginMS (hDbgAimTask, AuthLib, PLUGIN_TYPE_AUTHLIB);
    SetPluginMS (hDbgAimTask, PlugBase, PLUGIN_TYPE_PLUGBASE);
    for IterMM in PlugLibs do
      SetPluginMS (hDbgAimTask, IterMM, PLUGIN_TYPE_PLUGLIB);
    SetPluginMS (hDbgAimTask, FPlugPath + 'TrapDbgLib.dll', PLUGIN_TYPE_PLUGLIB);
    SetPluginMS (hDbgAimTask, Plugin, PLUGIN_TYPE_PLUGIN);

    //运行任务
    TaskRunRet := TaskRun (hDbgAimTask, PChar(AppCmdLine), RightLevel, InjectMode, RunMode);
    if TaskRunRet < 0 then
    begin
      DbgPrinter('TaskRun ERROR : %d',[TaskRunRet]);
      ShowMessage('运行目标程序失败，请检查权限相关windows选项');
      TaskDestroy (hDbgAimTask, True);
      hDbgAimTask := 0;
      File_ClearUpExecute (self);
      Exit;
    end;

    //和调试插件通讯的专用管道
    if not ResetTrapDbgClient (PChar(DbgEvtName), PChar(IpcCmdServer), 18000, @OnBreakEvent) then
    begin
      ShowMessage('初始化通讯管道失败');
      TaskDestroy (hDbgAimTask, True);
      hDbgAimTask := 0;
      File_ClearUpExecute (self);
      Exit;
    end;

    Result := true;
  end;

  if Result then
    UpdateShareLibCallStructList;  

  IsRemoteMode := True;
end;

function TMDIMain.Remote_Terminate (AppExit: BOOL): BOOL;
begin
  if hDbgAimTask > 0 then
  begin
    TaskDestroy (hDbgAimTask, AppExit);
    hDbgAimTask := 0;
    File_ClearUpExecute (self);
  end;
  CheckButtonState(self);

  Result := hDbgAimTask = 0;
  IsRemoteMode := False;
end;

function TMDIMain.DebugAimPlugin (ConfigSL: TStringList): BOOL;
var
  DbgEvtName, IpcCmdServer: String;
  LibName: String;
  AimExe: string;
  PlugBase: String;
  PluginLib: TStringList;
  DbgAim, MainPlugin, PlugLibStr: String;
  Index: Integer;
  KeyStr, ValStr: String;
  RightLevel, InjectMode: Integer;
  TaskRunRet: Integer;
begin
  DbgAim := '';
  Result := False;
  if IsDebugTaskContinue then exit;
  
  DbgEvtName := CreateClassID;
  IpcCmdServer := CreateClassID;

  hDbgAimTask := TaskCreate (@OnMessage, @OnProgress, @OnAppData, @OnConfig, @OnKeyData);
  if hDbgAimTask > 0 then
  begin
    //设置通讯管道
    TaskConfig (hDbgAimTask, 'DbgIpcServer', PChar(IpcCmdServer));
    TaskConfig (hDbgAimTask, 'DbgEvent', PChar(DbgEvtName));

    //设置插件运行参数
    for Index := 0 to ConfigSL.Count - 1 do
    begin
      KeyStr := ConfigSL.Names[Index];
      ValStr := ConfigSL.ValueFromIndex[Index];
      TaskConfig (hDbgAimTask, PChar(KeyStr), PChar(ValStr));
    end;                          

    //准备各插件的路径
    AimExe := ConfigSL.Values[Def_AppPath];    
    DbgAim := ConfigSL.Values[Def_DbgAim];
    MainPlugin := ConfigSL.Values[INI_KEY_PLUGIN];
    
    PlugBase := FPlugPath + ConfigSL.Values[INI_KEY_PLUGBASE];
    PlugLibStr := ConfigSL.Values[INI_KEY_PLUGLIBS];
    PluginLib := GetSplitBlankList (PlugLibStr, [',']);
    PluginLib.Add('TrapDbgLib.dll');
    for Index := 0 to PluginLib.Count - 1 do
      PluginLib[Index] := FPlugPath + PluginLib[Index];

    //设置各插件
    SetPluginMS (hDbgAimTask, PChar(PlugBase), PLUGIN_TYPE_PLUGBASE);
    for LibName in PluginLib do
      SetPluginMS (hDbgAimTask, PChar(LibName), PLUGIN_TYPE_PLUGLIB);
    SetPluginMS (hDbgAimTask, PChar(MainPlugin), PLUGIN_TYPE_PLUGIN);
    PluginLib.Free;

    //准备运行参数
    RightLevel := TranslateRightLevel (ConfigSL.Values['DropMyRights']);
    InjectMode := TranslateInjectMode (ConfigSL.Values['InjectMode']);

    //运行任务
    TaskRunRet := TaskRun (hDbgAimTask, PChar(AimExe), RightLevel, InjectMode, RUN_MODE_DEBUG);
    if TaskRunRet < 0 then
    begin
      DbgPrinter('TaskRun ERROR : %d',[TaskRunRet]);
      ShowMessage('运行目标程序失败，请检查权限相关windows选项');
      TaskDestroy (hDbgAimTask, True);
      hDbgAimTask := 0;
      File_ClearUpExecute (self);
      Exit;
    end;

    //和调试插件通讯的专用管道
    if not ResetTrapDbgClient (PChar(DbgEvtName), PChar(IpcCmdServer), 18000, @OnBreakEvent) then
    begin
      ShowMessage('初始化通讯管道失败');
      TaskDestroy (hDbgAimTask, True);
      hDbgAimTask := 0;
      File_ClearUpExecute (self);
      Exit;
    end;

    self.AddRecentPluginAim(DbgAim);
    Result := true;
  end;

  if Result then
    UpdateShareLibCallStructList;
end;
 

function TMDIMain.DebugAimExe (AimExe: string;
                      PlugBase: String;
                      PluginLib: Array of string;
                      MainPlugin: String): BOOL;
var
  DbgEvtName, IpcCmdServer: String;
  LibName: String;
  TaskRunRet: Integer;
begin
  Result := False;
  if IsDebugTaskContinue then exit;

  DbgEvtName := CreateClassID;
  IpcCmdServer := CreateClassID;

  hDbgAimTask := TaskCreate (@OnMessage, @OnProgress, @OnAppData, @OnConfig, @OnKeyData);
  if hDbgAimTask > 0 then
  begin
    TaskConfig (hDbgAimTask, 'DbgIpcServer', PChar(IpcCmdServer));
    TaskConfig (hDbgAimTask, 'DbgEvent', PChar(DbgEvtName));
    SetPluginMS (hDbgAimTask, PChar(PlugBase), PLUGIN_TYPE_PLUGBASE);
    for LibName in PluginLib do
      SetPluginMS (hDbgAimTask, PChar(LibName), PLUGIN_TYPE_PLUGLIB);

    SetPluginMS (hDbgAimTask, PChar(MainPlugin), PLUGIN_TYPE_PLUGIN);

    TaskRunRet := TaskRun (hDbgAimTask, PChar(AimExe), SAFER_LEVELID_FULLYTRUSTED, INJECT_MODE_DRIVER, RUN_MODE_DEBUG);
    if TaskRunRet < 0 then
    begin
      DbgPrinter ('TaskRun ERROR : %d',[TaskRunRet]);
      ShowMessage('运行目标程序失败，请检查权限相关windows选项');
      TaskDestroy (hDbgAimTask, True);
      hDbgAimTask := 0;
      File_ClearUpExecute (self);
      Exit;
    end;

    if not ResetTrapDbgClient (PChar(DbgEvtName), PChar(IpcCmdServer), 18000, @OnBreakEvent) then
    begin
      ShowMessage('初始化通讯管道失败');
      TaskDestroy (hDbgAimTask, True);
      hDbgAimTask := 0;
      File_ClearUpExecute (self);
      Exit;
    end;

    AddRecentAim(AimExe);
    Result := true;
  end;

  if Result then
    UpdateShareLibCallStructList;
end;


procedure TMDIMain.DbgPlugin_OpenExecute(Sender: TObject);
var
  CfgSL: TStringList;  
  PluginDbging: String;
begin
  self.OpenDialog1.Filter := '插件DLL|*.dll';
  if not self.OpenDialog1.Execute then exit;
  PluginDbging := self.OpenDialog1.FileName;

  CfgSL := TStringList.Create;

  With TSetParamForm.Create(Self) do
  Try
    //初始化参数窗口，这是必须的第一步
    if InitPlugin (PluginDbging) then
      if mrOK = ShowModal then
      begin
        //从用户输入中获取input参数
        ReadInputs (CfgSL);
        //从插件ini文件获取系统运行参数
        ReadSystems (CfgSL);
      end;
  finally
    Free;
  end;

  if CfgSL.Count > 0 then
  begin
    //加入PlugPath路径
    CfgSL.Values['PlugPath'] := FPlugPath;
    DebugAimPlugin (CfgSL);
    self.CheckButtonState(Sender);
  end;

  CfgSL.Free;
end;


procedure TMDIMain.DbgPlugin_ReOpenExecute(Sender: TObject);
var
  CfgSL: TStringList; 
  PluginDbging: String;
  SrcMenu: TMenuItem absolute Sender;
  IsFastRun: BOOL;
begin
  PluginDbging :=  StripHotkey(SrcMenu.Caption);
  IsFastRun := BOOL(SrcMenu.Tag);

  CfgSL := TStringList.Create;

  With TSetParamForm.Create(Self) do
  Try
    //初始化参数窗口，这是必须的第一步
    if InitPlugin (PluginDbging) then
    begin
      if IsFastRun then
      begin
        Button2Click (nil);
        ReadInputs (CfgSL);
        ReadSystems (CfgSL);
      end else
      begin
        if mrOK = ShowModal then
        begin
          ReadInputs (CfgSL); //从用户输入中获取input参数
          ReadSystems (CfgSL); //从插件ini文件获取系统运行参数
        end;
      end;
    end;
  finally
    Free;
  end;

  if CfgSL.Count > 0 then
  begin
    //加入PlugPath路径
    CfgSL.Values['PlugPath'] := FPlugPath;
    DebugAimPlugin (CfgSL);
    self.CheckButtonState(Sender);
  end;

  CfgSL.Free;
end;

procedure TMDIMain.File_OpenAimExeExecute(Sender: TObject);
var
  PlugBase: String;
  AppDbging: String;
  DbgPlugin: String;
  MainPlugin: String;
begin
  self.OpenDialog1.Filter := '可执行程序|*.exe';
  if not self.OpenDialog1.Execute then exit;

  AppDbging := self.OpenDialog1.FileName;
  PlugBase := FPlugPath + 'PlugBase.dll';
  DbgPlugin := FPlugPath + 'TrapDbgLib.dll';
  MainPlugin := FPlugPath + 'Empty.dll';

  DebugAimExe (AppDbging, PlugBase, [DbgPlugin], MainPlugin);

  self.CheckButtonState(Sender);
end;

procedure TMDIMain.File_OnRecentItemClick(Sender: TObject);
var
  PlugBase: String;
  AppDbging: String;
  DbgPlugin: String;
  MainPlugin: String;
begin
  AppDbging :=  StripHotkey(TMenuItem(Sender).Caption);
  PlugBase := FPlugPath + 'PlugBase.dll';
  DbgPlugin := FPlugPath + 'TrapDbgLib.dll';
  MainPlugin := FPlugPath + 'Empty.dll';

  DebugAimExe (AppDbging, PlugBase, [DbgPlugin], MainPlugin);
  CheckButtonState(Sender);
end;



procedure TMDIMain.View_CallStructExecute(Sender: TObject);
begin
  if not IsOnService then
  begin
    ShowMessage ('正在准备系统DLL分析结果，请稍候！');
    Exit;
  end;
  
  ShowMDIChild (TCallStructureForm);
end;

procedure TMDIMain.View_DbgViewExecute(Sender: TObject);
begin
  DbgPrint.WindowState := wsMaximized;
  DbgPrint.Show;
end;

procedure TMDIMain.View_MemEditExecute(Sender: TObject);
begin
  ShowMDIChild (TMemExplorer);
end;

procedure TMDIMain.View_ModuleListExecute(Sender: TObject);
begin
  ShowMDIChild (TApiListForm);
end;

function TMDIMain.FindFirstForm (frm : TFormClass): TForm;
var
  i:integer;
begin
  Result := NIL;
  for i:= 0 to Self.MDIChildCount-1 do
  begin
    if Self.MDIChildren[i] is frm then
    begin
      Result := Self.MDIChildren[i] as frm ;
      Break;
    end;
  end;    
end;

function TMDIMain.FindBreakListForm (Out Fmt: TForm): BOOL;
begin
  Fmt := FindFirstForm (TBreakPointLstForm);
  Result := Assigned (Fmt);
end;

function TMDIMain.FindModuleListForm (Out Fmt: TForm): BOOL;
begin
  Fmt := FindFirstForm (TApiListForm);
  Result := Assigned (Fmt);
end;


function TMDIMain.ShowMDIChild(frm : TFormClass): TForm;
begin
  Result := FindFirstForm (frm);

  if Assigned (Result) then
  begin
    Result.Perform(wm_SysCommand, SC_RESTORE, 0);
    Result.Show;
  end else
  begin
    Result := frm.Create(Application);
    Result.FreeOnRelease;
  end;
end;

procedure TMDIMain.Break_ListExecute(Sender: TObject);
begin
  if not IsOnService then
  begin
    ShowMessage ('正在准备系统DLL分析结果，请稍候！');
    Exit;
  end;

  ShowMDIChild (TBreakPointLstForm);
end;

procedure TMDIMain.Break_ReleaseAllExecute(Sender: TObject);
begin
  Cmd_ReleaseAllBreak;
end;

Procedure TMDIMain.ClearMDIChild();
var
  i:integer;
begin
  for i:= Self.MDIChildCount-1 downto 0 do
  begin
    if not (Self.MDIChildren[i] is TDbgPrint) then
    begin
      Self.MDIChildren[i].Release;
    end;
  end;
end;

end.
