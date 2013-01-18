object BreakPointLstForm: TBreakPointLstForm
  Left = 0
  Top = 0
  Caption = #26029#28857#21015#34920
  ClientHeight = 383
  ClientWidth = 453
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Visible = True
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 137
    Top = 0
    Height = 383
    ExplicitLeft = 106
    ExplicitTop = -8
  end
  object Splitter2: TSplitter
    Left = 277
    Top = 0
    Height = 383
    ExplicitLeft = 329
    ExplicitTop = 8
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 137
    Height = 383
    Align = alLeft
    TabOrder = 0
    object StaticText1: TStaticText
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 76
      Height = 17
      Align = alTop
      Caption = #36816#34892#20013#30340#26029#28857
      TabOrder = 0
    end
    object ListBox1: TListBox
      Left = 1
      Top = 24
      Width = 135
      Height = 358
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
    end
  end
  object Panel2: TPanel
    Left = 140
    Top = 0
    Width = 137
    Height = 383
    Align = alLeft
    TabOrder = 1
    object StaticText2: TStaticText
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 76
      Height = 17
      Align = alTop
      Caption = #24453#21629#20013#30340#26029#28857
      TabOrder = 0
    end
    object ListBox2: TListBox
      Left = 1
      Top = 24
      Width = 135
      Height = 358
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
    end
  end
  object Panel3: TPanel
    Left = 280
    Top = 0
    Width = 173
    Height = 383
    Align = alClient
    TabOrder = 2
    object StaticText3: TStaticText
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 88
      Height = 17
      Align = alTop
      Caption = #26368#36817#20351#29992#30340#26029#28857
      TabOrder = 0
    end
    object ListBox3: TListBox
      Left = 1
      Top = 24
      Width = 171
      Height = 358
      Align = alClient
      ItemHeight = 13
      TabOrder = 1
      OnDblClick = ListBox3DblClick
    end
  end
end
