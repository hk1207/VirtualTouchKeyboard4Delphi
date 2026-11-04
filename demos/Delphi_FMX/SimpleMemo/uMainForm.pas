unit uMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, uVirtualTouchKeyboard, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Layouts;

type
  TMainForm = class(TForm)
    Layout1: TLayout;
    ShowBtn: TButton;
    ShowKoreanBtn: TButton;
    HideBtn: TButton;
    VirtualTouchKeyboard1: TVirtualTouchKeyboard;
    Memo1: TMemo;
    procedure ShowBtnClick(Sender: TObject);
    procedure ShowKoreanBtnClick(Sender: TObject);
    procedure HideBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.HideBtnClick(Sender: TObject);
begin
  VirtualTouchKeyboard1.Hide;
end;

procedure TMainForm.ShowBtnClick(Sender: TObject);
begin
  VirtualTouchKeyboard1.Show;
end;

procedure TMainForm.ShowKoreanBtnClick(Sender: TObject);
begin
  // Activates the Korean layout in Hangul mode and shows the keyboard.
  // Windows must have a Korean keyboard installed (see IsKoreanInstalled).
  if VirtualTouchKeyboard1.IsKoreanInstalled then
    VirtualTouchKeyboard1.ShowKorean
   else
    ShowMessage('Korean keyboard is not installed in Windows.');
end;

end.
