program PlugsExplorer;

{$R 'IncludeRC.res' 'IncludeRC.rc'}


uses
  Forms,
  SysUtils,
  DLLLoader,
  MainForm in 'MainForm.pas' {MainManage},
  AddFormUnit in 'AddFormUnit.pas' {AddConfigForm},
  DataUnit in '..\ShareUnit\DataUnit.pas',
  RcFuncUnit in '..\ShareUnit\RcFuncUnit.pas',
  ModifyFormUnit in 'ModifyFormUnit.pas' {ModifyConfigForm},
  RunInfoDB in '..\ShareUnit\RunInfoDB.pas',
  PerpertyForm in 'PerpertyForm.pas' {Form5};

{$R *.res}


type
  TRunMode = (rmNone, rmModify, rmAddNew);

var
  InputCount: Integer;
  RunMode: TRunMode;
  RunParam: String;
  CfgFile: String;

function GetRunMode (InputParam: String): TRunMode;
var
  AppExe, PluginName: String;
begin
  Result := rmNone;
  repeat
    InputParam := Trim(InputParam);

    if FileExists (InputParam)  then
    if IsPeFile (InputParam) then
    begin
      Result := rmAddNew;
      Break;
    end;

    if DCM.GetPluginFromConfigID (InputParam, AppExe, PluginName) then
    begin
      Result := rmModify;
      Break;
    end;     
  until True;
end;

begin
  Application.Initialize;

  CfgFile := GetAppPaths ('Data') + 'PlugsHolder.json';
  DCM := TTDataCfgModule.Create(CfgFile);
  DCM.LoadPluginFromDisk;

  InputCount := ParamCount;
  Repeat
    RunMode := rmNone;
    if InputCount = 1 then   //修改窗口
    begin
      RunParam := ParamStr (1);
      RunMode := GetRunMode (RunParam);
    end;

    case RunMode of
      rmNone: Begin
        Application.Title := '通用插件系统';
        Application.CreateForm(TMainManage, MainManage);  //主窗口
        Application.CreateForm(TForm5, Form5);
        Break;
      end;
      rmModify: begin
        Application.CreateForm(TModifyConfigForm, ModifyConfigForm);
        ModifyConfigForm.ConfigID := RunParam;
        Break;
      end;
      rmAddNew: Begin
        Application.CreateForm(TAddConfigForm, AddConfigForm);
        AddConfigForm.ToAddAppExe := RunParam;
        Break;
      end;
    end;

    DCM.Destroy;
    Exit;
  until True;

  Application.Run;

  if Assigned (AddConfigForm) then
    if AddConfigForm.IsNeedSave then
      DCM.SaveToFile();

  DCM.Destroy;
end.
