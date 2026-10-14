unit DFUnity_Launcher;

{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

interface

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons,
  Vcl.ExtCtrls, // Фон формы - JPEG в TWICImage: декодирует Windows, без кода pngimage/jpeg в exe
  DFUnity_Updater, DFUnity_AccentButton;

{$IFNDEF DEBUG}
  {$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED} // Удаление из exe таблицы релокаций.
  {$SetPEFlags IMAGE_FILE_DEBUG_STRIPPED} //  Удаление из ехе Debug информации
  {$SetPEFlags IMAGE_FILE_LINE_NUMS_STRIPPED} // Удаление из exe информации о номерах строк
  {$SetPEFlags IMAGE_FILE_LOCAL_SYMS_STRIPPED} // Удаление local symbols
  {$SetPEFlags IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP} //При запуске exe с компакта, флэшки, других извлекаемых устройств, считать exe в свап и запустить оттуда. Полезно, если нужно запустить программу с компакта, а потом попросить вставить другой...
  {$SetPEFlags IMAGE_FILE_NET_RUN_FROM_SWAP} // Аналогично предыдущей, только для сетевых дисков
  {$SetPEFlags IMAGE_FILE_EXECUTABLE_IMAGE}
{$ENDIF}

type
  TMainWindow = class(TForm)
    DF_LaunchBut: TSpeedButton;
    DF_DeletThisBut: TSpeedButton;
    DF_UnitySiteBut: TSpeedButton;
    DF_TesallButt: TSpeedButton;
    DF_SettingsBut: TSpeedButton;
    Background: TImage;
    procedure DF_UnitySiteButClick(Sender: TObject);
    procedure DF_LaunchButClick(Sender: TObject);
    procedure DF_DeletThisButClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DF_TesallButtClick(Sender: TObject);
    procedure DF_SettingsButClick(Sender: TObject);

  private
    FLatest: TReleaseInfo;
    FAlive: ICancelToken;
    FUpdateBut: TAccentButton;
    procedure ApplyLanguage;
    procedure RefreshUpdateButton;
    procedure StartUpdateCheck;
    procedure OpenURL(const URL: string);
  end;

var
  MainWindow: TMainWindow;

implementation

{$R *.dfm}

uses
  DFUnity_Strings, DFUnity_Config, DFUnity_SettingsForm;

const
  TesallPage  = 'https://tesall.ru/files/modi-dlya-drugikh-igr/10820-daggerfall-unity-installer';
  DFUnitySite = 'https://www.dfworkshop.net';
  ButtonFont  = 'Kurale';
  ButtonFontHeight = -15; // в пикселях; самая длинная подпись - 185 px при ширине кнопки 200

// Подключает шрифт кнопок из ресурсов exe (DFUnity_Fonts.rc) - только для этого процесса,
// в системе ничего не устанавливается
function LoadButtonFont: Boolean;
var
  Res: HRSRC;
  Data: HGLOBAL;
  Count: DWORD;
begin
  Result := False;
  Res := FindResource(HInstance, 'KURALE', RT_RCDATA);
  if Res = 0 then
    Exit;
  Data := LoadResource(HInstance, Res);
  if Data = 0 then
    Exit;
  Count := 0;
  Result := AddFontMemResourceEx(LockResource(Data), SizeofResource(HInstance, Res), nil, @Count) <> 0;
end;

procedure TMainWindow.FormCreate(Sender: TObject);
var
  Button: TSpeedButton;
begin
  FAlive := NewCancelToken;

  // Шрифт в духе Daggerfall на главных кнопках; если не подключился - остаётся Segoe UI
  if LoadButtonFont then
    for Button in [DF_LaunchBut, DF_DeletThisBut, DF_UnitySiteBut, DF_TesallButt] do
    begin
      Button.Font.Name := ButtonFont;
      Button.Font.Height := ButtonFontHeight;
      Button.Font.Charset := DEFAULT_CHARSET;
    end;

  // Без деинсталлятора кнопка запуска опускается и перекрывает кнопку удаления
  if not FileExists(Config.UninstExe) then
    DF_LaunchBut.Top := DF_LaunchBut.Top + 32;
  // Кнопка «Доступно обновление» - над кнопкой запуска, видна только при найденном обновлении
  FUpdateBut := TAccentButton.Create(Self);
  FUpdateBut.Visible := False;
  FUpdateBut.SetBounds(DF_LaunchBut.Left, DF_LaunchBut.Top - 36, DF_LaunchBut.Width, 30);
  FUpdateBut.OnClick := DF_SettingsButClick;
  FUpdateBut.Parent := Self;

  // Шестерёнка: значок из системного шрифта (Windows 10+), на старых системах - символ ⚙
  if Screen.Fonts.IndexOf('Segoe MDL2 Assets') >= 0 then
  begin
    DF_SettingsBut.Font.Name := 'Segoe MDL2 Assets';
    DF_SettingsBut.Caption := #$E713;
  end
  else
  begin
    DF_SettingsBut.Font.Name := 'Segoe UI Symbol';
    DF_SettingsBut.Caption := #$2699;
  end;

  ApplyLanguage;
  if Config.CheckUpdates then
    StartUpdateCheck;
end;

procedure TMainWindow.FormDestroy(Sender: TObject);
begin
  FAlive.Cancel;
end;

procedure TMainWindow.ApplyLanguage;
var
  S: TLangStrings;
begin
  S := Strings[Config.Lang];
  DF_LaunchBut.Caption    := S.LaunchBut;
  DF_DeletThisBut.Caption := S.DeleteBut;
  DF_UnitySiteBut.Caption := S.UnitySiteBut;
  DF_TesallButt.Caption   := S.TesallBut;
  DF_SettingsBut.Hint     := S.SettingsHint;
  RefreshUpdateButton;
end;

// Кнопка видна, если известен релиз со сборкой под эту Windows и его тег отличается
// от установленного. Релиз узнаём автопроверкой при запуске или проверкой в настройках.
procedure TMainWindow.RefreshUpdateButton;
begin
  FUpdateBut.Visible := FLatest.HasAsset and (FLatest.Tag <> Config.GameVersion);
  FUpdateBut.Caption := Format(Strings[Config.Lang].UpdateAvailableBut, [FLatest.Tag]);
  // Тег релиза бывает длинным (v1.1.1-cve-2025): ширина по тексту, но не уже кнопки
  // запуска и не шире окна (с полями по 16px); по центру окна
  FUpdateBut.FitWidth(DF_LaunchBut.Width, ClientWidth - 32);
  FUpdateBut.Left := (ClientWidth - FUpdateBut.Width) div 2;
end;

// Тихая проверка при запуске: ошибки сети не показываем
procedure TMainWindow.StartUpdateCheck;
var
  Alive: ICancelToken;
begin
  Alive := FAlive;
  TThread.CreateAnonymousThread(
    procedure
    var
      Info: TReleaseInfo;
    begin
      if FetchLatestRelease(Info).Ok then
        TThread.Queue(nil,
          procedure
          begin
            if Alive.Cancelled then
              Exit;
            FLatest := Info;
            RefreshUpdateButton;
          end);
    end).Start;
end;

procedure TMainWindow.DF_SettingsButClick(Sender: TObject);
begin
  TSettingsForm.Execute(Self, FLatest, ApplyLanguage);
  RefreshUpdateButton;
end;

procedure TMainWindow.OpenURL(const URL: string);
begin
  ShellExecute(Handle, 'open', PChar(URL), nil, nil, SW_SHOW);
end;

procedure TMainWindow.DF_DeletThisButClick(Sender: TObject);
begin
  if FileExists(Config.UninstExe) then
  begin
    ShellExecute(Handle, 'open', PChar(Config.UninstExe), nil,
      PChar(ExtractFilePath(Config.UninstExe)), SW_SHOWNORMAL);
    Application.Terminate;
  end
  else
    ShowMessage(Strings[Config.Lang].UninstNotFound);
end;

procedure TMainWindow.DF_LaunchButClick(Sender: TObject);
begin
  if FileExists(Config.GameExe) then
    ShellExecute(Handle, 'open', PChar(Config.GameExe), nil,
      PChar(Config.GameDir), SW_SHOWNORMAL)
  else
    ShowMessage(Strings[Config.Lang].EXENotFound);
end;

procedure TMainWindow.DF_UnitySiteButClick(Sender: TObject);
begin
  OpenURL(DFUnitySite);
end;

procedure TMainWindow.DF_TesallButtClick(Sender: TObject);
begin
  OpenURL(TesallPage);
end;

end.
