unit SaveDataProgress;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Gauges, StdCtrls;

type
  TFrmSaveProgress = class(TForm)
    lbl1: TLabel;
    Gauge1: TGauge;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmSaveProgress: TFrmSaveProgress;

implementation

{$R *.dfm}

end.
