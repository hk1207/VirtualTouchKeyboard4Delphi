program TestHangul;

// Console tests of the Hangul composer and keyboard engine (no Windows needed).
// Build with Free Pascal :
//   fpc -Mdelphi -Fu../source -FE. TestHangul.pas

{$MODE Delphi}
{$CODEPAGE UTF8}
{$APPTYPE CONSOLE}

uses
  SysUtils, uHangulComposer, uVirtualHangulEngine;

type
  TTestOutput = class(THangulOutput)
    Screen : WideString;
    procedure SendText(const aText : WideString); override;
    procedure SendBackspace; override;
    procedure SendEnter; override;
    function  FocusToken : Int64; override;
  end;

procedure TTestOutput.SendText(const aText : WideString);
begin
  Screen := Screen + aText;
end;

procedure TTestOutput.SendBackspace;
begin
  Delete(Screen, length(Screen), 1);
end;

procedure TTestOutput.SendEnter;
begin
  Screen := Screen + #10;
end;

function TTestOutput.FocusToken : Int64;
begin
  Result := 1;
end;

var
  Failures : integer = 0;
  Total    : integer = 0;

procedure Check(const aName : string; const aExpected, aActual : WideString);
begin
  inc(Total);
  if (aExpected = aActual) then
    writeln('ok    ', aName, ' -> ', UTF8Encode(aActual))
   else
    begin
      inc(Failures);
      writeln('FAIL  ', aName, ' expected ', UTF8Encode(aExpected), ' got ', UTF8Encode(aActual));
    end;
end;

// Presses the key that types aChar (or the key with the caption aChar)
procedure Press(aEngine : THangulEngine; aChar : WideChar);
var
  i : integer;
begin
  for i := 0 to pred(aEngine.KeyCount) do
    if (length(aEngine.Keys[i].Chars) > 0) and (aEngine.Keys[i].Chars[1] = aChar) and
       (aEngine.Keys[i].Kind in [kkChar, kkCycle]) then
      begin
        aEngine.PressKey(i);
        exit;
      end;

  writeln('no key for ', UTF8Encode(WideString(aChar)));
  inc(Failures);
end;

procedure PressKind(aEngine : THangulEngine; aKind : TKeyKind);
var
  i : integer;
begin
  for i := 0 to pred(aEngine.KeyCount) do
    if (aEngine.Keys[i].Kind = aKind) then
      begin
        aEngine.PressKey(i);
        exit;
      end;
end;

procedure TypeKeys(aEngine : THangulEngine; const aKeys : WideString);
var
  i : integer;
begin
  for i := 1 to length(aKeys) do
    Press(aEngine, aKeys[i]);
end;

procedure Dubeol(const aName : string; const aKeys, aExpected : WideString);
var
  TempOut : TTestOutput;
  TempEng : THangulEngine;
begin
  TempOut := TTestOutput.Create;
  TempEng := THangulEngine.Create(TempOut);
  try
    TypeKeys(TempEng, aKeys);
    Check('dubeolsik ' + aName, aExpected, TempOut.Screen);
  finally
    TempEng.Free;
    TempOut.Free;
  end;
end;

// Cheonjiin : the keys are written with the first character of the key group
procedure Cheon(const aName : string; const aKeys, aExpected : WideString);
var
  TempOut : TTestOutput;
  TempEng : THangulEngine;
begin
  TempOut := TTestOutput.Create;
  TempEng := THangulEngine.Create(TempOut);
  try
    TempEng.Layout := hlCheonjiin;
    TypeKeys(TempEng, aKeys);
    Check('cheonjiin ' + aName, aExpected, TempOut.Screen);
  finally
    TempEng.Free;
    TempOut.Free;
  end;
end;

var
  TempOut : TTestOutput;
  TempEng : THangulEngine;
begin
  // ---- Dubeolsik ----
  Dubeol('han-geul',        'ㅎㅏㄴㄱㅡㄹ', '한글');
  Dubeol('ilg-eo',          'ㅇㅣㄹㄱㅇㅓ', '읽어');
  Dubeol('gabs-i',          'ㄱㅏㅂㅅㅇㅣ', '값이');
  Dubeol('gwaen-chanh-a',   'ㄱㅗㅐㄴㅊㅏㄴㅎ', '괜찮');
  Dubeol('gwaen-chanh-a2',  'ㄱㅗㅐㄴㅊㅏㄴㅎㅇㅏ', '괜찮아');
  Dubeol('annyeong',        'ㅇㅏㄴㄴㅕㅇ', '안녕');
  Dubeol('hanguk-eo',       'ㅎㅏㄴㄱㅜㄱㅇㅓ', '한국어');
  Dubeol('wi',              'ㅇㅜㅣ', '위');
  Dubeol('ui',              'ㅇㅡㅣ', '의');
  Dubeol('a-i',             'ㅇㅏㅇㅣ', '아이');
  Dubeol('dalg',            'ㄷㅏㄹㄱ', '닭');
  Dubeol('dalg-i',          'ㄷㅏㄹㄱㅇㅣ', '닭이');
  Dubeol('lone consonants', 'ㄱㄴ', 'ㄱㄴ');
  Dubeol('lone vowel',      'ㅏㅏ', 'ㅏㅏ');
  Dubeol('jamo first',      'ㅗㅏ', 'ㅘ');

  // Shift + Backspace + space + Enter
  TempOut := TTestOutput.Create;
  TempEng := THangulEngine.Create(TempOut);
  try
    PressKind(TempEng, kkShift);
    Press(TempEng, 'ㅃ');
    Press(TempEng, 'ㅏ');
    Check('dubeolsik shift ppa', '빠', TempOut.Screen);
    Press(TempEng, 'ㅂ');
    PressKind(TempEng, kkBackspace);
    Check('dubeolsik backspace jamo', '빠', TempOut.Screen);
    PressKind(TempEng, kkBackspace);
    Check('dubeolsik backspace syllable', 'ㅃ', TempOut.Screen);
    PressKind(TempEng, kkBackspace);
    PressKind(TempEng, kkBackspace);
    Check('dubeolsik plain backspace', '', TempOut.Screen);
    Press(TempEng, 'ㅎ'); Press(TempEng, 'ㅏ'); Press(TempEng, 'ㄴ');
    PressKind(TempEng, kkSpace);
    Press(TempEng, 'ㄱ');
    Check('dubeolsik space', '한 ㄱ', TempOut.Screen);
    PressKind(TempEng, kkEnter);
    Press(TempEng, 'ㅏ');
    Check('dubeolsik enter', '한 ㄱ'#10'ㅏ', TempOut.Screen);
  finally
    TempEng.Free;
    TempOut.Free;
  end;

  // English and symbols
  TempOut := TTestOutput.Create;
  TempEng := THangulEngine.Create(TempOut);
  try
    PressKind(TempEng, kkLang);
    Press(TempEng, 'h'); Press(TempEng, 'i');
    PressKind(TempEng, kkShift);
    Press(TempEng, 'A');
    Press(TempEng, 'b');
    Check('english', 'hiAb', TempOut.Screen);
    PressKind(TempEng, kkSymbol);
    Press(TempEng, '!');
    Press(TempEng, '5');
    PressKind(TempEng, kkSymbol);
    Check('symbols', 'hiAb!5', TempOut.Screen);
  finally
    TempEng.Free;
    TempOut.Free;
  end;

  // ---- Cheonjiin (ㅣ ㆍ ㅡ and the first consonant of each key) ----
  Cheon('i',        'ㅣ', 'ㅣ');
  Cheon('a',        'ㅇㅣㆍ', '아');
  Cheon('ya',       'ㅇㅣㆍㆍ', '야');
  Cheon('eo',       'ㅇㆍㅣ', '어');
  Cheon('yeo',      'ㅇㆍㅣㆍ', '여');
  Cheon('o',        'ㅇㆍㅡ', '오');
  Cheon('yo',       'ㅇㆍㅡㆍ', '요');
  Cheon('u',        'ㅇㅡㆍ', '우');
  Cheon('yu',       'ㅇㅡㆍㆍ', '유');
  Cheon('eu',       'ㅇㅡ', '으');
  Cheon('ui',       'ㅇㅡㅣ', '의');
  Cheon('ae',       'ㅇㅣㆍㅣ', '애');
  Cheon('e',        'ㅇㆍㅣㅣ', '에');
  Cheon('wa',       'ㅇㆍㅡㅣㆍ', '와');
  Cheon('wae',      'ㅇㆍㅡㅣㆍㅣ', '왜');
  Cheon('wo',       'ㅇㅡㆍㅣㆍ', '워');
  Cheon('wi',       'ㅇㅡㆍㅣ', '위');
  Cheon('han-geun', 'ㅅㅅㅣㆍㄴㄱㅡㄴ', '한근');

  // Cheonjiin consonant cycling : ㄱ ㅋ ㄲ / ㄴ ㄹ / ㅂ ㅍ ㅃ / ㅅ ㅎ ㅆ / ㅇ ㅁ
  TempOut := TTestOutput.Create;
  TempEng := THangulEngine.Create(TempOut);
  try
    TempEng.Layout := hlCheonjiin;
    Press(TempEng, 'ㄱ'); Check('cycle 1', 'ㄱ', TempOut.Screen);
    Press(TempEng, 'ㄱ'); Check('cycle 2', 'ㅋ', TempOut.Screen);
    Press(TempEng, 'ㄱ'); Check('cycle 3', 'ㄲ', TempOut.Screen);
    Press(TempEng, 'ㄱ'); Check('cycle 4', 'ㄱ', TempOut.Screen);
    Press(TempEng, 'ㅣ'); Press(TempEng, 'ㆍ');
    Check('cycle then vowel', '가', TempOut.Screen);
    Press(TempEng, 'ㅂ'); Check('tail 1', '갑', TempOut.Screen);
    Press(TempEng, 'ㅂ'); Check('tail 2', '갚', TempOut.Screen);
    Press(TempEng, 'ㅂ'); Check('tail 3 (ppp)', '가ㅃ', TempOut.Screen);
    Press(TempEng, 'ㅂ'); Check('tail 4', '갑', TempOut.Screen);
    Press(TempEng, 'ㅇ'); Press(TempEng, 'ㅇ');
    Check('mieum', '갑ㅁ', TempOut.Screen);
    PressKind(TempEng, kkBackspace);
    Check('backspace after cycle', '갑', TempOut.Screen);
    PressKind(TempEng, kkSpace);
    Press(TempEng, '.');  Check('punct 1', '갑 .', TempOut.Screen);
    Press(TempEng, '.');  Check('punct 2', '갑 ,', TempOut.Screen);
    Press(TempEng, '.');  Check('punct 3', '갑 ?', TempOut.Screen);
  finally
    TempEng.Free;
    TempOut.Free;
  end;

  // Layout / language switching
  TempOut := TTestOutput.Create;
  TempEng := THangulEngine.Create(TempOut);
  try
    TypeKeys(TempEng, 'ㅎㅏ');
    PressKind(TempEng, kkLayout);
    Check('layout switch', '1', IntToStr(Ord(TempEng.Layout)));
    Press(TempEng, 'ㄴ');
    Check('layout keeps text', '하ㄴ', TempOut.Screen);
  finally
    TempEng.Free;
    TempOut.Free;
  end;

  writeln;
  writeln(Total, ' checks, ', Failures, ' failures');
  if (Failures > 0) then Halt(1);
end.
