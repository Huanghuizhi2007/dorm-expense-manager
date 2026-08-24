#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw '没有找到 flutter 命令。请先安装鸿蒙版 Flutter SDK 并配置 PATH。'
}

$url = $env:SUPABASE_URL
$key = $env:SUPABASE_ANON_KEY
if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($key)) {
  throw '请先设置环境变量 SUPABASE_URL 和 SUPABASE_ANON_KEY。'
}

$overrideSource = Join-Path $PSScriptRoot 'ohos\pubspec_overrides.yaml'
$overrideTarget = Join-Path $root 'pubspec_overrides.yaml'
if (Test-Path $overrideTarget) {
  throw '项目根目录已存在 pubspec_overrides.yaml，请先移走后再执行。'
}

Copy-Item $overrideSource $overrideTarget
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get 失败。'
  }
  flutter build hap --release `
    --dart-define=SUPABASE_URL="$url" `
    --dart-define=SUPABASE_ANON_KEY="$key"
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter build hap 失败。'
  }
  Write-Host ''
  Write-Host 'HAP 构建完成。请到 ohos/entry/build 或 build/ohos 下查找 signed/unsigned 包。'
} finally {
  if (Test-Path $overrideTarget) {
    Remove-Item $overrideTarget -Force
  }
}
