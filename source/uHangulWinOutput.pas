unit uHangulWinOutput;

{$IFDEF FPC}{$MODE Delphi}{$ENDIF}

{$I VirtualTouchKeyboard.inc}

// Sends the text of the Hangul virtual keyboard to the control that has the
// keyboard focus using SendInput with KEYEVENTF_UNICODE. It doesn't need any
// IME or TabTip.exe.
//
// The virtual keyboard control must not take the keyboard focus. The VCL and
// FMX controls of this package don't, but if you put the keyboard in a form of
// its own, add the WS_EX_NOACTIVATE extended style to that form.

interface

uses
  {$IFDEF DELPHI16_UP}
    Winapi.Windows,
  {$ELSE}
    Windows,
  {$ENDIF}
  uVirtualHangulEngine;

type
  THangulWinOutput = class(THangulOutput)
    protected
      procedure SendKey(aVirtualKey : Word);
    public
      procedure SendText(const aText : WideString); override;
      procedure SendBackspace; override;
      procedure SendEnter; override;
      function  FocusToken : Int64; override;
  end;

implementation

const
  KEYEVENTF_UNICODE_FLAG = $0004;

procedure THangulWinOutput.SendKey(aVirtualKey : Word);
var
  TempInputs : array[0..1] of TInput;
begin
  FillChar(TempInputs, SizeOf(TempInputs), 0);

  TempInputs[0].Itype       := INPUT_KEYBOARD;
  TempInputs[0].ki.wVk      := aVirtualKey;
  TempInputs[0].ki.wScan    := MapVirtualKey(aVirtualKey, 0);

  TempInputs[1]             := TempInputs[0];
  TempInputs[1].ki.dwFlags  := KEYEVENTF_KEYUP;

  SendInput(2, TempInputs[0], SizeOf(TInput));
end;

procedure THangulWinOutput.SendText(const aText : WideString);
var
  TempInputs : array of TInput;
  i, j : integer;
begin
  if (length(aText) = 0) then exit;

  SetLength(TempInputs, length(aText) * 2);
  FillChar(TempInputs[0], length(TempInputs) * SizeOf(TInput), 0);

  for i := 1 to length(aText) do
    begin
      j := (i - 1) * 2;

      TempInputs[j].Itype      := INPUT_KEYBOARD;
      TempInputs[j].ki.wVk     := 0;
      TempInputs[j].ki.wScan   := Word(aText[i]);
      TempInputs[j].ki.dwFlags := KEYEVENTF_UNICODE_FLAG;

      TempInputs[j + 1]          := TempInputs[j];
      TempInputs[j + 1].ki.dwFlags := KEYEVENTF_UNICODE_FLAG or KEYEVENTF_KEYUP;
    end;

  SendInput(length(TempInputs), TempInputs[0], SizeOf(TInput));
end;

procedure THangulWinOutput.SendBackspace;
begin
  SendKey(VK_BACK);
end;

procedure THangulWinOutput.SendEnter;
begin
  SendKey(VK_RETURN);
end;

function THangulWinOutput.FocusToken : Int64;
begin
  // GetFocus returns the window of this thread that has the keyboard focus.
  Result := Int64(GetFocus);
end;

end.
