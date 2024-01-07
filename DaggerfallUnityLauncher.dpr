program DaggerfallUnityLauncher;

uses
  Vcl.Forms,
  DFUnity_Launcher in 'DFUnity_Launcher.pas' {MainWindow},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainWindow, MainWindow);
  Application.Run;
end.
