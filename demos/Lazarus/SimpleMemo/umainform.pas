unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  uVirtualTouchKeyboard;

type

  { TMainForm }

  TMainForm = class(TForm)
    Memo1: TMemo;
    ShowBtn: TButton;
    ShowKoreanBtn: TButton;
    HideBtn: TButton;
    Panel1: TPanel;
    VirtualTouchKeyboard1: TVirtualTouchKeyboard;
    procedure HideBtnClick(Sender: TObject);
    procedure ShowBtnClick(Sender: TObject);
    procedure ShowKoreanBtnClick(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.ShowBtnClick(Sender: TObject);
begin
  VirtualTouchKeyboard1.Show;
end;

procedure TMainForm.HideBtnClick(Sender: TObject);
begin
  VirtualTouchKeyboard1.Hide;
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

