unit SysRunParams;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, ComCtrls, ExtCtrls, FileCtrl;

type
  TFrmSysSet = class(TForm)
    pgc1: TPageControl;
    pnl1: TPanel;
    ts1: TTabSheet;
    chk_AutoSaveLog: TCheckBox;
    grp1: TGroupBox;
    lbl1: TLabel;
    edt_LogSavePath: TEdit;
    btn_SelectLogPath: TButton;
    lbl2: TLabel;
    chk_CreatePathForEveryDay: TCheckBox;
    chk_CreateLogFileForEveryHour: TCheckBox;
    chk_AutoClearData: TCheckBox;
    edt_AutoClearByMaxRows: TEdit;
    lbl3: TLabel;
    chk_StartProtocalPlugin: TCheckBox;
    grp2: TGroupBox;
    lbl4: TLabel;
    edt_PluginFile: TEdit;
    btn_SelectPluginFile: TButton;
    btn4: TBitBtn;
    btn5: TBitBtn;
    dlgOpen1: TOpenDialog;
    procedure FormShow(Sender: TObject);
    procedure btn5Click(Sender: TObject);
    procedure btn_SelectLogPathClick(Sender: TObject);
    procedure btn_SelectPluginFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmSysSet: TFrmSysSet;

implementation

uses GlobUnit;

{$R *.dfm}

procedure TFrmSysSet.FormShow(Sender: TObject);
begin
  chk_AutoSaveLog.Checked := P_AutoSaveLogFile;
  edt_LogSavePath.Text := P_LogFileSavePath;
  chk_CreatePathForEveryDay.Checked := P_CreateSubDirForEveryDay;
  chk_CreateLogFileForEveryHour.Checked := P_CreateLogFileForEveryHour;

  chk_AutoClearData.Checked := P_AutoClearDisplayData;
  edt_AutoClearByMaxRows.Text := IntToStr(P_AutoClearByMaxRows);

  chk_StartProtocalPlugin.Checked := P_StartProtocolPlugin;
  edt_PluginFile.Text := P_ProtocolPluginFile;
end;

procedure TFrmSysSet.btn5Click(Sender: TObject);
begin
  P_AutoSaveLogFile := chk_AutoSaveLog.Checked;
  P_LogFileSavePath := edt_LogSavePath.Text;
  P_CreateSubDirForEveryDay := chk_CreatePathForEveryDay.Checked;
  P_CreateLogFileForEveryHour := chk_CreateLogFileForEveryHour.Checked;

  P_AutoClearDisplayData := chk_AutoClearData.Checked;

  if not TryStrToInt(edt_AutoClearByMaxRows.Text, P_AutoClearByMaxRows) then
  begin
    Application.MessageBox('无效的行数！', '错误', MB_ICONERROR);
    Exit;
  end;  

  P_StartProtocolPlugin := chk_StartProtocalPlugin.Checked;
  P_ProtocolPluginFile := edt_PluginFile.Text;

  SaveConfigureToIni();

  ModalResult := mrOk;
end;

procedure TFrmSysSet.btn_SelectLogPathClick(Sender: TObject);
var
  sDir: string;
begin
  if SelectDirectory('选择日志存放目录', P_SysPath,  sDir) then
  begin
    edt_LogSavePath.Text := sDir; 
  end;  
end;

procedure TFrmSysSet.btn_SelectPluginFileClick(Sender: TObject);
begin
  dlgOpen1.Title := '选择解析插件';
  if dlgOpen1.Execute then
    edt_PluginFile.Text := dlgOpen1.FileName;
end;

end.
