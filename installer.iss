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
Name: "chs"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel1=欢迎
WelcomeLabel2=这将会在你的电脑上安装 [name/rev]。%n%n建议在继续安装前关闭其他应用程序。
SelectDirLabel3=安装程序将会把 [name] 安装到下面的文件夹中。
SelectDirBrowseLabel=如需安装到其他位置，请点击“浏览(B)”。
DirExists=文件夹已存在。要安装到这个文件夹吗？
ReadyLabel1=安装程序已准备好开始安装 [name]。
ReadyLabel2a=点击“安装(I)”开始安装。
SelectTasksLabel2=选择你想要安装程序执行的附加任务：
FinishedLabel1=[name] 已成功安装到你的电脑中。
FinishedLabel2=点击“完成(F)”退出安装向导。现在可以运行 [name] 了。
ExitSetupTitle=退出安装
ExitSetupMessage=安装尚未完成。如果现在退出，[name] 将不会被安装。%n%n你可以稍后再次运行安装程序完成安装。%n%n要退出安装吗？
WizardSetup=正在安装
PreparingSetup=正在准备安装…
Installing=正在安装…
InstallingLabel=请稍候，安装程序正在安装 [name]。
FinishedRestartLabel=要立即运行 [name]，请重启电脑。
FinishedRestartMessage=要完成安装，需要重启电脑。要现在重启吗？
ButtonNext=下一步(&N) >
ButtonInstall=安装(&I) >
ButtonFinish=完成(&F)
ButtonCancel=取消
ButtonBrowse=浏览(&B)...
ButtonBack=< 返回(&B)
SelectDirDesc=要安装到哪里？
SelectDirLabel3b=目标文件夹：
SelectTasksDesc=选择附加任务
SelectTasksLabel3=点击“下一步”继续。
ReadyTitle=准备安装
FinishedTitle=安装完成
WelcomeTitle=欢迎使用 [name] 安装向导

[CustomMessages]
CreateDesktopIcon=创建桌面快捷方式(&D)
AdditionalIcons=附加任务：
UninstallProgram=卸载 %1
LaunchProgram=运行 %1

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