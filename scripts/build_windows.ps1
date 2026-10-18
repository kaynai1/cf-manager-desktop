# Windows 桌面版构建脚本
# 用法：
#   ./scripts/build_windows.ps1          # 构建 release 版 exe
#   ./scripts/build_windows.ps1 -Debug   # 构建 debug 版
# 依赖：
#   - Flutter 3.22+（含 Windows 桌面支持，需已开启 "flutter config --enable-windows-desktop"）
#   - Visual Studio（桌面 C++ 工作负载）
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

param(
    [switch]$Debug
)

function Invoke-Native {
    param([string]$File, [string[]]$Args)
    & $File @Args
    if ($LASTEXITCODE -ne 0) { throw "$File 失败，退出码 $LASTEXITCODE" }
}

# 0) 检查 flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "未找到 flutter 命令。请先安装 Flutter 并加入 PATH。"
}

# 1) 检查 / 补充 Windows 桌面脚手架（首次需要生成 windows/ 目录）
if (-not (Test-Path "$Root\windows")) {
    Write-Host "[1/4] 生成 Windows 桌面平台脚手架（flutter create --platforms=windows）..." -ForegroundColor Cyan
    Invoke-Native "flutter" @("create", "--platforms=windows", "--project-name", "cloudflare_manager", ".")
}

# 2) 拉取依赖
Write-Host "[2/4] 获取依赖（flutter pub get）..." -ForegroundColor Cyan
Invoke-Native "flutter" @("pub", "get")

# 3) 构建
if ($Debug) {
    Write-Host "[3/4] 构建 Windows Debug..." -ForegroundColor Cyan
    Invoke-Native "flutter" @("build", "windows", "--debug")
    $out = "$Root\build\windows\x64\runner\Debug\cloudflare_manager.exe"
} else {
    Write-Host "[3/4] 构建 Windows Release..." -ForegroundColor Cyan
    Invoke-Native "flutter" @("build", "windows", "--release")
    $out = "$Root\build\windows\x64\runner\Release\cloudflare_manager.exe"
}

# 4) 输出
Write-Host "[4/4] 构建完成 ✔" -ForegroundColor Green
Write-Host "产物：$out"
Write-Host ""
Write-Host "提示：可以将 Release 目录整体拷贝到其它 Windows 电脑直接运行（含所需 DLL）。"

return $out