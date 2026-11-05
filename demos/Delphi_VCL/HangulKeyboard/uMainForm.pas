unit uMainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  uVirtualHangulKeyboard;

type
  TMainForm = class(TForm)
    protected
      Edit1    : TEdit;
      Memo1    : TMemo;
      Keyboard : TVirtualHangulKeyboard;
    public
      constructor Create(AOwner : TComponent); override;
  end;

var
  MainForm : TMainForm;

implementation

constructor TMainForm.Create(AOwner : TComponent);
begin
  inherited CreateNew(AOwner);

  Caption      := 'Hangul virtual keyboard (VCL)';
  ClientWidth  := 640;
  ClientHeight := 520;
  Font.Name    := 'Malgun Gothic';
  Font.Size    := 11;

  Keyboard        := TVirtualHangulKeyboard.Create(Self);
  Keyboard.Parent := Self;
  Keyboard.Align  := alBottom;
  Keyboard.Height := 260;
  Keyboard.Layout := hlDubeolsik;   // or hlCheonjiin. The layout key changes it too.

  Edit1        := TEdit.Create(Self);
  Edit1.Parent := Self;
  Edit1.Align  := alTop;

  Memo1            := TMemo.Create(Self);
  Memo1.Parent     := Self;
  Memo1.Align      := alClient;
  Memo1.ScrollBars := ssVertical;

  ActiveControl := Memo1;
end;

end.
