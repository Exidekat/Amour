Set-StrictMode -Version Latest

# Game Name
$env:GAME_NAME = "Duoble"
$env:ORIENTATION = "landscape"
$env:LOVE_VER = "11.5"

# Determine project directory based on this script's location
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
# Script is in PROJECT/Amour/powershell
# PROJECT dir is 3 levels up: PROJECT -> Amour -> powershell -> variables.ps1
$ProjectDir = (Join-Path (Join-Path $ScriptDir "..") "..") | Resolve-Path | Select-Object -ExpandProperty Path
$env:PROJECT_DIR = $ProjectDir

$env:AMOUR_DIR = Join-Path $env:PROJECT_DIR "Amour"
$env:GAMEDATA_DIR = Join-Path $env:PROJECT_DIR "gamedata"
$env:BUILD_DIR = Join-Path $env:PROJECT_DIR "build"

New-Item -ItemType Directory -Path (Join-Path $env:AMOUR_DIR "extern") -Force | Out-Null

$env:LOVE_WIN32_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_$($env:LOVE_VER)_win32"
$env:LOVE_WIN64_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_$($env:LOVE_VER)_win64"
$env:LOVE_MACOS_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_$($env:LOVE_VER)_macos"
$env:LOVE_ANDROID_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_android"

# Android SDK and NDK
$env:ANDROID_SDK_ROOT = "$env:USERPROFILE/Library/Android/sdk"
$env:ANDROID_NDK_VER = "28.0.12674087"
$env:ANDROID_NDK_HOME = Join-Path $env:ANDROID_SDK_ROOT ("ndk/" + $env:ANDROID_NDK_VER)

$env:JAVA_VERSION = "17"
$env:JAVA_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "java_jdk"

# Set PATH and environment variables
$env:ANDROID_HOME = $env:ANDROID_SDK_ROOT
$env:JAVA_HOME = Join-Path $env:JAVA_DIR "Contents/Home"
$env:PATH = "$($env:JAVA_HOME)\bin;$($env:ANDROID_HOME)\platform-tools;$env:PATH"

# Determine OS platform - since we're on Windows, just set to win32
$env:OS_PLATFORM = "win32"

switch ($env:OS_PLATFORM) {
    "macos" { $env:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-mac-8512546_latest.zip" }
    "linux" { $env:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip" }
    "win32" { $env:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-8512546_latest.zip" }
}

function Fix-Permissions($path) {
    Write-Host "Fixing permissions for $path (not typically required on Windows)"
}
