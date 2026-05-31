; Instalador de Sonora para Windows (Inno Setup).
; Se compila en CI con: iscc /DMyAppVersion=X.Y.Z installer\windows\sonora.iss
; Las rutas se resuelven relativas a la raíz del repo mediante SourcePath.

#define MyAppName "Sonora"
#define MyAppExeName "sonora.exe"
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#define Root SourcePath + "..\..\"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Sonora
DefaultDirName={autopf}\Sonora
DefaultGroupName=Sonora
DisableProgramGroupPage=yes
OutputDir={#Root}dist
OutputBaseFilename=Sonora-windows-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#Root}build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\Sonora"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,Sonora}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Sonora"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,Sonora}"; Flags: nowait postinstall skipifsilent
