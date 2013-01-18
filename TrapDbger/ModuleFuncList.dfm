object ApiListForm: TApiListForm
  Left = 0
  Top = 0
  Caption = #27169#22359#21015#34920'-'#36755#20986#20989#25968#31383#21475
  ClientHeight = 393
  ClientWidth = 356
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Visible = True
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ListBox1: TListBox
    Left = 0
    Top = 21
    Width = 356
    Height = 372
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemHeight = 13
    ParentFont = False
    PopupMenu = PopupMenu1
    TabOrder = 0
  end
  object ComboBox1: TComboBox
    Left = 0
    Top = 0
    Width = 356
    Height = 21
    Align = alTop
    Style = csDropDownList
    DropDownCount = 24
    ItemHeight = 13
    TabOrder = 1
    OnSelect = ComboBox1Select
  end
  object PopupMenu1: TPopupMenu
    Left = 184
    Top = 160
    object N3: TMenuItem
      Caption = #35774#32622#26029#28857
      OnClick = N3Click
    end
    object N1: TMenuItem
      Caption = #21047#26032#27169#22359#21015#34920
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #36873#25321#23383#20307
      OnClick = N2Click
    end
    object N4: TMenuItem
      Caption = #26597#30475#35843#29992#32467#26500
      OnClick = N4Click
    end
  end
  object FontDialog1: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Left = 200
    Top = 216
  end
end
