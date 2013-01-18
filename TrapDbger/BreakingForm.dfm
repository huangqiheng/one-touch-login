object BreakPointForm: TBreakPointForm
  Left = 0
  Top = 0
  Caption = #20195#30721#35843#35797#31383#21475
  ClientHeight = 499
  ClientWidth = 575
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Visible = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 404
    Top = 0
    Width = 5
    Height = 480
    Align = alRight
    Beveled = True
    ExplicitLeft = 406
    ExplicitTop = 22
    ExplicitHeight = 437
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 480
    Width = 575
    Height = 19
    Panels = <>
  end
  object Panel1: TPanel
    Left = 409
    Top = 0
    Width = 166
    Height = 480
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 1
    object Splitter2: TSplitter
      Left = 0
      Top = 161
      Width = 166
      Height = 5
      Cursor = crVSplit
      Align = alTop
      Beveled = True
      ExplicitLeft = 1
      ExplicitTop = 177
    end
    object ListBox2: TListBox
      Left = 0
      Top = 166
      Width = 166
      Height = 314
      Align = alClient
      ItemHeight = 13
      PopupMenu = PopupMenu2
      TabOrder = 0
      OnDblClick = ListBox4DblClick
      OnMouseDown = ListBox4MouseDown
    end
    object Panel3: TPanel
      Left = 0
      Top = 0
      Width = 166
      Height = 161
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object ListBox1: TListBox
        Left = 0
        Top = 0
        Width = 136
        Height = 161
        Align = alClient
        ItemHeight = 13
        PopupMenu = PopupMenu1
        TabOrder = 0
        OnDblClick = ListBox4DblClick
        OnMouseDown = ListBox4MouseDown
      end
      object ListBox5: TListBox
        Left = 136
        Top = 0
        Width = 30
        Height = 161
        Align = alRight
        ItemHeight = 13
        TabOrder = 1
        OnDblClick = ListBox4DblClick
        OnMouseDown = ListBox4MouseDown
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 404
    Height = 480
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object Splitter3: TSplitter
      Left = 0
      Top = 352
      Width = 404
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      Beveled = True
      ExplicitTop = 23
    end
    object ToolBar1: TToolBar
      Left = 0
      Top = 333
      Width = 404
      Height = 19
      Align = alBottom
      AutoSize = True
      ButtonHeight = 19
      ButtonWidth = 56
      Caption = 'ToolBar1'
      DrawingStyle = dsGradient
      List = True
      ShowCaptions = True
      TabOrder = 0
      Wrapable = False
      object ToolButton2: TToolButton
        Left = 0
        Top = 0
        Width = 8
        Caption = 'ToolButton2'
        ImageIndex = 1
        Style = tbsSeparator
      end
      object ToolButton3: TToolButton
        Left = 8
        Top = 0
        Caption = #27493#20837'(F7)'
        ImageIndex = 1
        OnClick = ToolButton3Click
      end
      object ToolButton8: TToolButton
        Left = 64
        Top = 0
        Width = 8
        Caption = 'ToolButton8'
        ImageIndex = 6
        Style = tbsSeparator
      end
      object ToolButton4: TToolButton
        Left = 72
        Top = 0
        Caption = #27493#36807'(F8)'
        ImageIndex = 2
        OnClick = ToolButton4Click
      end
      object ToolButton9: TToolButton
        Left = 128
        Top = 0
        Width = 8
        Caption = 'ToolButton9'
        ImageIndex = 6
        Style = tbsSeparator
      end
      object ToolButton5: TToolButton
        Left = 136
        Top = 0
        Caption = #37322#25918'(F9)'
        ImageIndex = 3
        OnClick = ToolButton5Click
      end
      object ToolButton10: TToolButton
        Left = 192
        Top = 0
        Width = 8
        Caption = 'ToolButton10'
        ImageIndex = 6
        Style = tbsSeparator
      end
      object ToolButton6: TToolButton
        Left = 200
        Top = 0
        Caption = #36820#22238'(F3)'
        ImageIndex = 4
        OnClick = ToolButton6Click
      end
      object ToolButton11: TToolButton
        Left = 256
        Top = 0
        Width = 8
        Caption = 'ToolButton11'
        ImageIndex = 7
        Style = tbsSeparator
      end
      object ToolButton7: TToolButton
        Left = 264
        Top = 0
        Caption = #30053#21040'(F4)'
        ImageIndex = 5
        OnClick = ToolButton7Click
      end
    end
    object ListBox3: TListBox
      Left = 0
      Top = 0
      Width = 404
      Height = 333
      Style = lbOwnerDrawFixed
      Align = alClient
      ItemHeight = 13
      PopupMenu = PopupMenu3
      TabOrder = 1
      OnDblClick = ListBox4DblClick
      OnDrawItem = ListBox3DrawItem
      OnMouseDown = ListBox4MouseDown
    end
    object ListBox4: TListBox
      Left = 0
      Top = 357
      Width = 404
      Height = 123
      Align = alBottom
      ItemHeight = 13
      PopupMenu = PopupMenu4
      TabOrder = 2
      OnDblClick = ListBox4DblClick
      OnMouseDown = ListBox4MouseDown
    end
  end
  object InputEditor: TEdit
    Left = 72
    Top = 419
    Width = 305
    Height = 21
    Hint = #25353'Enter'#38190#30830#35748#36755#20837
    BevelInner = bvNone
    BevelOuter = bvNone
    BiDiMode = bdLeftToRight
    BorderStyle = bsNone
    Color = clActiveBorder
    ParentBiDiMode = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    Text = 'InputEditor'
    Visible = False
    OnKeyPress = InputEditorKeyPress
  end
  object ApplicationEvents1: TApplicationEvents
    OnShortCut = ApplicationEvents1ShortCut
    Left = 192
    Top = 176
  end
  object PopupMenu1: TPopupMenu
    Left = 472
    Top = 64
    object N11: TMenuItem
      Caption = #36319#38543#23492#23384#22120#20540' - '#25968#25454#31383#21475
    end
    object N12: TMenuItem
      Caption = #36319#38543#23492#23384#22120#20540' - '#20195#30721#31383#21475
    end
  end
  object PopupMenu2: TPopupMenu
    Left = 480
    Top = 248
    object N1: TMenuItem
      Caption = #26174#31034#20840#26632
      OnClick = N1Click
    end
    object DWORD3: TMenuItem
      Caption = #36319#38543#26632#22320#22336' - '#20195#30721#31383#21475
    end
    object DWORD4: TMenuItem
      Caption = #36319#38543#26632#22320#22336' - '#25968#25454#31383#21475
    end
    object N4: TMenuItem
      Caption = #36319#38543#26632#20540' - '#20195#30721#31383#21475
    end
    object N5: TMenuItem
      Caption = #36319#38543#26632#20540' - '#25968#25454#31383#21475
    end
  end
  object PopupMenu3: TPopupMenu
    Left = 272
    Top = 120
    object arget1: TMenuItem
      Caption = #36319#38543#25351#20196#36339#36716#30446#26631
    end
    object N10: TMenuItem
      Caption = #36319#38543#20195#30721#22320#22336' - '#25968#25454#31383#21475
    end
    object N7: TMenuItem
      Caption = #22797#21046#21040#21098#20999#26495
    end
    object N8: TMenuItem
      Caption = #26597#30475#35843#29992#32467#26500
    end
    object N9: TMenuItem
      Caption = #35774#32622#26029#28857#65288#27880#24847#38480#21046#65289
    end
  end
  object PopupMenu4: TPopupMenu
    Left = 208
    Top = 400
    object DWORD1: TMenuItem
      Caption = #20195#30721#31383#21475#20013#36319#38543'DWORD'
    end
    object DWORD2: TMenuItem
      Caption = #25968#25454#31383#21475#20013#36319#38543'DWORD'
    end
    object N3: TMenuItem
      Caption = #21069#24448#22320#22336
    end
    object N2: TMenuItem
      Caption = #21069#24448#25968#25454#27573
    end
    object N6: TMenuItem
      Caption = #22797#21046#21040#21098#20999#26495
    end
  end
end
