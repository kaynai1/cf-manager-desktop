# 在 Windows 上直接以 Flutter 运行桌面版（开发调试用）
# 用法：
#   ./scripts/run_windows.ps1            # flutter run -d windows
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "未找到 flutter 命令。请先安装 Flutter 并加入 PATH。"
}

if (-not (Test-Path "$Root\windows")) {
    Write-Host "生成 Windows 桌面平台脚手架..." -ForegroundColor Cyan
    flutter create --platforms=windows --project-name cloudflare_manager .
}

flutter pub get
flutter run -d windows