object MainManage: TMainManage
  Left = 0
  Top = 0
  Caption = 'AppAdapter'
  ClientHeight = 487
  ClientWidth = 282
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 0
    Top = 38
    Width = 282
    Height = 8
    Align = alTop
    Shape = bsTopLine
    Style = bsRaised
    ExplicitWidth = 232
  end
  object CategoryButtons1: TCategoryButtons
    Left = 0
    Top = 46
    Width = 282
    Height = 441
    Align = alClient
    BevelEdges = []
    BevelInner = bvSpace
    BevelOuter = bvNone
    BevelWidth = 5
    BorderStyle = bsNone
    ButtonFlow = cbfVertical
    ButtonOptions = [boFullSize, boGradientFill, boShowCaptions, boUsePlusMinus, boCaptionOnlyBorder]
    BackgroundGradientColor = 16773335
    BackgroundGradientDirection = gdVertical
    Categories = <>
    GradientDirection = gdVertical
    HotButtonColor = 13565927
    PopupMenu = PopupMenu1
    RegularButtonColor = 15790320
    SelectedButtonColor = 14145495
    TabOrder = 0
    OnAfterDrawButton = CategoryButtons1AfterDrawButton
    OnClick = CategoryButtons1Click
    OnMouseUp = CategoryButtons1MouseUp
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 282
    Height = 38
    ButtonHeight = 38
    ButtonWidth = 40
    Caption = 'ToolBar1'
    DrawingStyle = dsGradient
    EdgeInner = esNone
    EdgeOuter = esRaised
    GradientEndColor = clSkyBlue
    Images = DataModuleBase.ImageList1
    List = True
    ParentShowHint = False
    AllowTextButtons = True
    ShowHint = True
    TabOrder = 1
    Transparent = True
    Wrapable = False
    object ToolButton3: TToolButton
      Left = 0
      Top = 0
      Action = DataModuleBase.Bar_CheckPlugins
    end
    object ToolButton1: TToolButton
      Left = 40
      Top = 0
      Action = DataModuleBase.Bar_StayOnTop
      Style = tbsCheck
    end
    object ToolButton2: TToolButton
      Left = 80
      Top = 0
      Action = DataModuleBase.Bar_ViewConst
      Style = tbsCheck
    end
    object ToolButton4: TToolButton
      Left = 120
      Top = 0
      Action = DataModuleBase.Bar_ViewPrivacy
      Style = tbsCheck
    end
    object ToolButton6: TToolButton
      Left = 160
      Top = 0
      Hint = #26174#31034#35843#35797#20449#24687#31383#21475
      Caption = 'Bar_MachineSignature'
      ImageIndex = 0
      Style = tbsCheck
      OnClick = ToolButton6Click
    end
    object ToolButton7: TToolButton
      Left = 200
      Top = 0
      Action = DataModuleBase.Bar_UninstallDriver
    end
    object ToolButton5: TToolButton
      Left = 240
      Top = 0
      Action = DataModuleBase.Bar_Helper
    end
  end
  object Memo1: TMemo
    Left = 80
    Top = 176
    Width = 129
    Height = 57
    Lines.Strings = (
      'Memo1')
    TabOrder = 2
    Visible = False
    WordWrap = False
  end
  object PopupMenu1: TPopupMenu
    OnPopup = PopupMenu1Popup
    Left = 96
    Top = 256
    object N13: TMenuItem
      Caption = #28155#21152#26032#37197#32622
      OnClick = N13Click
    end
    object ConfigReflash: TMenuItem
      Caption = #21047#26032#21015#34920
      OnClick = ConfigReflashClick
    end
    object N49: TMenuItem
      Caption = #22797#21046#37197#32622
      OnClick = N49Click
    end
    object N25: TMenuItem
      Caption = #19978#31227#19968#34892
      OnClick = N25Click
    end
    object N26: TMenuItem
      Caption = #19979#31227#19968#34892
      OnClick = N26Click
    end
    object N14: TMenuItem
      Caption = #21024#38500#36873#20013#37197#32622
      OnClick = N14Click
    end
    object N1: TMenuItem
      Caption = #28165#38500#35813#25554#20214#20840#37096#37197#32622
      OnClick = N1Click
    end
    object N37: TMenuItem
      Caption = #28165#31354#20840#37096#37197#32622
      OnClick = N37Click
    end
    object N20: TMenuItem
      Caption = #36816#34892#36873#20013#37197#32622
      OnClick = N20Click
    end
    object N21: TMenuItem
      Caption = #36816#34892#36873#20013#37197#32622' - '#35843#35797#27169#24335
      OnClick = N21Click
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.json'
    Filter = 'JSON|*.json'
    Title = #35831#36755#20837#35201#20445#23384#30340#25991#20214#21517
    Left = 64
    Top = 120
  end
end
