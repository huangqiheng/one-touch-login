object Form3: TForm3
  Left = 0
  Top = 0
  Caption = #26032#36827#31243#21019#24314#25552#31034
  ClientHeight = 231
  ClientWidth = 308
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ListBox1: TListBox
    Left = 0
    Top = 0
    Width = 308
    Height = 176
    Align = alClient
    ItemHeight = 13
    PopupMenu = PopupMenu1
    TabOrder = 0
    OnDblClick = ListBox1DblClick
    OnMouseUp = ListBox1MouseUp
  end
  object Panel1: TPanel
    Left = 0
    Top = 196
    Width = 308
    Height = 35
    Align = alBottom
    BevelOuter = bvLowered
    TabOrder = 1
    object Label1: TLabel
      Left = 10
      Top = 11
      Width = 84
      Height = 13
      Caption = 'SpyCodeSize =  ?'
    end
    object Button1: TButton
      Left = 143
      Top = 6
      Width = 75
      Height = 25
      Caption = #26356#26032#21015#34920
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 224
      Top = 6
      Width = 75
      Height = 25
      Caption = #21368#36733#39537#21160
      TabOrder = 1
      OnClick = Button2Click
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 176
    Width = 308
    Height = 20
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object StaticText1: TStaticText
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 81
      Height = 14
      Align = alLeft
      Caption = #35201#27880#20837#30340'DLL'#65306
      TabOrder = 0
    end
    object ComboBox1: TComboBox
      Left = 87
      Top = 0
      Width = 201
      Height = 21
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
    end
    object Button3: TButton
      Left = 288
      Top = 0
      Width = 20
      Height = 20
      Align = alRight
      Caption = '...'
      TabOrder = 2
      OnClick = Button3Click
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 128
    Top = 24
    object N1: TMenuItem
      Caption = #28155#21152
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #21024#38500
      OnClick = N2Click
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 256
    Top = 16
  end
end
