program DaggerfallUnityLauncher;

// Не тащим в exe расширенную RTTI, которая лаунчеру не нужна
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  Vcl.Forms,
  DFUnity_Launcher in 'DFUnity_Launcher.pas' {MainWindow},
  DFUnity_Strings in 'DFUnity_Strings.pas',
  DFUnity_Config in 'DFUnity_Config.pas',
  DFUnity_Updater in 'DFUnity_Updater.pas',
  DFUnity_AccentButton in 'DFUnity_AccentButton.pas',
  DFUnity_SettingsForm in 'DFUnity_SettingsForm.pas' {SettingsForm};

{$R *.res}
{$R 'DFUnity_Fonts.res' 'DFUnity_Fonts.rc'}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Daggerfall Unity Launcher';
  Application.CreateForm(TMainWindow, MainWindow);
  Application.Run;
end.
