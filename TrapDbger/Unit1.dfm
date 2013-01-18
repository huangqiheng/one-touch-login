object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 487
  ClientWidth = 603
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 464
    Top = 0
    Height = 487
    Align = alRight
    ExplicitLeft = 224
    ExplicitTop = 152
    ExplicitHeight = 100
  end
  object Panel1: TPanel
    Left = 467
    Top = 0
    Width = 136
    Height = 487
    Align = alRight
    TabOrder = 0
    object Memo2: TMemo
      Left = 1
      Top = 1
      Width = 134
      Height = 217
      Align = alTop
      Lines.Strings = (
        'Memo2')
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object Memo3: TMemo
      Left = 1
      Top = 218
      Width = 134
      Height = 268
      Align = alClient
      Lines.Strings = (
        'Memo3')
      ScrollBars = ssVertical
      TabOrder = 1
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 464
    Height = 487
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    object Splitter2: TSplitter
      Left = 1
      Top = 382
      Width = 462
      Height = 3
      Cursor = crVSplit
      Align = alBottom
      ExplicitLeft = 0
      ExplicitTop = 391
      ExplicitWidth = 425
    end
    object Splitter3: TSplitter
      Left = 1
      Top = 292
      Width = 462
      Height = 4
      Cursor = crVSplit
      Align = alBottom
      ExplicitTop = 301
      ExplicitWidth = 425
    end
    object Panel3: TPanel
      Left = 1
      Top = 347
      Width = 462
      Height = 35
      Align = alBottom
      TabOrder = 0
      object Button1: TButton
        Left = 63
        Top = 6
        Width = 50
        Height = 25
        Caption = 'run code'
        TabOrder = 0
        OnClick = Button1Click
      end
      object Button2: TButton
        Left = 114
        Top = 6
        Width = 72
        Height = 25
        Caption = 'makeJmpTrap'
        TabOrder = 1
        OnClick = Button2Click
      end
      object Button3: TButton
        Left = 227
        Top = 6
        Width = 34
        Height = 25
        Caption = #27493#36807
        TabOrder = 2
        OnClick = Button3Click
      end
      object Button4: TButton
        Left = 8
        Top = 6
        Width = 49
        Height = 25
        Caption = 'Button4'
        TabOrder = 3
        OnClick = Button4Click
      end
      object Button5: TButton
        Left = 299
        Top = 6
        Width = 66
        Height = 25
        Caption = #36816#34892#21040#36820#22238
        TabOrder = 4
        OnClick = Button5Click
      end
      object Button6: TButton
        Left = 263
        Top = 6
        Width = 34
        Height = 25
        Caption = #36816#34892
        TabOrder = 5
        OnClick = Button6Click
      end
      object Button7: TButton
        Left = 195
        Top = 6
        Width = 30
        Height = 25
        Caption = #27493#20837
        TabOrder = 6
        OnClick = Button7Click
      end
      object Button8: TButton
        Left = 367
        Top = 6
        Width = 69
        Height = 25
        Caption = #36816#34892#21040#22320#22336
        TabOrder = 7
        OnClick = Button8Click
      end
    end
    object Memo1: TMemo
      Left = 1
      Top = 385
      Width = 462
      Height = 101
      Align = alBottom
      Lines.Strings = (
        'Memo1')
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object ListBox1: TListBox
      Left = 1
      Top = 1
      Width = 462
      Height = 291
      Style = lbOwnerDrawVariable
      Align = alClient
      ItemHeight = 13
      TabOrder = 2
      OnDrawItem = ListBox1DrawItem
      OnKeyPress = ListBox1KeyPress
    end
    object Memo4: TMemo
      Left = 1
      Top = 296
      Width = 462
      Height = 51
      Align = alBottom
      Lines.Strings = (
        'Memo4')
      TabOrder = 3
    end
    object Button9: TButton
      Left = 328
      Top = 244
      Width = 37
      Height = 25
      Caption = '<<<'
      TabOrder = 4
      OnClick = Button9Click
    end
    object Button10: TButton
      Left = 367
      Top = 244
      Width = 36
      Height = 25
      Caption = '>>>'
      TabOrder = 5
      OnClick = Button10Click
    end
  end
  object ApplicationEvents1: TApplicationEvents
    OnShortCut = ApplicationEvents1ShortCut
    Left = 160
    Top = 184
  end
end
