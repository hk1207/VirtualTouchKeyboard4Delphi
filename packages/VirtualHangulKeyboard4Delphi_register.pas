unit VirtualHangulKeyboard4Delphi_register;

{$I ..\source\VirtualTouchKeyboard.inc}

interface

procedure Register;

implementation

uses
  System.Classes,
  uVirtualHangulKeyboard;

procedure Register;
begin
  RegisterComponents('VirtualTouchKeyboard4Delphi', [TVirtualHangulKeyboard]);
end;

end.
