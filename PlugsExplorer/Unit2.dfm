object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #25554#20214#37197#32622#31649#29702' [Plug'#39's Configuration Manger]'
  ClientHeight = 551
  ClientWidth = 580
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 181
    Top = 0
    Width = 8
    Height = 551
    ExplicitLeft = 1
    ExplicitTop = 1
    ExplicitHeight = 491
  end
  object ListBox1: TListBox
    Left = 0
    Top = 0
    Width = 181
    Height = 551
    Align = alLeft
    ItemHeight = 13
    PopupMenu = PopupMenu1
    TabOrder = 0
    ExplicitHeight = 532
  end
  object Panel1: TPanel
    Left = 189
    Top = 0
    Width = 391
    Height = 551
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitHeight = 532
    object Splitter2: TSplitter
      Left = 0
      Top = 209
      Width = 391
      Height = 8
      Cursor = crVSplit
      Align = alTop
      ExplicitLeft = -2
      ExplicitTop = 152
      ExplicitWidth = 365
    end
    object Panel3: TPanel
      Left = 0
      Top = 0
      Width = 391
      Height = 209
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object ValueListEditor1: TValueListEditor
        Left = 0
        Top = 0
        Width = 391
        Height = 189
        Align = alClient
        TabOrder = 0
        TitleCaptions.Strings = (
          #23646#24615#21517#31216' [Key]'
          #23646#24615#20869#23481' [Value]')
        ColWidths = (
          146
          239)
      end
      object ToolBar1: TToolBar
        Left = 0
        Top = 189
        Width = 391
        Height = 20
        Align = alBottom
        AutoSize = True
        ButtonHeight = 19
        ButtonWidth = 110
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
          Caption = #28155#21152#20462#25913' [Add/Set]'
          ImageIndex = 0
        end
        object ToolButton2: TToolButton
          Left = 110
          Top = 0
          Width = 8
          Caption = 'ToolButton2'
          ImageIndex = 1
          Style = tbsSeparator
        end
        object ToolButton3: TToolButton
          Left = 118
          Top = 0
          Caption = #28165#31354#20174#22635' [Reset]'
          ImageIndex = 1
        end
      end
    end
    object Panel4: TPanel
      Left = 0
      Top = 217
      Width = 391
      Height = 334
      Align = alClient
      BevelOuter = bvLowered
      TabOrder = 1
      ExplicitHeight = 315
      object Memo1: TMemo
        Left = 1
        Top = 1
        Width = 389
        Height = 332
        Align = alClient
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Color = clBtnFace
        Ctl3D = False
        Lines.Strings = (
          'Memo1')
        ParentCtl3D = False
        ParentShowHint = False
        ReadOnly = True
        ShowHint = False
        TabOrder = 0
        ExplicitHeight = 313
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 312
    Top = 280
    object File1: TMenuItem
      Caption = #25991#20214' [&File]'
      object N1: TMenuItem
        Caption = #20445#23384#24182#36864#20986' [&Save and Exit]'
      end
      object N2: TMenuItem
        Caption = #25918#24323#20462#25913#24182#36864#20986' [&Abort and Exit]'
      end
      object N3: TMenuItem
        Caption = #25764#38144#20840#37096#25913#21464' [&Rollback All]'
      end
      object N15: TMenuItem
        Caption = #23548#20986#21040#25991#20214' [&Export to File]'
      end
      object RestoreHistory1: TMenuItem
        Caption = #36824#21407#21040#21382#21490#20445#23384' [Restore From &History]'
      end
    end
    object N16: TMenuItem
      Caption = #32534#36753' [&Edit]'
      object N17: TMenuItem
        Caption = #28155#21152#26032#37197#32622' [&Add New]'
      end
      object N18: TMenuItem
        Caption = #21024#38500#36873#20013#37197#32622' [&Remove Selected]'
      end
      object MoveUpSelected1: TMenuItem
        Caption = #19978#31227#36873#20013#37197#32622' [Move &Up Selected]'
      end
      object MoveDownSelected1: TMenuItem
        Caption = #19979#31227#36873#20013#37197#32622' [Move &Down Selected]'
      end
      object N19: TMenuItem
        Caption = #28165#31354#20840#37096#37197#32622' [&Clear All]'
      end
      object SorttheList1: TMenuItem
        Caption = #20174#26032#33258#21160#25490#24207' [&Sort the List]'
      end
    end
    object Run1: TMenuItem
      Caption = #36816#34892' [&Run]'
      object RunTheSetting1: TMenuItem
        Caption = #36816#34892#36873#20013#37197#32622' [&Run The Setting]'
      end
      object RunforDebug1: TMenuItem
        Caption = #35843#35797#36816#34892#36873#20013#37197#32622' [Run for &Debug]'
      end
    end
    object PlugIns1: TMenuItem
      Caption = #25554#20214' [&Plugins]'
      object N4: TMenuItem
        Caption = #26816#26597#37197#32622#20013#25152#32570#25554#20214' [&Search Requirement]'
      end
      object N5: TMenuItem
        Caption = #28165#29702#37197#32622#20013#27809#29992#30340#22810#20313#25554#20214' [&Clear Useless]'
      end
      object N12: TMenuItem
        Caption = #25554#20214#20248#21155#35780#20215#21644#20030#25253' [&Quality Report]'
      end
    end
    object N10: TMenuItem
      Caption = #37197#32622' [&Setting]'
      object AutoDownload1: TMenuItem
        Caption = #33258#21160#19979#36733#20449#20219#25554#20214' [Auto Download &Credible]'
        Checked = True
      end
      object Download1: TMenuItem
        Caption = #33258#21160#19979#36733#22909#35780#25554#20214' [Auto Download &Excellent]'
        Checked = True
      end
      object N71: TMenuItem
        Caption = #33258#21160#21024#38500'7'#22825#20197#19978#22791#20221' [Auto Delete &History]'
      end
      object N11: TMenuItem
        Caption = #21487#30097#25554#20214'1'#22825#20869#19981#20877#25552#31034' [Disable &Tips of Validity]'
      end
      object AllwaysOnTop1: TMenuItem
        Caption = #24635#22312#26368#19978#23618#26174#31034' [Allways On &Top]'
        OnClick = AllwaysOnTop1Click
      end
    end
    object Help1: TMenuItem
      Caption = #24110#21161' [&Help]'
      object N6: TMenuItem
        Caption = #22914#20309#20351#29992#26412#36719#20214' [Usage &Menual]'
      end
      object N7: TMenuItem
        Caption = #22914#20309#24320#21457#25554#20214' [Plugin &Development]'
      end
      object N9: TMenuItem
        Caption = #25216#26415#25903#25345#36164#28304' [&Technical Support Resources]'
      end
      object N8: TMenuItem
        Caption = #29256#26435#19982#22768#26126' [&Copyright and Announcement]'
      end
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 96
    Top = 248
    object N13: TMenuItem
      Caption = #28155#21152#26032#37197#32622
    end
    object N14: TMenuItem
      Caption = #21024#38500#36873#20013#37197#32622
    end
  end
end
