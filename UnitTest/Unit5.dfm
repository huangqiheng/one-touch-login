object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 427
  ClientWidth = 485
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 119
    Width = 75
    Height = 25
    Caption = 'Create'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 89
    Top = 119
    Width = 75
    Height = 25
    Caption = 'Destroy'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 485
    Height = 113
    Align = alTop
    Lines.Strings = (
      'Memo1')
    TabOrder = 2
  end
  object Button3: TButton
    Left = 280
    Top = 119
    Width = 75
    Height = 25
    Caption = 'Button3'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 199
    Top = 119
    Width = 75
    Height = 25
    Caption = 'Button4'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 361
    Top = 119
    Width = 75
    Height = 25
    Caption = 'Button5'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 288
    Top = 365
    Width = 75
    Height = 25
    Caption = 'Button6'
    TabOrder = 6
    OnClick = Button6Click
  end
  object Edit1: TEdit
    Left = 51
    Top = 369
    Width = 206
    Height = 21
    TabOrder = 7
    Text = 'call dword ptr ds: [ebx+esi-300]'
  end
  object Button7: TButton
    Left = 369
    Top = 365
    Width = 75
    Height = 25
    Caption = 'Button7'
    TabOrder = 8
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 143
    Top = 288
    Width = 106
    Height = 25
    Caption = 'CreateTheShare'
    TabOrder = 9
    OnClick = Button8Click
  end
  object Button9: TButton
    Left = 288
    Top = 288
    Width = 113
    Height = 25
    Caption = 'OpenTheShare'
    TabOrder = 10
    OnClick = Button9Click
  end
  object Button10: TButton
    Left = 143
    Top = 319
    Width = 106
    Height = 25
    Caption = 'Button10'
    TabOrder = 11
    OnClick = Button10Click
  end
  object Button11: TButton
    Left = 288
    Top = 319
    Width = 113
    Height = 25
    Caption = 'Button10'
    TabOrder = 12
    OnClick = Button11Click
  end
  object Button12: TButton
    Left = 120
    Top = 240
    Width = 75
    Height = 25
    Caption = 'Button12'
    TabOrder = 13
    OnClick = Button12Click
  end
  object OpenDialog1: TOpenDialog
    Left = 216
    Top = 152
  end
end
