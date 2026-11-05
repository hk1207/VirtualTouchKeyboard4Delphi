unit uVirtualHangulEngine;

{$IFDEF FPC}{$MODE Delphi}{$ENDIF}

// Framework independent logic of the Hangul virtual keyboard.
//
// The engine knows the key layouts (Dubeolsik, Cheonjiin, English and
// symbols), handles the shift / language / symbol states and sends the typed
// text to a THangulOutput object. The VCL and FMX controls only draw the keys
// that the engine creates and call PressKey when a key is pressed.
//
// This file contains only ASCII characters on purpose: all the Hangul
// characters are written as Unicode code points.

{$I VirtualTouchKeyboard.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    System.Classes,
  {$ELSE}
    Classes,
  {$ENDIF}
  uHangulComposer;

const
  HANGUL_GRID_COLS = 20;

type
  /// <summary>
  /// Korean keyboard layout.
  /// </summary>
  THangulLayout = (hlDubeolsik, hlCheonjiin);

  TKeyKind = (kkChar,       // Types the first character of Chars
              kkCycle,      // Every press selects the next character of Chars
              kkBackspace,
              kkSpace,
              kkEnter,
              kkShift,
              kkLang,       // Korean / English
              kkSymbol,     // Symbols / letters
              kkLayout);    // Dubeolsik / Cheonjiin

  /// <summary>
  /// Key of the keyboard. The position is measured in grid cells : the
  /// keyboard has HANGUL_GRID_COLS columns and GridRows rows.
  /// </summary>
  THangulKey = record
    Kind    : TKeyKind;
    Caption : WideString;
    Chars   : WideString;
    Row     : integer;
    Col     : integer;
    Span    : integer;
    Active  : boolean;
  end;

  /// <summary>
  /// Where the engine sends the typed text. See uHangulWinOutput for the
  /// Windows implementation.
  /// </summary>
  THangulOutput = class
    public
      procedure SendText(const aText : WideString); virtual; abstract;
      procedure SendBackspace; virtual; abstract;
      procedure SendEnter; virtual; abstract;
      /// <summary>
      /// Identifies the control that receives the text. When it changes the
      /// engine stops composing the current syllable.
      /// </summary>
      function  FocusToken : Int64; virtual; abstract;
  end;

  THangulEngine = class
    protected
      FOutput       : THangulOutput;
      FComposer     : THangulComposer;
      FKeys         : array of THangulKey;
      FKeyCount     : integer;
      FGridRows     : integer;
      FLayout       : THangulLayout;
      FKorean       : boolean;
      FShift        : boolean;
      FSymbol       : boolean;
      FFocusToken   : Int64;
      FCycleKey     : integer;
      FCycleIdx     : integer;
      FCycleBase    : THangulComposerState;
      FCycleScreen  : WideString;
      FOnChange     : TNotifyEvent;

      function  GetKey(aIndex : integer) : THangulKey;

      procedure SetLayout(aValue : THangulLayout);
      procedure SetKorean(aValue : boolean);
      procedure SetShift(aValue : boolean);
      procedure SetSymbol(aValue : boolean);

      procedure DoChange;
      procedure AddKey(aKind : TKeyKind; const aCaption, aChars : WideString; aRow, aCol, aSpan : integer; aActive : boolean = False);
      procedure AddCharKeys(const aChars : WideString; aRow, aCol : integer);
      procedure BuildKeys;
      procedure BuildQwertyKeys;
      procedure BuildCheonjiinKeys;

      procedure CheckTarget;
      procedure Replace(const aOld, aTarget : WideString);
      procedure FinishComposition;
      procedure TypeChar(aChar : WideChar);
      procedure InputJamo(aChar : WideChar);
      procedure DoCycle(aIndex : integer);
      procedure DoBackspace;
      procedure ReleaseShift;

    public
      constructor Create(aOutput : THangulOutput);
      destructor  Destroy; override;

      /// <summary>
      /// Executes the action of the key aIndex.
      /// </summary>
      procedure PressKey(aIndex : integer);
      /// <summary>
      /// Stops composing the current syllable. The text that is already in the
      /// control is not changed. Call it when the user moves the caret.
      /// </summary>
      procedure ResetComposition;
      /// <summary>
      /// Returns true if the key has to be repeated while it's held down
      /// (the backspace key).
      /// </summary>
      function  IsRepeatKey(aIndex : integer) : boolean;

      property KeyCount           : integer             read FKeyCount;
      property Keys[aIndex : integer] : THangulKey      read GetKey;
      property GridRows           : integer             read FGridRows;
      property Layout             : THangulLayout       read FLayout   write SetLayout;
      /// <summary>
      /// True = Korean letters, False = English letters.
      /// </summary>
      property Korean             : boolean             read FKorean   write SetKorean;
      property Shift              : boolean             read FShift    write SetShift;
      property Symbol             : boolean             read FSymbol   write SetSymbol;
      property Output             : THangulOutput       read FOutput   write FOutput;
      property OnChange           : TNotifyEvent        read FOnChange write FOnChange;
  end;

implementation

function CodesToStr(const aCodes : array of Word) : WideString;
var
  i : integer;
begin
  Result := '';
  for i := low(aCodes) to high(aCodes) do
    Result := Result + WideChar(aCodes[i]);
end;

function W1(a : Word) : WideString;
begin
  Result := WideChar(a);
end;

function W2(a, b : Word) : WideString;
begin
  Result := WideChar(a) + WideChar(b);
end;

function W3(a, b, c : Word) : WideString;
begin
  Result := WideChar(a) + WideChar(b) + WideChar(c);
end;

const
  // Dubeolsik rows : q w e r t y u i o p / a s d f g h j k l / z x c v b n m
  DUBEOLSIK_ROW1 : array[0..9] of Word = ($3142, $3148, $3137, $3131, $3145, $315B, $3155, $3151, $3150, $3154);
  DUBEOLSIK_ROW2 : array[0..8] of Word = ($3141, $3134, $3147, $3139, $314E, $3157, $3153, $314F, $3163);
  DUBEOLSIK_ROW3 : array[0..6] of Word = ($314B, $314C, $314A, $314D, $3160, $315C, $3161);
  // The same keys with the shift key pressed
  DUBEOLSIK_ROW1_SHIFT : array[0..9] of Word = ($3143, $3149, $3138, $3132, $3146, $315B, $3155, $3151, $3152, $3156);

  // Captions
  CAP_LANG    : array[0..2] of Word = ($D55C, $002F, $C601);          // han/yeong
  CAP_DUBEOL  : array[0..2] of Word = ($B450, $BC8C, $C2DD);          // dubeolsik
  CAP_CHEONJI : array[0..2] of Word = ($CC9C, $C9C0, $C778);          // cheonjiin
  CAP_SPACE   : array[0..1] of Word = ($B744, $AE30);                 // space (spacing)

  CAP_BACKSPACE = $232B;
  CAP_ENTER     = $23CE;
  CAP_SHIFT     = $21E7;

{ THangulEngine }

constructor THangulEngine.Create(aOutput : THangulOutput);
begin
  inherited Create;

  FOutput     := aOutput;
  FComposer   := THangulComposer.Create;
  FLayout     := hlDubeolsik;
  FKorean     := True;
  FShift      := False;
  FSymbol     := False;
  FFocusToken := 0;
  FCycleKey   := -1;
  FCycleIdx   := 0;
  FCycleScreen := '';

  BuildKeys;
end;

destructor THangulEngine.Destroy;
begin
  FComposer.Free;

  inherited Destroy;
end;

function THangulEngine.GetKey(aIndex : integer) : THangulKey;
begin
  Result := FKeys[aIndex];
end;

procedure THangulEngine.DoChange;
begin
  if assigned(FOnChange) then
    FOnChange(self);
end;

procedure THangulEngine.SetLayout(aValue : THangulLayout);
begin
  if (FLayout <> aValue) then
    begin
      FinishComposition;
      FLayout := aValue;
      FComposer.Cheonjiin := (FLayout = hlCheonjiin);
      FCycleKey := -1;
      BuildKeys;
      DoChange;
    end;
end;

procedure THangulEngine.SetKorean(aValue : boolean);
begin
  if (FKorean <> aValue) then
    begin
      FinishComposition;
      FKorean := aValue;
      FShift  := False;
      FCycleKey := -1;
      BuildKeys;
      DoChange;
    end;
end;

procedure THangulEngine.SetShift(aValue : boolean);
begin
  if (FShift <> aValue) then
    begin
      FShift := aValue;
      BuildKeys;
      DoChange;
    end;
end;

procedure THangulEngine.SetSymbol(aValue : boolean);
begin
  if (FSymbol <> aValue) then
    begin
      FinishComposition;
      FSymbol := aValue;
      FShift  := False;
      FCycleKey := -1;
      BuildKeys;
      DoChange;
    end;
end;

procedure THangulEngine.AddKey(aKind : TKeyKind; const aCaption, aChars : WideString; aRow, aCol, aSpan : integer; aActive : boolean);
begin
  if (FKeyCount >= length(FKeys)) then
    SetLength(FKeys, length(FKeys) + 16);

  FKeys[FKeyCount].Kind    := aKind;
  FKeys[FKeyCount].Caption := aCaption;
  FKeys[FKeyCount].Chars   := aChars;
  FKeys[FKeyCount].Row     := aRow;
  FKeys[FKeyCount].Col     := aCol;
  FKeys[FKeyCount].Span    := aSpan;
  FKeys[FKeyCount].Active  := aActive;

  inc(FKeyCount);
end;

// One key with a width of 2 cells for each character of aChars
procedure THangulEngine.AddCharKeys(const aChars : WideString; aRow, aCol : integer);
var
  i : integer;
begin
  for i := 1 to length(aChars) do
    AddKey(kkChar, aChars[i], aChars[i], aRow, aCol + ((i - 1) * 2), 2);
end;

procedure THangulEngine.BuildKeys;
begin
  FKeyCount := 0;
  FComposer.Cheonjiin := (FLayout = hlCheonjiin);

  if FKorean and not(FSymbol) and (FLayout = hlCheonjiin) then
    BuildCheonjiinKeys
   else
    BuildQwertyKeys;
end;

procedure THangulEngine.BuildQwertyKeys;
var
  TempRow0, TempRow1, TempRow2, TempRow3 : WideString;
  TempLayoutCaption : WideString;
begin
  FGridRows     := 5;
  TempRow0      := '1234567890';

  if FSymbol then
    begin
      TempRow1 := '!@#$%^&*()';
      TempRow2 := '-_=+[]{}|';
      TempRow3 := ';:''"<>?';
    end
   else
    if FKorean then
      begin
        if FShift then
          TempRow1 := CodesToStr(DUBEOLSIK_ROW1_SHIFT)
         else
          TempRow1 := CodesToStr(DUBEOLSIK_ROW1);

        TempRow2 := CodesToStr(DUBEOLSIK_ROW2);
        TempRow3 := CodesToStr(DUBEOLSIK_ROW3);
      end
     else
      begin
        TempRow1 := 'qwertyuiop';
        TempRow2 := 'asdfghjkl';
        TempRow3 := 'zxcvbnm';

        if FShift then
          begin
            TempRow1 := 'QWERTYUIOP';
            TempRow2 := 'ASDFGHJKL';
            TempRow3 := 'ZXCVBNM';
          end;
      end;

  AddCharKeys(TempRow0, 0, 0);
  AddCharKeys(TempRow1, 1, 0);
  AddCharKeys(TempRow2, 2, 1);

  // Row 3 : shift, 7 characters, backspace
  if FSymbol then
    AddKey(kkChar, '`', '`', 3, 0, 3)
   else
    AddKey(kkShift, W1(CAP_SHIFT), '', 3, 0, 3, FShift);

  AddCharKeys(TempRow3, 3, 3);
  AddKey(kkBackspace, W1(CAP_BACKSPACE), '', 3, 17, 3);

  // Row 4
  if FSymbol then
    AddKey(kkSymbol, 'ABC', '', 4, 0, 2, True)
   else
    AddKey(kkSymbol, '?123', '', 4, 0, 2, False);

  AddKey(kkLang, CodesToStr(CAP_LANG), '', 4, 2, 3, FKorean and not(FSymbol));

  if (FLayout = hlDubeolsik) then
    TempLayoutCaption := CodesToStr(CAP_CHEONJI)
   else
    TempLayoutCaption := CodesToStr(CAP_DUBEOL);

  AddKey(kkLayout, TempLayoutCaption, '', 4, 5, 3);
  AddKey(kkChar, ',', ',', 4, 8, 2);
  AddKey(kkSpace, '', ' ', 4, 10, 4);
  AddKey(kkChar, '.', '.', 4, 14, 2);
  AddKey(kkEnter, W1(CAP_ENTER), '', 4, 16, 4);
end;

procedure THangulEngine.BuildCheonjiinKeys;
begin
  FGridRows := 4;

  // Row 0
  AddKey(kkChar, W1($3163), W1($3163), 0, 0, 5);
  AddKey(kkChar, W1($318D), W1($318D), 0, 5, 5);
  AddKey(kkChar, W1($3161), W1($3161), 0, 10, 5);
  AddKey(kkBackspace, W1(CAP_BACKSPACE), '', 0, 15, 5);

  // Row 1
  AddKey(kkCycle, W2($3131, $314B), W3($3131, $314B, $3132), 1, 0, 5);
  AddKey(kkCycle, W2($3134, $3139), W2($3134, $3139), 1, 5, 5);
  AddKey(kkCycle, W2($3137, $314C), W3($3137, $314C, $3138), 1, 10, 5);
  AddKey(kkSpace, CodesToStr(CAP_SPACE), ' ', 1, 15, 5);

  // Row 2
  AddKey(kkCycle, W2($3142, $314D), W3($3142, $314D, $3143), 2, 0, 5);
  AddKey(kkCycle, W2($3145, $314E), W3($3145, $314E, $3146), 2, 5, 5);
  AddKey(kkCycle, W2($3148, $314A), W3($3148, $314A, $3149), 2, 10, 5);
  AddKey(kkEnter, W1(CAP_ENTER), '', 2, 15, 5);

  // Row 3
  AddKey(kkSymbol, '?123', '', 3, 0, 4);
  AddKey(kkCycle, W2($3147, $3141), W2($3147, $3141), 3, 4, 5);
  AddKey(kkCycle, '.,?!', '.,?!', 3, 9, 5);
  AddKey(kkLang, CodesToStr(CAP_LANG), '', 3, 14, 3, True);
  AddKey(kkLayout, CodesToStr(CAP_DUBEOL), '', 3, 17, 3);
end;

procedure THangulEngine.CheckTarget;
var
  TempToken : Int64;
begin
  if (FOutput = nil) then exit;

  TempToken := FOutput.FocusToken;

  if (TempToken <> FFocusToken) then
    begin
      FFocusToken := TempToken;
      ResetComposition;
    end;
end;

procedure THangulEngine.ResetComposition;
begin
  FComposer.Reset;
  FCycleKey := -1;
end;

// Changes the text that is on the screen from aOld to aTarget
procedure THangulEngine.Replace(const aOld, aTarget : WideString);
var
  TempBackspaces, i : integer;
  TempText : WideString;
begin
  if (FOutput = nil) then exit;

  ComputeHangulEdit(aOld, aTarget, TempBackspaces, TempText);

  for i := 1 to TempBackspaces do
    FOutput.SendBackspace;

  if (length(TempText) > 0) then
    FOutput.SendText(TempText);
end;

procedure THangulEngine.FinishComposition;
begin
  FComposer.Reset;
  FCycleKey := -1;
end;

procedure THangulEngine.InputJamo(aChar : WideChar);
var
  TempOld, TempCommit : WideString;
begin
  TempOld := FComposer.Composing;
  FComposer.Input(aChar, TempCommit);
  Replace(TempOld, TempCommit + FComposer.Composing);
end;

procedure THangulEngine.TypeChar(aChar : WideChar);
begin
  if IsHangulJamo(aChar) then
    InputJamo(aChar)
   else
    begin
      FinishComposition;

      if (FOutput <> nil) then
        FOutput.SendText(aChar);
    end;
end;

procedure THangulEngine.DoCycle(aIndex : integer);
var
  TempChars, TempCommit, TempTarget : WideString;
  TempChar : WideChar;
begin
  TempChars := FKeys[aIndex].Chars;

  if (FCycleKey = aIndex) then
    begin
      FCycleIdx := (FCycleIdx + 1) mod length(TempChars);
      FComposer.State := FCycleBase;
    end
   else
    begin
      FCycleKey := aIndex;
      FCycleIdx := 0;

      if IsHangulJamo(TempChars[1]) then
        FCycleScreen := FComposer.Composing
       else
        begin
          // The text in the control is not replaced : it is only finished.
          FComposer.Reset;
          FCycleScreen := '';
        end;

      FCycleBase := FComposer.State;
    end;

  TempChar := TempChars[FCycleIdx + 1];

  if IsHangulJamo(TempChar) then
    begin
      FComposer.Input(TempChar, TempCommit);
      TempTarget := TempCommit + FComposer.Composing;
    end
   else
    TempTarget := TempChar;

  Replace(FCycleScreen, TempTarget);
  FCycleScreen := TempTarget;
end;

procedure THangulEngine.DoBackspace;
var
  TempOld : WideString;
begin
  TempOld := FComposer.Composing;

  if (length(TempOld) > 0) and FComposer.Backspace then
    Replace(TempOld, FComposer.Composing)
   else
    if (FOutput <> nil) then
      FOutput.SendBackspace;
end;

function THangulEngine.IsRepeatKey(aIndex : integer) : boolean;
begin
  Result := (aIndex >= 0) and (aIndex < FKeyCount) and (FKeys[aIndex].Kind = kkBackspace);
end;

procedure THangulEngine.ReleaseShift;
begin
  if FShift then
    begin
      FShift := False;
      BuildKeys;
      DoChange;
    end;
end;

procedure THangulEngine.PressKey(aIndex : integer);
var
  TempKind : TKeyKind;
begin
  if (aIndex < 0) or (aIndex >= FKeyCount) then exit;

  CheckTarget;

  TempKind := FKeys[aIndex].Kind;

  if (TempKind <> kkCycle) then
    FCycleKey := -1;

  case TempKind of
    kkChar :
      begin
        TypeChar(FKeys[aIndex].Chars[1]);
        ReleaseShift;
      end;

    kkCycle :
      begin
        DoCycle(aIndex);
        ReleaseShift;
      end;

    kkBackspace :
      DoBackspace;

    kkSpace :
      begin
        FinishComposition;
        if (FOutput <> nil) then FOutput.SendText(' ');
      end;

    kkEnter :
      begin
        FinishComposition;
        if (FOutput <> nil) then FOutput.SendEnter;
      end;

    kkShift :
      SetShift(not(FShift));

    kkLang :
      begin
        if FSymbol then
          begin
            FSymbol := False;
            FinishComposition;
            BuildKeys;
            DoChange;
          end
         else
          SetKorean(not(FKorean));
      end;

    kkSymbol :
      SetSymbol(not(FSymbol));

    kkLayout :
      begin
        if (FLayout = hlDubeolsik) then
          SetLayout(hlCheonjiin)
         else
          SetLayout(hlDubeolsik);
      end;
  end;
end;

end.
