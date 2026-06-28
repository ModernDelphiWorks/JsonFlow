object frmBenchmark: TfrmBenchmark
  Left = 0
  Top = 0
  Caption = 'Delphi JSON Benchmarks'
  ClientHeight = 600
  ClientWidth = 880
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Size = 9
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 14
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    Color = $00F5F5F5
    ParentBackground = False
    ParentColor = False
    TabOrder = 0
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
    object lblStatus: TLabel
      Left = 572
      Top = 19
      Width = 300
      Height = 14
      Caption = 'Click "Start Benchmarks" to begin'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
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
    object pnlLogo: TPanel
      Left = 0
      Top = 0
      Width = 195
      Height = 150
      Align = alLeft
      BevelOuter = bvNone
      Color = $00201510
      ParentBackground = False
      ParentColor = False
      TabOrder = 0
      object lblJson: TLabel
        Left = 14
        Top = 22
        Width = 170
        Height = 50
        Caption = 'json'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -37
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblFlow: TLabel
        Left = 14
        Top = 76
        Width = 170
        Height = 42
        Caption = 'Flow'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = $0066FF44
        Font.Height = -31
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSub: TLabel
        Left = 12
        Top = 130
        Width = 175
        Height = 14
        Caption = 'serialization library'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clSilver
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object memResults: TMemo
      Left = 195
      Top = 0
      Width = 685
      Height = 150
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Size = 9
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 1
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
    ParentColor = False
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
