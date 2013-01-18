object CallStructureForm: TCallStructureForm
  Left = 0
  Top = 0
  Caption = #35843#29992#32467#26500#20851#31995
  ClientHeight = 480
  ClientWidth = 576
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 185
    Top = 0
    Height = 480
    ExplicitTop = -68
    ExplicitHeight = 456
  end
  object Splitter2: TSplitter
    Left = 388
    Top = 0
    Height = 480
    Align = alRight
    ExplicitLeft = 403
    ExplicitTop = -68
    ExplicitHeight = 456
  end
  object Panel1: TPanel
    Left = 391
    Top = 0
    Width = 185
    Height = 480
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
      OnDblClick = ListBox1DblClick
    end
    object ListBox4: TListBox
      Left = 1
      Top = 190
      Width = 183
      Height = 289
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
      Caption = #37117#35843#29992#20102#20160#20040'API'#65311
      TabOrder = 2
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 480
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
      Height = 289
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
      Caption = #35841#35843#29992#20102#26412#20989#25968#65311
      TabOrder = 2
    end
  end
  object Panel3: TPanel
    Left = 188
    Top = 0
    Width = 200
    Height = 480
    Align = alClient
    TabOrder = 2
    object StaticText3: TStaticText
      Left = 1
      Top = 1
      Width = 198
      Height = 17
      Align = alTop
      Alignment = taCenter
      Caption = #35201#26597#30475#30340#20989#25968#20307
      TabOrder = 0
    end
    object ListBox3: TListBox
      Left = 1
      Top = 18
      Width = 198
      Height = 461
      Align = alClient
      ItemHeight = 13
      PopupMenu = PopupMenu1
      TabOrder = 1
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 288
    Top = 168
    object N1: TMenuItem
      Caption = #20837#21475
    end
    object N2: TMenuItem
      Caption = #36339#21040
      OnClick = N2Click
    end
  end
end
