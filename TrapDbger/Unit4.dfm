object MDIMain: TMDIMain
  Left = 0
  Top = 0
  Caption = 'TrapDebuger'
  ClientHeight = 578
  ClientWidth = 653
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIForm
  Menu = MainMenu1
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object MainMenu1: TMainMenu
    Left = 240
    Top = 176
    object File1: TMenuItem
      Caption = #25991#20214'(&File)'
      object N1: TMenuItem
        Action = File_OpenAimExe
      end
      object N2: TMenuItem
        Caption = #26368#36817#25171#24320
      end
      object N6: TMenuItem
        Action = File_CloseAimExe
      end
      object N8: TMenuItem
        Caption = '-'
      end
      object N7: TMenuItem
        Action = File_CloseApp
      end
    end
    object Edit1: TMenuItem
      Caption = #26597#30475'(&View)'
      object N3: TMenuItem
        Caption = #20869#23384#32534#36753
        OnClick = N3Click
      end
      object N9: TMenuItem
        Caption = #35843#35797#20449#24687#31383#21475
      end
    end
    object Break1: TMenuItem
      Caption = #26029#28857'(&Break)'
      object N4: TMenuItem
        Caption = #26029#28857#21015#34920
      end
    end
    object Set1: TMenuItem
      Caption = #35774#32622'(&Set)'
      object N5: TMenuItem
        Caption = #21551#21160#26102#20013#26029#22312#31243#24207#20837#21475#28857
      end
    end
  end
  object ActionList1: TActionList
    Left = 224
    Top = 240
    object File_OpenAimExe: TAction
      Caption = #25171#24320#30446#26631
    end
    object File_CloseAimExe: TAction
      Caption = #20851#38381#30446#26631
    end
    object File_CloseApp: TAction
      Caption = #36864#20986
    end
  end
end
