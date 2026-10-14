unit DFUnity_SettingsForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ExtCtrls, DFUnity_Updater;

type
  TSettingsForm = class(TForm)
    LangLabel: TLabel;
    LangCombo: TComboBox;
    Separator: TBevel;
    AutoCheckBox: TCheckBox;
    InstalledLabel: TLabel;
    LatestLabel: TLabel;
    ProgressLabel: TLabel;
    ProgressPanel: TPanel;
    ProgressFill: TPanel;
    LogMemo: TMemo;
    CheckBut: TButton;
    UpdateBut: TButton;
    CloseBut: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure LangComboChange(Sender: TObject);
    procedure AutoCheckBoxClick(Sender: TObject);
    procedure CheckButClick(Sender: TObject);
    procedure UpdateButClick(Sender: TObject);
    procedure CloseButClick(Sender: TObject);

  private
    FLatest: TReleaseInfo;
    FOnLanguageChange: TProc;
    FLoading: Boolean;
    FChecking: Boolean;
    FUpdating: Boolean;
    FCanCancel: Boolean;
    FAlive: ICancelToken;       // отменяется при закрытии окна - результаты потоков игнорируются
    FOperation: ICancelToken;   // отмена загрузки кнопкой
    FLastProgress: Cardinal;
    procedure ApplyLanguage;
    procedure RefreshState;
    procedure SaveConfig;
    procedure Log(const Text: string);
    procedure SetProgress(Done, Total: Int64; const Text: string);
    procedure LogError(const R: TUpdateResult);
    procedure UpdateFinished(const R: TUpdateResult);
  public
    // Latest - уже известный релиз (из автопроверки), после закрытия - последний найденный
    class procedure Execute(AOwner: TForm; var Latest: TReleaseInfo; const OnLanguageChange: TProc);
  end;

implementation

{$R *.dfm}

uses
  DFUnity_Strings, DFUnity_Config;

const
  MB = 1024 * 1024;

class procedure TSettingsForm.Execute(AOwner: TForm; var Latest: TReleaseInfo;
  const OnLanguageChange: TProc);
var
  F: TSettingsForm;
begin
  F := TSettingsForm.Create(AOwner);
  try
    F.FLatest := Latest;
    F.FOnLanguageChange := OnLanguageChange;
    F.RefreshState;
    if (F.FLatest.Tag <> '') and (F.FLatest.Tag <> Config.GameVersion) then
      F.Log(Format(Strings[Config.Lang].UpdateFound, [F.FLatest.Tag]));
    F.ShowModal;
    Latest := F.FLatest;
  finally
    F.Free;
  end;
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  FAlive := NewCancelToken;
  FLoading := True;
  try
    AutoCheckBox.Checked := Config.CheckUpdates;
    ApplyLanguage;
  finally
    FLoading := False;
  end;
end;

procedure TSettingsForm.FormDestroy(Sender: TObject);
begin
  FAlive.Cancel;
end;

procedure TSettingsForm.ApplyLanguage;
var
  S: TLangStrings;
  L: TLanguage;
begin
  S := Strings[Config.Lang];
  Caption := S.SettingsCaption;
  LangLabel.Caption := S.LanguageLabel;
  AutoCheckBox.Caption := S.AutoCheck;
  CheckBut.Caption := S.CheckBut;
  UpdateBut.Caption := S.UpdateBut;

  LangCombo.Items.BeginUpdate;
  try
    LangCombo.Items.Clear;
    LangCombo.Items.Add(S.LanguageSystem);
    for L := Low(TLanguage) to High(TLanguage) do
      LangCombo.Items.Add(Strings[L].Name);
  finally
    LangCombo.Items.EndUpdate;
  end;
  if Config.Language = '' then
    LangCombo.ItemIndex := 0
  else
    LangCombo.ItemIndex := Ord(Config.Lang) + 1;
  RefreshState;
end;

procedure TSettingsForm.RefreshState;
var
  S: TLangStrings;
begin
  S := Strings[Config.Lang];
  if Config.GameVersion <> '' then
    InstalledLabel.Caption := Format(S.InstalledVersion, [Config.GameVersion])
  else
    InstalledLabel.Caption := Format(S.InstalledVersion, [S.VersionUnknown]);
  if FLatest.Tag <> '' then
    LatestLabel.Caption := Format(S.LatestVersion, [FLatest.Tag])
  else
    LatestLabel.Caption := Format(S.LatestVersion, [S.LatestUnknown]);

  LangCombo.Enabled := not FUpdating;
  AutoCheckBox.Enabled := not FUpdating;
  CheckBut.Enabled := not (FChecking or FUpdating);
  UpdateBut.Enabled := not (FChecking or FUpdating) and FLatest.HasAsset and
    (FLatest.Tag <> Config.GameVersion);
  if FUpdating then
  begin
    CloseBut.Caption := S.CancelBut;
    CloseBut.Enabled := FCanCancel;
  end
  else
  begin
    CloseBut.Caption := S.CloseBut;
    CloseBut.Enabled := True;
  end;
end;

procedure TSettingsForm.SaveConfig;
begin
  if not Config.Save then
    MessageBox(Handle, PChar(Format(Strings[Config.Lang].SaveFailed, [Config.IniPath])),
      PChar(Application.Title), MB_OK or MB_ICONWARNING);
end;

procedure TSettingsForm.Log(const Text: string);
begin
  LogMemo.Lines.Add(Text);
  LogMemo.SelStart := Length(LogMemo.Text);
  LogMemo.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TSettingsForm.SetProgress(Done, Total: Int64; const Text: string);
begin
  if Total > 0 then
    ProgressFill.Width := Round(ProgressPanel.ClientWidth * Done / Total)
  else
    ProgressFill.Width := 0;
  ProgressLabel.Caption := Text;
end;

procedure TSettingsForm.LogError(const R: TUpdateResult);
var
  S: TLangStrings;
begin
  S := Strings[Config.Lang];
  case R.Error of
    ueNetwork:     Log(Format(S.ErrNetwork, [R.Detail]));
    ueHttp:        Log(Format(S.ErrHttp, [R.HttpCode]));
    ueNoAsset:     Log(S.ErrNoAsset);
    ueChecksum:    Log(S.ErrChecksum);
    ueCancelled:   Log(S.Cancelled);
    ueGameRunning: Log(S.ErrGameRunning);
    ueNoAccess:    Log(S.ErrNoAccess);
    ueExtract:     Log(Format(S.ErrExtract, [R.Detail]));
  end;
end;

procedure TSettingsForm.LangComboChange(Sender: TObject);
begin
  if LangCombo.ItemIndex <= 0 then
    Config.Language := ''
  else
    Config.Language := Strings[TLanguage(LangCombo.ItemIndex - 1)].Code;
  SaveConfig;
  ApplyLanguage;
  if Assigned(FOnLanguageChange) then
    FOnLanguageChange;
end;

procedure TSettingsForm.AutoCheckBoxClick(Sender: TObject);
begin
  if FLoading then
    Exit;
  Config.CheckUpdates := AutoCheckBox.Checked;
  SaveConfig;
end;

procedure TSettingsForm.CheckButClick(Sender: TObject);
var
  Alive: ICancelToken;
begin
  FChecking := True;
  RefreshState;
  SetProgress(0, 1, '');
  Log(Strings[Config.Lang].Checking);
  Alive := FAlive;
  TThread.CreateAnonymousThread(
    procedure
    var
      Info: TReleaseInfo;
      R: TUpdateResult;
    begin
      R := FetchLatestRelease(Info);
      TThread.Queue(nil,
        procedure
        begin
          if Alive.Cancelled then
            Exit;
          FChecking := False;
          if Info.Tag <> '' then
            FLatest := Info;
          RefreshState;
          if not R.Ok then
            LogError(R)
          else if Info.Tag = Config.GameVersion then
            Log(Strings[Config.Lang].UpToDate)
          else
            Log(Format(Strings[Config.Lang].UpdateFound, [Info.Tag]));
        end);
    end).Start;
end;

procedure TSettingsForm.UpdateButClick(Sender: TObject);
var
  Alive, Op: ICancelToken;
  Info: TReleaseInfo;
  GameDir, GameExe: string;
begin
  FUpdating := True;
  FCanCancel := True;
  FOperation := NewCancelToken;
  FLastProgress := 0;
  RefreshState;
  SetProgress(0, 1, '');

  Alive := FAlive;
  Op := FOperation;
  Info := FLatest;
  GameDir := Config.GameDir;
  GameExe := Config.GameExe;
  TThread.CreateAnonymousThread(
    procedure
    var
      R: TUpdateResult;
      ZipPath: string;
    begin
      try
        R := CheckGameWritable(GameDir, GameExe);
        if R.Ok then
        begin
          TThread.Queue(nil,
            procedure
            begin
              if Alive.Cancelled then
                Exit;
              Log(Format(Strings[Config.Lang].DownloadStart, [Info.AssetName, Info.Size / MB]));
              SetProgress(0, 1, Format(Strings[Config.Lang].Downloading, [0.0, Info.Size / MB]));
            end);
          R := DownloadRelease(Info, Op,
            procedure(Done, Total: Int64)
            begin
              // Не заваливаем окно сообщениями - не чаще 10 раз в секунду
              if (GetTickCount - FLastProgress < 100) and (Done < Total) then
                Exit;
              FLastProgress := GetTickCount;
              TThread.Queue(nil,
                procedure
                begin
                  if Alive.Cancelled then
                    Exit;
                  SetProgress(Done, Total, Format(Strings[Config.Lang].Downloading, [Done / MB, Total / MB]));
                  if Done >= Total then
                    Log(Strings[Config.Lang].Verifying);
                end);
            end, ZipPath);
        end;
        // Перед распаковкой ещё раз: игру могли запустить, пока шла загрузка
        if R.Ok then
          R := CheckGameWritable(GameDir, GameExe);
        if R.Ok then
        begin
          // Распаковку не прерываем - иначе игра останется наполовину обновлённой
          TThread.Queue(nil,
            procedure
            begin
              if Alive.Cancelled then
                Exit;
              FCanCancel := False;
              RefreshState;
              Log(Strings[Config.Lang].ExtractStart);
            end);
          R := ExtractRelease(ZipPath, GameDir,
            procedure(Done, Total: Int64)
            begin
              TThread.Queue(nil,
                procedure
                begin
                  if Alive.Cancelled or (Total <= 0) then
                    Exit;
                  SetProgress(Done, Total, Format(Strings[Config.Lang].Extracting, [Done * 100 div Total]));
                end);
            end);
        end;
      except
        on E: Exception do
        begin
          R := Default(TUpdateResult);
          R.Error := ueExtract;
          R.Detail := E.Message;
        end;
      end;
      TThread.Queue(nil,
        procedure
        begin
          if not Alive.Cancelled then
            UpdateFinished(R);
        end);
    end).Start;
end;

procedure TSettingsForm.UpdateFinished(const R: TUpdateResult);
begin
  FUpdating := False;
  SetProgress(0, 1, '');
  if R.Ok then
  begin
    Config.GameVersion := FLatest.Tag;
    SaveConfig;
    SetProgress(1, 1, '');
    Log(Format(Strings[Config.Lang].UpdateDone, [FLatest.Tag]));
  end
  else
    LogError(R);
  RefreshState;
end;

procedure TSettingsForm.CloseButClick(Sender: TObject);
begin
  if FUpdating then
    FOperation.Cancel
  else
    Close;
end;

procedure TSettingsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Пока идёт обновление, окно не закрываем - загрузку можно только отменить
  CanClose := not FUpdating;
  if FUpdating and FCanCancel then
    FOperation.Cancel;
end;

end.
