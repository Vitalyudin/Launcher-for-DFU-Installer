unit DFUnity_Updater;

// Обновление Daggerfall Unity из релизов GitHub.
// Все функции блокирующие - вызывать из фонового потока.

interface

uses
  System.SysUtils;

type
  TUpdateError = (ueNone, ueNetwork, ueHttp, ueNoAsset, ueChecksum, ueCancelled,
    ueGameRunning, ueNoAccess, ueExtract);

  TUpdateResult = record
    Error: TUpdateError;
    Detail: string;     // описание для ueNetwork/ueExtract
    HttpCode: Integer;  // для ueHttp
    function Ok: Boolean;
  end;

  TReleaseInfo = record
    Tag: string;        // например 'v1.1.1-cve-2025'
    AssetName: string;
    Url: string;
    Size: Int64;
    Sha256: string;     // '' - GitHub не отдал контрольную сумму
    function HasAsset: Boolean;
  end;

  ICancelToken = interface
    ['{6A3F2C1E-8B4D-4E7A-9C15-2D7E0B9F4A61}']
    function Cancelled: Boolean;
    procedure Cancel;
  end;

  TProgressProc = reference to procedure(Done, Total: Int64);

function NewCancelToken: ICancelToken;

// Последний стабильный релиз и архив под разрядность лаунчера
function FetchLatestRelease(out Info: TReleaseInfo): TUpdateResult;
// Игра не запущена и в её папку можно писать
function CheckGameWritable(const GameDir, GameExe: string): TUpdateResult;
// Скачивает архив во временную папку и проверяет размер и SHA-256.
// Уже скачанный и проверенный архив повторно не качается.
function DownloadRelease(const Info: TReleaseInfo; const Token: ICancelToken;
  const OnProgress: TProgressProc; out ZipPath: string): TUpdateResult;
// Распаковывает архив поверх папки игры (сохранения и GameFiles не трогаются)
function ExtractRelease(const ZipPath, GameDir: string;
  const OnProgress: TProgressProc): TUpdateResult;

implementation

uses
  Winapi.Windows, Winapi.WinInet, System.Classes, System.StrUtils, System.JSON,
  System.Zip, System.Hash, System.IOUtils;

const
  LatestReleaseUrl = 'https://api.github.com/repos/Interkarma/daggerfall-unity/releases/latest';
  UserAgent        = 'DaggerfallUnityLauncher';
  TimeoutMs        = 20000;
  {$IFDEF WIN64}
  AssetArch = '_64bit';
  {$ELSE}
  AssetArch = '_32bit';
  {$ENDIF}
  // В архиве лежит заглушка вместо файлов оригинальной игры - установщик её тоже не ставит
  SkippedZipEntry = 'DaggerfallUnity_Data/StreamingAssets/GameFiles/readme.txt';

type
  TCancelToken = class(TInterfacedObject, ICancelToken)
  private
    FCancelled: Boolean;
  public
    function Cancelled: Boolean;
    procedure Cancel;
  end;

function TCancelToken.Cancelled: Boolean;
begin
  Result := FCancelled;
end;

procedure TCancelToken.Cancel;
begin
  FCancelled := True;
end;

function NewCancelToken: ICancelToken;
begin
  Result := TCancelToken.Create;
end;

function TUpdateResult.Ok: Boolean;
begin
  Result := Error = ueNone;
end;

function TReleaseInfo.HasAsset: Boolean;
begin
  Result := Url <> '';
end;

function MakeResult(Error: TUpdateError; const Detail: string = ''): TUpdateResult;
begin
  Result.Error := Error;
  Result.Detail := Detail;
  Result.HttpCode := 0;
end;

// Текст ошибки WinINet (коды 12xxx лежат в wininet.dll, а не в системе)
function NetErrorResult(Code: DWORD): TUpdateResult;
var
  Buf: array[0..511] of Char;
  Len: DWORD;
begin
  Len := FormatMessage(FORMAT_MESSAGE_FROM_HMODULE or FORMAT_MESSAGE_FROM_SYSTEM or
    FORMAT_MESSAGE_IGNORE_INSERTS, Pointer(GetModuleHandle('wininet.dll')), Code, 0,
    Buf, Length(Buf), nil);
  if Len > 0 then
    Result := MakeResult(ueNetwork, Trim(Buf) + Format(' (%d)', [Code]))
  else
    Result := MakeResult(ueNetwork, Format('#%d', [Code]));
end;

function HttpGet(const Url, Headers: string; Dest: TStream; const Token: ICancelToken;
  const OnProgress: TProgressProc; ExpectedSize: Int64): TUpdateResult;
var
  hNet, hUrl: HINTERNET;
  Timeout, Code, Len, Index, Read: DWORD;
  Buf: TBytes;
  Done: Int64;
begin
  Result := MakeResult(ueNone);
  hNet := InternetOpen(UserAgent, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hNet = nil then
    Exit(NetErrorResult(GetLastError));
  try
    Timeout := TimeoutMs;
    InternetSetOption(hNet, INTERNET_OPTION_CONNECT_TIMEOUT, @Timeout, SizeOf(Timeout));
    InternetSetOption(hNet, INTERNET_OPTION_RECEIVE_TIMEOUT, @Timeout, SizeOf(Timeout));
    hUrl := InternetOpenUrl(hNet, PChar(Url), PChar(Headers), Length(Headers),
      INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_NO_UI or
      INTERNET_FLAG_NO_COOKIES, 0);
    if hUrl = nil then
      Exit(NetErrorResult(GetLastError));
    try
      Code := 0; Len := SizeOf(Code); Index := 0;
      if HttpQueryInfo(hUrl, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER, @Code, Len, Index)
        and (Code <> 200) then
      begin
        Result := MakeResult(ueHttp);
        Result.HttpCode := Code;
        Exit;
      end;
      SetLength(Buf, 64 * 1024);
      Done := 0;
      repeat
        if (Token <> nil) and Token.Cancelled then
          Exit(MakeResult(ueCancelled));
        if not InternetReadFile(hUrl, @Buf[0], Length(Buf), Read) then
          Exit(NetErrorResult(GetLastError));
        if Read > 0 then
        begin
          Dest.WriteBuffer(Buf[0], Read);
          Inc(Done, Read);
          if Assigned(OnProgress) then
            OnProgress(Done, ExpectedSize);
        end;
      until Read = 0;
    finally
      InternetCloseHandle(hUrl);
    end;
  finally
    InternetCloseHandle(hNet);
  end;
end;

function FetchLatestRelease(out Info: TReleaseInfo): TUpdateResult;
var
  Response: TBytesStream;
  Json: TJSONValue;
  Assets: TJSONArray;
  Asset: TJSONValue;
  Name, Digest: string;
begin
  Info := Default(TReleaseInfo);
  Response := TBytesStream.Create;
  try
    Result := HttpGet(LatestReleaseUrl, 'Accept: application/vnd.github+json'#13#10,
      Response, nil, nil, 0);
    if not Result.Ok then
      Exit;
    Json := TJSONObject.ParseJSONValue(Response.Bytes, 0, Response.Size);
    try
      if (Json = nil) or not Json.TryGetValue<string>('tag_name', Info.Tag) then
        Exit(MakeResult(ueNetwork, 'Invalid GitHub response'));
      // Имена архивов менялись (dfu_win_64bit / dfu_windows_64bit), поэтому ищем по шаблону
      if Json.TryGetValue<TJSONArray>('assets', Assets) then
        for Asset in Assets do
        begin
          Name := Asset.GetValue<string>('name', '');
          if StartsText('dfu_win', Name) and ContainsText(Name, AssetArch) and EndsText('.zip', Name) then
          begin
            Info.AssetName := Name;
            Info.Url := Asset.GetValue<string>('browser_download_url', '');
            Info.Size := Asset.GetValue<Int64>('size', 0);
            Digest := Asset.GetValue<string>('digest', '');
            if StartsText('sha256:', Digest) then
              Info.Sha256 := Copy(Digest, 8, MaxInt);
            Break;
          end;
        end;
      if not Info.HasAsset then
        Exit(MakeResult(ueNoAsset));
    finally
      Json.Free;
    end;
  finally
    Response.Free;
  end;
end;

function CheckGameWritable(const GameDir, GameExe: string): TUpdateResult;
var
  H: THandle;
  Err: DWORD;
begin
  Result := MakeResult(ueNone);
  if not ForceDirectories(GameDir) then
    Exit(MakeResult(ueNoAccess));
  // Запущенный exe нельзя открыть на запись - так заодно ловим запущенную игру
  if FileExists(GameExe) then
  begin
    H := CreateFile(PChar(GameExe), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
    if H = INVALID_HANDLE_VALUE then
    begin
      Err := GetLastError;
      if Err = ERROR_SHARING_VIOLATION then
        Exit(MakeResult(ueGameRunning));
      Exit(MakeResult(ueNoAccess));
    end;
    CloseHandle(H);
  end;
  H := CreateFile(PChar(GameDir + '.write_test'), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
    FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE, 0);
  if H = INVALID_HANDLE_VALUE then
    Exit(MakeResult(ueNoAccess));
  CloseHandle(H);
end;

function FileSizeOf(const FileName: string): Int64;
var
  Data: TWin32FileAttributeData;
begin
  if GetFileAttributesEx(PChar(FileName), GetFileExInfoStandard, @Data) then
    Result := Int64(Data.nFileSizeHigh) shl 32 or Data.nFileSizeLow
  else
    Result := -1;
end;

function ArchiveValid(const FileName: string; const Info: TReleaseInfo): Boolean;
begin
  Result := (FileSizeOf(FileName) = Info.Size) and
    ((Info.Sha256 = '') or SameText(THashSHA2.GetHashStringFromFile(FileName, SHA256), Info.Sha256));
end;

function DownloadRelease(const Info: TReleaseInfo; const Token: ICancelToken;
  const OnProgress: TProgressProc; out ZipPath: string): TUpdateResult;
var
  TempDir: array[0..MAX_PATH] of Char;
  PartPath: string;
  F: TFileStream;
begin
  GetTempPath(Length(TempDir), TempDir);
  // Тег в имени - чтобы не перепутать с архивом другого релиза
  ZipPath := IncludeTrailingPathDelimiter(TempDir) + 'DFU_' + Info.Tag + '_' + Info.AssetName;
  if FileExists(ZipPath) and ArchiveValid(ZipPath, Info) then
    Exit(MakeResult(ueNone));

  PartPath := ZipPath + '.part';
  try
    F := TFileStream.Create(PartPath, fmCreate);
    try
      Result := HttpGet(Info.Url, '', F, Token, OnProgress, Info.Size);
    finally
      F.Free;
    end;
    if Result.Ok and not ArchiveValid(PartPath, Info) then
      Result := MakeResult(ueChecksum);
    if Result.Ok then
    begin
      System.SysUtils.DeleteFile(ZipPath);
      if not RenameFile(PartPath, ZipPath) then
        Result := MakeResult(ueExtract, SysErrorMessage(GetLastError));
    end;
  except
    on E: Exception do
      Result := MakeResult(ueExtract, E.Message);
  end;
  System.SysUtils.DeleteFile(PartPath);
end;

function SafeEntryName(const Name: string): Boolean;
begin
  // Защита от путей вида ../../ и абсолютных путей внутри архива
  Result := (Name <> '') and (Name[1] <> '/') and (Name[1] <> '\') and
    (Pos(':', Name) = 0) and (Pos('..', Name) = 0);
end;

function ExtractRelease(const ZipPath, GameDir: string;
  const OnProgress: TProgressProc): TUpdateResult;
var
  Zip: TZipFile;
  I: Integer;
  Name, Staging, Target: string;
  Files: TStringList;
  Total, Done: Int64;
begin
  Result := MakeResult(ueNone);
  // Сначала распаковываем во временную папку и только потом переносим на место:
  // если распаковка сорвётся, игра останется нетронутой
  Staging := GameDir + '.update\';
  Files := TStringList.Create;
  Zip := TZipFile.Create;
  try
    try
      if TDirectory.Exists(Staging) then
        TDirectory.Delete(Staging, True);
      Zip.Open(ZipPath, zmRead);
      Total := 0;
      for I := 0 to Zip.FileCount - 1 do
        Inc(Total, Zip.FileInfo[I].UncompressedSize);
      Done := 0;
      for I := 0 to Zip.FileCount - 1 do
      begin
        Name := Zip.FileNames[I];
        if not SafeEntryName(Name) then
          raise EZipException.CreateFmt('Invalid file name in archive: %s', [Name]);
        if not EndsText('/', Name) and not SameText(Name, SkippedZipEntry) then
        begin
          Zip.Extract(I, ExcludeTrailingPathDelimiter(Staging), True);
          Files.Add(StringReplace(Name, '/', '\', [rfReplaceAll]));
        end;
        Inc(Done, Zip.FileInfo[I].UncompressedSize);
        if Assigned(OnProgress) then
          OnProgress(Done, Total);
      end;
      Zip.Close;

      for Name in Files do
      begin
        Target := GameDir + Name;
        ForceDirectories(ExtractFileDir(Target));
        if not MoveFileEx(PChar(Staging + Name), PChar(Target),
          MOVEFILE_REPLACE_EXISTING or MOVEFILE_COPY_ALLOWED) then
          raise EInOutError.CreateFmt('%s: %s', [Target, SysErrorMessage(GetLastError)]);
      end;
    except
      on E: Exception do
        Result := MakeResult(ueExtract, E.Message);
    end;
  finally
    Zip.Free;
    Files.Free;
    try
      if TDirectory.Exists(Staging) then
        TDirectory.Delete(Staging, True);
    except
      // Остатки временной папки удалятся при следующем обновлении
    end;
  end;
  if Result.Ok then
    System.SysUtils.DeleteFile(ZipPath);
end;

end.
