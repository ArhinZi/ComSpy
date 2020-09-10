program ComSpyApp;

uses
  Forms,
  SysUtils,
  Main in 'Main.pas' {FrmMain},
  ctr_uint in 'ctr_uint.pas',
  untServiceMan in 'untServiceMan.pas',
  untFunction in 'untFunction.pas',
  SaveDataProgress in 'SaveDataProgress.pas' {FrmSaveProgress},
  GlobUnit in 'GlobUnit.pas',
  SysRunParams in 'SysRunParams.pas' {FrmSysSet};

{$R *.res}

begin
  Application.Initialize;

  {系统运行路经}
  P_SysPath := ExtractFilePath(Application.ExeName);

  {导入配置参数}
  LoadConfigureFromIni();

  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
