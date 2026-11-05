unit uMainForm;

interface

uses
  System.Classes, FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls,
  FMX.Memo, FMX.Edit, FMX.Controls.Presentation, FMX.ScrollBox,
  uVirtualHangulKeyboardFMX, uVirtualHangulEngine;

type
  TMainForm = class(TForm)
    protected
      Edit1    : TEdit;
      Memo1    : TMemo;
      Keyboard : TVirtualHangulKeyboardFMX;
    public
      constructor Create(AOwner : TComponent); override;
  end;

var
  MainForm : TMainForm;

implementation

constructor TMainForm.Create(AOwner : TComponent);
begin
  inherited CreateNew(AOwner);

  Caption      := 'Hangul virtual keyboard (FMX)';
  ClientWidth  := 640;
  ClientHeight := 520;

  Keyboard        := TVirtualHangulKeyboardFMX.Create(Self);
  Keyboard.Parent := Self;
  Keyboard.Align  := TAlignLayout.Bottom;
  Keyboard.Height := 260;
  Keyboard.Layout := hlDubeolsik;   // or hlCheonjiin. The layout key changes it too.

  Edit1        := TEdit.Create(Self);
  Edit1.Parent := Self;
  Edit1.Align  := TAlignLayout.Top;

  Memo1        := TMemo.Create(Self);
  Memo1.Parent := Self;
  Memo1.Align  := TAlignLayout.Client;

  ActiveControl := Memo1;
end;

end.
