object Form6: TForm6
  Left = 0
  Top = 0
  Caption = #20989#25968#35843#29992#32467#26500
  ClientHeight = 456
  ClientWidth = 591
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
  object Splitter1: TSplitter
    Left = 185
    Top = 0
    Height = 456
    ExplicitLeft = 232
    ExplicitTop = 8
    ExplicitHeight = 427
  end
  object Splitter2: TSplitter
    Left = 403
    Top = 0
    Height = 456
    Align = alRight
    ExplicitLeft = 280
    ExplicitTop = 280
    ExplicitHeight = 100
  end
  object Panel1: TPanel
    Left = 406
    Top = 0
    Width = 185
    Height = 456
    Align = alRight
    TabOrder = 0
    object Splitter3: TSplitter
      Left = 1
      Top = 187
      Width = 183
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitLeft = 0
      ExplicitTop = 169
      ExplicitWidth = 258
    end
    object ListBox2: TListBox
      Left = 1
      Top = 18
      Width = 183
      Height = 169
      Align = alTop
      ItemHeight = 13
      TabOrder = 0
      OnClick = ListBox2Click
      OnDblClick = ListBox2DblClick
    end
    object ListBox4: TListBox
      Left = 1
      Top = 190
      Width = 183
      Height = 265
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
    end
    object StaticText2: TStaticText
      Left = 1
      Top = 1
      Width = 183
      Height = 17
      Align = alTop
      Alignment = taCenter
      Caption = 'Call to list:'
      TabOrder = 2
      ExplicitWidth = 54
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 456
    Align = alLeft
    TabOrder = 1
    object Splitter4: TSplitter
      Left = 1
      Top = 187
      Width = 183
      Height = 3
      Cursor = crVSplit
      Align = alTop
      ExplicitLeft = 0
      ExplicitTop = 169
      ExplicitWidth = 258
    end
    object ListBox1: TListBox
      Left = 1
      Top = 18
      Width = 183
      Height = 169
      Align = alTop
      ItemHeight = 13
      TabOrder = 0
      OnClick = ListBox1Click
      OnDblClick = ListBox1DblClick
    end
    object ListBox5: TListBox
      Left = 1
      Top = 190
      Width = 183
      Height = 265
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
    end
    object StaticText1: TStaticText
      Left = 1
      Top = 1
      Width = 183
      Height = 17
      Align = alTop
      Alignment = taCenter
      Caption = 'Call from list:'
      TabOrder = 2
      ExplicitWidth = 66
    end
  end
  object Panel3: TPanel
    Left = 188
    Top = 0
    Width = 215
    Height = 456
    Align = alClient
    TabOrder = 2
    object StaticText3: TStaticText
      Left = 1
      Top = 1
      Width = 74
      Height = 17
      Align = alTop
      Alignment = taCenter
      Caption = 'function body:'
      TabOrder = 0
    end
    object ListBox3: TListBox
      Left = 1
      Top = 18
      Width = 213
      Height = 437
      Align = alClient
      ItemHeight = 13
      PopupMenu = PopupMenu1
      TabOrder = 1
    end
    object Button1: TButton
      Left = 87
      Top = 328
      Width = 75
      Height = 25
      Caption = 'Button1'
      TabOrder = 2
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 87
      Top = 359
      Width = 75
      Height = 25
      Caption = 'Button2'
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 87
      Top = 390
      Width = 75
      Height = 25
      Caption = 'Button3'
      TabOrder = 4
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 87
      Top = 421
      Width = 75
      Height = 25
      Caption = 'Button4'
      TabOrder = 5
      OnClick = Button4Click
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 296
    Top = 160
    object N1: TMenuItem
      Caption = #20837#21475
    end
    object N2: TMenuItem
      Caption = #36339#21040
      OnClick = N2Click
    end
  end
end
