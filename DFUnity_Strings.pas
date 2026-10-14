unit DFUnity_Strings;

// Тексты интерфейса на всех языках. Чтобы добавить язык - допишите значение
// в TLanguage и запись в Strings.

interface

type
  TLanguage = (langRU, langEN);

  TLangStrings = record
    Code: string;               // код языка в ini
    Name: string;               // название языка в списке настроек
    // Главное окно
    LaunchBut: string;
    DeleteBut: string;
    UnitySiteBut: string;
    TesallBut: string;
    SettingsHint: string;
    UpdateAvailableBut: string; // %s - тег релиза
    EXENotFound: string;
    UninstNotFound: string;
    // Окно настроек
    SettingsCaption: string;
    LanguageLabel: string;
    LanguageSystem: string;
    AutoCheck: string;
    InstalledVersion: string;   // %s - тег релиза
    VersionUnknown: string;
    LatestVersion: string;      // %s - тег релиза
    LatestUnknown: string;
    CheckBut: string;
    UpdateBut: string;
    CloseBut: string;
    CancelBut: string;
    SaveFailed: string;
    // Ход обновления
    Checking: string;
    UpToDate: string;
    UpdateFound: string;        // %s - тег релиза
    DownloadStart: string;      // %s - имя архива, %.1f - размер в МБ
    Downloading: string;        // %.1f из %.1f МБ
    Verifying: string;
    ExtractStart: string;
    Extracting: string;         // %d - проценты
    UpdateDone: string;         // %s - тег релиза
    Cancelled: string;
    // Ошибки обновления
    ErrNetwork: string;         // %s - описание
    ErrHttp: string;            // %d - код ответа
    ErrNoAsset: string;
    ErrChecksum: string;
    ErrGameRunning: string;
    ErrNoAccess: string;
    ErrExtract: string;         // %s - описание
  end;

const
  Strings: array[TLanguage] of TLangStrings = (
    (Code:               'RU';
     Name:               'Русский';
     LaunchBut:          'Запустить Daggerfall Unity';
     DeleteBut:          'Удалить';
     UnitySiteBut:       'Сайт проекта';
     TesallBut:          'Страница на TESALL';
     SettingsHint:       'Настройки';
     UpdateAvailableBut: 'Доступно обновление: %s';
     EXENotFound:        'Файл "DaggerfallUnity.exe" не найден. Возможно, он был перемещён или удалён. Во втором случае придётся переустановить Daggerfall Unity.';
     UninstNotFound:     'Деинсталлятор не найден - возможно, был перемещён или удалён. В таком случае просто удалите всё вручную.';
     SettingsCaption:    'Настройки';
     LanguageLabel:      'Язык лаунчера:';
     LanguageSystem:     'Как в системе';
     AutoCheck:          'Проверять обновления при запуске';
     InstalledVersion:   'Установленная версия: %s';
     VersionUnknown:     'неизвестна';
     LatestVersion:      'Последняя версия: %s';
     LatestUnknown:      'не проверялась';
     CheckBut:           'Проверить обновления';
     UpdateBut:          'Обновить';
     CloseBut:           'Закрыть';
     CancelBut:          'Отмена';
     SaveFailed:         'Не удалось сохранить настройки: нет доступа на запись к файлу "%s".';
     Checking:           'Проверка обновлений...';
     UpToDate:           'Установлена последняя версия.';
     UpdateFound:        'Доступна новая версия %s.';
     DownloadStart:      'Загрузка %s (%.1f МБ)...';
     Downloading:        'Загрузка: %.1f из %.1f МБ';
     Verifying:          'Проверка загруженного файла...';
     ExtractStart:       'Установка обновления...';
     Extracting:         'Установка обновления: %d%%';
     UpdateDone:         'Daggerfall Unity обновлён до версии %s.';
     Cancelled:          'Обновление отменено.';
     ErrNetwork:         'Ошибка сети: %s';
     ErrHttp:            'Сервер вернул ошибку %d.';
     ErrNoAsset:         'В последнем релизе нет сборки для этой версии Windows.';
     ErrChecksum:        'Загруженный файл повреждён (не совпала контрольная сумма).';
     ErrGameRunning:     'Закройте Daggerfall Unity и попробуйте снова.';
     ErrNoAccess:        'Нет доступа на запись в папку игры. Переустановите игру или запустите лаунчер от имени администратора.';
     ErrExtract:         'Ошибка установки обновления: %s'),
    (Code:               'EN';
     Name:               'English';
     LaunchBut:          'Launch Daggerfall Unity';
     DeleteBut:          'Uninstall';
     UnitySiteBut:       'Project website';
     TesallBut:          'TESALL page';
     SettingsHint:       'Settings';
     UpdateAvailableBut: 'Update available: %s';
     EXENotFound:        '"DaggerfallUnity.exe" was not found. It may have been moved or deleted. In the latter case you will need to reinstall Daggerfall Unity.';
     UninstNotFound:     'The uninstaller was not found - it may have been moved or deleted. In that case just delete everything manually.';
     SettingsCaption:    'Settings';
     LanguageLabel:      'Launcher language:';
     LanguageSystem:     'System default';
     AutoCheck:          'Check for updates on startup';
     InstalledVersion:   'Installed version: %s';
     VersionUnknown:     'unknown';
     LatestVersion:      'Latest version: %s';
     LatestUnknown:      'not checked';
     CheckBut:           'Check for updates';
     UpdateBut:          'Update';
     CloseBut:           'Close';
     CancelBut:          'Cancel';
     SaveFailed:         'Could not save settings: no write access to "%s".';
     Checking:           'Checking for updates...';
     UpToDate:           'You have the latest version.';
     UpdateFound:        'New version %s is available.';
     DownloadStart:      'Downloading %s (%.1f MB)...';
     Downloading:        'Downloading: %.1f of %.1f MB';
     Verifying:          'Verifying the downloaded file...';
     ExtractStart:       'Installing the update...';
     Extracting:         'Installing the update: %d%%';
     UpdateDone:         'Daggerfall Unity has been updated to %s.';
     Cancelled:          'Update cancelled.';
     ErrNetwork:         'Network error: %s';
     ErrHttp:            'The server returned error %d.';
     ErrNoAsset:         'The latest release has no build for this version of Windows.';
     ErrChecksum:        'The downloaded file is corrupted (checksum mismatch).';
     ErrGameRunning:     'Close Daggerfall Unity and try again.';
     ErrNoAccess:        'No write access to the game folder. Reinstall the game or run the launcher as administrator.';
     ErrExtract:         'Failed to install the update: %s')
  );

function SystemLanguage: TLanguage;
// Язык по коду из ini; пустой или неизвестный код - системный язык
function LanguageByCode(const Code: string): TLanguage;

implementation

uses
  Winapi.Windows, System.SysUtils;

function SystemLanguage: TLanguage;
begin
  case PRIMARYLANGID(GetUserDefaultUILanguage) of
    LANG_RUSSIAN, LANG_UKRAINIAN, LANG_BELARUSIAN: Result := langRU;
  else
    Result := langEN;
  end;
end;

function LanguageByCode(const Code: string): TLanguage;
var
  L: TLanguage;
begin
  for L := Low(TLanguage) to High(TLanguage) do
    if SameText(Code, Strings[L].Code) then
      Exit(L);
  Result := SystemLanguage;
end;

end.
