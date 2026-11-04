unit uVirtualTouchKeyboard;

{$IFDEF FPC}{$MODE Delphi}{$ENDIF}
                                       
{$I VirtualTouchKeyboard.inc}

// This unit uses undocumented Windows interfaces!

// ITipInvocation, IInputHostManagerBroker and IImmersiveShellBroker are
// available in Windows 8, 10 and 11 but the code in this unit works best in a
// fully updated Windows 10 or 11 system.

// Some ITipInvocation code examples use alternative ways to detect when the
// virtual keyboard is visible but the tests showed that using
// IInputHostManagerBroker is much safer and easier.

// The code in this unit is a translation of these examples :
// https://stackoverflow.com/questions/38774139/show-touch-keyboard-tabtip-exe-in-windows-10-anniversary-edition
// https://fire-monkey.ru/topic/5621-%D1%81%D0%B5%D0%BD%D1%81%D0%BE%D1%80%D0%BD%D0%B0%D1%8F-%D0%BA%D0%BB%D0%B0%D0%B2%D0%B8%D0%B0%D1%82%D1%83%D1%80%D0%B0-windows/
// https://stackoverflow.com/questions/50623154/c-sharp-wpf-windows-10-1803-touchkeyboard-unreliable-issue-prism-clickonce
// https://github.com/TransposonY/GestureSign/blob/master/GestureSign.CorePlugins/TouchKeyboard/TouchKeyboard.cs
// https://stackoverflow.com/questions/47187216/determine-if-windows-10-touch-keyboard-is-visible-or-hidden

interface

uses
  {$IFDEF DELPHI16_UP}
    Winapi.Windows, System.Classes, System.SysUtils, Winapi.SHFolder,
    Winapi.ActiveX, Winapi.ShellAPI;
  {$ELSE}
    Windows, Classes, SysUtils, {$IFDEF FPC}LResources,{$ENDIF} SHFolder,
    ActiveX, ShellAPI;
  {$ENDIF}

const                                                                           
  CLSID_UIHostNoLaunch        : TGUID = '{4CE576FA-83DC-4F88-951C-9D0782B4E376}';
  IID_ITipInvocation          : TGUID = '{37C994E7-432B-4834-A2F7-DCE1F13B834B}';  
  
  CLSID_ImmersiveShellBroker  : TGUID = '{228826af-02e1-4226-a9e0-99a855e455a6}';
  IID_IImmersiveShellBroker   : TGUID = '{9767060c-9476-42e2-8f7b-2f10fd13765c}';   
  IID_IInputHostManagerBroker : TGUID = '{2166ee67-71df-4476-8394-0ced2ed05274}';

  TABTIP_PROCNAME = 'TabTip.exe';

  // Korean (Hangul) input support
  KOREAN_LANGID          = $0412;
  KOREAN_KLID            = '00000412';
  IME_CMODE_NATIVE_HANGUL = $0001;

  {$IFDEF DELPHI16_UP}
  {$IF NOT DECLARED(pidWin32)}
  pidWin32 = 0;
  {$IFEND}
  {$IF NOT DECLARED(pidWin64)}
  pidWin64 = 0;
  {$IFEND}
  {$IF NOT DECLARED(pfidWindows)}
  pfidWindows = pidWin32 or pidWin64;
  {$IFEND}
  {$ENDIF}

type
  TDisplayMode = type integer;
  
  ITipInvocation = interface
    ['{37C994E7-432B-4834-A2F7-DCE1F13B834B}']
    procedure Toggle(WND: HWND); safecall;
  end;

  IInputHostManagerBroker = interface
    ['{2166ee67-71df-4476-8394-0ced2ed05274}']
    procedure GetIhmLocation(out rect : TRect; out mode : TDisplayMode); safecall; 
  end;

  IImmersiveShellBroker = interface
    ['{9767060c-9476-42e2-8f7b-2f10fd13765c}']
    procedure Dummy; safecall;
    function GetInputHostManagerBroker : IInputHostManagerBroker; safecall;
  end;

  /// <summary>
  /// Implementation of the virtual touch keyboard available in Windows using
  /// the undocumented ITipInvocation, IInputHostManagerBroker and
  /// IImmersiveShellBroker interfaces.
  /// </summary>
  {$IFDEF DELPHI16_UP}[ComponentPlatformsAttribute(pfidWindows)]{$ENDIF}
  TVirtualTouchKeyboard = class(TComponent)
    protected
      function GetTabTipPath : string;
      function GetCommonProgramFilesPath : string;
      function GetVisible : boolean;
      function GetExecuting : boolean;

      function ProcessExists(const aExeFileName : string) : Boolean;
      function GetIhmLocation(var aRect : TRect) : boolean;

      FAutoKorean : boolean;

      property TabTipPath              : string   read GetTabTipPath;
      property CommonProgramFilesPath  : string   read GetCommonProgramFilesPath;

    public
      /// <summary>
      /// Show the virtual keyboard. It opens TabTip.exe if it's not running.
      /// </summary>
      procedure Show;
      /// <summary>
      /// Hide the virtual keyboard.
      /// </summary>
      procedure Hide;
      /// <summary>
      /// Toggle virtual keyboard visibility.
      /// </summary>
      function  Toggle : boolean;
      /// <summary>
      /// Execute TabTip.exe
      /// </summary>
      function  ExecuteTabTip : boolean;
      /// <summary>
      /// Returns true if a Korean keyboard layout is installed for the current user.
      /// </summary>
      function  IsKoreanInstalled : boolean;
      /// <summary>
      /// Loads the Korean keyboard layout and makes it the active input
      /// language of the window aWnd (0 = the focused window of this thread, or
      /// the foreground window). The virtual keyboard then shows the Hangul
      /// layout and typed characters are composed as Hangul.
      /// </summary>
      function  ActivateKorean(aWnd : HWND = 0) : boolean;
      /// <summary>
      /// Switches the Korean IME between Hangul (True) and English/Alphanumeric
      /// (False) mode for the window aWnd (0 = focused window).
      /// </summary>
      function  SetHangulMode(aHangul : boolean; aWnd : HWND = 0) : boolean;
      /// <summary>
      /// Activates the Korean layout in Hangul mode and shows the virtual keyboard.
      /// </summary>
      procedure ShowKorean(aWnd : HWND = 0);
      /// <summary>
      /// Returns true if the virtual keyboard is visible.
      /// </summary>
      property Visible    : boolean  read GetVisible;
      /// <summary>
      /// Returns true if TabTip.exe is running.
      /// </summary>
      property Executing  : boolean  read GetExecuting;

    published
      /// <summary>
      /// When True, Show activates the Korean layout and Hangul mode before
      /// displaying the virtual keyboard.
      /// </summary>
      property AutoKorean : boolean  read FAutoKorean write FAutoKorean default False;
  end;

{$IFDEF FPC}
procedure Register;
{$ENDIF}


implementation

uses
  {$IFDEF DELPHI16_UP}
    Winapi.TlHelp32;
  {$ELSE}
    {$IFDEF FPC}
      jwatlhelp32;
    {$ELSE}
      TlHelp32;
    {$ENDIF}
  {$ENDIF}

function ImmGetContext(hWnd: HWND): THandle; stdcall; external 'imm32.dll' name 'ImmGetContext';
function ImmReleaseContext(hWnd: HWND; hIMC: THandle): BOOL; stdcall; external 'imm32.dll' name 'ImmReleaseContext';
function ImmGetConversionStatus(hIMC: THandle; var lpfdwConversion, lpfdwSentence: DWORD): BOOL; stdcall; external 'imm32.dll' name 'ImmGetConversionStatus';
function ImmSetConversionStatus(hIMC: THandle; fdwConversion, fdwSentence: DWORD): BOOL; stdcall; external 'imm32.dll' name 'ImmSetConversionStatus';

function TVirtualTouchKeyboard.GetTabTipPath : string;
const
  TABTIP_SUBPATH            = 'microsoft shared\ink\' + TABTIP_PROCNAME;
  DEFAULT_COMMON_FILES_PATH = 'C:\Program Files\Common Files\';
begin
  Result := CommonProgramFilesPath + TABTIP_SUBPATH;

  if not(FileExists(Result)) then
    begin
      Result := DEFAULT_COMMON_FILES_PATH + TABTIP_SUBPATH;

      if not(FileExists(Result)) then
        Result := '';
    end;
end;

function TVirtualTouchKeyboard.GetCommonProgramFilesPath: string;
var
  TempBuffer: array [0..pred(MAX_PATH)] of Char;
begin
  FillChar(TempBuffer, MAX_PATH * SizeOf(Char), 0);

  if succeeded(SHGetFolderPath(0, CSIDL_PROGRAM_FILES_COMMON, 0, 0, @TempBuffer[0])) then
    Result := IncludeTrailingPathDelimiter(TempBuffer)
   else
    Result := '';
end;

function TVirtualTouchKeyboard.GetVisible : boolean;
var
  TempRect : TRect;
begin
  Result := GetIhmLocation(TempRect) and (TempRect.Right > TempRect.Left) and (TempRect.Bottom > TempRect.Top);
end;

function TVirtualTouchKeyboard.GetExecuting : boolean;
begin
  Result := ProcessExists(TABTIP_PROCNAME);
end;

function TVirtualTouchKeyboard.ProcessExists(const aExeFileName: string): Boolean;
var
  TempHandle  : THandle;
  TempProcess : TProcessEntry32;
begin
  Result     := False;
  TempHandle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);

  if (TempHandle <> INVALID_HANDLE_VALUE) then
    try
      ZeroMemory(@TempProcess, SizeOf(TProcessEntry32));
      TempProcess.dwSize := Sizeof(TProcessEntry32);

      if Process32First(TempHandle, TempProcess) then
        repeat
          if (CompareText(ExtractFileName(TempProcess.szExeFile), aExeFileName) = 0) then
            begin
              Result := True;
              break;
            end;
        until not(Process32Next(TempHandle, TempProcess));
    finally
      CloseHandle(TempHandle);
    end;
end;

function TVirtualTouchKeyboard.ExecuteTabTip : boolean;
var
  TempPath : string;
begin
  TempPath := TabTipPath;
  Result   := (length(TempPath) > 0) and
              (ShellExecute(0, 'open', PChar(TempPath + #0), nil, nil, SW_SHOWNORMAL) > 32);
end;

function TVirtualTouchKeyboard.Toggle : boolean;
var
  TempInvocation : ITipInvocation;
  TempResult     : HRESULT;
begin
  Result     := False;
  TempResult := CoCreateInstance(CLSID_UIHostNoLaunch,
                                 nil,
                                 CLSCTX_INPROC_HANDLER or CLSCTX_LOCAL_SERVER,
                                 IID_ITipInvocation,
                                 TempInvocation);

  if succeeded(TempResult) then
    begin
      TempInvocation.Toggle(GetDesktopWindow);
      Result := True;
    end;
end;         

function TVirtualTouchKeyboard.GetIhmLocation(var aRect : TRect) : boolean;
var
  TempShellBroker : IImmersiveShellBroker;
  TempMgrBroker : IInputHostManagerBroker;
  TempResult : HRESULT;
  TempRect : TRect;
  TempMode : TDisplayMode;
begin
  Result     := False;
  TempResult := CoCreateInstance(CLSID_ImmersiveShellBroker,
                                 nil,
                                 CLSCTX_INPROC_HANDLER or CLSCTX_LOCAL_SERVER,
                                 IID_IImmersiveShellBroker,
                                 TempShellBroker);

  if succeeded(TempResult) then
    begin
      TempMgrBroker := TempShellBroker.GetInputHostManagerBroker;
      TempMgrBroker.GetIhmLocation(TempRect, TempMode);
      aRect  := TempRect;
      Result := True;
    end;
end;

function TargetWindow(aWnd : HWND) : HWND;
begin
  Result := aWnd;
  if (Result = 0) then Result := GetFocus;
  if (Result = 0) then Result := GetForegroundWindow;
end;

function TVirtualTouchKeyboard.IsKoreanInstalled : boolean;
var
  TempList : array of HKL;
  TempDummy : HKL;
  TempCount, i : integer;
begin
  Result    := False;
  TempDummy := 0;
  TempCount := GetKeyboardLayoutList(0, TempDummy);
  if (TempCount <= 0) then exit;

  SetLength(TempList, TempCount);
  TempCount := GetKeyboardLayoutList(TempCount, TempList[0]);

  for i := 0 to pred(TempCount) do
    if ((DWORD(TempList[i]) and $FFFF) = KOREAN_LANGID) then
      begin
        Result := True;
        break;
      end;
end;

function TVirtualTouchKeyboard.ActivateKorean(aWnd : HWND) : boolean;
var
  TempLayout : HKL;
  TempWnd    : HWND;
begin
  TempLayout := LoadKeyboardLayout(KOREAN_KLID, KLF_ACTIVATE);
  Result     := (TempLayout <> 0);

  if Result then
    begin
      TempWnd := TargetWindow(aWnd);

      // Make it the input language of this thread and of the target window.
      ActivateKeyboardLayout(TempLayout, 0);
      if (TempWnd <> 0) then
        SendMessage(TempWnd, WM_INPUTLANGCHANGEREQUEST, 0, LPARAM(TempLayout));
    end;
end;

function TVirtualTouchKeyboard.SetHangulMode(aHangul : boolean; aWnd : HWND) : boolean;
var
  TempWnd : HWND;
  TempIMC : THandle;
  TempConversion, TempSentence : DWORD;
begin
  Result  := False;
  TempWnd := TargetWindow(aWnd);
  if (TempWnd = 0) then exit;

  TempIMC := ImmGetContext(TempWnd);
  if (TempIMC = 0) then exit;

  try
    if ImmGetConversionStatus(TempIMC, TempConversion, TempSentence) then
      begin
        if aHangul then
          TempConversion := TempConversion or IME_CMODE_NATIVE_HANGUL
         else
          TempConversion := TempConversion and not(DWORD(IME_CMODE_NATIVE_HANGUL));

        Result := ImmSetConversionStatus(TempIMC, TempConversion, TempSentence);
      end;
  finally
    ImmReleaseContext(TempWnd, TempIMC);
  end;
end;

procedure TVirtualTouchKeyboard.ShowKorean(aWnd : HWND);
begin
  if ActivateKorean(aWnd) then
    SetHangulMode(True, aWnd);

  Show;
end;

procedure TVirtualTouchKeyboard.Show;
begin
  if FAutoKorean then
    begin
      if ActivateKorean then SetHangulMode(True);
    end;

  if not(Visible) then
    begin
      if Executing then
        Toggle
       else
        if ExecuteTabTip then
          begin
            {$IFDEF DELPHI17_UP}
              TThread.ForceQueue(nil,
                procedure
                begin
                  Toggle;
                end, 500);
            {$ELSE}
              sleep(500);
              Toggle;
            {$ENDIF}
          end;
    end;
end;

procedure TVirtualTouchKeyboard.Hide;
begin
  if Visible then 
    Toggle;
end;    

{$IFDEF FPC}
procedure Register;
begin
  {$I res/tvirtualtouchkeyboard.lrs}
  RegisterComponents('VirtualTouchKeyboard4Delphi', [TVirtualTouchKeyboard]);
end;
{$ENDIF}

end.
