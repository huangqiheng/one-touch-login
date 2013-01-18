object Form1: TForm1
  Left = 0
  Top = 0
  Caption = #25554#20214#37197#32622#29983#25104#24037#20855
  ClientHeight = 483
  ClientWidth = 416
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ValueListEditor1: TValueListEditor
    Left = 0
    Top = 0
    Width = 416
    Height = 456
    Align = alClient
    TabOrder = 0
    ColWidths = (
      150
      260)
  end
  object Panel1: TPanel
    Left = 0
    Top = 456
    Width = 416
    Height = 27
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object Button1: TButton
      Left = 65
      Top = 0
      Width = 351
      Height = 27
      Align = alClient
      Caption = #29983#25104#37197#32622#25991#20214
      Default = True
      TabOrder = 0
      OnClick = Button1Click
      ExplicitLeft = 72
      ExplicitWidth = 344
    end
    object Button2: TButton
      Left = 0
      Top = 0
      Width = 65
      Height = 27
      Align = alLeft
      Caption = #35835#21462
      TabOrder = 1
      OnClick = Button2Click
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 168
    Top = 248
  end
end
