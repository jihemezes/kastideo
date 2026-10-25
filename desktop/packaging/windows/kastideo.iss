; Installateur Windows de Kastideo (Inno Setup 6).
; Construit par .github/workflows/desktop.yml :
;   ISCC.exe /DAppVersion=1.2.0-desktop8 /DNumericVersion=1.2.0.8 packaging\windows\kastideo.iss
; Par défaut, installation pour l'utilisateur seul (sans droits administrateur) ; « Installer pour tous les utilisateurs »
; reste proposé. Les mises à jour intégrées relancent cet installateur en silencieux avec /RELAUNCH=1.

#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif
#ifndef NumericVersion
  #define NumericVersion "0.0.0.0"
#endif

[Setup]
AppId={{6E0C3B1F-4B7A-4D3E-9A61-2F8C5D7E4B90}
AppName=Kastideo
AppVersion={#AppVersion}
AppVerName=Kastideo {#AppVersion}
VersionInfoVersion={#NumericVersion}
AppPublisher=Jean-Michel Ezes
AppPublisherURL=https://github.com/jihemezes/kastideo
AppSupportURL=https://github.com/jihemezes/kastideo/issues
AppUpdatesURL=https://github.com/jihemezes/kastideo/releases
DefaultDirName={autopf}\Kastideo
DefaultGroupName=Kastideo
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\dist
OutputBaseFilename=Kastideo-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\kastideo.exe
UninstallDisplayName=Kastideo
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=force
RestartApplications=no
ChangesAssociations=yes
MinVersion=10.0

[Languages]
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
fr.AssocM3U=Ouvrir les fichiers .m3u et .m3u8 avec Kastideo
en.AssocM3U=Open .m3u and .m3u8 files with Kastideo
fr.AutoStart=Lancer Kastideo à l'ouverture de session (réduit, pour les enregistrements programmés)
en.AutoStart=Start Kastideo when I sign in (minimized, for scheduled recordings)
fr.Options=Options :
en.Options=Options:
fr.PlaylistType=Playlist M3U
en.PlaylistType=M3U playlist

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "m3u"; Description: "{cm:AssocM3U}"; GroupDescription: "{cm:Options}"; Flags: unchecked
Name: "autostart"; Description: "{cm:AutoStart}"; GroupDescription: "{cm:Options}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Kastideo"; Filename: "{app}\kastideo.exe"
Name: "{autodesktop}\Kastideo"; Filename: "{app}\kastideo.exe"; Tasks: desktopicon

[Registry]
; Fichiers .m3u / .m3u8 (facultatif).
Root: HKA; Subkey: "Software\Classes\Kastideo.m3u"; ValueType: string; ValueName: ""; ValueData: "{cm:PlaylistType}"; Flags: uninsdeletekey; Tasks: m3u; Check: not WizardSilent
Root: HKA; Subkey: "Software\Classes\Kastideo.m3u\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\kastideo.exe"",0"; Tasks: m3u; Check: not WizardSilent
Root: HKA; Subkey: "Software\Classes\Kastideo.m3u\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\kastideo.exe"" ""%1"""; Tasks: m3u; Check: not WizardSilent
Root: HKA; Subkey: "Software\Classes\.m3u"; ValueType: string; ValueName: ""; ValueData: "Kastideo.m3u"; Flags: uninsdeletevalue; Tasks: m3u; Check: not WizardSilent
Root: HKA; Subkey: "Software\Classes\.m3u8"; ValueType: string; ValueName: ""; ValueData: "Kastideo.m3u"; Flags: uninsdeletevalue; Tasks: m3u; Check: not WizardSilent
Root: HKA; Subkey: "Software\Classes\.m3u\OpenWithProgids"; ValueType: none; ValueName: "Kastideo.m3u"; Flags: uninsdeletevalue; Tasks: m3u; Check: not WizardSilent
Root: HKA; Subkey: "Software\Classes\.m3u8\OpenWithProgids"; ValueType: none; ValueName: "Kastideo.m3u"; Flags: uninsdeletevalue; Tasks: m3u; Check: not WizardSilent
; Lancement à l'ouverture de session (facultatif ; aussi réglable dans Kastideo > Réglages > Général).
; « not WizardSilent » : une mise à jour silencieuse ne rétablit pas une option désactivée depuis Kastideo.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Kastideo"; ValueData: """{app}\kastideo.exe"" --minimized"; Flags: uninsdeletevalue; Tasks: autostart; Check: not WizardSilent

[Run]
Filename: "{app}\kastideo.exe"; Description: "{cm:LaunchProgram,Kastideo}"; Flags: nowait postinstall skipifsilent
; Mise à jour intégrée : relance de Kastideo après l'installation silencieuse.
Filename: "{app}\kastideo.exe"; Flags: nowait; Check: IsRelaunch

[UninstallRun]
Filename: "{cmd}"; Parameters: "/C taskkill /IM kastideo.exe /F"; Flags: runhidden; RunOnceId: "StopKastideo"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
function IsRelaunch: Boolean;
begin
  Result := ExpandConstant('{param:RELAUNCH|0}') = '1';
end;

// Lancement automatique réglé dans Kastideo : la désinstallation le retire aussi.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Kastideo');
end;
