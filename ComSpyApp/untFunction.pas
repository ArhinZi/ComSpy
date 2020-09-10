unit untFunction;

interface

uses Windows, WinSvc;

function InstallService(SvcName, SvcDispName, SvcFullPath: string): integer;
function unInstallService(SvcName: string): boolean;

implementation

function InstallService(SvcName, SvcDispName, SvcFullPath: string): integer;
var
    hSCM, hService: SC_HANDLE;
begin
    result := 0;
    hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
    if hSCM = 0 then
      exit;

    try
      hService := CreateService(hSCM,
        PChar(SvcName),
        PChar(SvcDispName),
        SERVICE_ALL_ACCESS, //SERVICE_START OR SERVICE_QUERY_STATUS OR _DELETE,
        SERVICE_WIN32_OWN_PROCESS,
        SERVICE_DEMAND_START, //SERVICE_AUTO_START,
        SERVICE_ERROR_NORMAL,
        PChar(SvcFullPath),
        nil, nil, nil, nil, nil);

        CloseServiceHandle(hService);
    finally
      CloseServiceHandle(hSCM);
    end;
end;

function unInstallService(SvcName: string): boolean;
var
    hSCM, hService: SC_HANDLE;
begin
    Result := false;
    hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
    if hSCM = 0 then
      exit;

    try
      hService := OpenService(hSCM, PChar(SvcName), SERVICE_ALL_ACCESS);
      if hService = 0 then
        exit;

      result := DeleteService(hService);

      CloseServiceHandle(hService);
    finally
      CloseServiceHandle(hSCM);
    end;
end;


end.
 