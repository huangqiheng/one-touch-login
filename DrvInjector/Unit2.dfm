object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #27880#23556#22120' - '#39537#21160#20860#23481#29256
  ClientHeight = 363
  ClientWidth = 440
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
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 440
    Height = 344
    Align = alClient
    BevelInner = bvLowered
    BevelOuter = bvNone
    TabOrder = 0
    object Panel5: TPanel
      Left = 1
      Top = 1
      Width = 331
      Height = 342
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      object Splitter1: TSplitter
        Left = 0
        Top = 145
        Width = 331
        Height = 8
        Cursor = crVSplit
        Align = alTop
        ExplicitTop = 196
        ExplicitWidth = 368
      end
      object Bevel1: TBevel
        Left = 0
        Top = 39
        Width = 331
        Height = 8
        Align = alTop
        Shape = bsSpacer
        ExplicitWidth = 368
      end
      object HistoryList: TListBox
        Left = 0
        Top = 170
        Width = 331
        Height = 172
        Align = alClient
        Color = clBtnFace
        ItemHeight = 13
        PopupMenu = PopupMenu2
        TabOrder = 0
        OnDblClick = N6Click
      end
      object ToInjectList: TListBox
        Left = 0
        Top = 64
        Width = 331
        Height = 81
        Align = alTop
        ItemHeight = 13
        PopupMenu = PopupMenu1
        TabOrder = 1
        OnMouseUp = ToInjectListMouseUp
      end
      object StaticText1: TStaticText
        Left = 0
        Top = 47
        Width = 331
        Height = 17
        Align = alTop
        Caption = #34987#27880#23556'DLL'#21015#34920#65306
        TabOrder = 2
      end
      object StaticText2: TStaticText
        Left = 0
        Top = 153
        Width = 331
        Height = 17
        Align = alTop
        Caption = #26366#27880#23556#36807#30340'DLL'#65306
        TabOrder = 3
      end
      object StaticText3: TStaticText
        Left = 0
        Top = 0
        Width = 331
        Height = 17
        Align = alTop
        Caption = #27880#23556#30446#26631#65306
        TabOrder = 4
      end
      object Panel2: TPanel
        Left = 0
        Top = 17
        Width = 331
        Height = 22
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 5
        object ComboBox1: TComboBox
          Left = 0
          Top = 0
          Width = 308
          Height = 21
          Align = alClient
          ItemHeight = 13
          TabOrder = 0
          Text = 'ComboBox1'
        end
        object Panel4: TPanel
          Left = 308
          Top = 0
          Width = 23
          Height = 22
          Align = alRight
          BevelInner = bvLowered
          Caption = '...'
          TabOrder = 1
          OnClick = Panel4Click
        end
      end
    end
    object Panel6: TPanel
      Left = 332
      Top = 1
      Width = 107
      Height = 342
      Align = alRight
      BevelKind = bkFlat
      BevelOuter = bvNone
      TabOrder = 1
      object Button2: TButton
        Left = 6
        Top = 264
        Width = 91
        Height = 50
        Caption = #21368#36733#39537#21160
        TabOrder = 0
        OnClick = Button2Click
      end
      object Button1: TButton
        Left = 6
        Top = 60
        Width = 91
        Height = 50
        Caption = #21019#24314#36827#31243
        TabOrder = 2
        OnClick = Button1Click
      end
      object TrackBar1: TTrackBar
        Left = -1
        Top = 110
        Width = 106
        Height = 45
        Max = 30
        Min = 2
        ParentShowHint = False
        Frequency = 2
        Position = 10
        PositionToolTip = ptRight
        ShowHint = True
        ShowSelRange = False
        TabOrder = 3
        OnChange = TrackBar1Change
      end
      object StaticText4: TStaticText
        Left = 22
        Top = 142
        Width = 52
        Height = 17
        Caption = #27880#23556#36229#26102
        TabOrder = 1
      end
      object Button3: TButton
        Left = 6
        Top = 8
        Width = 91
        Height = 50
        Caption = #21551#21160#25195#25551
        TabOrder = 4
        OnClick = Button3Click
      end
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 344
    Width = 440
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
    Left = 168
    Top = 112
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
