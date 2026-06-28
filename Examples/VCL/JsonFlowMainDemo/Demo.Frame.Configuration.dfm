object frameConfiguration: TframeConfiguration
  Left = 0
  Top = 0
  Width = 280
  Height = 350
  TabOrder = 0
  object grpOptions: TGroupBox
    Left = 8
    Top = 8
    Width = 264
    Height = 334
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = ' Serializer Settings '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object lblDateTimeFormat: TLabel
      Left = 16
      Top = 135
      Width = 98
      Height = 15
      Caption = 'DateTime Format:'
    end
    object lblFloatFormat: TLabel
      Left = 16
      Top = 195
      Width = 71
      Height = 15
      Caption = 'Float Format:'
    end
    object lblMaxDepth: TLabel
      Left = 16
      Top = 255
      Width = 60
      Height = 15
      Caption = 'Max Depth:'
    end
    object chkProcessAttributes: TCheckBox
      Left = 16
      Top = 32
      Width = 230
      Height = 24
      Caption = 'Process Attributes'
      TabOrder = 0
    end
    object chkIgnoreNullValues: TCheckBox
      Left = 16
      Top = 64
      Width = 230
      Height = 24
      Caption = 'Ignore Null Values'
      TabOrder = 1
    end
    object chkDetectCircularRefs: TCheckBox
      Left = 16
      Top = 96
      Width = 230
      Height = 24
      Caption = 'Detect Circular References'
      TabOrder = 2
    end
    object edtDateTimeFormat: TEdit
      Left = 16
      Top = 156
      Width = 230
      Height = 23
      TabOrder = 3
      Text = 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"'
    end
    object edtFloatFormat: TEdit
      Left = 16
      Top = 216
      Width = 230
      Height = 23
      TabOrder = 4
      Text = '0.##########'
    end
    object edtMaxDepth: TEdit
      Left = 16
      Top = 276
      Width = 230
      Height = 23
      TabOrder = 5
      Text = '100'
    end
  end
end
