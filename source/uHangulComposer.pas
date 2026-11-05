unit uHangulComposer;

{$IFDEF FPC}{$MODE Delphi}{$ENDIF}

// Platform independent Hangul syllable composer (state machine).
//
// It receives compatibility jamo (U+3131..U+3163 and the Cheonjiin "arae-a"
// U+318D) one at a time and keeps the syllable that is currently being
// composed. It supports the Dubeolsik (2-set) rules and the Cheonjiin
// (Chunjiin) vowel rules.
//
// This unit does not use any Windows or VCL/FMX unit, so it can be tested on
// any platform.
//
// This file contains only ASCII characters on purpose: all the jamo are
// written as Unicode code points.

interface

const
  ARAE_A = $318D;  // Cheonjiin dot vowel

type
  /// <summary>
  /// Snapshot of the composer state. It can be saved and restored later.
  /// </summary>
  THangulComposerState = record
    L : integer;   // Lead consonant index (0..18), -1 = none
    V : Word;      // Vowel compatibility jamo code, 0 = none
    T : integer;   // Tail consonant index (1..27), 0 = none
  end;

  THangulComposer = class
    protected
      FL           : integer;
      FV           : Word;
      FT           : integer;
      FCheonjiin   : boolean;

      function  GetComposing : WideString;
      function  GetState : THangulComposerState;
      procedure SetState(const aState : THangulComposerState);
      function  Syllable(aL : integer; aV : Word; aT : integer) : WideString;

    public
      constructor Create;
      /// <summary>
      /// Forget the composing syllable. The text stays in the target control.
      /// </summary>
      procedure Reset;
      /// <summary>
      /// Add a jamo. aCommit receives the text that is finished and will not
      /// change anymore. After this call the Composing property has the new
      /// composing text. The composing text that was returned before the call
      /// has to be replaced by aCommit + Composing.
      /// </summary>
      procedure Input(aJamo : WideChar; out aCommit : WideString);
      /// <summary>
      /// Remove the last jamo of the composing syllable. Returns False if
      /// there was nothing to remove.
      /// </summary>
      function  Backspace : boolean;

      /// <summary>
      /// The text that is being composed and might change with the next key.
      /// </summary>
      property Composing  : WideString           read GetComposing;
      property State      : THangulComposerState read GetState write SetState;
      /// <summary>
      /// Use the Cheonjiin vowel rules instead of the Dubeolsik ones.
      /// </summary>
      property Cheonjiin  : boolean              read FCheonjiin  write FCheonjiin;
  end;

/// <summary>
/// Returns true if aChar is a Hangul compatibility jamo (consonant or vowel).
/// </summary>
function IsHangulJamo(aChar : WideChar) : boolean;

/// <summary>
/// Calculates how to change the text of a control that shows aOld to make it
/// show aTarget : aBackspaces characters have to be erased and then aText has
/// to be typed.
/// </summary>
procedure ComputeHangulEdit(const aOld, aTarget : WideString; out aBackspaces : integer; out aText : WideString);

implementation

type
  TVowelRule = record
    A, B, R : Word;
  end;

const
  // Compatibility jamo of the 19 lead consonants
  LEAD_CODES : array[0..18] of Word = (
    $3131, $3132, $3134, $3137, $3138, $3139, $3141, $3142, $3143, $3145,
    $3146, $3147, $3148, $3149, $314A, $314B, $314C, $314D, $314E);

  // Compatibility jamo of the 27 tail consonants (index 1..27)
  TAIL_CODES : array[1..27] of Word = (
    $3131, $3132, $3133, $3134, $3135, $3136, $3137, $3139, $313A, $313B,
    $313C, $313D, $313E, $313F, $3140, $3141, $3142, $3144, $3145, $3146,
    $3147, $3148, $314A, $314B, $314C, $314D, $314E);

  FIRST_VOWEL = $314F;
  LAST_VOWEL  = $3163;

  // Compound tails : tail index, first tail index, second tail index
  COMPOUND_TAIL_COUNT = 11;
  COMPOUND_TAILS : array[0..COMPOUND_TAIL_COUNT - 1, 0..2] of integer = (
    (3, 1, 19),   (5, 4, 22),   (6, 4, 27),   (9, 8, 1),    (10, 8, 16),
    (11, 8, 17),  (12, 8, 19),  (13, 8, 25),  (14, 8, 26),  (15, 8, 27),
    (18, 17, 19));

  DUBEOLSIK_RULES : array[0..6] of TVowelRule = (
    (A: $3157; B: $314F; R: $3158),   // o  + a  = wa
    (A: $3157; B: $3150; R: $3159),   // o  + ae = wae
    (A: $3157; B: $3163; R: $315A),   // o  + i  = oe
    (A: $315C; B: $3153; R: $315D),   // u  + eo = wo
    (A: $315C; B: $3154; R: $315E),   // u  + e  = we
    (A: $315C; B: $3163; R: $315F),   // u  + i  = wi
    (A: $3161; B: $3163; R: $3162));  // eu + i  = ui

  CHEONJIIN_RULES : array[0..18] of TVowelRule = (
    (A: $3163; B: ARAE_A; R: $314F),  // i  + . = a
    (A: $314F; B: ARAE_A; R: $3151),  // a  + . = ya
    (A: ARAE_A; B: $3163; R: $3153),  // .  + i = eo
    (A: $3153; B: ARAE_A; R: $3155),  // eo + . = yeo
    (A: ARAE_A; B: $3161; R: $3157),  // .  + eu = o
    (A: $3157; B: ARAE_A; R: $315B),  // o  + . = yo
    (A: $3161; B: ARAE_A; R: $315C),  // eu + . = u
    (A: $315C; B: ARAE_A; R: $3160),  // u  + . = yu
    (A: $3161; B: $3163; R: $3162),   // eu + i = ui
    (A: $314F; B: $3163; R: $3150),   // a  + i = ae
    (A: $3153; B: $3163; R: $3154),   // eo + i = e
    (A: $3151; B: $3163; R: $3152),   // ya + i = yae
    (A: $3155; B: $3163; R: $3156),   // yeo+ i = ye
    (A: $3157; B: $3163; R: $315A),   // o  + i = oe
    (A: $315C; B: $3163; R: $315F),   // u  + i = wi
    (A: $315A; B: ARAE_A; R: $3158),  // oe + . = wa
    (A: $3158; B: $3163; R: $3159),   // wa + i = wae
    (A: $315F; B: ARAE_A; R: $315D),  // wi + . = wo
    (A: $315D; B: $3163; R: $315E));  // wo + i = we

function IsHangulJamo(aChar : WideChar) : boolean;
begin
  Result := ((Word(aChar) >= $3131) and (Word(aChar) <= LAST_VOWEL)) or
            (Word(aChar) = ARAE_A);
end;

function IsConsonantCode(aCode : Word) : boolean;
begin
  Result := (aCode >= $3131) and (aCode < FIRST_VOWEL);
end;

function LeadIndex(aCode : Word) : integer;
var
  i : integer;
begin
  Result := -1;
  for i := 0 to 18 do
    if (LEAD_CODES[i] = aCode) then
      begin
        Result := i;
        exit;
      end;
end;

function TailIndex(aCode : Word) : integer;
var
  i : integer;
begin
  Result := 0;
  for i := 1 to 27 do
    if (TAIL_CODES[i] = aCode) then
      begin
        Result := i;
        exit;
      end;
end;

function IsSyllableVowel(aCode : Word) : boolean;
begin
  Result := (aCode >= FIRST_VOWEL) and (aCode <= LAST_VOWEL);
end;

function CombineTails(aTail, aNext : integer) : integer;
var
  i : integer;
begin
  Result := 0;
  for i := 0 to pred(COMPOUND_TAIL_COUNT) do
    if (COMPOUND_TAILS[i, 1] = aTail) and (COMPOUND_TAILS[i, 2] = aNext) then
      begin
        Result := COMPOUND_TAILS[i, 0];
        exit;
      end;
end;

// Splits a tail in the part that stays and the part that moves to the next
// syllable. aKeep is 0 if the tail is a single consonant.
procedure SplitTail(aTail : integer; out aKeep, aMove : integer);
var
  i : integer;
begin
  aKeep := 0;
  aMove := aTail;
  for i := 0 to pred(COMPOUND_TAIL_COUNT) do
    if (COMPOUND_TAILS[i, 0] = aTail) then
      begin
        aKeep := COMPOUND_TAILS[i, 1];
        aMove := COMPOUND_TAILS[i, 2];
        exit;
      end;
end;

function CombineVowels(aCheonjiin : boolean; aA, aB : Word) : Word;
var
  i : integer;
begin
  Result := 0;

  if aCheonjiin then
    begin
      for i := low(CHEONJIIN_RULES) to high(CHEONJIIN_RULES) do
        if (CHEONJIIN_RULES[i].A = aA) and (CHEONJIIN_RULES[i].B = aB) then
          begin
            Result := CHEONJIIN_RULES[i].R;
            exit;
          end;
    end
   else
    for i := low(DUBEOLSIK_RULES) to high(DUBEOLSIK_RULES) do
      if (DUBEOLSIK_RULES[i].A = aA) and (DUBEOLSIK_RULES[i].B = aB) then
        begin
          Result := DUBEOLSIK_RULES[i].R;
          exit;
        end;
end;

// Returns the vowel that was typed before aVowel, or 0 if aVowel is a simple
// vowel.
function PreviousVowel(aCheonjiin : boolean; aVowel : Word) : Word;
var
  i : integer;
begin
  Result := 0;

  if aCheonjiin then
    begin
      for i := low(CHEONJIIN_RULES) to high(CHEONJIIN_RULES) do
        if (CHEONJIIN_RULES[i].R = aVowel) then
          begin
            Result := CHEONJIIN_RULES[i].A;
            exit;
          end;
    end
   else
    for i := low(DUBEOLSIK_RULES) to high(DUBEOLSIK_RULES) do
      if (DUBEOLSIK_RULES[i].R = aVowel) then
        begin
          Result := DUBEOLSIK_RULES[i].A;
          exit;
        end;
end;

procedure ComputeHangulEdit(const aOld, aTarget : WideString; out aBackspaces : integer; out aText : WideString);
var
  TempOldLen : integer;
begin
  TempOldLen := length(aOld);

  if (TempOldLen <= length(aTarget)) and (copy(aTarget, 1, TempOldLen) = aOld) then
    begin
      // The old text is still valid, we only have to add the rest.
      aBackspaces := 0;
      aText       := copy(aTarget, TempOldLen + 1, length(aTarget));
    end
   else
    begin
      aBackspaces := TempOldLen;
      aText       := aTarget;
    end;
end;

{ THangulComposer }

constructor THangulComposer.Create;
begin
  inherited Create;

  FCheonjiin := False;
  Reset;
end;

procedure THangulComposer.Reset;
begin
  FL := -1;
  FV := 0;
  FT := 0;
end;

function THangulComposer.GetState : THangulComposerState;
begin
  Result.L := FL;
  Result.V := FV;
  Result.T := FT;
end;

procedure THangulComposer.SetState(const aState : THangulComposerState);
begin
  FL := aState.L;
  FV := aState.V;
  FT := aState.T;
end;

function THangulComposer.Syllable(aL : integer; aV : Word; aT : integer) : WideString;
begin
  if IsSyllableVowel(aV) then
    Result := WideChar($AC00 + (((aL * 21) + (aV - FIRST_VOWEL)) * 28) + aT)
   else
    // A syllable can't be built with the Cheonjiin dot, show the jamo.
    Result := WideChar(LEAD_CODES[aL]) + WideChar(aV);
end;

function THangulComposer.GetComposing : WideString;
begin
  if (FV = 0) then
    begin
      if (FL < 0) then
        Result := ''
       else
        Result := WideChar(LEAD_CODES[FL]);
    end
   else
    if (FL < 0) then
      Result := WideChar(FV)
     else
      Result := Syllable(FL, FV, FT);
end;

procedure THangulComposer.Input(aJamo : WideChar; out aCommit : WideString);
var
  TempCode    : Word;
  TempLead    : integer;
  TempTail    : integer;
  TempVowel   : Word;
  TempKeep    : integer;
  TempMove    : integer;
  TempNewLead : integer;
begin
  aCommit  := '';
  TempCode := Word(aJamo);

  if not(IsHangulJamo(aJamo)) then
    begin
      // Not a jamo, finish the composition.
      aCommit := GetComposing + aJamo;
      Reset;
      exit;
    end;

  if IsConsonantCode(TempCode) then
    begin
      TempLead := LeadIndex(TempCode);
      TempTail := TailIndex(TempCode);

      if (TempLead < 0) then
        begin
          // Compound consonants (for example U+3133) can't start a syllable.
          aCommit := GetComposing + aJamo;
          Reset;
          exit;
        end;

      if (FL < 0) and (FV = 0) then
        FL := TempLead
       else
        if (FL >= 0) and IsSyllableVowel(FV) then
          begin
            if (FT = 0) then
              begin
                if (TempTail > 0) then
                  FT := TempTail
                 else
                  begin
                    aCommit := GetComposing;
                    Reset;
                    FL := TempLead;
                  end;
              end
             else
              begin
                TempKeep := 0;

                if (TempTail > 0) then
                  TempKeep := CombineTails(FT, TempTail);

                if (TempKeep > 0) then
                  FT := TempKeep
                 else
                  begin
                    aCommit := GetComposing;
                    Reset;
                    FL := TempLead;
                  end;
              end;
          end
         else
          begin
            // Lone consonant, lone vowel or incomplete Cheonjiin vowel
            aCommit := GetComposing;
            Reset;
            FL := TempLead;
          end;
    end
   else
    begin
      // Vowel
      if (FV = 0) then
        FV := TempCode   // empty or after a lone consonant
       else
        if (FT = 0) then
          begin
            TempVowel := CombineVowels(FCheonjiin, FV, TempCode);

            if (TempVowel <> 0) then
              FV := TempVowel
             else
              begin
                aCommit := GetComposing;
                Reset;
                FV := TempCode;
              end;
          end
         else
          begin
            // The tail moves to the new syllable.
            SplitTail(FT, TempKeep, TempMove);
            TempNewLead := LeadIndex(TAIL_CODES[TempMove]);
            aCommit     := Syllable(FL, FV, TempKeep);
            FL          := TempNewLead;
            FV          := TempCode;
            FT          := 0;
          end;
    end;
end;

function THangulComposer.Backspace : boolean;
var
  TempKeep, TempMove : integer;
begin
  Result := (FL >= 0) or (FV <> 0);

  if (FT > 0) then
    begin
      SplitTail(FT, TempKeep, TempMove);
      FT := TempKeep;
    end
   else
    if (FV <> 0) then
      FV := PreviousVowel(FCheonjiin, FV)
     else
      if (FL >= 0) then
        FL := -1;
end;

end.
