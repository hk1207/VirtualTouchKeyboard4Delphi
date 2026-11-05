unit VirtualHangulKeyboard4DelphiFMX_register;

{$I ..\source\VirtualTouchKeyboard.inc}

interface

procedure Register;

implementation

uses
  System.Classes,
  uVirtualHangulKeyboardFMX;

procedure Register;
begin
  RegisterComponents('VirtualTouchKeyboard4Delphi', [TVirtualHangulKeyboardFMX]);
end;

end.
