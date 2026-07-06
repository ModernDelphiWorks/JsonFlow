object frmBenchmark: TfrmBenchmark
  Left = 0
  Top = 0
  Caption = 'Delphi JSON Benchmarks - JsonFlow vs X-SuperObject'
  ClientHeight = 600
  ClientWidth = 880
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    Color = clWhitesmoke
    ParentBackground = False
    TabOrder = 0
    object lblStatus: TLabel
      Left = 572
      Top = 19
      Width = 171
      Height = 13
      Caption = 'Click "Start Benchmarks" to begin'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object rdSimple: TRadioButton
      Left = 10
      Top = 17
      Width = 95
      Height = 18
      Caption = 'Simple Class'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object rdComplex: TRadioButton
      Left = 112
      Top = 17
      Width = 113
      Height = 18
      Caption = 'Complex Class'
      TabOrder = 1
    end
    object chkSave: TCheckBox
      Left = 232
      Top = 17
      Width = 190
      Height = 18
      Caption = 'Save Results (takes much longer)'
      TabOrder = 2
    end
    object btnStart: TButton
      Left = 432
      Top = 13
      Width = 130
      Height = 26
      Caption = 'Start Benchmarks'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnStartClick
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 450
    Width = 880
    Height = 150
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object imgLogo: TImage
      Left = 0
      Top = 0
      Width = 195
      Height = 150
      Align = alLeft
      Center = True
      Proportional = True
      Stretch = True
    end
    object memResults: TMemo
      Left = 195
      Top = 0
      Width = 685
      Height = 150
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object pnlCharts: TPanel
    Left = 0
    Top = 52
    Width = 880
    Height = 398
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 2
    object pnlChartLeft: TPanel
      Left = 0
      Top = 0
      Width = 440
      Height = 398
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
    end
    object pnlChartRight: TPanel
      Left = 440
      Top = 0
      Width = 440
      Height = 398
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
    end
  end
end
