unit DFUnity_Config;

// Пути и настройки лаунчера. Всё хранится в ini рядом с exe, реестр не используется.
// Установщик создаёт этот ini с правом записи для пользователей и пишет в него
// тег установленного релиза ([Game] Version).

interface

uses
  DFUnity_Strings;

type
  TLauncherConfig = class
  private
    FAppDir, FIniPath: string;
  public
    Language: string;       // '' - как в системе, иначе код из Strings
    CheckUpdates: Boolean;
    GameVersion: string;    // тег релиза DFU, '' - неизвестен
    constructor Create;
    procedure Load;
    function Save: Boolean; // False - нет доступа на запись
    function Lang: TLanguage;
    function GameDir: string;
    function GameExe: string;
    function UninstExe: string;
    property IniPath: string read FIniPath;
  end;

var
  Config: TLauncherConfig;

implementation

uses
  System.SysUtils, System.IniFiles;

const
  SecLauncher = 'Launcher';
  SecGame     = 'Game';

constructor TLauncherConfig.Create;
begin
  // Пути считаем от папки лаунчера, а не от текущей рабочей папки
  FAppDir := ExtractFilePath(ParamStr(0));
  FIniPath := FAppDir + 'DaggerfallUnityLauncher.ini';
end;

function TLauncherConfig.GameDir: string;
begin
  Result := FAppDir + 'DaggerfallUnity\';
end;

function TLauncherConfig.GameExe: string;
begin
  Result := GameDir + 'DaggerfallUnity.exe';
end;

function TLauncherConfig.UninstExe: string;
begin
  Result := FAppDir + 'unins000.exe';
end;

function TLauncherConfig.Lang: TLanguage;
begin
  Result := LanguageByCode(Language);
end;

procedure TLauncherConfig.Load;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Language     := Ini.ReadString(SecLauncher, 'Language', '');
    CheckUpdates := Ini.ReadBool(SecLauncher, 'CheckUpdates', False);
    GameVersion  := Ini.ReadString(SecGame, 'Version', '');
  finally
    Ini.Free;
  end;
end;

function TLauncherConfig.Save: Boolean;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    try
      Ini.WriteString(SecLauncher, 'Language', Language);
      Ini.WriteBool(SecLauncher, 'CheckUpdates', CheckUpdates);
      Ini.WriteString(SecGame, 'Version', GameVersion);
      Result := True;
    except
      on EIniFileException do
        Result := False;
    end;
  finally
    Ini.Free;
  end;
end;

initialization
  Config := TLauncherConfig.Create;
  Config.Load;

finalization
  Config.Free;

end.
