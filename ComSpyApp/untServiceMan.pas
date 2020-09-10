unit untServiceMan;

interface

uses windows, WinSvc;

type
  TServiceMan = class
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
**���ܣ�װ�ط���                                          *
**����1��������                                           *
**����2����������                                         *
**����3�������ļ��ĵ�ַ                                   *
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

      ServiceClose(result);           //��ס�رվ����������޷�ж�ط���
    end;
  finally
    ServiceDisconn(hManager);
  end;
end;

{**********************************************************
**���ܣ��رմ򿪵ķ�����                                *
**����1��������                                         *
***********************************************************}
function TServiceMan.ServiceClose(hService: SC_HANDLE): Boolean;
begin
  if (hService <> 0) then
    result := CloseServiceHandle(hService)
  else
    result := True;
end;

{**********************************************************
**���ܣ��򿪷��������                                    *
**����ֵΪ����                                          *
***********************************************************}
function TServiceMan.ServiceConnect: SC_HANDLE;
begin
  result := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
end;

{**********************************************************
**���ܣ��رչ��������                                    *
**����1��������                                         *
***********************************************************}
function TServiceMan.ServiceDisconn(hService: SC_HANDLE): SC_HANDLE;
begin
  if (hService <> 0) then
    CloseServiceHandle(hService);
  result := 0;
end;

{**********************************************************
**���ܣ����һ���Ѿ����صķ���ľ��                      *
**����1�����������                                       *
**����2�����������                                       *
***********************************************************}
function TServiceMan.ServiceOpen(hService:SC_HANDLE; AServName: PChar): SC_HANDLE;
begin
  result := OpenService(hService, AServName, SERVICE_ALL_ACCESS);
end;

{**********************************************************
**���ܣ�ж�ط���                                          *
**����1�����������                                       *
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
        ControlService(hService, SERVICE_CONTROL_STOP, ServiceStatus);     //��ж��ǰֹͣ���񣬷�����Ҫֹͣ�����������ж��
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
**���ܣ���������                                          *
**����1�����������                                       *
**����ֵ��    0��������δ��װ                             *
              1������������                               *
              2�����������ɹ�                             *
              3����������ʧ��                             *
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
          if StartService(hService, 1, AServName) then         //��������
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
**���ܣ�ֹͣ����                                          *
**����1�����������                                       *
**����ֵ��    0��������δ��װ                             *
              1��������ֹͣ                               *
              2������ֹͣ�ɹ�                             *
              3������ֹͣʧ��                             *
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
**���ܣ���÷����״̬                                    *
**����1���������ľ��                                     *
**����2�����������                                       *
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

{�ж�ĳ�����Ƿ�װ��δ��װ����true���Ѱ�װ����false} 
function TServiceMan.ServiceUninstalled(hService:SC_HANDLE; AServName:PChar):Boolean;
begin 
  Result  :=  0 = ServiceGetStatus(hService, AServName);
end; 

{�ж�ĳ�����Ƿ���������������true��δ��������false} 
function TServiceMan.ServiceRunning(hService:SC_HANDLE; AServName:PChar):Boolean;
begin 
  Result := SERVICE_RUNNING = ServiceGetStatus(hService, AServName);
end; 

{�ж�ĳ�����Ƿ�ֹͣ��ֹͣ����true��δֹͣ����false} 
function TServiceMan.ServiceStopped(hService:SC_HANDLE; AServName:PChar):Boolean;
begin 
  Result := SERVICE_STOPPED = ServiceGetStatus(hService, AServName);
end;

end.
