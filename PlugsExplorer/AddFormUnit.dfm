object AddConfigForm: TAddConfigForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = #28155#21152#37197#32622#31383#21475
  ClientHeight = 347
  ClientWidth = 433
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 433
    Height = 21
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel1'
    TabOrder = 0
    object ComboBox1: TComboBox
      Left = 105
      Top = 0
      Width = 294
      Height = 21
      Align = alClient
      ItemHeight = 13
      TabOrder = 0
      OnChange = ComboBox2Change
      OnDropDown = ComboBox1DropDown
    end
    object Panel2: TPanel
      Left = 0
      Top = 0
      Width = 105
      Height = 21
      Align = alLeft
      BevelOuter = bvNone
      Caption = #35201#36816#34892#30340#31243#24207#65306
      TabOrder = 2
    end
    object Button1: TButton
      Left = 399
      Top = 0
      Width = 34
      Height = 21
      Align = alRight
      Caption = #27983#35272
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 21
    Width = 433
    Height = 21
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel1'
    TabOrder = 1
    object ComboBox2: TComboBox
      Left = 105
      Top = 0
      Width = 294
      Height = 21
      Align = alClient
      ItemHeight = 13
      TabOrder = 0
      OnChange = ComboBox2Change
      OnDropDown = ComboBox2DropDown
    end
    object Panel4: TPanel
      Left = 0
      Top = 0
      Width = 105
      Height = 21
      Align = alLeft
      BevelOuter = bvNone
      Caption = #35201#37197#32622#30340#25554#20214#65306
      TabOrder = 1
    end
    object Button6: TButton
      Left = 399
      Top = 0
      Width = 34
      Height = 21
      Align = alRight
      Caption = #27983#35272
      TabOrder = 2
      OnClick = Button6Click
    end
  end
  object Panel5: TPanel
    Left = 0
    Top = 42
    Width = 433
    Height = 305
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object Panel6: TPanel
      Left = 343
      Top = 0
      Width = 90
      Height = 305
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 1
      object Panel7: TPanel
        Left = 0
        Top = 0
        Width = 90
        Height = 125
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object Button2: TButton
          Left = 5
          Top = 7
          Width = 79
          Height = 25
          Caption = #28155#21152#37197#32622
          TabOrder = 0
          OnClick = Button2Click
        end
        object Button3: TButton
          Left = 5
          Top = 36
          Width = 79
          Height = 25
          Caption = #28165#31354#20174#22635
          TabOrder = 1
          OnClick = ComboBox2Change
        end
        object Button5: TButton
          Left = 6
          Top = 94
          Width = 79
          Height = 25
          Caption = #36864#20986
          TabOrder = 3
          OnClick = Button5Click
        end
        object Button4: TButton
          Left = 5
          Top = 65
          Width = 79
          Height = 25
          Caption = #25554#20214#25991#26723
          TabOrder = 2
        end
      end
      object Panel8: TPanel
        Left = 0
        Top = 125
        Width = 90
        Height = 180
        Align = alClient
        BevelOuter = bvNone
        BorderWidth = 6
        TabOrder = 1
        object Label1: TLabel
          Left = 6
          Top = 6
          Width = 78
          Height = 168
          Align = alClient
          AutoSize = False
          WordWrap = True
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 402
          ExplicitHeight = 13
        end
      end
    end
    object ValueListEditor1: TValueListEditor
      Left = 0
      Top = 0
      Width = 343
      Height = 305
      Align = alClient
      TabOrder = 0
      TitleCaptions.Strings = (
        #23646#24615#21517#31216' [Key]'
        #23646#24615#20869#23481' [Value]')
      OnSelectCell = ValueListEditor1SelectCell
      ColWidths = (
        104
        233)
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 200
    Top = 152
  end
end
