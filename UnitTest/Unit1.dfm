object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 488
  ClientWidth = 564
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 207
    Width = 564
    Height = 10
    Cursor = crVSplit
    Align = alTop
    ExplicitTop = 200
    ExplicitWidth = 508
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 564
    Height = 207
    Align = alTop
    Caption = 'Panel1'
    TabOrder = 0
    ExplicitWidth = 610
    object Button1: TButton
      Left = 152
      Top = 152
      Width = 75
      Height = 25
      Caption = #29983#25104'SpyCode'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 247
      Top = 152
      Width = 75
      Height = 25
      Caption = #21152#36733'SpyCoce'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 240
      Top = 112
      Width = 75
      Height = 25
      Caption = 'Button3'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 80
      Top = 72
      Width = 75
      Height = 25
      Caption = 'Button4'
      TabOrder = 3
    end
    object Button5: TButton
      Left = 280
      Top = 48
      Width = 75
      Height = 25
      Caption = 'Button5'
      TabOrder = 4
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 392
      Top = 152
      Width = 75
      Height = 25
      Caption = 'Button6'
      TabOrder = 5
    end
    object Button7: TButton
      Left = 32
      Top = 152
      Width = 75
      Height = 25
      Caption = 'Button7'
      TabOrder = 6
      OnClick = Button7Click
    end
    object Edit1: TEdit
      Left = 48
      Top = 24
      Width = 307
      Height = 21
      TabOrder = 7
      Text = 'Edit1'
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 217
    Width = 564
    Height = 271
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    ExplicitWidth = 610
    ExplicitHeight = 401
    object ListBox1: TListBox
      Left = 1
      Top = 1
      Width = 562
      Height = 188
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'System'
      Font.Pitch = fpFixed
      Font.Style = []
      ItemHeight = 16
      ParentFont = False
      TabOrder = 0
      OnClick = ListBox1Click
      ExplicitWidth = 608
      ExplicitHeight = 318
    end
    object Panel3: TPanel
      Left = 1
      Top = 189
      Width = 562
      Height = 81
      Align = alBottom
      TabOrder = 1
      ExplicitTop = 319
      ExplicitWidth = 608
      object Button8: TButton
        Left = 216
        Top = 6
        Width = 91
        Height = 25
        Caption = 'ntoskrnl.exe'
        TabOrder = 0
        OnClick = Button8Click
      end
      object Button9: TButton
        Left = 313
        Top = 6
        Width = 89
        Height = 25
        Caption = 'ntkrnlpa.exe'
        TabOrder = 1
        OnClick = Button9Click
      end
      object Edit2: TEdit
        Left = 464
        Top = 6
        Width = 121
        Height = 21
        TabOrder = 2
        Text = 'Edit2'
      end
      object Edit3: TEdit
        Left = 16
        Top = 8
        Width = 194
        Height = 21
        TabOrder = 3
        Text = 'Edit3'
      end
      object Button10: TButton
        Left = 510
        Top = 33
        Width = 75
        Height = 25
        Caption = 'addr to name'
        TabOrder = 4
        OnClick = Button10Click
      end
      object Edit4: TEdit
        Left = 97
        Top = 37
        Width = 121
        Height = 21
        TabOrder = 5
        Text = 'Edit4'
      end
      object Edit5: TEdit
        Left = 383
        Top = 37
        Width = 121
        Height = 21
        TabOrder = 6
        Text = 'Edit5'
      end
      object Button11: TButton
        Left = 16
        Top = 35
        Width = 75
        Height = 25
        Caption = 'name to addr'
        TabOrder = 7
        OnClick = Button11Click
      end
    end
  end
end
