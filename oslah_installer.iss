; Inno Setup Compiler configuration script for OSLAH (Open-Source Local Agent Hub)
; Generated for Beezyman Studio

#define MyAppName "OSLAH"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Beezyman Studio"
#define MyAppExeName "oslah.exe"
#define MyAppBuildReleaseDir "E:\oslah\build\windows\x64\runner\Release"
#define MyProjectRoot "E:\oslah"

[Setup]
; Unique App ID for install registry
AppId={{5E227092-B7AE-4D61-A795-B330F6C92AA8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Output folder path at the project root
OutputDir={#MyProjectRoot}\InnoOutput
OutputBaseFilename=OSLAH_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64

; Brand Identity Asset Configurations (Absolute Paths)
SetupIconFile={#MyProjectRoot}\oslah logo\favicon.ico
WizardSmallImageFile={#MyProjectRoot}\oslah logo\beezy_man_logo.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main Executable
Source: "{#MyAppBuildReleaseDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Supporting DLL libraries (Flutter engine, SQLite dependencies, etc.)
Source: "{#MyAppBuildReleaseDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
; Flutter app data asset folders recursively
Source: "{#MyAppBuildReleaseDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Copy the icon file into the installation directory for shortcut reference
Source: "{#MyProjectRoot}\oslah logo\favicon.ico"; DestDir: "{app}"; DestName: "app_icon.ico"; Flags: ignoreversion

[Icons]
; Start Menu icon shortcut utilizing the copied .ico file
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
; Desktop icon shortcut task utilizing the copied .ico file
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\app_icon.ico"

[Run]
; Option to launch OSLAH immediately after setup finishes
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
