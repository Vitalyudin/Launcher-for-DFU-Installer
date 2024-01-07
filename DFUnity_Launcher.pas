unit DFUnity_Launcher;

{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

interface

uses
//  Winapi.Windows,
  Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, ShellAPI, Vcl.ExtCtrls,
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.XPMan, Vcl.Menus,
  Windows, Vcl.StdCtrls;
  //IOUtils;

  {$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED}

{$IFNDEF DEBUG}
  {$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED} // �������� �� exe ������� ���������.
  {$SetPEFlags IMAGE_FILE_DEBUG_STRIPPED} //  �������� �� ��� Debug ����������
  {$SetPEFlags IMAGE_FILE_LINE_NUMS_STRIPPED} // �������� �� exe ���������� � ������� �����
  {$SetPEFlags IMAGE_FILE_LOCAL_SYMS_STRIPPED} // �������� local symbols
  {$SetPEFlags IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP} //��� ������� exe � ��������, ������, ������ ����������� ���������, ������� exe � ���� � ��������� ������. �������, ���� ����� ��������� ��������� � ��������, � ����� ��������� �������� ������...
  {$SetPEFlags IMAGE_FILE_NET_RUN_FROM_SWAP} // ���������� ����������, ������ ��� ������� ������
  {$SetPEFlags IMAGE_FILE_EXECUTABLE_IMAGE}
{$ENDIF}


type
  TMainWindow = class(TForm)
    DF_LaunchBut: TSpeedButton;
    DF_DeletThisBut: TSpeedButton;
    DF_UnitySiteBut: TSpeedButton;
    DF_TesallButt: TSpeedButton;
    Background: TImage;
    procedure DF_UnitySiteButClick(Sender: TObject);
    procedure DF_LaunchButClick(Sender: TObject);
    procedure DF_DeletThisButClick(Sender: TObject);
    procedure DF_ManualButClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DF_ExitButClick(Sender: TObject);
    procedure DF_TesallButtClick(Sender: TObject);

  private

  public

  end;

var
  MainWindow: TMainWindow;
  EXENotFound, UninstNotFound, GuideNotFound, Deletmsg: string;
  DFUexePath, UninstPath, GuidePath, DFUnitySite, TesallPage: pwidechar;

implementation

{$R *.dfm}


procedure DFUnityDeleting;
begin
ShellExecute(MainWindow.handle, 'open', UninstPath, nil, nil, sw_shownormal);
Application.Terminate;
end;

procedure DFUnityLaunch;
begin
ShellExecute(MainWindow.handle, 'open', DFUexepath, nil, nil, sw_shownormal);
//Application.Terminate;
end;


procedure TMainWindow.FormCreate(Sender: TObject);
begin
TesallPage:='https://tesall.ru/files/modi-dlya-drugikh-igr/10820-daggerfall-unity-installer';
DFUnitySite:='https://www.dfworkshop.net';
DFUexePath:='.\Daggerfallunity\DaggerfallUnity.exe';
UninstPath:='.\unins000.exe';
GuidePath:='.\Daggerfall Unity Manual.pdf';
EXENotFound:='���� "DaggerfallUnity.exe" �� ������. ��������, �� ��� ��������� ��� �����. �� ������ ������ ������� �������������� Daggerfall Unity.';
UninstNotFound:='������������� �� ������ - ��������, ��� ��������� ��� �����. � ����� ������ ������ ������� �� �������.';
GuideNotFound:='���� ����������� "Daggerfall Unity Manual.pdf" �� ������. ��������, ��� ��������� ��� �����.';
end;


procedure TMainWindow.DF_DeletThisButClick(Sender: TObject);
begin
  if FileExists(UninstPath)
    then DFUnityDeleting
  else showmessage(UninstNotFound);
end;

procedure TMainWindow.DF_LaunchButClick(Sender: TObject);
begin
  if FileExists(DFUexePath)
    then DFUnitylaunch
  else ShowMessage(EXENotFound);
end;

procedure TMainWindow.DF_ManualButClick(Sender: TObject);
begin
  if FileExists(GuidePath)
    then ShellExecute(handle, 'open', GuidePath, nil, nil, sw_show)
  else     Showmessage(GuideNotFound);
end;

procedure TMainWindow.DF_UnitySiteButClick(Sender: TObject);
begin
  ShellExecute(handle, 'open', DFUnitySite, nil, nil, sw_show);
end;

procedure TMainWindow.DF_TesallButtClick(Sender: TObject);
begin
  ShellExecute(handle, 'open', TesallPage, nil, nil, sw_show);
end;


procedure TMainWindow.df_exitbutClick(Sender: TObject);
begin
Application.Terminate;
end;

end.
