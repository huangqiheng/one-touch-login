unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Grids, ValEdit, ComCtrls, ToolWin, Menus,
  CheckLst,  Dialogs, CategoryButtons, ImgList, ActnList;
                        
type
  TBtnActionType = (atNone, atView, atRun);
  
const
  RunCaption = '运行';
  RunWidth = 40;
  RunBevel = 1;
  
Const     
  WM_DBG_MSG = WM_USER + 100;


type
  TMainManage = class(TForm)
    PopupMenu1: TPopupMenu;
    N13: TMenuItem;
    N14: TMenuItem;
    ConfigReflash: TMenuItem;
    SaveDialog1: TSaveDialog;
    N20: TMenuItem;
    N21: TMenuItem;
    N25: TMenuItem;
    N26: TMenuItem;
    N37: TMenuItem;
    N49: TMenuItem;
    CategoryButtons1: TCategoryButtons;
    ToolBar1: TToolBar;
    ToolButton3: TToolButton;
    Bevel1: TBevel;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton4: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton5: TToolButton;
    N1: TMenuItem;
    Memo1: TMemo;
    procedure PopupMenu1Popup(Sender: TObject);
    procedure ToolButton6Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N37Click(Sender: TObject);
    procedure N14Click(Sender: TObject);
    procedure N26Click(Sender: TObject);
    procedure N25Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure N21Click(Sender: TObject);
    procedure N20Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CategoryButtons1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CategoryButtons1AfterDrawButton(Sender: TObject; const Button: TButtonItem; Canvas: TCanvas; Rect: TRect; State: TButtonDrawState);
    procedure CategoryButtons1Click(Sender: TObject);
    procedure N49Click(Sender: TObject);
    procedure ConfigReflashClick(Sender: TObject);
    procedure N13Click(Sender: TObject);
  private
    procedure RecvDbgMessage(var msg:TMessage);message WM_DBG_MSG;
  protected
    ItemActionType: TBtnActionType;
    AimIndexA, AimIndexB: Integer;
    PluginDir: String;
    function GetActionType(MouseUpX, MouseUpY: Integer): TBtnActionType;
  public
    function  StartTheTask (PlugFile: String; ConfigSL: TStringList; RunMode: Integer): BOOL;
  end;

var
  MainManage: TMainManage;

implementation

uses AddFormUnit, PassWord, math, PerpertyForm, RcFuncUnit,
     PlugKernelLib, TrapDbgLib, HandlerUnit, SpecialFolderUnit;

{$R *.dfm}


procedure TMainManage.RecvDbgMessage(var msg:TMessage);
var
  PostBuff: PChar;
begin
  PostBuff := Pointer (msg.WParam);
  self.Memo1.Lines.Add(StrPas(PostBuff));
  FreeMem(PostBuff);
end;

Procedure DbgPrinter (Head, Msg: String);
var
  PostBuff: PChar;
begin
  if Application.Terminated then exit;

  Head := '[' + Head + ']';
  Msg := format ('%-10s %-10s %s', [TimeToStr(now), Head, Msg]);

  GetMem (PostBuff, Length(Msg) + 1);
  CopyMemory (PostBuff, PChar(Msg), Length(Msg));
  PostBuff [Length(Msg)] := #0;

  PostMessage (MainManage.Handle, WM_DBG_MSG, Integer(PostBuff), 0);
end;


function TranslateRightLevel (DropMyRights: String): Integer;
begin
  DropMyRights := Trim(DropMyRights);
  if DropMyRights = 'SAFER_LEVELID_FULLYTRUSTED' then Result := SAFER_LEVELID_FULLYTRUSTED else
  if DropMyRights = 'SAFER_LEVELID_NORMALUSER' then Result := SAFER_LEVELID_NORMALUSER else
  if DropMyRights = 'SAFER_LEVELID_CONSTRAINED' then Result := SAFER_LEVELID_CONSTRAINED else
  Result := SAFER_LEVELID_FULLYTRUSTED;
end;

function TranslateInjectMode (InjectMode: String): Integer;
begin
  InjectMode := Trim(InjectMode);
  if InjectMode = 'INJECT_MODE_REMOTE_THREAD' then Result := INJECT_MODE_REMOTE_THREAD else
  if InjectMode = 'INJECT_MODE_DRIVER' then Result := INJECT_MODE_DRIVER else
  Result := INJECT_MODE_DRIVER;
end;

Procedure SLMoveToFirst (SL: TStrings; Name: String);
var
  Index: Integer;
begin
  Index := SL.IndexOfName(Name);
  if Index > 0 then
    SL.Move(Index, 0);
end;

Procedure OnMessage (Task: THandle; MsgType: Integer; MsgBuff: PChar; MsgSize: Integer); Stdcall;
var
  MsgHead: String;
begin
  if MsgSize <= 0 then Exit;

  case MsgType of
    MESSAGE_TYPE_SYSTEM: MsgHead := 'System';
    MESSAGE_TYPE_ERROR : MsgHead := 'Error';
    MESSAGE_TYPE_DEBUG : MsgHead := 'Debug';
    MESSAGE_TYPE_LOG   : MsgHead := 'LogMsg';
    MESSAGE_TYPE_NOTICE: MsgHead := 'Notice';
    ELSE Exit;
  end;

  DbgPrinter (MsgHead, StrPas(MsgBuff));
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

function LoadExactlyLibrary(PlugDir, PlugFile, DllName: String): TMemoryStream;
var
  ToLoad, PlugFileDir: String;
begin
  Result := TMemoryStream.Create;
  PlugFileDir := ExtractFilePath(PlugFile);
  ToLoad := GetExactlyDir (PlugDir, PlugFileDir, DllName);
  if ToLoad = '' then
  begin
    DbgPrinter ('RunTask', 'Not Found：' + DllName);
    Exit;
  end else
    DbgPrinter ('RunTask', 'Load：' + ToLoad);
  Result.LoadFromFile(ToLoad);
end;

function TMainManage.StartTheTask (PlugFile: String; ConfigSL: TStringList; RunMode: Integer): BOOL;
var
  FTaskCreate: Function (OnMessage,OnProgress,OnAppData,OnConfig,OnKeyData: Pointer): THandle; Stdcall;
  FTaskDestroy: Function (Task: THandle; AppExit: BOOL): BOOL; Stdcall;
  FTaskConfig: Function (Task: THandle; Key: PChar; Value: PChar): BOOL; Stdcall;
  FTaskPlugin: Function (Task: THandle; FileBuff: Pointer; FileSize: Integer; PlugType: Integer): BOOL; Stdcall;
  FTaskRun: Function (Task: THandle; AppCmdLine: PChar; RightLevel, InjectMode, RunMode: Integer): Integer; Stdcall;
  TaskHandle: THandle;
  Index: Integer;
  KeyStr, ValStr, LibName: String;
  AppCmdLine: String;
  RightLevel, InjectMode: Integer;
  LoadMS: TMemoryStream;
  Names: TStringList;
  RunRet: Integer;
  IsPlugBaseSucceed: BOOL;
begin
  Result := False;
  RightLevel := SAFER_LEVELID_FULLYTRUSTED;
  InjectMode := INJECT_MODE_DRIVER;

  case RunMode of
  RUN_MODE_DEBUG: begin
    if not IsDbgOK then Exit;
    FTaskCreate := @DBTaskCreate;
    FTaskDestroy := @DBTaskDestroy;
    FTaskConfig := @DBTaskConfig;
    FTaskPlugin := @DBTaskPlugin;
    FTaskRun := @DBTaskRun;
  end;
  RUN_MODE_NORMAL, RUN_MODE_AUTOCONFIG: begin
    FTaskCreate := @TaskCreate;
    FTaskDestroy := @TaskDestroy;
    FTaskConfig := @TaskConfig;
    FTaskPlugin := @TaskPlugin;
    FTaskRun := @TaskRun;
  end;
  ELSE Exit;
  end;

  TaskHandle := FTaskCreate (@OnMessage,@OnProgress,@OnAppData,@OnConfig,@OnKeyData);
  if TaskHandle = 0 then Exit;

  SLMoveToFirst (ConfigSL, INI_KEY_PRIVACYFIELDS);
  ConfigSL.Values[INI_KEY_PLUGIN] := ExtractFileName(PlugFile);
                                        
  IsPlugBaseSucceed := False;
  for Index := 0 to ConfigSL.Count - 1 do
  begin
    KeyStr := ConfigSL.Names[Index];
    ValStr := ConfigSL.ValueFromIndex[Index];

    if KeyStr = INI_KEY_NAME then
    begin
      DbgPrinter ('RunTask', ConfigSL[Index]);
    end else
    if KeyStr = INI_KEY_APPCMDLINE then
    begin
      AppCmdLine := ValStr;
      DbgPrinter ('RunTask', ConfigSL[Index]);
    end else
    if KeyStr = INI_KEY_PLUGBASE then
    begin
      LoadMS := LoadExactlyLibrary (PluginDir, PlugFile, ValStr);
      if FTaskPlugin (TaskHandle, LoadMS.Memory, LoadMS.Size, PLUGIN_TYPE_PLUGBASE) then
        IsPlugBaseSucceed := True;
      LoadMS.Free;
    end else
    if KeyStr = INI_KEY_PLUGLIBS then
    begin
      Names := GetSplitBlankList (ValStr, [',']);
      for LibName in Names do
      begin
        LoadMS := LoadExactlyLibrary (PluginDir, PlugFile, LibName);
        FTaskPlugin (TaskHandle, LoadMS.Memory, LoadMS.Size, PLUGIN_TYPE_PLUGLIB);
        LoadMS.Free;
      end;      
      Names.Free;
    end else
    if KeyStr = INI_KEY_PLUGIN then
    begin
      LoadMS := LoadExactlyLibrary (PluginDir, PlugFile, ValStr);
      FTaskPlugin (TaskHandle, LoadMS.Memory, LoadMS.Size, PLUGIN_TYPE_PLUGIN);
      LoadMS.Free;
    end else
    if KeyStr = INI_KEY_PRIVACYFIELDS then
    begin

    end else
    if KeyStr = INI_KEY_RIGHTLEVEL then
    begin
      RightLevel := TranslateRightLevel (ValStr);
    end else
    if KeyStr = INI_KEY_INJECTMODE then
    begin
      InjectMode := TranslateInjectMode (ValStr);
    end else
    begin
      FTaskConfig (TaskHandle, PChar(KeyStr), PChar(ValStr));
    end;          
  end;

  if not FileExists (GetAppExeFromCmdLine (AppCmdLine)) then
  begin
    DbgPrinter ('RunTask', 'AppCmdLine ERROR');
    FTaskDestroy (TaskHandle, False);
    ShowMessage ('目标程序不存在，请检查配置！');
    Exit;
  end;

  if not IsPlugBaseSucceed then
  begin
    DbgPrinter ('RunTask', 'Load default PlugBase.dll');
    LoadMS := GetRCDataMMemory ('PEFILE', 'PLUGBASEDLL');
    FTaskPlugin (TaskHandle, LoadMS.Memory, LoadMS.Size, PLUGIN_TYPE_PLUGBASE);
    LoadMS.Free;
  end;

  RunRet := FTaskRun (TaskHandle, PChar(AppCmdLine), RightLevel, InjectMode, RunMode);
  if RunRet < 0 then
  begin
    DbgPrinter ('RunTask', 'TaskRun ERROR = ' + IntToStr(RunRet));
    FTaskDestroy (TaskHandle, True);
    Exit;
  end;

  Result := True;
end;


procedure TMainManage.ToolButton6Click(Sender: TObject);
var
  Item: TToolButton absolute Sender;
begin            
  self.Memo1.Visible := Item.Down;
  self.CategoryButtons1.Visible := not Item.Down;
end;

function GetAveCharSize(Canvas: TCanvas): TPoint;
var
  I: Integer;
  Buffer: array[0..51] of Char;
begin
  for I := 0 to 25 do Buffer[I] := Chr(I + Ord('A'));
  for I := 0 to 25 do Buffer[I + 26] := Chr(I + Ord('a'));
  GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
  Result.X := Result.X div 52;
end;

const
  SMsgDlgOK = 'OK';
  SMsgDlgCancel = 'Cancel';
  
function InputQuery(const ACaption, APrompt: string;
  var Value: string): Boolean;
var
  Form: TForm;
  Prompt: TLabel;
  Edit: TEdit;
  DialogUnits: TPoint;
  ButtonTop, ButtonWidth, ButtonHeight: Integer;
begin
  Result := False;
  Form := TForm.Create(Application);
  with Form do
    try
      Canvas.Font := Font;
      DialogUnits := GetAveCharSize(Canvas);
      BorderStyle := bsDialog;
      Caption := ACaption;
      ClientWidth := MulDiv(180, DialogUnits.X, 4);
      Position := poMainFormCenter;
      Prompt := TLabel.Create(Form);
      with Prompt do
      begin
        Parent := Form;
        Caption := APrompt;
        Left := MulDiv(8, DialogUnits.X, 4);
        Top := MulDiv(8, DialogUnits.Y, 8);
        Constraints.MaxWidth := MulDiv(164, DialogUnits.X, 4);
        WordWrap := True;
      end;
      Edit := TEdit.Create(Form);
      with Edit do
      begin
        Parent := Form;
        PasswordChar := '*';
        Left := Prompt.Left;
        Top := Prompt.Top + Prompt.Height + 5;
        Width := MulDiv(164, DialogUnits.X, 4);
        MaxLength := 255;
        Text := Value;
        SelectAll;
      end;
      ButtonTop := Edit.Top + Edit.Height + 15;
      ButtonWidth := MulDiv(50, DialogUnits.X, 4);
      ButtonHeight := MulDiv(14, DialogUnits.Y, 8);
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := SMsgDlgOK;
        ModalResult := mrOk;
        Default := True;
        SetBounds(MulDiv(38, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      with TButton.Create(Form) do
      begin
        Parent := Form;
        Caption := SMsgDlgCancel;
        ModalResult := mrCancel;
        Cancel := True;
        SetBounds(MulDiv(92, DialogUnits.X, 4), Edit.Top + Edit.Height + 15,
          ButtonWidth, ButtonHeight);
        Form.ClientHeight := Top + Height + 13;          
      end;
      if ShowModal = mrOk then
      begin
        Value := Edit.Text;
        Result := True;
      end;
    finally
      Form.Free;
    end;
end;

function InputBox(const ACaption, APrompt, ADefault: string): string;
begin
  Result := ADefault;
  InputQuery(ACaption, APrompt, Result);
end;



procedure TMainManage.CategoryButtons1AfterDrawButton(Sender: TObject;
  const Button: TButtonItem; Canvas: TCanvas; Rect: TRect;
  State: TButtonDrawState);
var
  BorderRect: TRect;
  TextX, TextY: Integer;
begin
  BorderRect := Rect;

  BorderRect.Left := BorderRect.Right - RunWidth;
  BorderRect.Top := BorderRect.Top + RunBevel;
  BorderRect.Bottom := BorderRect.Bottom - RunBevel;
  BorderRect.Right := BorderRect.Left + RunWidth - RunBevel;

  Canvas.Pen.Color := clBtnFace;
  Canvas.Rectangle(BorderRect);

  TextX := BorderRect.Left + (BorderRect.Right - BorderRect.Left - Canvas.TextWidth(RunCaption)) div 2;
  TextY := BorderRect.Top + (BorderRect.Bottom - BorderRect.Top - Canvas.TextHeight(RunCaption)) div 2;

  Canvas.TextOut(TextX, TextY, RunCaption);
end;


procedure TMainManage.CategoryButtons1Click(Sender: TObject);
var
  Item: TButtonItem;
  ItemRect: TRect;
  LeftP, RightP: TPoint;
  ConfigSL: TStringList;
  PlugFile: String;
begin
  case ItemActionType of
    atNone: PropertyForm.Hide;
    atView: begin           
      Item := CategoryButtons1.SelectedItem;
      if Assigned (Item) then
      begin
        ItemRect := CategoryButtons1.GetButtonRect(Item);
        RightP.X := ItemRect.Left;
        RightP.Y := ItemRect.Top;
        RightP := CategoryButtons1.ClientToParent(RightP);
        RightP := self.ClientToScreen(RightP);
                           
        LeftP.X := self.Left;
        LeftP.Y := RightP.Y;
        RightP.X := self.Left + self.Width;
        RightP.Y := LeftP.Y;

        PlugFile := StrPas(self.CategoryButtons1.Categories.Items[Self.AimIndexA].Data);

        With PropertyForm do
        begin
          AimIndexA := Self.AimIndexA;
          AimIndexB := Self.AimIndexB;
          FPlugFile := PlugFile;
          ValueListEditor1.Strings.Clear;
          if DataModule.ReadConfigItem(AimIndexA, AimIndexB, ValueListEditor1.Strings) then
          begin
            Caption := format ('属性窗口 [%s]', [Item.Caption]);
            ResetPosition (LeftP, RightP);
            ToolButton9.Enabled := IsDbgOK;
            Show;
          end;
        end;
      end;
    end;
    atRun: begin
      PropertyForm.Hide;
      ConfigSL := DataModule.ReadConfigItem (Self.AimIndexA, Self.AimIndexB);
      PlugFile := StrPas(self.CategoryButtons1.Categories.Items[Self.AimIndexA].Data);
      self.StartTheTask(PlugFile, ConfigSL, RUN_MODE_NORMAL);
    end;
  end;
  ItemActionType := atNone;

end;


function TMainManage.GetActionType(MouseUpX, MouseUpY: Integer): TBtnActionType;
var
  ItemRect: TRect;
  ButtonItem: TButtonItem;
begin
  Result := atNone;
  ButtonItem := CategoryButtons1.GetButtonAt(MouseUpX, MouseUpY);
  if ButtonItem = nil then exit;
  ItemRect := CategoryButtons1.GetButtonRect(ButtonItem);

  if MouseUpX < ItemRect.Left then Exit;
  if MouseUpX > ItemRect.Right then Exit;
  if MouseUpY < ItemRect.Top then Exit;
  if MouseUpY > ItemRect.Bottom then Exit;

  Result := atView;

  if MouseUpX >= ItemRect.Right - RunWidth then
    Result := atRun;
end;

procedure TMainManage.CategoryButtons1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ButtonItem: TButtonItem;
  Category: TButtonCategory;
begin
  ItemActionType := GetActionType (X, Y);
  ButtonItem := CategoryButtons1.GetButtonAt(X, Y);
  if Assigned (ButtonItem) then
  begin
    AimIndexA := ButtonItem.Category.Index;
    AimIndexB := ButtonItem.Index;
  end else
  begin
    Category := CategoryButtons1.GetCategoryAt(X, Y);
    if Assigned (Category) then
    begin
      AimIndexA := Category.Index;
      AimIndexB := -1;
    end else
    begin
      AimIndexA := -1;
      AimIndexB := -1;
    end;
  end;
end;


procedure TMainManage.PopupMenu1Popup(Sender: TObject);
var
  PopXY: TPoint;
  ButtonItem: TButtonItem;
  Category: TButtonCategory;
  IterMenu: TMenuItem;
begin              
  PopXY := self.CategoryButtons1.ScreenToClient(PopupMenu1.PopupPoint);

  for IterMenu in PopupMenu1.Items do
    IterMenu.Visible := True;

  ButtonItem := CategoryButtons1.GetButtonAt(PopXY.X, PopXY.Y);
  if Assigned (ButtonItem) then
  begin

  end else
  begin
    Category := CategoryButtons1.GetCategoryAt(PopXY.X, PopXY.Y);
    if Assigned (Category) then
    begin
      PopupMenu1.Items[2].Visible := False;
      PopupMenu1.Items[3].Visible := False;
      PopupMenu1.Items[4].Visible := False;
      PopupMenu1.Items[5].Visible := False;  
      PopupMenu1.Items[8].Visible := False;
      PopupMenu1.Items[9].Visible := False;
    end else
    begin
      PopupMenu1.Items[2].Visible := False;
      PopupMenu1.Items[3].Visible := False;
      PopupMenu1.Items[4].Visible := False;
      PopupMenu1.Items[5].Visible := False;  
      PopupMenu1.Items[6].Visible := False;
      PopupMenu1.Items[8].Visible := False;
      PopupMenu1.Items[9].Visible := False;
    end;
  end;
end;


//  SAFER_LEVELID_FULLYTRUSTED = $40000;
//  SAFER_LEVELID_NORMALUSER   = $20000;
//  SAFER_LEVELID_CONSTRAINED  = $10000;
//  SAFER_LEVELID_UNTRUSTED    = $01000;
//  SAFER_LEVELID_DISALLOWED   = $00000;

procedure TMainManage.FormShow(Sender: TObject);
var
  SystemField, PrivacyField, StayOnTop: BOOL;
begin 
  self.Color := clWebAliceBlue;
  self.CategoryButtons1.Color := clWebAliceBlue;
  PropertyForm.ValueListEditor1.Color := clWebAliceBlue;
  AddConfigForm.ValueListEditor1.Color := clWebAliceBlue;

  DataModule.ReadMainPos (Self);
  DataModule.GetViewBool (SystemField, PrivacyField, StayOnTop);

  self.ToolButton1.Down := StayOnTop;
  self.ToolButton2.Down := SystemField;
  self.ToolButton4.Down := PrivacyField;

  if StayOnTop then
    self.FormStyle := fsStayOnTop
  else
    self.FormStyle := fsNormal;

  ConfigReflashClick(NIL);
  DataModule.ReadCollapsed(self.CategoryButtons1);

  self.Memo1.Align := alClient;
  self.Memo1.Clear;

  PluginDir := GetAppPath() + 'PlugIn\';
  if not DirectoryExists(PluginDir) then
  begin
    ForceDirectories (PluginDir);
  end;

  self.N21.Enabled := IsDbgOK;
end;


procedure TMainManage.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DataModule.SaveCollapsed(self.CategoryButtons1);
  DataModule.SaveMainPos (Self);
end;


procedure TMainManage.N13Click(Sender: TObject);
begin
  if self.AimIndexA >= 0 then
    AddConfigForm.ToAddPlugin := StrPas(self.CategoryButtons1.Categories.Items[self.AimIndexA].Data);

  if self.AimIndexB >= 0 then
    AddConfigForm.ToAddAppExe := StrPas(self.CategoryButtons1.Categories.Items[self.AimIndexA].Items[self.AimIndexB].Data);
               
  AddConfigForm.Position := poMainFormCenter;
  AddConfigForm.ShowModal;
  DataModule.LoadConfigLst(self.CategoryButtons1);
end;

procedure TMainManage.N14Click(Sender: TObject);
begin
  if DataModule.DeleteConfigItem(AimIndexA, AimIndexB) then
    self.ConfigReflashClick(Sender);
end;

procedure TMainManage.N1Click(Sender: TObject);
begin
  if AimIndexA >= 0 then
    case Application.MessageBox ('你真的要清空全部配置？', '清除确认', MB_YESNO) of
    IDYes: begin
      if DataModule.ClearConfigItem(AimIndexA) then
        self.ConfigReflashClick(Sender);
    end;
    IDNO:;
    end;
end;

procedure TMainManage.ConfigReflashClick(Sender: TObject);
begin
  DataModule.LoadConfigLst(self.CategoryButtons1);
end;

procedure TMainManage.N20Click(Sender: TObject);
var
  CfgSL: TStringList;
  PlugFile: String;
begin
  CfgSL := DataModule.ReadConfigItem (AimIndexA, AimIndexB);
  if CfgSL.Count > 0 then
  begin
    PlugFile := StrPas(self.CategoryButtons1.Categories.Items[AimIndexA].Data);
    self.StartTheTask (PlugFile, CfgSL, RUN_MODE_NORMAL);
  end;
  CfgSL.Free;
end;

procedure TMainManage.N21Click(Sender: TObject);
var
  CfgSL: TStringList;
  PlugFile: String;
begin
  CfgSL := DataModule.ReadConfigItem (AimIndexA, AimIndexB);
  if CfgSL.Count > 0 then
  begin
    PlugFile := StrPas(self.CategoryButtons1.Categories.Items[AimIndexA].Data);
    StartTheTask (PlugFile, CfgSL, RUN_MODE_DEBUG);
  end;
  CfgSL.Free;
end;

procedure TMainManage.N25Click(Sender: TObject);
begin
  if DataModule.MoveConfigItem(AimIndexA, AimIndexB, -1) then
    self.ConfigReflashClick(Sender);
end;

procedure TMainManage.N26Click(Sender: TObject);
begin
  if DataModule.MoveConfigItem(AimIndexA, AimIndexB, 1) then
    self.ConfigReflashClick(Sender);
end;

procedure TMainManage.N37Click(Sender: TObject);
begin
  case Application.MessageBox ('你真的要清空全部配置？', '清除确认', MB_YESNO) of
  IDYes: begin
    if DataModule.ClearConfigItem(-1) then
      self.ConfigReflashClick(Sender);
  end;
  IDNO:;
  end;
end;

procedure TMainManage.N49Click(Sender: TObject);
begin
  if DataModule.CloneConfigItem(AimIndexA, AimIndexB) then
    self.ConfigReflashClick(Sender);
end;


end.
