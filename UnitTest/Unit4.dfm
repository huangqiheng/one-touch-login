object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Form4'
  ClientHeight = 353
  ClientWidth = 501
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 40
    Top = 147
    Width = 48
    Height = 13
    Caption = #36335#24452#21517#65306
  end
  object Button1: TButton
    Left = 94
    Top = 171
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Edit1: TEdit
    Left = 94
    Top = 144
    Width = 281
    Height = 21
    ImeName = #35895#27468#25340#38899#36755#20837#27861' 2.0'
    TabOrder = 1
    Text = 'Edit1'
  end
  object Button2: TButton
    Left = 381
    Top = 142
    Width = 27
    Height = 25
    Caption = '...'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 94
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Button3'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 128
    Top = 25
    Width = 99
    Height = 25
    Caption = 'CreateIpcServer'
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 128
    Top = 56
    Width = 99
    Height = 25
    Caption = 'DestroyIpcServer'
    TabOrder = 5
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 272
    Top = 25
    Width = 117
    Height = 25
    Caption = 'SendIpcCommand'
    TabOrder = 6
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 395
    Top = 25
    Width = 75
    Height = 25
    Caption = 'Button7'
    TabOrder = 7
  end
  object Button8: TButton
    Left = 320
    Top = 263
    Width = 121
    Height = 25
    Caption = 'OpenProgressWindow'
    TabOrder = 8
    OnClick = Button8Click
  end
  object Button9: TButton
    Left = 224
    Top = 171
    Width = 75
    Height = 25
    Caption = 'Button9'
    TabOrder = 9
  end
  object Button10: TButton
    Left = 320
    Top = 319
    Width = 121
    Height = 25
    Caption = 'CloseProgressWindow'
    TabOrder = 10
    OnClick = Button10Click
  end
  object Button11: TButton
    Left = 320
    Top = 291
    Width = 121
    Height = 25
    Caption = 'ReportProgress'
    TabOrder = 11
    OnClick = Button11Click
  end
  object Button12: TButton
    Left = 169
    Top = 304
    Width = 113
    Height = 25
    Caption = 'ShowUserMessage'
    TabOrder = 12
    OnClick = Button12Click
  end
  object Memo1: TMemo
    Left = 272
    Top = 56
    Width = 198
    Height = 80
    Lines.Strings = (
      'Memo1')
    TabOrder = 13
  end
  object OpenDialog1: TOpenDialog
    Left = 344
    Top = 176
  end
end
