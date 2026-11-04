unit uMainForm;

interface    

{$I ..\..\..\source\VirtualTouchKeyboard.inc}

uses          
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, 
  {$ENDIF}
  uVirtualTouchKeyboard;

type
  TMainForm = class(TForm)
    VirtualTouchKeyboard1: TVirtualTouchKeyboard;
    Memo1: TMemo;
    ShowBtn: TButton;
    ShowKoreanBtn: TButton;
    HideBtn: TButton;
    Panel1: TPanel;
    procedure HideBtnClick(Sender: TObject);
    procedure ShowBtnClick(Sender: TObject);
    procedure ShowKoreanBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

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
