object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #27880#23556#22120' - '#39537#21160#29256
  ClientHeight = 385
  ClientWidth = 455
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 455
    Height = 22
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object ComboBox1: TComboBox
      Left = 105
      Top = 0
      Width = 327
      Height = 21
      Align = alClient
      ItemHeight = 13
      TabOrder = 0
      Text = 'ComboBox1'
    end
    object Panel4: TPanel
      Left = 432
      Top = 0
      Width = 23
      Height = 22
      Align = alRight
      BevelKind = bkFlat
      Caption = '...'
      TabOrder = 1
      OnClick = Panel4Click
    end
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 105
      Height = 22
      Align = alLeft
      BevelOuter = bvNone
      Caption = #27880#23556#30446#26631#65306
      TabOrder = 2
      OnDblClick = Panel4Click
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 22
    Width = 455
    Height = 344
    Align = alClient
    BevelInner = bvLowered
    BevelOuter = bvNone
    TabOrder = 1
    object Panel5: TPanel
      Left = 105
      Top = 1
      Width = 349
      Height = 342
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      object Splitter1: TSplitter
        Left = 0
        Top = 129
        Width = 349
        Height = 5
        Cursor = crVSplit
        Align = alTop
      end
      object HistoryList: TListBox
        Left = 0
        Top = 134
        Width = 349
        Height = 208
        Align = alClient
        Color = clBtnFace
        ItemHeight = 13
        PopupMenu = PopupMenu2
        TabOrder = 0
        OnDblClick = N6Click
      end
      object ToInjectList: TListBox
        Left = 0
        Top = 0
        Width = 349
        Height = 129
        Align = alTop
        ItemHeight = 13
        PopupMenu = PopupMenu1
        TabOrder = 1
        OnMouseUp = ToInjectListMouseUp
      end
    end
    object Panel6: TPanel
      Left = 1
      Top = 1
      Width = 104
      Height = 342
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 1
      object StaticText1: TStaticText
        Left = 9
        Top = 13
        Width = 93
        Height = 17
        Caption = #34987#27880#23556'DLL'#21015#34920#65306
        TabOrder = 0
      end
      object StaticText2: TStaticText
        Left = 11
        Top = 152
        Width = 93
        Height = 17
        Caption = #26366#27880#23556#36807#30340'DLL'#65306
        TabOrder = 1
      end
      object Button1: TButton
        Left = 9
        Top = 34
        Width = 87
        Height = 64
        Caption = #27880#23556
        TabOrder = 2
        OnClick = Button1Click
      end
      object TrackBar1: TTrackBar
        Left = 2
        Top = 98
        Width = 101
        Height = 45
        Max = 30
        Min = 2
        ParentShowHint = False
        Frequency = 2
        Position = 10
        ShowHint = True
        TabOrder = 3
        OnChange = TrackBar1Change
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 366
    Width = 455
    Height = 19
    Panels = <
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object OpenDialog1: TOpenDialog
    Left = 256
    Top = 56
  end
  object PopupMenu1: TPopupMenu
    Left = 344
    Top = 96
    object N1: TMenuItem
      Caption = #28155#21152
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #21024#38500
      OnClick = N2Click
    end
    object N3: TMenuItem
      Caption = #28165#31354
      OnClick = N3Click
    end
    object N4: TMenuItem
      Caption = #19978#31227
      OnClick = N4Click
    end
    object N5: TMenuItem
      Caption = #19979#31227
      OnClick = N5Click
    end
  end
  object PopupMenu2: TPopupMenu
    Left = 272
    Top = 232
    object N6: TMenuItem
      Caption = #28155#21152#21040#27880#23556#21015#34920
      OnClick = N6Click
    end
    object N7: TMenuItem
      Caption = #21024#38500
      OnClick = N7Click
    end
  end
end
