program HangulKeyboardDemo;

// Demo of TVirtualHangulKeyboardFMX. The form is created in code, so the
// component doesn't have to be installed in the IDE.

uses
  System.StartUpCopy,
  FMX.Forms,
  uMainForm in 'uMainForm.pas',
  uVirtualHangulKeyboardFMX in '..\..\..\source\uVirtualHangulKeyboardFMX.pas',
  uVirtualHangulEngine in '..\..\..\source\uVirtualHangulEngine.pas',
  uHangulComposer in '..\..\..\source\uHangulComposer.pas',
  uHangulWinOutput in '..\..\..\source\uHangulWinOutput.pas';

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
