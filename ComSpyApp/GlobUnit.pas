unit GlobUnit;

interface

uses
  Messages, IniFiles, SysUtils, Forms;

const
  DRVFILE32 = 'sermon.sys';
  DRVFILE64 = 'sermon.sys';
  SVRNAME = 'sermon';

  {处理消息定义}
  WM_SPYCOM_OPEN_OR_CLOSE   = WM_USER + 10080;
  WM_SPYCOM_READ            = WM_USER + 10081;
  WM_SPYCOM_WRITE           = WM_USER + 10082;
  WM_SPYCOM_SETBAUDRATE     = WM_USER + 10083;
  WM_SPYCOM_SETLINECONTROL  = WM_USER + 10084;

  {串口事件定义}
  SPY_EVENT_OPEN  = 'SERIAL_OPENED';
  SPY_EVENT_CLOSE = 'SERIAL_CLOSED';
  SPY_EVENT_READ  = 'SERIAL_READED';
  SPY_EVENT_WRITE = 'SERIAL_WRITED';

  {日志存储格式：time,port,event,bytes,data}
  LOG_SAVE_FORMAT = '%-9s%-6s%-14s%-6s%s';

//type
//  TPluginFunc = function(pShareMemory, Buffer: Pointer; BufferSize: Cardinal;

var
  P_SysPath: string;//系统运行目录
  P_AutoSaveLogFile: Boolean;//自动保存日志
  P_LogFileSavePath: string;//日志存放目录
  P_CreateSubDirForEveryDay: Boolean;//每天建立一个子目录
  P_CreateLogFileForEveryHour: Boolean;//每小时建立一个日志文件

  P_AutoClearDisplayData: Boolean;//自动清除显示数据
  P_AutoClearByMaxRows: Integer;//达到多少行则自动清除

  P_StartProtocolPlugin: Boolean;//启用协议解析插件
  P_ProtocolPluginFile: string;//协议解析插件文件

  {传递到动态库共享内存的地址和大小}
  P_ShareMemoryAddress: Pointer;
  P_ShareMemorySize: Cardinal;

  {从ini文件导入配置}
  procedure LoadConfigureFromIni();
  {配置保存到ini文件}
  procedure SaveConfigureToIni();

  {写日志文件}
  procedure WriteLogFile(sLog: string);


implementation

  {从ini文件导入配置}
  procedure LoadConfigureFromIni();
  var
    inifile: TIniFile;
  begin
    inifile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));

    P_AutoSaveLogFile := inifile.ReadBool('日志参数', '自动保存日志', True);
    P_LogFileSavePath := inifile.ReadString('日志参数', '日志存放目录', P_SysPath + 'log');
    P_CreateSubDirForEveryDay := inifile.ReadBool('日志参数','按天建立子目录', False);
    P_CreateLogFileForEveryHour := inifile.ReadBool('日志参数','按小时建立日志文件', False);

    P_AutoClearDisplayData := inifile.ReadBool('界面运行参数', '自动清除显示数据', True);
    P_AutoClearByMaxRows := inifile.ReadInteger('界面运行参数', '自动清除满足行数', 1000);

    P_StartProtocolPlugin := inifile.ReadBool('协议解析插件参数', '启用协议解析插件', False);
    P_ProtocolPluginFile := inifile.ReadString('协议解析插件参数', '协议解析插件文件', '');

    inifile.Free;
  end;

  {配置保存到ini文件}
  procedure SaveConfigureToIni();
  var
    inifile: TIniFile;
  begin
    inifile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));

    inifile.WriteBool('日志参数', '自动保存日志', P_AutoSaveLogFile);
    inifile.WriteString('日志参数', '日志存放目录', P_LogFileSavePath);
    inifile.WriteBool('日志参数','按天建立子目录', P_CreateSubDirForEveryDay);
    inifile.WriteBool('日志参数','按小时建立日志文件', P_CreateLogFileForEveryHour);

    inifile.WriteBool('界面运行参数', '自动清除显示数据', P_AutoClearDisplayData);
    inifile.WriteInteger('界面运行参数', '自动清除满足行数', P_AutoClearByMaxRows);

    inifile.WriteBool('协议解析插件参数', '启用协议解析插件', P_StartProtocolPlugin);
    inifile.WriteString('协议解析插件参数', '协议解析插件文件', P_ProtocolPluginFile);

    inifile.Free;
  end;  

  {写日志文件}
  procedure WriteLogFile(sLog: string);
  var
    F: TextFile;
    sFileName, sPath: string;
  begin
    sPath := P_LogFileSavePath;
    if (sPath[Length(sPath)] <> '\') then sPath := sPath + '\';
    {按天建立目录}
    if P_CreateSubDirForEveryDay then
      sPath := sPath + FormatDateTime('yyyy_mm_dd', Now) + '\';
    {判断目录是否存在}
    if not DirectoryExists(sPath) then
    begin
      {强制建立多级目录}
      if not ForceDirectories(sPath) then Exit;
    end;
    {每小时产生一个日志文件}
    if P_CreateLogFileForEveryHour then
      sFileName := sPath + FormatDateTime('yyyy_mm_dd_hh', Now) + '.log'
    else
      sFileName := sPath + FormatDateTime('yyyy_mm_dd', Now) + '.log';

    try
      AssignFile(F, sFileName);//关联文件

      if FileExists(sFileName) then//文件存在
        Append(F)//追加到文件尾部
      else                         //文件不存在
      begin
        Rewrite(F);//创建新文件
        //写入标题
        Writeln(F, Format(LOG_SAVE_FORMAT, ['Time','Port','Event','Bytes','Data']));
      end;
        
      {写入文件}
      Writeln(F, slog);
    finally
      CloseFile(F);
    end;
  end;

end.
