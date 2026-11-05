unit uVirtualHangulKeyboardFMX;

{$I VirtualTouchKeyboard.inc}

// FireMonkey virtual keyboard that can type Hangul without TabTip.exe or an
// IME. It supports the Dubeolsik and Cheonjiin layouts, English letters and
// symbols. Windows only : the text is sent with SendInput.
//
// The control can't get the keyboard focus, so clicking on it doesn't take the
// focus from the edit control that is being used.

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Graphics,
  uVirtualHangulEngine, uHangulWinOutput;

type
  /// <summary>
  /// FireMonkey virtual keyboard with Korean (Hangul) input.
  /// </summary>
  [ComponentPlatformsAttribute(pidWin32 or pidWin64)]
  TVirtualHangulKeyboardFMX = class(TControl)
    protected
      FEngine         : THangulEngine;
      FOutput         : THangulWinOutput;
      FDownKey        : integer;
      FKeyColor       : TAlphaColor;
      FKeyDownColor   : TAlphaColor;
      FKeyActiveColor : TAlphaColor;
      FKeyTextColor   : TAlphaColor;
      FBackColor      : TAlphaColor;
      FFontSize       : Single;
      FRepeatTimer    : TTimer;

      function  GetLayout : THangulLayout;
      procedure SetLayout(aValue : THangulLayout);
      function  GetKorean : boolean;
      procedure SetKorean(aValue : boolean);

      procedure EngineChange(Sender : TObject);
      procedure RepeatTimerEvent(Sender : TObject);
      procedure StopRepeat;
      function  KeyRect(aIndex : integer) : TRectF;
      function  KeyAt(aX, aY : Single) : integer;

      procedure Paint; override;
      procedure MouseDown(Button : TMouseButton; Shift : TShiftState; X, Y : Single); override;
      procedure MouseUp(Button : TMouseButton; Shift : TShiftState; X, Y : Single); override;

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
      property KeyColor       : TAlphaColor   read FKeyColor       write FKeyColor;
      property KeyDownColor   : TAlphaColor   read FKeyDownColor   write FKeyDownColor;
      property KeyActiveColor : TAlphaColor   read FKeyActiveColor write FKeyActiveColor;
      property KeyTextColor   : TAlphaColor   read FKeyTextColor   write FKeyTextColor;
      property BackColor      : TAlphaColor   read FBackColor      write FBackColor;
      property FontSize       : Single        read FFontSize       write FFontSize;
      property Align;
      property Anchors;
      property Height;
      property Width;
      property Margins;
      property Position;
      property Size;
      property Visible;
  end;

implementation

const
  KEY_GAP         = 3;
  REPEAT_DELAY    = 450;   // ms before a held key starts to repeat
  REPEAT_INTERVAL = 60;    // ms between repeated key presses

constructor TVirtualHangulKeyboardFMX.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);

  FOutput          := THangulWinOutput.Create;
  FEngine          := THangulEngine.Create(FOutput);
  FEngine.OnChange := EngineChange;
  FDownKey         := -1;
  FKeyColor        := $FFF0F0F0;
  FKeyDownColor    := $FFC8C8C8;
  FKeyActiveColor  := $FFB0D0E8;
  FKeyTextColor    := $FF000000;
  FBackColor       := $FF808080;
  FFontSize        := 16;

  FRepeatTimer         := TTimer.Create(self);
  FRepeatTimer.Enabled := False;
  FRepeatTimer.OnTimer := RepeatTimerEvent;

  CanFocus := False;
  HitTest  := True;
  Width    := 560;
  Height   := 220;
end;

destructor TVirtualHangulKeyboardFMX.Destroy;
begin
  StopRepeat;
  FEngine.Free;
  FOutput.Free;

  inherited Destroy;
end;

function TVirtualHangulKeyboardFMX.GetLayout : THangulLayout;
begin
  Result := FEngine.Layout;
end;

procedure TVirtualHangulKeyboardFMX.SetLayout(aValue : THangulLayout);
begin
  FEngine.Layout := aValue;
end;

function TVirtualHangulKeyboardFMX.GetKorean : boolean;
begin
  Result := FEngine.Korean;
end;

procedure TVirtualHangulKeyboardFMX.SetKorean(aValue : boolean);
begin
  FEngine.Korean := aValue;
end;

procedure TVirtualHangulKeyboardFMX.EngineChange(Sender : TObject);
begin
  StopRepeat;
  FDownKey := -1;
  Repaint;
end;

procedure TVirtualHangulKeyboardFMX.StopRepeat;
begin
  if (FRepeatTimer <> nil) then
    FRepeatTimer.Enabled := False;
end;

procedure TVirtualHangulKeyboardFMX.RepeatTimerEvent(Sender : TObject);
begin
  if (FDownKey < 0) then
    StopRepeat
   else
    begin
      FRepeatTimer.Interval := REPEAT_INTERVAL;
      FEngine.PressKey(FDownKey);
    end;
end;

function TVirtualHangulKeyboardFMX.KeyRect(aIndex : integer) : TRectF;
var
  TempKey : THangulKey;
begin
  TempKey := FEngine.Keys[aIndex];

  Result.Left   := (TempKey.Col * Width) / HANGUL_GRID_COLS;
  Result.Right  := ((TempKey.Col + TempKey.Span) * Width) / HANGUL_GRID_COLS;
  Result.Top    := (TempKey.Row * Height) / FEngine.GridRows;
  Result.Bottom := ((TempKey.Row + 1) * Height) / FEngine.GridRows;

  Result.Inflate(-KEY_GAP, -KEY_GAP);
end;

function TVirtualHangulKeyboardFMX.KeyAt(aX, aY : Single) : integer;
var
  i : integer;
begin
  Result := -1;

  for i := 0 to pred(FEngine.KeyCount) do
    if KeyRect(i).Contains(PointF(aX, aY)) then
      begin
        Result := i;
        exit;
      end;
end;

procedure TVirtualHangulKeyboardFMX.Paint;
var
  i : integer;
  TempRect : TRectF;
  TempKey : THangulKey;
begin
  Canvas.Fill.Kind  := TBrushKind.Solid;
  Canvas.Fill.Color := FBackColor;
  Canvas.FillRect(LocalRect, 0, 0, [], 1);

  Canvas.Font.Family := 'Malgun Gothic';
  Canvas.Font.Size   := FFontSize;

  for i := 0 to pred(FEngine.KeyCount) do
    begin
      TempKey  := FEngine.Keys[i];
      TempRect := KeyRect(i);

      if (i = FDownKey) then
        Canvas.Fill.Color := FKeyDownColor
       else
        if TempKey.Active then
          Canvas.Fill.Color := FKeyActiveColor
         else
          Canvas.Fill.Color := FKeyColor;

      Canvas.FillRect(TempRect, 6, 6, AllCorners, 1);

      if (length(TempKey.Caption) > 0) then
        begin
          Canvas.Fill.Color := FKeyTextColor;
          Canvas.FillText(TempRect, TempKey.Caption, False, 1, [], TTextAlign.Center, TTextAlign.Center);
        end;
    end;
end;

procedure TVirtualHangulKeyboardFMX.MouseDown(Button : TMouseButton; Shift : TShiftState; X, Y : Single);
var
  TempKey : integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if (Button = TMouseButton.mbLeft) and not(csDesigning in ComponentState) then
    begin
      TempKey  := KeyAt(X, Y);
      FDownKey := TempKey;

      if (TempKey >= 0) then
        begin
          Repaint;
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

procedure TVirtualHangulKeyboardFMX.MouseUp(Button : TMouseButton; Shift : TShiftState; X, Y : Single);
begin
  inherited MouseUp(Button, Shift, X, Y);

  StopRepeat;

  if (FDownKey >= 0) then
    begin
      FDownKey := -1;
      Repaint;
    end;
end;

end.
