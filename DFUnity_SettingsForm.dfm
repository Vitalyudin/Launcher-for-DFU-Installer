object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 333
  ClientWidth = 376
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object LangLabel: TLabel
    Left = 12
    Top = 15
    Width = 100
    Height = 15
    Caption = 'Launcher language:'
  end
  object InstalledLabel: TLabel
    Left = 12
    Top = 88
    Width = 100
    Height = 15
    Caption = 'Installed version:'
  end
  object LatestLabel: TLabel
    Left = 12
    Top = 108
    Width = 100
    Height = 15
    Caption = 'Latest version:'
  end
  object ProgressLabel: TLabel
    Left = 12
    Top = 134
    Width = 352
    Height = 15
    AutoSize = False
  end
  object Separator: TBevel
    Left = 12
    Top = 46
    Width = 352
    Height = 2
    Shape = bsTopLine
  end
  object LangCombo: TComboBox
    Left = 164
    Top = 11
    Width = 200
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    OnChange = LangComboChange
  end
  object AutoCheckBox: TCheckBox
    Left = 12
    Top = 58
    Width = 352
    Height = 19
    Caption = 'Check for updates on startup'
    TabOrder = 1
    OnClick = AutoCheckBoxClick
  end
  object ProgressPanel: TPanel
    Left = 12
    Top = 153
    Width = 352
    Height = 14
    BevelOuter = bvLowered
    Color = clWindow
    ParentBackground = False
    ShowCaption = False
    TabOrder = 2
    object ProgressFill: TPanel
      Left = 1
      Top = 1
      Width = 0
      Height = 12
      Align = alLeft
      BevelOuter = bvNone
      Color = clHighlight
      ParentBackground = False
      ShowCaption = False
      TabOrder = 0
    end
  end
  object LogMemo: TMemo
    Left = 12
    Top = 175
    Width = 352
    Height = 110
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object CheckBut: TButton
    Left = 12
    Top = 295
    Width = 150
    Height = 27
    Caption = 'Check for updates'
    TabOrder = 4
    OnClick = CheckButClick
  end
  object UpdateBut: TButton
    Left = 168
    Top = 295
    Width = 100
    Height = 27
    Caption = 'Update'
    Enabled = False
    TabOrder = 5
    OnClick = UpdateButClick
  end
  object CloseBut: TButton
    Left = 274
    Top = 295
    Width = 90
    Height = 27
    Cancel = True
    Caption = 'Close'
    TabOrder = 6
    OnClick = CloseButClick
  end
end
