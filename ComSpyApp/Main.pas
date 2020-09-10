unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, untServiceMan, ctr_uint,
  Registry, ImgList, ToolWin, Menus, ActnList, Buttons, GlobUnit;

type
  TFrmMain = class(TForm)
    grp2: TGroupBox;
    grp_Detail: TGroupBox;
    spl2: TSplitter;
    pnl1: TPanel;
    lv1: TListView;
    il1: TImageList;
    actlst1: TActionList;
    act_Save: TAction;
    act_SerialSelect: TAction;
    act_StartMonitor: TAction;
    act_HexData: TAction;
    act_ClearData: TAction;
    act_Configure: TAction;
    act_AutoScroll: TAction;
    act_ShowDetail: TAction;
    act_Exit: TAction;
    pm_ComList: TPopupMenu;
    stat1: TStatusBar;
    tlb2: TToolBar;
    btnSerialSelect1: TToolButton;
    btn7: TToolButton;
    btn8: TToolButton;
    btn11: TToolButton;
    btnSave1: TToolButton;
    btnClearData1: TToolButton;
    btnAutoScroll: TToolButton;
    btn9: TToolButton;
    btnConfigure1: TToolButton;
    btn10: TToolButton;
    btnShowDetail1: TToolButton;
    btn12: TToolButton;
    btnExit1: TToolButton;
    btnStart: TToolButton;
    btnHexData: TToolButton;
    dlgSave1: TSaveDialog;
    mmo_HexData: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure lv1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure act_StartMonitorExecute(Sender: TObject);
    procedure act_HexDataExecute(Sender: TObject);
    procedure act_SaveExecute(Sender: TObject);
    procedure act_ClearDataExecute(Sender: TObject);
    procedure act_AutoScrollExecute(Sender: TObject);
    procedure act_ShowDetailExecute(Sender: TObject);
    procedure act_ExitExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure act_ConfigureExecute(Sender: TObject);
  private
    sSelectPort: string;
    {监控返回的消息处理}
    procedure WM_SpyOpenOrClose(var Msg: TMessage); message WM_SPYCOM_OPEN_OR_CLOSE;
    procedure WM_SpyRead(var Msg: TMessage); message WM_SPYCOM_READ;
    procedure WM_SpyWrite(var Msg: TMessage); message WM_SPYCOM_WRITE;
    procedure WM_SpySetBaudRate(var Msg: TMessage); message WM_SPYCOM_SETBAUDRATE;
    procedure WM_SpySetLineCtl(var Msg: TMessage); message WM_SPYCOM_SETLINECONTROL;

    //构造串口显示数据
    function MakeComDataString(buff: array of Byte; len: Integer): string;

    {添加信息}
    procedure AppendLogStr(sTime, sPort, sEvent, sData: string;
      iDataLen: Integer);

    {开始监控}
    function StartMonitor(sComPort: string): Boolean;
    {停止监控}
    function StopMonitor(): Boolean;

    {构造串口选择菜单}
    procedure MakeComListMenu(Sender: TObject);
    {串口选择菜单事件}
    procedure ComSelectMenuClick(Sender: TObject);

    {将listview数据保存到文件}
    procedure SaveDataToFile(sFile: string);
  public
    { Public declarations }
  end;

  TWatchThread = class(TThread)
  private
    procedure ProcessIOReq(p: pIOReq);
  protected
    procedure Execute; override;
  public
    constructor Create();
  end;

var
  FrmMain: TFrmMain;
  {全局变量}
  ComSpyDriver: string;
  ServiceMan: TServiceMan;
  hDevice: THandle;
  hEvent: THandle;
  myWatchThread: TWatchThread;
  hWnd: THandle;
  pReadBytes, pWriteBytes: PByteArray;
  pRead, pWrite: PByte;
  globHandle: MHANDLE;

  function CheckComFast(var ComList: TStringList): boolean;

implementation

uses SaveDataProgress, SysRunParams;

{$R *.dfm}

{-------------------------------------------------------------------------------
过程名:    CheckComFast    列举所有的串口
作者:      Administrator
日期:      2010.04.17
参数:      var ts: TStrings
返回值:    boolean
-------------------------------------------------------------------------------}
function CheckComFast(var ComList: TStringList): boolean;
var
  reg: TRegistry;
  i,iCount: integer;
  ts: TStrings ;
begin
  result := false;
  reg := TRegistry.Create;
  ts := TStringList.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;// HKEY_LOCAL_MACHINE;
    result := reg.OpenKey('HARDWARE\DEVICEMAP\SERIALCOMM', false);
    if result then
    begin
      reg.GetValueNames(ts);
      iCount := ts.Count ;
      for i := 0 to pred(iCount) do
        ComList.Add(reg.Readstring(ts.strings[i]));
    end
    else
    begin
      for i := 1 to 16 do
        ComList.Add(Format('COM%d',[i]));
    end;
    reg.CloseKey;
    ts.Free;
    reg.free;
  except
    result := false;
    reg.CloseKey;
    ts.Free;
    reg.free;
  end;
end;

{线程构造函数}
constructor TWatchThread.Create();
begin
  inherited Create(False);

  FreeOnTerminate := True;
end;

{线程主体：监控和等待驱动程序事件}
procedure TWatchThread.Execute;
var
	Size,dw: DWORD;
	over: TOVERLAPPED;
  hEvents: array[0..1] of THandle;
  bres, flag: Boolean;
  dres: DWORD;
  nInBufferSize: DWORD;
  p: PByte;

  label GetInfo;
begin
	over.hEvent := CreateEvent(nil,TRUE,FALSE,nil);
	hEvents[0] := over.hEvent;
  hEvents[1] := hEvent;

  nInBufferSize := SizeOf(MHANDLE);

  while (not Terminated) do
  begin
    bres := DeviceIoControl(hDevice,
      IOCTL_SERMON_GETINFOSIZE,
      @GlobHandle,
      SizeOf(MHANDLE),
      @Size,
      SizeOf(Size),
      dw,
      @over);
    if (bres = True) then
    begin
      if ((dw = SizeOf(Size)) and (Size > 0)) then
      begin
        goto GetInfo;
      end;
    end
    else
    begin
      dres := GetLastError();
      if (dres <> ERROR_IO_PENDING) then Break;

      dres := WaitForMultipleObjects(2, @hEvents, False, INFINITE);
      flag := GetOverlappedResult(hDevice, over, dw, False);
      if ((dres = WAIT_OBJECT_0 + 1) or (not flag)) then Break;//close
    end;

GetInfo:

    GetMem(p, Size);
    bres := DeviceIoControl(hDevice,
      IOCTL_SERMON_GETINFO,
      @GlobHandle,
      SizeOf(MHANDLE),
      p,
      Size,
      dw,
      @over);
    if (bres = True) then//request completed
    begin
      ProcessIOReq(pIOReq(p));
      Continue;
    end;
    if (GetLastError <> ERROR_IO_PENDING) then
    begin
      FreeMem(p);
      Break;
    end;

    dres := WaitForMultipleObjects(2, @hEvents, False, INFINITE);
    flag := GetOverlappedResult(hDevice, over, dw, False);
    if ((dres = WAIT_OBJECT_0 + 1) or (not flag)) then //close
    begin
      FreeMem(p);
      Break;
    end;
    
    ProcessIOReq(pIOReq(p));
  end;//end while

  myWatchThread := nil;
end;

{线程内部函数：解析IRP数据包}
procedure TWatchThread.ProcessIOReq(p: pIOReq);
var
  ptr: PByte;
  pbytes: Pointer;
  Size: DWORD;
  _type: Byte;
begin
  _type := p^._type;

  case _type of
    Ord(REQ_OPEN),
    Ord(REQ_CLOSE):
      begin
        SendMessage(hWnd, WM_SPYCOM_OPEN_OR_CLOSE, _type, 0);
      end;
    Ord(REQ_SETBAUDRATE):
      begin
        ptr := PByte(p);
        Inc(ptr, SizeOf(IOReq));
        GetMem(pbytes, SizeOf(DWORD));
        ZeroMemory(pbytes, SizeOf(DWORD));
        CopyMemory(pbytes, ptr, SizeOf(DWORD));
        SendMessage(hWnd, WM_SPYCOM_SETBAUDRATE, DWORD(pbytes), SizeOf(DWORD));
      end;
    Ord(REQ_READ), Ord(REQ_WRITE):
      begin
        ptr := PByte(p);
        Inc(ptr, SizeOf(IOReq));
        Size := p^.SizeCopied;
        GetMem(pbytes, Size);
        ZeroMemory(pbytes, Size);
        CopyMemory(pbytes, ptr, Size);
        if (_type = Ord(REQ_READ)) then
          SendMessage(hWnd, WM_SPYCOM_READ, DWORD(pbytes), Size)
        else
          SendMessage(hWnd, WM_SPYCOM_WRITE, DWORD(pbytes), Size)
      end;
    Ord(REQ_SETLINECONTROL):
      begin
        ptr := PByte(p);
        Inc(ptr, SizeOf(IOReq));
        Size := SizeOf(SERIAL_LINE_CONTROL);
        GetMem(pbytes, Size);
        ZeroMemory(pbytes, Size);
        CopyMemory(pbytes, ptr, Size);
        SendMessage(hWnd, WM_SPYCOM_SETLINECONTROL, DWORD(pbytes), Size);
      end;
  end;

  FreeMem(p);
end;

//构造串口显示数据
function TFrmMain.MakeComDataString(buff: array of Byte; len: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to len - 1 do
  begin
    if Odd(act_HexData.Tag) then//奇数，标识ASC码显示
      Result := Result + Chr(buff[i])
    else
      Result := Result + IntToHex(buff[i], 2) + ' ';
  end;
  Result := Trim(Result);
end;  

{添加信息到listview}
procedure TFrmMain.AppendLogStr(sTime, sPort, sEvent, sData: string; iDataLen: Integer);
var
  listItem: TListItem;
  sLogString: string;
begin
  {自动保存日志文件}
  if P_AutoSaveLogFile then
  begin
    sLogString := Format(LOG_SAVE_FORMAT, [sTime, sPort, sEvent, IntToStr(iDataLen), sData]);
    WriteLogFile(sLogString);
  end;

  {添加到listview显示}
  listItem := lv1.Items.Add;
  with listItem do
  begin
    Caption := sTime;
    SubItems.Add(sPort);
    SubItems.Add(sEvent);
    SubItems.Add(IntToStr(iDataLen));
    SubItems.Add(sData); 
  end;
  if not Odd(act_AutoScroll.Tag) then//判断是否自动滚屏（奇数为手动滚屏）
  begin
    SendMessage(lv1.Handle, { HWND of the Memo Control }
                WM_VSCROLL, { Windows Message }
                SB_PAGEDOWN, { Scroll Command }
                0); { Not Used }
  end;  
end;  

{串口打开或者关闭消息}
procedure TFrmMain.WM_SpyOpenOrClose(var Msg: TMessage);
var
  stime, sport,sevent,sdata: string;
begin
  stime := FormatDateTime('hh:mm:ss', Now);
  sport := sSelectPort;
  case Msg.WParam of
    Ord(REQ_OPEN):
      begin
        sevent := SPY_EVENT_OPEN;
        sdata := sport + ' Opened.';
      end;
    Ord(REQ_CLOSE):
      begin
        sevent := SPY_EVENT_CLOSE;
        sdata := sport + ' Closed.';
      end;
  end;
  AppendLogStr(stime, sport, sevent, sdata, 0);
end;

{串口读取数据消息}
procedure TFrmMain.WM_SpyRead(var Msg: TMessage);
var
  ptr: PByte;
  size: DWORD;
  buffer: array[0..1024] of Byte;
  stime, sport,sevent,sdata: string;
  i: Integer;
begin
  stime := FormatDateTime('hh:mm:ss', Now);
  sport := sSelectPort;

  ptr := pbyte(Msg.WParam);
  size := Msg.LParam;

  if size > High(buffer) then size := High(buffer);
  FillChar(buffer, SizeOf(buffer), 0);
  CopyMemory(@buffer[0], ptr, size);

  FreeMem(ptr, size);

  sevent := SPY_EVENT_READ;
  sdata := MakeComDataString(buffer, size);

  AppendLogStr(stime, sport, sevent, sdata, size);
end;

{串口写入数据消息}
procedure TFrmMain.WM_SpyWrite(var Msg: TMessage);
var
  ptr: PByte;
  size: DWORD;
  buffer: array[0..1024] of Byte;
  stime, sport,sevent,sdata: string;
  i: Integer;
begin
  stime := FormatDateTime('hh:mm:ss', Now);
  sport := sSelectPort;

  ptr := pbyte(Msg.WParam);
  size := Msg.LParam;

  if size > High(buffer) then size := High(buffer);
  FillChar(buffer, SizeOf(buffer), 0);
  CopyMemory(@buffer[0], ptr, size);

  FreeMem(ptr, size);

  sevent := SPY_EVENT_WRITE;
  sdata := MakeComDataString(buffer, size);

  AppendLogStr(stime, sport, sevent, sdata, size);
end;

{串口设置波特率消息}
procedure TFrmMain.WM_SpySetBaudRate(var Msg: TMessage);
var
  baudrate: DWORD;
  stime, sport,sevent,sdata: string;
  p: Pointer;
  size: DWORD;
begin
  p := Pointer(Msg.WParam);
  size := Msg.LParam;
  CopyMemory(@baudrate, p, size);
  FreeMem(p, size);//在此释放内存

  stime := FormatDateTime('hh:mm:ss', Now);
  sport := sSelectPort;
  sevent := SPY_EVENT_OPEN;
  sdata := Format('Baud rate: %d', [baudrate]);

  AppendLogStr(stime, sport, sevent, sdata, 0);
end;

{串口设置（数据位、校验、停止位）消息}
procedure TFrmMain.WM_SpySetLineCtl(var Msg: TMessage);
var
  plinectl: PSERIAL_LINE_CONTROL;
  linectrl: SERIAL_LINE_CONTROL;
  size: DWORD;
  stime, sport,sevent,sdata: string;
begin
  plinectl := PSERIAL_LINE_CONTROL(Msg.WParam);
  size := Msg.LParam;
  CopyMemory(@linectrl, plinectl, size);
  FreeMem(plinectl, size);

  stime := FormatDateTime('hh:mm:ss', Now);
  sport := sSelectPort;
  sevent := SPY_EVENT_OPEN;
  sdata := '';
  case linectrl.Parity of
    NOPARITY: AppendStr(sdata, 'Parity: NONE; ');
    ODDPARITY: AppendStr(sdata, 'Parity: ODD; ');
    EVENPARITY: AppendStr(sdata, 'Parity: EVENT; ');
    MARKPARITY: AppendStr(sdata, 'Parity: MARK; ');
    SPACEPARITY: AppendStr(sdata, 'Parity: SPACE; ');
  end;
  AppendStr(sdata, Format('DataBytes: %d; StopBits: %d',
    [linectrl.WordLength, linectrl.StopBits]));

  AppendLogStr(stime, sport, sevent, sdata, 0);
end;

{主窗口创建事件}
procedure TFrmMain.FormCreate(Sender: TObject);
var
  dwStatus: DWORD;
begin
  hWnd := Self.Handle;

  //driver sys file path
  ComSpyDriver := ExtractFilePath(Application.ExeName) + DRVFILE32;

  //创建服务管理单元
  ServiceMan := TServiceMan.Create;

  hDevice := CreateFile(PChar('\\.\' + SVRNAME),
    GENERIC_READ or GENERIC_WRITE or GENERIC_EXECUTE,
    FILE_SHARE_WRITE or FILE_SHARE_READ,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED,
    0
    );
  if (hDevice = INVALID_HANDLE_VALUE) then // no device
  begin
    //install driver
    dwStatus := ServiceMan.ServiceInstall(SVRNAME, SVRNAME, PChar(ComSpyDriver));
    //start driver
    dwStatus := ServiceMan.ServiceStart(SVRNAME);
    case dwStatus of
      0, 3: //0: no install; 3: start faild;
        begin
          Application.MessageBox('驱动加载异常！', '错误', MB_OK + MB_ICONERROR);
          act_StartMonitor.Visible := False;
          Exit;
        end;
    else
      begin
        hDevice := CreateFile(PChar('\\.\' + SVRNAME),
          GENERIC_READ or GENERIC_WRITE or GENERIC_EXECUTE,
          FILE_SHARE_WRITE or FILE_SHARE_READ,
          nil,
          OPEN_EXISTING,
          FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED,
          0
          );
        if (hDevice = INVALID_HANDLE_VALUE) then // no device
        begin
          Application.MessageBox('打开设备异常！', '错误', MB_OK + MB_ICONERROR);
          act_StartMonitor.Visible := False;
          Exit;
        end;
      end;
    end;
  end;

  {创建事件}
  hEvent := CreateEvent(nil, True, False, nil);

  sSelectPort := '';
end;

{主窗口显示事件}
procedure TFrmMain.FormShow(Sender: TObject);
begin
  mmo_HexData.Lines.Clear;

  grp_Detail.Width := 0;

  MakeComListMenu(Sender);
end;

{主窗口关闭前查询事件}
procedure TFrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  bret: Boolean;
begin
  bret := Application.MessageBox('是否退出系统？', '询问',
    MB_YESNO + MB_ICONQUESTION) = IDYES;

  if bret then
  begin
    if ((hDevice <> INVALID_HANDLE_VALUE) and//服务已经启动
        Odd(act_StartMonitor.Tag)) then//处于监控状态
    begin
      bret := StopMonitor();
      if not bret then
      begin
        Application.MessageBox('停止监控失败，请先关闭已打开的串口！', '异常', MB_ICONERROR);
      end;
    end;
  end;

  CanClose := bret;
end;

{主窗口关闭事件}
procedure TFrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (hDevice <> INVALID_HANDLE_VALUE) then
  begin
    SetEvent(hEvent);
    if Assigned(myWatchThread) then
    begin
      myWatchThread.Terminate();
    end;
    CloseHandle(hDevice);
    CloseHandle(hEvent);
//    ServiceMan.ServiceStop(SVRNAME);
//    ServiceMan.ServiceUnInstall(SVRNAME);
  end;
  ServiceMan.Free;
end;

{构造串口菜单列表}
procedure TFrmMain.MakeComListMenu(Sender: TObject);
var
  i: integer;
  sList: TStringList;
  mItem: TMenuItem;
begin
  sList := TStringList.Create;
  CheckComFast(sList);
  pm_ComList.Items.Clear;

  mItem := TMenuItem.Create(pm_ComList);
  mItem.Caption := '刷新';
  mItem.GroupIndex := 0;
  mItem.OnClick := ComSelectMenuClick;
  pm_ComList.Items.Add(mItem);

  mItem := TMenuItem.Create(pm_ComList);
  mItem.Caption := '-';
  mItem.GroupIndex := 0;
  pm_ComList.Items.Add(mItem);

  for i := 0 to sList.Count - 1 do
  begin
    mItem := TMenuItem.Create(pm_ComList);
    mItem.Caption := sList[i];
    mItem.RadioItem := True;
    mItem.GroupIndex := 1;
    mItem.OnClick := ComSelectMenuClick;
    pm_ComList.Items.Add(mItem);
  end;
  sList.Free;
end;  

{串口菜单点击事件}
procedure TFrmMain.ComSelectMenuClick(Sender: TObject);
var
  sCaption: string;
begin
  with Sender as TMenuItem do
  begin
    sCaption := StripHotkey(Caption);//去掉快捷键
    if sCaption = '刷新' then
    begin
      MakeComListMenu(Self);
    end
    else
    begin
      TMenuItem(Sender).Checked := True;
      sSelectPort := sCaption;
    end;    
  end;  
end;  

{开始监控函数}
function TFrmMain.StartMonitor(sComPort: string): Boolean;
var
  sPort: string;
  sPortArr: array[0..255] of  WideChar;
  dw, size, ilen: DWORD;
begin
  sPort := Format('\??\%s', [sComPort]) + #0;

  //需要把string转换为Unicode string传递给驱动
  ilen := Length(sPort);
  size := SizeOf(WideChar) * ilen;
  FillChar(sPortArr, SizeOf(WideChar)*256, 0);
  StringToWideChar(sPort, @(sPortArr[0]), 256);

  {启动监视}
  Result := DeviceIoControl(hDevice,
    IOCTL_SERMON_STARTMONITOR,
    @sPortArr,
    size,
    @globHandle,
    SizeOf(MHANDLE),
    dw,
    nil);
end;

{停止监控函数}
function TFrmMain.StopMonitor(): Boolean;
var
  dw: DWORD;
begin
  Result := DeviceIoControl(hDevice,
    IOCTL_SERMON_STOPMONITOR,
    @GlobHandle,
    SizeOf(MHANDLE),
    nil,
    0,
    dw,
    nil
    );
end;

{listview点击显示明细数据}
procedure TFrmMain.lv1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  mmo_HexData.Text := Item.SubItems.Strings[3];
end;

{开始监控按钮事件}
procedure TFrmMain.act_StartMonitorExecute(Sender: TObject);
var
  iddlg: DWORD;
  bres: Boolean;
  dw: DWORD;
begin
  if not Odd(act_StartMonitor.Tag) then//判断非奇数（启动监控）
  begin
    if sSelectPort = '' then
    begin
      Application.MessageBox('请选择需要监控的串口！', '错误', MB_ICONERROR);
      Exit;
    end;

    iddlg := Application.MessageBox(PChar('是否开始监控 ' + sSelectPort + ' ？'),
      '询问', MB_YESNO + MB_ICONQUESTION);
    if (iddlg = IDNO) then Exit;

    if (not StartMonitor(sSelectPort)) then
    begin
      Application.MessageBox(
        PChar('启动串口' + sSelectPort + '监测失败，请检查串口是否被其它应用程序打开！'),
        '错误', MB_ICONERROR);
      Exit;
    end;

    {设置事件为无信号}
    ResetEvent(hEvent);

    {创建线程}
    myWatchThread := TWatchThread.Create();

    if not Assigned(myWatchThread) then
    begin
      Application.MessageBox('创建线程失败！', '错误！', MB_ICONERROR);
      Exit;
    end;

    act_StartMonitor.ImageIndex := 2;
    act_StartMonitor.Caption := '停止监控';
    stat1.Panels[0].Text := '串口' + sSelectPort + '监控已启动。';
  end
  else
  begin
    iddlg := Application.MessageBox('必须先停止应用程序才能停止本监控，是否停止？',
      '询问', MB_YESNO + MB_ICONQUESTION);
    if (iddlg = IDNO) then Exit;

    if (not StopMonitor()) then
    begin
      Application.MessageBox('停止监控失败！', '异常', MB_ICONERROR);
      Exit;
    end;

    {设置事件为有信号}
    SetEvent(hEvent);

    if Assigned(myWatchThread) then
    begin
      myWatchThread.Terminate();
    end;

    act_StartMonitor.ImageIndex := 1;
    act_StartMonitor.Caption := '启动监控';
    stat1.Panels[0].Text := '串口' + sSelectPort + '监控已停止！';
  end;

  act_StartMonitor.Tag := act_StartMonitor.Tag + 1;
end;

{HEX显示按钮事件}
procedure TFrmMain.act_HexDataExecute(Sender: TObject);
begin
  act_HexData.Tag := act_HexData.Tag + 1;
  if Odd(act_HexData.Tag) then//奇数
  begin
    act_HexData.Caption := 'ASC显示';
    act_HexData.ImageIndex := 4;
  end
  else
  begin
    act_HexData.Caption := 'HEX显示';
    act_HexData.ImageIndex := 3;
  end;
end;

{将listview数据保存到文件}
procedure TFrmMain.SaveDataToFile(sFile: string);
var
  WindowList: Pointer;
  i, Count: Integer;
  F: TextFile;
  str: string;
  FrmProgress: TFrmSaveProgress;
begin

  FrmProgress := TFrmSaveProgress.Create(Self);

  {除了FrmProgress外使所有窗口无效}
  WindowList := DisableTaskWindows(FrmProgress.Handle);

  Count := lv1.Items.Count;

  FrmProgress.Gauge1.MinValue := 0;
  FrmProgress.Gauge1.MaxValue := Count - 1;

  try
    FrmProgress.Show;

    AssignFile(F, sFile);
    Rewrite(F);//创建新文件，不管是否存在

    //日志标题
    str := Format(LOG_SAVE_FORMAT, ['Time','Port','Event','Bytes','Data']);
    if Odd(act_HexData.Tag) then
      str := str + '(ASC)'
    else
      str := str + '(HEX)';
      
    Writeln(F, str);

    with lv1 do
    begin
      for i := 0 to pred(Count) do
      begin
        FrmProgress.Gauge1.Progress := i;
        str := Format(LOG_SAVE_FORMAT,[lv1.Items[i].Caption,
          lv1.Items[i].SubItems[0], lv1.Items[i].SubItems[1],
          lv1.Items[i].SubItems[2], lv1.Items[i].SubItems[3]]);
        Writeln(F, str);
      end;
    end;
  finally
    CloseFile(F);
    EnableTaskWindows(WindowList);
    FrmProgress.Close;
    FrmProgress.Free;
  end;
end;

{保存数据按钮事件}
procedure TFrmMain.act_SaveExecute(Sender: TObject);
begin
  if dlgSave1.Execute then
  begin
    SaveDataToFile(dlgSave1.FileName); 
  end;  
end;

{清除数据按钮事件}
procedure TFrmMain.act_ClearDataExecute(Sender: TObject);
begin
  lv1.Items.Clear;
  mmo_HexData.Text := '';
end;

{自动滚屏按钮事件}
procedure TFrmMain.act_AutoScrollExecute(Sender: TObject);
begin
  act_AutoScroll.Tag := act_AutoScroll.Tag + 1;
  if Odd(act_AutoScroll.Tag) then
    act_AutoScroll.Caption := '手动滚屏'
  else
    act_AutoScroll.Caption := '自动滚屏';
end;

{显示明细按钮事件}
procedure TFrmMain.act_ShowDetailExecute(Sender: TObject);
begin
  act_ShowDetail.Tag := act_ShowDetail.Tag + 1;
  if Odd(act_ShowDetail.Tag) then//奇数
  begin
    grp_Detail.Width := 200;
    act_ShowDetail.Caption := '隐藏明细';
  end
  else
  begin
    grp_Detail.Width := 0;
    act_ShowDetail.Caption := '显示明细';
  end;
end;

{退出系统按钮事件}
procedure TFrmMain.act_ExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TFrmMain.act_ConfigureExecute(Sender: TObject);
begin
  with TFrmSysSet.Create(Self) do
  begin
    try
      ShowModal;
    finally
      Free;
    end;
  end;  
end;

end.

