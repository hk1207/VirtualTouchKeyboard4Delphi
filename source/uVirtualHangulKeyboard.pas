unit uVirtualHangulKeyboard;

{$IFDEF FPC}{$MODE Delphi}{$ENDIF}

{$I VirtualTouchKeyboard.inc}

// VCL virtual keyboard that can type Hangul without TabTip.exe or an IME.
// It supports the Dubeolsik and Cheonjiin layouts, English letters and symbols.
//
// The keyboard is a graphic control (it has no window handle) so clicking on
// it never takes the keyboard focus from the edit control that is being used.

interface

uses
  {$IFDEF DELPHI16_UP}
    Winapi.Windows, System.Types, System.Classes, System.SysUtils, Vcl.Controls,
    Vcl.Graphics, Vcl.ExtCtrls,
  {$ELSE}
    Windows, Types, Classes, SysUtils, Controls, Graphics, ExtCtrls,
  {$ENDIF}
  uVirtualHangulEngine, uHangulWinOutput;

type
  /// <summary>
  /// VCL virtual keyboard with Korean (Hangul) input.
  /// </summary>
  TVirtualHangulKeyboard = class(TGraphicControl)
    protected
      FEngine     : THangulEngine;
      FOutput     : THangulWinOutput;
      FDownKey    : integer;
      FKeyColor   : TColor;
      FKeyDownColor : TColor;
      FKeyActiveColor : TColor;
      FKeyTextColor : TColor;
      FGap        : integer;
      FRepeatTimer : TTimer;

      function  GetLayout : THangulLayout;
      procedure SetLayout(aValue : THangulLayout);
      function  GetKorean : boolean;
      procedure SetKorean(aValue : boolean);
      procedure SetColorProp(var aField : TColor; aValue : TColor);
      procedure SetKeyColor(aValue : TColor);
      procedure SetKeyDownColor(aValue : TColor);
      procedure SetKeyActiveColor(aValue : TColor);
      procedure SetKeyTextColor(aValue : TColor);

      procedure EngineChange(Sender : TObject);
      procedure RepeatTimerEvent(Sender : TObject);
      procedure StopRepeat;
      function  KeyRect(aIndex : integer) : TRect;
      function  KeyAt(aX, aY : integer) : integer;

      procedure Paint; override;
      procedure MouseDown(Button : TMouseButton; Shift : TShiftState; X, Y : Integer); override;
      procedure MouseUp(Button : TMouseButton; Shift : TShiftState; X, Y : Integer); override;

    public
      constructor Create(AOwner : TComponent); override;
      destructor  Destroy; override;

      /// <summary>
      /// Access to the keyboard logic.
      /// </summary>
      property Engine : THangulEngine read FEngine;

    published
      /// <summary>
      /// Dubeolsik or Cheonjiin. The user can also change it with the layout key.
      /// </summary>
      property Layout         : THangulLayout read GetLayout write SetLayout default hlDubeolsik;
      /// <summary>
      /// True = Korean letters, False = English letters.
      /// </summary>
      property Korean         : boolean       read GetKorean write SetKorean default True;
      property KeyColor       : TColor        read FKeyColor       write SetKeyColor       default $00F0F0F0;
      property KeyDownColor   : TColor        read FKeyDownColor   write SetKeyDownColor   default $00C8C8C8;
      property KeyActiveColor : TColor        read FKeyActiveColor write SetKeyActiveColor default $00E8D0B0;
      property KeyTextColor   : TColor        read FKeyTextColor   write SetKeyTextColor   default clBlack;
      property Align;
      property Anchors;
      property Color;
      property Font;
      property Height default 220;
      property Width default 560;
      property Visible;
  end;

implementation

const
  REPEAT_DELAY    = 450;   // ms before a held key starts to repeat
  REPEAT_INTERVAL = 60;    // ms between repeated key presses

constructor TVirtualHangulKeyboard.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);

  FOutput         := THangulWinOutput.Create;
  FEngine         := THangulEngine.Create(FOutput);
  FEngine.OnChange := EngineChange;
  FDownKey        := -1;
  FGap            := 3;
  FKeyColor       := $00F0F0F0;
  FKeyDownColor   := $00C8C8C8;
  FKeyActiveColor := $00E8D0B0;
  FKeyTextColor   := clBlack;

  FRepeatTimer           := TTimer.Create(self);
  FRepeatTimer.Enabled   := False;
  FRepeatTimer.OnTimer   := RepeatTimerEvent;

  Color  := $00808080;
  Width  := 560;
  Height := 220;
  Font.Name := 'Malgun Gothic';
  Font.Size := 12;
end;

destructor TVirtualHangulKeyboard.Destroy;
begin
  StopRepeat;
  FEngine.Free;
  FOutput.Free;

  inherited Destroy;
end;

function TVirtualHangulKeyboard.GetLayout : THangulLayout;
begin
  Result := FEngine.Layout;
end;

procedure TVirtualHangulKeyboard.SetLayout(aValue : THangulLayout);
begin
  FEngine.Layout := aValue;
end;

function TVirtualHangulKeyboard.GetKorean : boolean;
begin
  Result := FEngine.Korean;
end;

procedure TVirtualHangulKeyboard.SetKorean(aValue : boolean);
begin
  FEngine.Korean := aValue;
end;

procedure TVirtualHangulKeyboard.SetColorProp(var aField : TColor; aValue : TColor);
begin
  if (aField <> aValue) then
    begin
      aField := aValue;
      Invalidate;
    end;
end;

procedure TVirtualHangulKeyboard.SetKeyColor(aValue : TColor);
begin
  SetColorProp(FKeyColor, aValue);
end;

procedure TVirtualHangulKeyboard.SetKeyDownColor(aValue : TColor);
begin
  SetColorProp(FKeyDownColor, aValue);
end;

procedure TVirtualHangulKeyboard.SetKeyActiveColor(aValue : TColor);
begin
  SetColorProp(FKeyActiveColor, aValue);
end;

procedure TVirtualHangulKeyboard.SetKeyTextColor(aValue : TColor);
begin
  SetColorProp(FKeyTextColor, aValue);
end;

procedure TVirtualHangulKeyboard.EngineChange(Sender : TObject);
begin
  StopRepeat;
  FDownKey := -1;
  Invalidate;
end;

procedure TVirtualHangulKeyboard.StopRepeat;
begin
  if (FRepeatTimer <> nil) then
    FRepeatTimer.Enabled := False;
end;

procedure TVirtualHangulKeyboard.RepeatTimerEvent(Sender : TObject);
begin
  if (FDownKey < 0) then
    StopRepeat
   else
    begin
      FRepeatTimer.Interval := REPEAT_INTERVAL;
      FEngine.PressKey(FDownKey);
    end;
end;

function TVirtualHangulKeyboard.KeyRect(aIndex : integer) : TRect;
var
  TempKey : THangulKey;
begin
  TempKey := FEngine.Keys[aIndex];

  Result.Left   := (TempKey.Col * ClientWidth) div HANGUL_GRID_COLS;
  Result.Right  := ((TempKey.Col + TempKey.Span) * ClientWidth) div HANGUL_GRID_COLS;
  Result.Top    := (TempKey.Row * ClientHeight) div FEngine.GridRows;
  Result.Bottom := ((TempKey.Row + 1) * ClientHeight) div FEngine.GridRows;

  InflateRect(Result, -FGap, -FGap);
end;

function TVirtualHangulKeyboard.KeyAt(aX, aY : integer) : integer;
var
  i : integer;
  TempRect : TRect;
begin
  Result := -1;

  for i := 0 to pred(FEngine.KeyCount) do
    begin
      TempRect := KeyRect(i);

      if PtInRect(TempRect, Point(aX, aY)) then
        begin
          Result := i;
          exit;
        end;
    end;
end;

procedure TVirtualHangulKeyboard.Paint;
var
  i : integer;
  TempRect : TRect;
  TempKey : THangulKey;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := FKeyTextColor;
  Canvas.Pen.Color  := $00A0A0A0;
  SetBkMode(Canvas.Handle, TRANSPARENT);

  for i := 0 to pred(FEngine.KeyCount) do
    begin
      TempKey  := FEngine.Keys[i];
      TempRect := KeyRect(i);

      if (i = FDownKey) then
        Canvas.Brush.Color := FKeyDownColor
       else
        if TempKey.Active then
          Canvas.Brush.Color := FKeyActiveColor
         else
          Canvas.Brush.Color := FKeyColor;

      Canvas.RoundRect(TempRect.Left, TempRect.Top, TempRect.Right, TempRect.Bottom, 8, 8);

      if (length(TempKey.Caption) > 0) then
        DrawTextW(Canvas.Handle, PWideChar(TempKey.Caption), length(TempKey.Caption),
                  TempRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    end;
end;

procedure TVirtualHangulKeyboard.MouseDown(Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
var
  TempKey : integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if (Button = mbLeft) and not(csDesigning in ComponentState) then
    begin
      TempKey  := KeyAt(X, Y);
      FDownKey := TempKey;

      if (TempKey >= 0) then
        begin
          Invalidate;
          // The key is typed when it's pressed. PressKey might rebuild the keys
          // and call EngineChange, which clears FDownKey.
          FEngine.PressKey(TempKey);

          if (FDownKey = TempKey) and FEngine.IsRepeatKey(TempKey) then
            begin
              FRepeatTimer.Interval := REPEAT_DELAY;
              FRepeatTimer.Enabled  := True;
            end;
        end;
    end;
end;

procedure TVirtualHangulKeyboard.MouseUp(Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  StopRepeat;

  if (FDownKey >= 0) then
    begin
      FDownKey := -1;
      Invalidate;
    end;
end;

end.
