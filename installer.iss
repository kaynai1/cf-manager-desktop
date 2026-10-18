; Inno Setup 脚本：将 Cloudflare 管理器打包成 Windows 安装程序 (Setup.exe)
; 使用: ISCC.exe installer.iss

#define MyAppName "Cloudflare 管理器"
#define MyAppVersion "1.0.1"
#define MyAppPublisher "Cloudflare Manager"
#define MyAppExeName "cloudflare_manager.exe"

[Setup]
AppId={{8E7D3C1A-5F2B-4A6C-9D3E-0F1A2B3C4D5E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer-output
OutputBaseFilename=cloudflare_manager_setup_{#MyAppVersion}
; SetupIconFile 需要 .ico 文件，无时使用默认图标
; SetupIconFile=assets\icon\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "chs"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Messages]
chs.WelcomeLabel2=这将会在你的电脑上安装 [name/rev]。%n%n建议在继续安装前关闭其他应用程序。
chs.SelectDirLabel3=安装程序将会把 [name] 安装到下面的文件夹中。
chs.SelectDirBrowseLabel=如需安装到其他位置，请点击“浏览(B)”。
chs.ReadyLabel1=安装程序已准备好开始安装 [name]。
chs.ReadyLabel2a=点击“安装(I)”开始安装。
chs.SelectTasksLabel2=选择你想要安装程序执行的附加任务：
chs.FinishedLabel1=[name] 已成功安装到你的电脑中。
chs.FinishedLabel2=点击“完成(F)”退出安装向导。现在可以运行 [name] 了。

[CustomMessages]
chs.CreateDesktopIcon=创建桌面快捷方式(&D)
chs.AdditionalIcons=附加任务：
chs.UninstallProgram=卸载 %1
chs.LaunchProgram=运行 %1

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 主程序与运行时
Source: "build\windows\x64\runner\Release\*.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent