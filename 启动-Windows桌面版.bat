# 一键启动 Windows 桌面版（双击本文件即可）
@echo off
chcp 65001 >nul
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (
    echo [错误] 未找到 flutter，请先安装 Flutter 并加入 PATH。
    pause
    exit /b 1
)
if not exist "windows" (
    echo 首次运行，正在生成 Windows 平台脚手架...
    flutter create --platforms=windows --project-name cloudflare_manager .
)
flutter pub get
if errorlevel 1 ( pause & exit /b 1 )
powershell -ExecutionPolicy Bypass -File "scripts\build_windows.ps1"
if errorlevel 1 ( pause & exit /b 1 )
echo.
echo 构建完成，正在启动...
start "" "build\windows\x64\runner\Release\cloudflare_manager.exe"
pause