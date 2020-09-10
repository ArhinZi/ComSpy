object FrmSysSet: TFrmSysSet
  Left = 304
  Top = 232
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #31995#32479#36816#34892#21442#25968
  ClientHeight = 329
  ClientWidth = 633
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #26032#23435#20307
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
  object pgc1: TPageControl
    Left = 0
    Top = 0
    Width = 633
    Height = 288
    ActivePage = ts1
    Align = alClient
    TabOrder = 0
    object ts1: TTabSheet
      Caption = #22522#26412#36816#34892#21442#25968
      object lbl3: TLabel
        Left = 275
        Top = 129
        Width = 24
        Height = 12
        Caption = #34892#12290
      end
      object chk_AutoSaveLog: TCheckBox
        Left = 8
        Top = 8
        Width = 281
        Height = 17
        Caption = #33258#21160#20445#23384#26085#24535#65288#40664#35748#20197#24180#26376#26085#20026#25991#20214#21517#65289#65306
        TabOrder = 0
      end
      object grp1: TGroupBox
        Left = 8
        Top = 32
        Width = 609
        Height = 80
        Caption = #20445#23384#21442#25968#65306
        TabOrder = 1
        object lbl1: TLabel
          Left = 11
          Top = 24
          Width = 84
          Height = 12
          Caption = #26085#24535#23384#25918#30446#24405#65306
        end
        object lbl2: TLabel
          Left = 11
          Top = 52
          Width = 108
          Height = 12
          Caption = #26085#24535#25991#20214#20135#29983#35268#21017#65306
        end
        object edt_LogSavePath: TEdit
          Left = 96
          Top = 22
          Width = 481
          Height = 20
          ReadOnly = True
          TabOrder = 0
        end
        object btn_SelectLogPath: TButton
          Left = 577
          Top = 22
          Width = 26
          Height = 20
          Caption = #8230
          TabOrder = 1
          OnClick = btn_SelectLogPathClick
        end
        object chk_CreatePathForEveryDay: TCheckBox
          Left = 120
          Top = 50
          Width = 129
          Height = 17
          Caption = #27599#22825#24314#31435#19968#20010#23376#30446#24405
          TabOrder = 2
        end
        object chk_CreateLogFileForEveryHour: TCheckBox
          Left = 256
          Top = 50
          Width = 161
          Height = 17
          Caption = #27599#23567#26102#29983#25104#19968#20010#26085#24535#25991#20214
          TabOrder = 3
        end
      end
      object chk_AutoClearData: TCheckBox
        Left = 8
        Top = 128
        Width = 192
        Height = 17
        Caption = #33258#21160#28165#38500#26174#31034#30028#38754#20869#23481#65292#26465#20214#8805
        TabOrder = 2
      end
      object edt_AutoClearByMaxRows: TEdit
        Left = 201
        Top = 126
        Width = 72
        Height = 20
        TabOrder = 3
      end
      object chk_StartProtocalPlugin: TCheckBox
        Left = 8
        Top = 160
        Width = 169
        Height = 17
        Caption = #21551#29992#20018#21475#25968#25454#35299#26512#25554#20214#65306
        TabOrder = 4
      end
      object grp2: TGroupBox
        Left = 8
        Top = 191
        Width = 609
        Height = 58
        Caption = #20018#21475#21327#35758#25554#20214#35774#32622#65306
        TabOrder = 5
        object lbl4: TLabel
          Left = 11
          Top = 24
          Width = 84
          Height = 12
          Caption = #21327#35758#35299#26512#27169#26495#65306
        end
        object edt_PluginFile: TEdit
          Left = 96
          Top = 22
          Width = 481
          Height = 20
          ReadOnly = True
          TabOrder = 0
        end
        object btn_SelectPluginFile: TButton
          Left = 577
          Top = 22
          Width = 26
          Height = 20
          Caption = #8230
          TabOrder = 1
          OnClick = btn_SelectPluginFileClick
        end
      end
    end
  end
  object pnl1: TPanel
    Left = 0
    Top = 288
    Width = 633
    Height = 41
    Align = alBottom
    BevelInner = bvLowered
    TabOrder = 1
    object btn4: TBitBtn
      Left = 540
      Top = 8
      Width = 75
      Height = 25
      Caption = #21462#28040'(&C)'
      TabOrder = 0
      Kind = bkCancel
    end
    object btn5: TBitBtn
      Left = 448
      Top = 8
      Width = 75
      Height = 25
      Caption = #30830#23450'(&S)'
      Default = True
      TabOrder = 1
      OnClick = btn5Click
      Glyph.Data = {
        DE010000424DDE01000000000000760000002800000024000000120000000100
        0400000000006801000000000000000000001000000000000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
        3333333333333333333333330000333333333333333333333333F33333333333
        00003333344333333333333333388F3333333333000033334224333333333333
        338338F3333333330000333422224333333333333833338F3333333300003342
        222224333333333383333338F3333333000034222A22224333333338F338F333
        8F33333300003222A3A2224333333338F3838F338F33333300003A2A333A2224
        33333338F83338F338F33333000033A33333A222433333338333338F338F3333
        0000333333333A222433333333333338F338F33300003333333333A222433333
        333333338F338F33000033333333333A222433333333333338F338F300003333
        33333333A222433333333333338F338F00003333333333333A22433333333333
        3338F38F000033333333333333A223333333333333338F830000333333333333
        333A333333333333333338330000333333333333333333333333333333333333
        0000}
      NumGlyphs = 2
    end
  end
  object dlgOpen1: TOpenDialog
    DefaultExt = 'pas'
    Filter = 'Pascal'#25991#20214'|*.pas'
    Left = 212
    Top = 262
  end
end
