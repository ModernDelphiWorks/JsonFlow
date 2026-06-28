object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'JsonFlow - Premium Serialization Demo'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clWindow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlSidebar: TPanel
    Left = 0
    Top = 0
    Width = 180
    Height = 600
    Align = alLeft
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 0
    object pnlLogo: TPanel
      Left = 0
      Top = 0
      Width = 180
      Height = 70
      Align = alTop
      BevelOuter = bvNone
      Caption = 'JsonFlow VCL'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 12615680
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object btnSimple: TButton
      Left = 10
      Top = 90
      Width = 160
      Height = 40
      Caption = 'Simple Types'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = btnSimpleClick
    end
    object btnRecords: TButton
      Left = 10
      Top = 140
      Width = 160
      Height = 40
      Caption = 'Records && Sets'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnRecordsClick
    end
    object btnComplex: TButton
      Left = 10
      Top = 190
      Width = 160
      Height = 40
      Caption = 'Complex Objects'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnComplexClick
    end
    object btnDelphi: TButton
      Left = 10
      Top = 240
      Width = 160
      Height = 40
      Caption = 'Delphi Types'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnClick = btnDelphiClick
    end
    object btnDataSet: TButton
      Left = 10
      Top = 290
      Width = 160
      Height = 40
      Caption = 'DataSets'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = btnDataSetClick
    end
    object btnCustomTypes: TButton
      Left = 10
      Top = 340
      Width = 160
      Height = 40
      Caption = 'Custom Types'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      OnClick = btnCustomTypesClick
    end
    object btnValidation: TButton
      Left = 10
      Top = 390
      Width = 160
      Height = 40
      Caption = 'Schema Validation'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnClick = btnValidationClick
    end
  end
  object pnlRight: TPanel
    Left = 180
    Top = 0
    Width = 820
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object pnlTopBar: TPanel
      Left = 0
      Top = 0
      Width = 820
      Height = 70
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblTitle: TLabel
        Left = 20
        Top = 20
        Width = 328
        Height = 25
        Caption = 'Scenario: Simple Serialization'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3355443
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
    object pnlConfigParent: TPanel
      Left = 0
      Top = 70
      Width = 285
      Height = 530
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 1
      inline frameConfig: TframeConfiguration
        Left = 0
        Top = 0
        Width = 285
        Height = 530
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 285
        ExplicitHeight = 530
        inherited grpOptions: TGroupBox
          Width = 269
          Height = 514
          ExplicitWidth = 269
          ExplicitHeight = 514
        end
      end
    end
    object pnlContent: TPanel
      Left = 285
      Top = 70
      Width = 535
      Height = 530
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object pnlVisual: TPanel
        Left = 295
        Top = 0
        Width = 240
        Height = 530
        Align = alRight
        BevelOuter = bvNone
        Color = 15790320
        ParentBackground = False
        TabOrder = 0
        object lblVisualTitle: TLabel
          AlignWithMargins = True
          Left = 5
          Top = 10
          Width = 230
          Height = 20
          Margins.Left = 5
          Margins.Top = 10
          Margins.Right = 5
          Margins.Bottom = 10
          Align = alTop
          Alignment = taCenter
          Caption = 'Visual Schema / Diff'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitWidth = 143
        end
        object lblImageStatus: TLabel
          Left = 0
          Top = 500
          Width = 240
          Height = 30
          Align = alBottom
          Alignment = taCenter
          Caption = 'Visual diff status: Ready'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Layout = tlCenter
          ExplicitWidth = 113
        end
        object pnlImageContainer: TPanel
          Left = 10
          Top = 40
          Width = 220
          Height = 450
          Align = alClient
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          object imgVisual: TImage
            Left = 0
            Top = 0
            Width = 220
            Height = 450
            Align = alClient
            Center = True
            Proportional = True
            ExplicitLeft = 32
            ExplicitTop = 80
            ExplicitWidth = 105
            ExplicitHeight = 105
          end
        end
      end
      object pnlJSONPanel: TPanel
        Left = 0
        Top = 0
        Width = 295
        Height = 530
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object pnlActions: TPanel
          Left = 0
          Top = 0
          Width = 295
          Height = 50
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object btnSerialize: TButton
            Left = 6
            Top = 10
            Width = 90
            Height = 30
            Caption = 'Serialize'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 0
            OnClick = btnSerializeClick
          end
          object btnDeserialize: TButton
            Left = 102
            Top = 10
            Width = 90
            Height = 30
            Caption = 'Deserialize'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 1
            OnClick = btnDeserializeClick
          end
          object btnValidate: TButton
            Left = 198
            Top = 10
            Width = 90
            Height = 30
            Caption = 'Validate'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 2
            OnClick = btnValidateClick
          end
        end
        object memJSON: TMemo
          Left = 0
          Top = 50
          Width = 295
          Height = 480
          Align = alClient
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
    end
  end
end
