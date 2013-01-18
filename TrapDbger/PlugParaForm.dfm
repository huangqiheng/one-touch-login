object SetParamForm: TSetParamForm
  Left = 0
  Top = 0
  ActiveControl = Button2
  BorderStyle = bsSizeToolWin
  Caption = #35831#22635#20837#25554#20214#21442#25968
  ClientHeight = 218
  ClientWidth = 307
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object ValueListEditor1: TValueListEditor
    Left = 0
    Top = 0
    Width = 307
    Height = 190
    Align = alClient
    PopupMenu = PopupMenu1
    TabOrder = 0
    TitleCaptions.Strings = (
      #23646#24615#21517#31216' [Key]'
      #23646#24615#20869#23481' [Value]')
    OnDrawCell = ValueListEditor1DrawCell
    ColWidths = (
      104
      197)
  end
  object Panel1: TPanel
    Left = 0
    Top = 190
    Width = 307
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object Button1: TButton
      Left = 74
      Top = 3
      Width = 76
      Height = 22
      Caption = #21462#28040
      ModalResult = 2
      TabOrder = 0
    end
    object Button2: TButton
      Left = 155
      Top = 3
      Width = 76
      Height = 22
      Caption = #30830#23450
      ModalResult = 1
      TabOrder = 1
      OnClick = Button2Click
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 120
    Top = 80
  end
  object PopupMenu1: TPopupMenu
    TrackButton = tbLeftButton
    Left = 136
    Top = 128
  end
end
