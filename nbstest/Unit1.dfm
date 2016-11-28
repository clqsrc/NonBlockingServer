object Form1: TForm1
  Left = 231
  Top = 172
  Width = 561
  Height = 357
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  PixelsPerInch = 96
  TextHeight = 12
  object btnStart: TButton
    Left = 96
    Top = 56
    Width = 75
    Height = 25
    Caption = 'start'
    TabOrder = 0
    OnClick = btnStartClick
  end
  object Timer1: TTimer
    Interval = 10
    OnTimer = Timer1Timer
    Left = 56
    Top = 64
  end
end
