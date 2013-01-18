object ModifyConfigForm: TModifyConfigForm
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = #20462#25913#37197#32622#20449#24687
  ClientHeight = 268
  ClientWidth = 304
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ValueListEditor1: TValueListEditor
    Left = 0
    Top = 0
    Width = 304
    Height = 248
    Align = alClient
    TabOrder = 0
    TitleCaptions.Strings = (
      #23646#24615#21517#31216' [Key]'
      #23646#24615#20869#23481' [Value]')
    ColWidths = (
      104
      194)
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 248
    Width = 304
    Height = 20
    Align = alBottom
    AutoSize = True
    ButtonHeight = 19
    ButtonWidth = 60
    Caption = 'ToolBar1'
    DrawingStyle = dsGradient
    EdgeBorders = [ebBottom]
    EdgeInner = esNone
    List = True
    ShowCaptions = True
    TabOrder = 1
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Caption = #20445#23384#37197#32622
      ImageIndex = 0
      OnClick = ToolButton1Click
    end
    object ToolButton2: TToolButton
      Left = 60
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object ToolButton3: TToolButton
      Left = 68
      Top = 0
      Caption = #28165#31354#20174#22635
      ImageIndex = 1
      OnClick = ToolButton3Click
    end
    object ToolButton4: TToolButton
      Left = 128
      Top = 0
      Width = 8
      Caption = 'ToolButton4'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton5: TToolButton
      Left = 136
      Top = 0
      Caption = #24110#21161
      ImageIndex = 2
      OnClick = ToolButton5Click
    end
    object ToolButton7: TToolButton
      Left = 196
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 4
      Style = tbsSeparator
    end
    object ToolButton6: TToolButton
      Left = 204
      Top = 0
      Caption = #36864#20986
      ImageIndex = 3
      OnClick = ToolButton6Click
    end
  end
end
