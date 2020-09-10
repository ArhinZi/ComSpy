unit GlobUnit;

interface

uses
  Messages, IniFiles, SysUtils, Forms;

const
  DRVFILE32 = 'sermon.sys';
  DRVFILE64 = 'sermon.sys';
  SVRNAME = 'sermon';

  {������Ϣ����}
  WM_SPYCOM_OPEN_OR_CLOSE   = WM_USER + 10080;
  WM_SPYCOM_READ            = WM_USER + 10081;
  WM_SPYCOM_WRITE           = WM_USER + 10082;
  WM_SPYCOM_SETBAUDRATE     = WM_USER + 10083;
  WM_SPYCOM_SETLINECONTROL  = WM_USER + 10084;

  {�����¼�����}
  SPY_EVENT_OPEN  = 'SERIAL_OPENED';
  SPY_EVENT_CLOSE = 'SERIAL_CLOSED';
  SPY_EVENT_READ  = 'SERIAL_READED';
  SPY_EVENT_WRITE = 'SERIAL_WRITED';

  {��־�洢��ʽ��time,port,event,bytes,data}
  LOG_SAVE_FORMAT = '%-9s%-6s%-14s%-6s%s';

//type
//  TPluginFunc = function(pShareMemory, Buffer: Pointer; BufferSize: Cardinal;

var
  P_SysPath: string;//ϵͳ����Ŀ¼
  P_AutoSaveLogFile: Boolean;//�Զ�������־
  P_LogFileSavePath: string;//��־���Ŀ¼
  P_CreateSubDirForEveryDay: Boolean;//ÿ�콨��һ����Ŀ¼
  P_CreateLogFileForEveryHour: Boolean;//ÿСʱ����һ����־�ļ�

  P_AutoClearDisplayData: Boolean;//�Զ������ʾ����
  P_AutoClearByMaxRows: Integer;//�ﵽ���������Զ����

  P_StartProtocolPlugin: Boolean;//����Э��������
  P_ProtocolPluginFile: string;//Э���������ļ�

  {���ݵ���̬�⹲���ڴ�ĵ�ַ�ʹ�С}
  P_ShareMemoryAddress: Pointer;
  P_ShareMemorySize: Cardinal;

  {��ini�ļ���������}
  procedure LoadConfigureFromIni();
  {���ñ��浽ini�ļ�}
  procedure SaveConfigureToIni();

  {д��־�ļ�}
  procedure WriteLogFile(sLog: string);


implementation

  {��ini�ļ���������}
  procedure LoadConfigureFromIni();
  var
    inifile: TIniFile;
  begin
    inifile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));

    P_AutoSaveLogFile := inifile.ReadBool('��־����', '�Զ�������־', True);
    P_LogFileSavePath := inifile.ReadString('��־����', '��־���Ŀ¼', P_SysPath + 'log');
    P_CreateSubDirForEveryDay := inifile.ReadBool('��־����','���콨����Ŀ¼', False);
    P_CreateLogFileForEveryHour := inifile.ReadBool('��־����','��Сʱ������־�ļ�', False);

    P_AutoClearDisplayData := inifile.ReadBool('�������в���', '�Զ������ʾ����', True);
    P_AutoClearByMaxRows := inifile.ReadInteger('�������в���', '�Զ������������', 1000);

    P_StartProtocolPlugin := inifile.ReadBool('Э������������', '����Э��������', False);
    P_ProtocolPluginFile := inifile.ReadString('Э������������', 'Э���������ļ�', '');

    inifile.Free;
  end;

  {���ñ��浽ini�ļ�}
  procedure SaveConfigureToIni();
  var
    inifile: TIniFile;
  begin
    inifile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));

    inifile.WriteBool('��־����', '�Զ�������־', P_AutoSaveLogFile);
    inifile.WriteString('��־����', '��־���Ŀ¼', P_LogFileSavePath);
    inifile.WriteBool('��־����','���콨����Ŀ¼', P_CreateSubDirForEveryDay);
    inifile.WriteBool('��־����','��Сʱ������־�ļ�', P_CreateLogFileForEveryHour);

    inifile.WriteBool('�������в���', '�Զ������ʾ����', P_AutoClearDisplayData);
    inifile.WriteInteger('�������в���', '�Զ������������', P_AutoClearByMaxRows);

    inifile.WriteBool('Э������������', '����Э��������', P_StartProtocolPlugin);
    inifile.WriteString('Э������������', 'Э���������ļ�', P_ProtocolPluginFile);

    inifile.Free;
  end;  

  {д��־�ļ�}
  procedure WriteLogFile(sLog: string);
  var
    F: TextFile;
    sFileName, sPath: string;
  begin
    sPath := P_LogFileSavePath;
    if (sPath[Length(sPath)] <> '\') then sPath := sPath + '\';
    {���콨��Ŀ¼}
    if P_CreateSubDirForEveryDay then
      sPath := sPath + FormatDateTime('yyyy_mm_dd', Now) + '\';
    {�ж�Ŀ¼�Ƿ����}
    if not DirectoryExists(sPath) then
    begin
      {ǿ�ƽ����༶Ŀ¼}
      if not ForceDirectories(sPath) then Exit;
    end;
    {ÿСʱ����һ����־�ļ�}
    if P_CreateLogFileForEveryHour then
      sFileName := sPath + FormatDateTime('yyyy_mm_dd_hh', Now) + '.log'
    else
      sFileName := sPath + FormatDateTime('yyyy_mm_dd', Now) + '.log';

    try
      AssignFile(F, sFileName);//�����ļ�

      if FileExists(sFileName) then//�ļ�����
        Append(F)//׷�ӵ��ļ�β��
      else                         //�ļ�������
      begin
        Rewrite(F);//�������ļ�
        //д�����
        Writeln(F, Format(LOG_SAVE_FORMAT, ['Time','Port','Event','Bytes','Data']));
      end;
        
      {д���ļ�}
      Writeln(F, slog);
    finally
      CloseFile(F);
    end;
  end;

end.
