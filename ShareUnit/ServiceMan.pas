unit ServiceMan;

interface

uses windows, WinSvc;

type
  TServiceMan = class (TObject)
  private
    function ServiceConnect:SC_HANDLE;
    function ServiceDisconn(hService:SC_HANDLE):SC_HANDLE;

    function ServiceOpen(hService:SC_HANDLE; AServName:PChar):SC_HANDLE;
    function ServiceClose(hService:SC_HANDLE):Boolean;

    function ServiceGetStatus(hService:SC_HANDLE; AServName:PChar ):DWord;

    function ServiceUninstalled(hService:SC_HANDLE; AServName:PChar):Boolean;
    function ServiceRunning(hService:SC_HANDLE; AServName:PChar):Boolean;
    function ServiceStopped(hService:SC_HANDLE; AServName:PChar):Boolean;
  public
    function ServiceInstall(AServName, ADispName, AServPath:PChar):SC_HANDLE;
    function ServiceUnInstall(AServName:PChar):DWORD;
    function ServiceStart(AServName:PChar):DWORD;
    function ServiceStop(AServName:PChar):DWORD;
  end;

implementation
{ TServiceMan }

{**********************************************************
**功能：装载服务 *
**参数1：服务名 *
**参数2：服务描述 *
**参数3：服务文件的地址 *
***********************************************************}
function TServiceMan.ServiceInstall(AServName, ADispName, AServPath: PChar): SC_HANDLE;
var
  hManager:SC_HANDLE;
begin
  result := 0;

  hManager := ServiceConnect;

  try
    if ServiceUninstalled(hManager, AServName) then
    begin
      result := CreateService(hManager,
      AServName,
      ADispName,
      SERVICE_ALL_ACCESS,
      SERVICE_KERNEL_DRIVER,
      SERVICE_DEMAND_START,
      SERVICE_ERROR_NORMAL,
      AServPath,
      nil,
      nil,
      nil,
      nil,
      nil);

      ServiceClose(result); //记住关闭句柄，否则会无法卸载服务
    end;
  finally
    ServiceDisconn(hManager);
  end;
end;

{**********************************************************
**功能：关闭打开的服务句柄 *
**参数1：服务句柄 *
***********************************************************}
function TServiceMan.ServiceClose(hService: SC_HANDLE): Boolean;
begin
  if (hService <> 0) then
    result := CloseServiceHandle(hService)
  else
    result := True;
end;

{**********************************************************
**功能：打开服务管理器 *
**返回值为其句柄 *
***********************************************************}
function TServiceMan.ServiceConnect: SC_HANDLE;
begin
  result := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
end;

{**********************************************************
**功能：关闭管理器句柄 *
**参数1：服务句柄 *
***********************************************************}
function TServiceMan.ServiceDisconn(hService: SC_HANDLE): SC_HANDLE;
begin
  if (hService <> 0) then
    CloseServiceHandle(hService);
  result := 0;
end;

{**********************************************************
**功能：获得一个已经加载的服务的句柄 *
**参数1：管理器句柄 *
**参数2：服务的名称 *
***********************************************************}
function TServiceMan.ServiceOpen(hService:SC_HANDLE; AServName: PChar): SC_HANDLE;
begin
  result := OpenService(hService, AServName, SERVICE_ALL_ACCESS);
end;

{**********************************************************
**功能：卸载服务 *
**参数1：服务的名称 *
***********************************************************}
function TServiceMan.ServiceUnInstall(AServName:PChar): DWORD;
var
  hService, hManager:SC_HANDLE;
  ServiceStatus:TServiceStatus;
begin
  result := 0;

  hManager := ServiceConnect;

  try
    if not ServiceUninstalled(hManager, AServName) then
    begin
      hService := ServiceOpen(hManager, AServName);

      if (hService <> 0) then
      begin
        ControlService(hService, SERVICE_CONTROL_STOP, ServiceStatus); //在卸载前停止服务，否则需要停止服务才能正常卸载
        if DeleteService(hService) then
          result := 2
        else
          result := 1;
      end;
      ServiceClose(hService);
    end;
  finally
    ServiceDisconn(hManager);
  end;
end;

{**********************************************************
**功能：启动服务 *
**参数1：服务的名称 *
**返回值： 0：驱动还未安装 *
1：驱动已启动 *
2：驱动启动成功 *
3：驱动启动失败 *
***********************************************************}
function TServiceMan.ServiceStart(AServName: PChar): DWORD;
var
  hService, hManager:SC_HANDLE;
begin
  result := 0;

  hManager := ServiceConnect;

  try
    if not ServiceUninstalled(hManager, AServName) then
    begin
      if not ServiceRunning(hManager, AServName) then
      begin
        hService := ServiceOpen(hManager, AServName);

        if (hService <> 0) then
          if StartService(hService, 1, AServName) then //启动服务
            result := 2
          else
            result := 3;

        ServiceClose(hService);
      end
      else
        result := 1;
    end;
  finally
    ServiceDisconn(hManager);
  end;
end;

{**********************************************************
**功能：停止服务 *
**参数1：服务的名称 *
**返回值： 0：驱动还未安装 *
1：驱动已停止 *
2：驱动停止成功 *
3：驱动停止失败 *
***********************************************************}
function TServiceMan.ServiceStop(AServName: PChar): DWORD;
var
  hService, hManager:SC_HANDLE;
  ServiceStatus:TServiceStatus;
begin
  result := 0;

  hManager := ServiceConnect;

  try
    if not ServiceUninstalled(hManager, AServName) then
    begin
      if not ServiceStopped(hManager, AServName) then
      begin
        hService := ServiceOpen(hManager, AServName);

        if (hService <> 0) then
        if ControlService(hService, SERVICE_CONTROL_STOP, ServiceStatus) then
          result := 2
        else            
          result := 3;

        ServiceClose(hService);
      end
      else
        result := 1;
    end;
  finally
    ServiceDisconn(hManager);
  end;
end;

{**********************************************************
**功能：获得服务的状态 *
**参数1：管理器的句柄 *
**参数2：服务的名称 *
***********************************************************}
function TServiceMan.ServiceGetStatus(hService:SC_HANDLE; AServName:PChar ):DWORD;
var
  hService2:SC_HANDLE;
  queryStatus:TServiceStatus;
  dwStat:DWORD;
begin
  dwStat := 0;

  if(hService > 0)then
  begin
    hService2 := ServiceOpen(hService, AServName);

    if(QueryServiceStatus(hService2, queryStatus))then
    begin
      dwStat := queryStatus.dwCurrentState;
    end;

    ServiceClose(hService2);
  end;
  Result := dwStat;
end;

{判断某服务是否安装，未安装返回true，已安装返回false}
function TServiceMan.ServiceUninstalled(hService:SC_HANDLE; AServName:PChar):Boolean;
begin 
  Result := 0 = ServiceGetStatus(hService, AServName);
end; 

{判断某服务是否启动，启动返回true，未启动返回false} 
function TServiceMan.ServiceRunning(hService:SC_HANDLE; AServName:PChar):Boolean;
begin 
  Result := SERVICE_RUNNING = ServiceGetStatus(hService, AServName);
end; 

{判断某服务是否停止，停止返回true，未停止返回false} 
function TServiceMan.ServiceStopped(hService:SC_HANDLE; AServName:PChar):Boolean;
begin 
  Result := SERVICE_STOPPED = ServiceGetStatus(hService, AServName);
end;

end.
