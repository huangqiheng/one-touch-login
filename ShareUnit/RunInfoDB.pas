unit RunInfoDB;

interface
uses windows, classes, sysutils;

Type
  TSortMode =  (smByNameASC, smByNameDESC,
                smByPluginASC, smByPluginDESC,
                smByModifyTimeASC, smByModifyTimeDESC,
                smByLastRunTimeASC, smByLastRunTimeDESC,
                smByRunTimesASC, smByRunTimesDESC
               );

function PluginList_UserConfirm (PluginName: String): BOOL;
function PluginList_RunRecord (PluginName: String): BOOL;
function PluginList_SetMD5 (PluginName, PlugMD5: String): BOOL;
function PluginList_Delete (PluginName: String): BOOL;
function PluginList_GetRunInfo (PluginName: String; var RunTimes: Integer; var LastRunTime, LastConfirmTime: TDateTime): BOOL;
function PluginList_GetMD5 (PluginName: String; var PlugMD5: String): BOOL;
function PluginList_GetLastRunPlugin (var Plugins: TStringList; var LastRunTime: TDateTime): BOOL;


function AppConfigList_ModifyRecord (ConfigID, Name, PluginName: String): BOOL;
function AppConfigList_RunRecord (ConfigID, Name, PluginName: String): BOOL;
function AppConfigList_Delete (ConfigID: String): BOOL; Overload;
function AppConfigList_Delete (DaysBefore: Integer): BOOL; Overload;
function AppConfigList_GetMaxRunConfig (var ConfigIDs: TStringList; var LastRunTime: TDateTime): BOOL;
function AppConfigList_GetLastRunConfig (var ConfigIDs: TStringList; var LastRunTime: TDateTime): BOOL;
function AppConfigList_GetLastModifyConfig (var ConfigIDs: TStringList; var LastModifyTime: TDateTime): BOOL;
function AppConfigList_GetSortedList (Sort: TSortMode; const ConfigIDs: TStringList; Out SortSL: TStringList): BOOL;


implementation

uses SyncObjs, MkSqLite3, math, DataUnit, MKSqLite3Api, DateUtils;

var
  RunDB: TMkSqlite;
  CTS: TCriticalSection;

//          PluginList
//'SN integer PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,'+
//'PluginName varchar NOT NULL,'+
//'MD5 varchar NOT NULL,'+
//'RunTimes integer NOT NULL,'+
//'LastRunTime datetime NOT NULL,' +
//'LastConfirmTime datetime NOT NULL)';
function PluginList_GetLastRunPlugin (var Plugins: TStringList; var LastRunTime: TDateTime): BOOL;
var
  SqlCmd, TimeStr, KeyName: String;
  RunTimes: Integer;
  RS:IMksqlStmt;
begin
  SqlCmd := 'SELECT PluginName,RunTimes,LastRunTime FROM PluginList ORDER BY LastRunTime desc';
  RS := RunDB.exec (SqlCmd);
  TimeStr := '';
  While not RS.EOF do
  begin
    KeyName := RS[0];
    RunTimes := RS[1];
    Plugins.AddObject(KeyName, Pointer(RunTimes));
    if TimeStr = '' then
    begin
      TimeStr := RS[2];
      LastRunTime := mkStrToDate (TimeStr);
    end;
    RS.next;
  end;
  RS := NIL;
  Result := Plugins.Count > 0;
end;


function PluginList_GetMD5 (PluginName: String; var PlugMD5: String): BOOL;
var
  SqlCmd: String;
  RS:IMksqlStmt;
begin
  Result := False;
  SqlCmd := Format('SELECT MD5 FROM PluginList WHERE PluginName=''%s''', [PluginName]);
  RS := RunDB.exec (SqlCmd);

  if not RS.EOF then
  begin
    PlugMD5 := RS[0];
    Result := True;
  end;
  RS := NIL;
end;                

function PluginList_GetRunInfo (PluginName: String; var RunTimes: Integer; var LastRunTime, LastConfirmTime: TDateTime): BOOL;
var
  SqlCmd: String;
  RS:IMksqlStmt;
begin
  Result := False;
  SqlCmd := Format('SELECT RunTimes,LastRunTime,LastConfirmTime FROM PluginList WHERE PluginName=''%s''', [PluginName]);
  RS := RunDB.exec (SqlCmd);

  if not RS.EOF then
  begin
    RunTimes := RS[0];
    LastRunTime := mkStrToDate(RS[1]);
    LastConfirmTime := mkStrToDate(RS[2]);
    Result := True;
  end;
  RS := NIL;
end;

function PluginList_SetMD5 (PluginName, PlugMD5: String): BOOL;
var
  SqlCmd: String;
begin
  SqlCmd := Format('UPDATE PluginList SET MD5=''%s'' WHERE PluginName=''%s''',
            [PlugMD5, PluginName]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

function PluginList_FindSerialNumber (PluginName: String; out SerialNumber, RunTimes: Integer): BOOL; Overload;
var
  SqlCmd: String;
  RS:IMksqlStmt;
begin
  Result := False;
  //SN	Name	MD5 RunTimes LastRunTime LastConfirmTime
  SqlCmd := 'SELECT SN,RunTimes FROM PluginList WHERE PluginName=''' + PluginName + '''';
  RS := RunDB.exec (SqlCmd);
  if RS.rowCount > 0 then
  begin
    SerialNumber := RS[0];
    RunTimes := RS[1];
    Result := True;
  end;
  RS := NIL;
end;

function PluginList_FindSerialNumber (PluginName: String; out SerialNumber: Integer): BOOL; Overload;
var
  SqlCmd: String;
  RS:IMksqlStmt;
begin
  Result := False;
  //SN	Name	MD5 RunTimes LastRunTime LastConfirmTime
  SqlCmd := 'SELECT SN FROM PluginList WHERE PluginName=''' + PluginName + '''';
  RS := RunDB.exec (SqlCmd);
  if RS.rowCount > 0 then
  begin
    SerialNumber := RS[0];
    Result := True;
  end;
  RS := NIL;
end;

function PluginList_NewRecord (PluginName: String; Md5Str: String = ''): BOOL;
var
  SqlCmd, NowTimeStr: String;
begin
  if Md5Str = '' then
    Md5Str := 'NULL';
  NowTimeStr := mkDateToStr(0);
  SqlCmd := 'INSERT INTO PluginList (PluginName,MD5,RunTimes,LastRunTime,LastConfirmTime) ';
  SqlCmd := Format(SqlCmd+'VALUES(''%s'',''%s'',%d,''%s'',''%s'')',
            [PluginName, Md5Str, 0, NowTimeStr, NowTimeStr]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

function PluginList_UpdateTime (SerialNumber, PreRunTimes: Integer): BOOL;
var
  SqlCmd, NowTimeStr: String;
begin
  Inc (PreRunTimes);
  NowTimeStr := mkdateToStr(Now);
  SqlCmd := Format('UPDATE PluginList SET RunTimes=%d,LastRunTime=''%s'' WHERE SN=%d',
            [PreRunTimes, NowTimeStr, SerialNumber]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

function PluginList_RunRecord (PluginName: String): BOOL;
var
  SerialNumber, RunTimes: Integer;
  IsInPluginList: BOOL;
begin
  //判断用如何方式更新入数据库
  IsInPluginList := PluginList_FindSerialNumber (PluginName, SerialNumber, RunTimes);

  //将自己的信息放入数据库
  if IsInPluginList then
    Result := PluginList_UpdateTime (SerialNumber, RunTimes)
  else
    Result := PluginList_NewRecord (PluginName);
end;

function PluginList_UserConfirm (PluginName: String): BOOL;
var
  SqlCmd: String;
begin
  SqlCmd := Format('UPDATE PluginList SET LastConfirmTime=''%s'' WHERE PluginName=''%s''',
            [mkDateToStr(Now), PluginName]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;


function PluginList_Delete (PluginName: String): BOOL;
var
  SqlCmd: String;
begin
  SqlCmd := Format('DELETE FROM PluginList WHERE PluginName=''%s''', [PluginName]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

//============================================================================//



function AppConfigList_GetLastModifyConfig (var ConfigIDs: TStringList; var LastModifyTime: TDateTime): BOOL;
var
  SqlCmd, TimeStr, ConfigID: String;
  RunTimes: Integer;
  RS:IMksqlStmt;
begin
  SqlCmd := 'SELECT ConfigID,RunTimes,LastModifyTime FROM AppConfigList ORDER BY LastModifyTime desc';
  RS := RunDB.exec (SqlCmd);
  TimeStr := '';
  While not RS.EOF do
  begin
    ConfigID := RS[0];
    RunTimes := RS[1];
    ConfigIDs.AddObject(ConfigID, Pointer(RunTimes));
    if TimeStr = '' then
    begin
      TimeStr := RS[2];
      LastModifyTime := mkStrToDate (TimeStr);
    end;
    RS.next;
  end;
  RS := NIL;
  Result := ConfigIDs.Count > 0;
end;


function AppConfigList_GetLastRunConfig (var ConfigIDs: TStringList; var LastRunTime: TDateTime): BOOL;
var
  SqlCmd, TimeStr, ConfigID: String;
  RunTimes: Integer;
  RS:IMksqlStmt;
begin
  SqlCmd := 'SELECT ConfigID,RunTimes,LastRunTime FROM AppConfigList ORDER BY LastRunTime desc';
  RS := RunDB.exec (SqlCmd);
  TimeStr := '';
  While not RS.EOF do
  begin
    ConfigID := RS[0];
    RunTimes := RS[1];
    ConfigIDs.AddObject(ConfigID, Pointer(RunTimes));
    if TimeStr = '' then
    begin
      TimeStr := RS[2];
      LastRunTime := mkStrToDate (TimeStr);
    end;
    RS.next;
  end;
  RS := NIL;
  Result := ConfigIDs.Count > 0;
end;

function AppConfigList_GetMaxRunConfig (var ConfigIDs: TStringList; var LastRunTime: TDateTime): BOOL;
var
  SqlCmd, TimeStr, ConfigID: String;
  RunTimes: Integer;
  RS:IMksqlStmt;
begin
  SqlCmd := 'SELECT ConfigID,RunTimes,LastRunTime FROM AppConfigList ORDER BY RunTimes desc';
  RS := RunDB.exec (SqlCmd);
  TimeStr := '';
  While not RS.EOF do
  begin
    ConfigID := RS[0];
    RunTimes := RS[1];
    ConfigIDs.AddObject(ConfigID, Pointer(RunTimes));
    if TimeStr = '' then
    begin
      TimeStr := RS[2];
      LastRunTime := mkStrToDate (TimeStr);
    end;
    RS.next;
  end;
  RS := NIL;
  Result := ConfigIDs.Count > 0;
end;

function AppConfigList_FindSerialNumber (ConfigID: String; var SerialNumber,RunTimes: Integer): BOOL;
var
  SqlCmd: String;
  RS:IMksqlStmt;
begin
  Result := False;
  //SN	ConfigID	RunTimes LastRunTime  LastModifyTime
  SqlCmd := 'SELECT SN,RunTimes FROM AppConfigList WHERE ConfigID=''' + ConfigID + '''';
  RS := RunDB.exec (SqlCmd);
  if RS.rowCount > 0 then
  begin
    SerialNumber := RS[0];
    RunTimes := RS[1];
    Result := True;
  end;
  RS := NIL;
end;

function AppConfigList_UpdateRunTime (SerialNumber: Integer; Name, PluginName: String; RunTimes: Integer): BOOL;
var
  SqlCmd, NowTimeStr: String;
begin
  Inc (RunTimes);
  NowTimeStr := mkdateToStr(Now);
  SqlCmd := Format('UPDATE AppConfigList SET Name=''%s'',PluginName=''%s'',RunTimes=%d,LastRunTime=''%s'' WHERE SN=%d',
            [Name, PluginName, RunTimes, NowTimeStr, SerialNumber]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

function AppConfigList_NewRecord (ConfigID, Name, PluginName: String): BOOL;
var
  SqlCmd, NowTimeStr, LastRunTimeStr: String;
begin
  LastRunTimeStr := mkdateToStr(0);
  NowTimeStr := mkdateToStr(Now);
  SqlCmd := 'INSERT INTO AppConfigList (ConfigID,Name,PluginName,RunTimes,LastRunTime,LastModifyTime) ';
  SqlCmd := Format(SqlCmd+'VALUES(''%s'',''%s'',''%s'',%d,''%s'',''%s'')',
            [ConfigID, Name, PluginName, 0, LastRunTimeStr, NowTimeStr]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

function AppConfigList_RunRecord (ConfigID, Name, PluginName: String): BOOL;
var
  SerialNumber, RunTimes: Integer;
  IsInAppConfigList: BOOL;
begin
  //判断用如何方式更新入数据库
  IsInAppConfigList := AppConfigList_FindSerialNumber (ConfigID, SerialNumber, RunTimes);

  //将自己的信息放入数据库
  if IsInAppConfigList then
    Result := AppConfigList_UpdateRunTime (SerialNumber, Name, PluginName, RunTimes)
  else
    Result := AppConfigList_NewRecord (ConfigID, Name, PluginName);
end;

function AppConfigList_Delete (ConfigID: String): BOOL;
var
  SqlCmd: String;
begin
  SqlCmd := Format('DELETE FROM AppConfigList WHERE ConfigID=''%s''', [ConfigID]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

//'SN integer PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,'+
//'ConfigID varchar NOT NULL,'+
//'Name varchar NOT NULL,'+
//'PluginName varchar NOT NULL,'+
//'RunTimes integer NOT NULL,'+
//'LastRunTime datetime NOT NULL)';
//'LastModifyTime datetime NOT NULL)';
function AppConfigList_Delete (DaysBefore: Integer): BOOL;
var
  SqlCmd, BeginTimeStr: String;
begin
  BeginTimeStr := mkDateToStr (IncDay (Now, -DaysBefore));
  SqlCmd := Format('DELETE FROM AppConfigList WHERE LastRunTime<datetime(''%s'') AND LastModifyTime<datetime(''%s'')', [BeginTimeStr,BeginTimeStr]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;


function AppConfigList_UpdateModifyTime (SerialNumber: Integer; Name, PluginName: String): BOOL;
var
  SqlCmd, NowTimeStr: String;
begin
  NowTimeStr := mkdateToStr(Now);
  SqlCmd := Format('UPDATE AppConfigList SET Name=''%s'',PluginName=''%s'',LastModifyTime=datetime''%s'' WHERE SN=%d',
            [Name, PluginName, NowTimeStr, SerialNumber]);
  Result := RunDB._exec(SqlCmd) = SQLITE_OK;
end;

function AppConfigList_ModifyRecord (ConfigID, Name, PluginName: String): BOOL;
var
  SerialNumber, RunTimes: Integer;
  IsInAppConfigList: BOOL;
begin
  //判断用如何方式更新入数据库
  IsInAppConfigList := AppConfigList_FindSerialNumber (ConfigID, SerialNumber, RunTimes);

  //将自己的信息放入数据库
  if IsInAppConfigList then
    Result := AppConfigList_UpdateModifyTime (SerialNumber, Name, PluginName)
  else
    Result := AppConfigList_NewRecord (ConfigID, Name, PluginName);
end;

function AppConfigList_GetSortedList (Sort: TSortMode; const ConfigIDs: TStringList; Out SortSL: TStringList): BOOL;
var
  SqlCmd, ConfigID: String;
  RS:IMksqlStmt;
  InputList, GetDBList: TStringList;
  Index: Integer;
begin
  Result := False;
  if ConfigIDs.Count = 0 then exit;
  InputList := TStringList.Create;
  InputList.AddStrings(ConfigIDs);

  case Sort of
    smByNameASC:         SqlCmd := 'ORDER BY Name ASC';
    smByNameDESC:        SqlCmd := 'ORDER BY Name DESC';
    smByPluginASC:       SqlCmd := 'ORDER BY PluginName ASC';
    smByPluginDESC:      SqlCmd := 'ORDER BY PluginName DESC';
    smByModifyTimeASC:   SqlCmd := 'ORDER BY LastModifyTime ASC';
    smByModifyTimeDESC:  SqlCmd := 'ORDER BY LastModifyTime DESC';
    smByLastRunTimeASC:  SqlCmd := 'ORDER BY LastRunTime ASC';
    smByLastRunTimeDESC: SqlCmd := 'ORDER BY LastRunTime DESC';
    smByRunTimesASC:     SqlCmd := 'ORDER BY RunTimes ASC';
    smByRunTimesDESC:    SqlCmd := 'ORDER BY RunTimes DESC';
    else exit;
  end;

  SqlCmd := Format ('SELECT ConfigID FROM AppConfigList %s', [SqlCmd]);
  RS := RunDB.exec (SqlCmd);
  GetDBList := TStringList.Create;
  While not RS.EOF do
  begin
    ConfigID := RS[0];
    GetDBList.Add(ConfigID);
    RS.next;
  end;
  RS := NIL;

  SortSL.Clear;
  for ConfigID in GetDBList do
  begin
    Index := InputList.IndexOf(ConfigID);
    if Index >= 0 then
    begin
      SortSL.Add(ConfigID);
      InputList.Delete(Index);
      if InputList.Count = 0 then Break;
    end;
  end;

  if InputList.Count > 0 then
    SortSL.AddStrings(InputList);  

  InputList.Free;
  GetDBList.Free;
  Result := SortSL.Count > 0;
end;
      

//          PluginList
//SN
//"PluginName": "MMK\\SilkRoadAddr.dll",
//"MD5": "8852435442924115BA30909211595303",
//"RunTimes": 133,
//"LastRunTime": "2009-06-12 15:12:44",
//"LastConfirmTime": "2009-06-12 12:12:44",

//          AppConfigList
//SN
//"ConfigID": "{0AB8972D-4B0D-4099-BEE5-1A61C88DD1F1}",
//"Name": "电信3区ss号",
//"PluginName": "MMK\\SilkRoadAddr.dll",
//"RunTimes": 33,      //系统计算
//"LastRunTime": "2009-06-12 15:12:44",
//"LastModifyTime": "2009-06-12 15:12:44",
Procedure InitRunDB;
var
  CreateSql, DbName, SqliteDLL: String;
  NeedCreateTable: BOOL;
begin
  if not assigned (RunDB) then
  begin
    CTS := TCriticalSection.Create;

    DbName := GetAppPaths ('Data') + 'RunInfo.DB';
    NeedCreateTable := not FileExists (DbName);
    SqliteDLL := GetAppPaths ('Data') + 'sqlite3.dll';
    DefineSqliteDLL := SqliteDLL;

    RunDB := TMkSqlite.Create(nil);
    RunDB.dbName := AnsiToUtf8 (DbName);
    RunDB.open;

    if NeedCreateTable then
    begin
      CreateSql:= 'CREATE TABLE PluginList('+
                  'SN integer PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,'+
                  'PluginName varchar NOT NULL,'+
                  'MD5 varchar NOT NULL,'+
                  'RunTimes integer NOT NULL,'+
                  'LastRunTime datetime NOT NULL,' +
                  'LastConfirmTime datetime NOT NULL)';
      RunDB.execCmd(CreateSql);

      CreateSql:= 'CREATE TABLE AppConfigList('+
                  'SN integer PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,'+
                  'ConfigID varchar NOT NULL,'+
                  'Name varchar NOT NULL,'+
                  'PluginName varchar NOT NULL,'+
                  'RunTimes integer NOT NULL,'+
                  'LastRunTime datetime NOT NULL,'+
                  'LastModifyTime datetime NOT NULL)';
      RunDB.execCmd(CreateSql);
    end;
  end;
end;

Procedure FinalRunDB;
begin
  if assigned (RunDB) then
    RunDB.close;
  if assigned (CTS) then
    CTS.Free;
end;


Initialization
  InitRunDB;

Finalization
  FinalRunDB;

end.
