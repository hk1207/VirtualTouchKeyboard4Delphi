program HangulKeyboardDemo;

// Demo of TVirtualHangulKeyboard. The form is created in code, so the
// component doesn't have to be installed in the IDE.

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas',
  uVirtualHangulKeyboard in '..\..\..\source\uVirtualHangulKeyboard.pas',
  uVirtualHangulEngine in '..\..\..\source\uVirtualHangulEngine.pas',
  uHangulComposer in '..\..\..\source\uHangulComposer.pas',
  uHangulWinOutput in '..\..\..\source\uHangulWinOutput.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
