object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Simple Memo'
  ClientHeight = 192
  ClientWidth = 489
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDefault
  TextHeight = 15
  object Memo1: TMemo
    Left = 0
    Top = 43
    Width = 489
    Height = 149
    Align = alClient
    Lines.Strings = (
      
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ' +
        'eiusmod '
      
        'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad m' +
        'inim '
      
        'veniam, quis nostrud exercitation ullamco laboris nisi ut aliqui' +
        'p ex ea '
      
        'commodo consequat. Duis aute irure dolor in reprehenderit in vol' +
        'uptate '
      
        'velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sin' +
        't occaecat '
      
        'cupidatat non proident, sunt in culpa qui officia deserunt molli' +
        't anim id '
      'est laborum.')
    ScrollBars = ssBoth
    TabOrder = 0
    ExplicitTop = 40
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 489
    Height = 43
    Align = alTop
    TabOrder = 1
    ExplicitLeft = 8
    object HideBtn: TButton
      Left = 320
      Top = 9
      Width = 150
      Height = 25
      Caption = 'Hide virtual keyboard'
      TabOrder = 0
      OnClick = HideBtnClick
    end
    object ShowKoreanBtn: TButton
      Left = 168
      Top = 9
      Width = 150
      Height = 25
      Caption = 'Show Korean keyboard'
      TabOrder = 2
      OnClick = ShowKoreanBtnClick
    end
    object ShowBtn: TButton
      Left = 16
      Top = 9
      Width = 150
      Height = 25
      Caption = 'Show virtual keyboard'
      TabOrder = 1
      OnClick = ShowBtnClick
    end
  end
  object VirtualTouchKeyboard1: TVirtualTouchKeyboard
    Left = 224
  end
end
