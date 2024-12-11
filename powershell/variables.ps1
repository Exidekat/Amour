# Set strict mode for safer scripting
Set-StrictMode -Version Latest

# Game Name
$env:GAME_NAME = "Duoble"

# Orientation (for mobile)
$env:ORIENTATION = "landscape"

# Love2D Version
$env:LOVE_VER = "11.5"

# Absolute path to the project directory
# Assuming this script is located in powershell folder inside the project
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$ProjectDir = (Join-Path (Join-Path $ScriptDir "..") "..") | Resolve-Path | Select-Object -ExpandProperty Path
$env:PROJECT_DIR = $ProjectDir

# Absolute paths
$env:AMOUR_DIR = Join-Path $env:PROJECT_DIR "Amour"
$env:GAMEDATA_DIR = Join-Path $env:PROJECT_DIR "gamedata"
$env:BUILD_DIR = Join-Path $env:PROJECT_DIR "build"

# Create extern directory if not exists
New-Item -ItemType Directory -Path (Join-Path $env:AMOUR_DIR "extern") -Force | Out-Null

$env:LOVE_WIN32_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_$($env:LOVE_VER)_win32"
$env:LOVE_WIN64_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_$($env:LOVE_VER)_win64"
$env:LOVE_MACOS_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_$($env:LOVE_VER)_macos"
$env:LOVE_ANDROID_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "love_android"

# Directories for SDK, NDK, and JDK
$env:ANDROID_SDK_ROOT = "$env:USERPROFILE/Library/Android/sdk"
$env:ANDROID_NDK_VER = "28.0.12674087"
$env:ANDROID_NDK_HOME = Join-Path $env:ANDROID_SDK_ROOT ("ndk/" + $env:ANDROID_NDK_VER)

$env:JAVA_VERSION = "17"
$env:JAVA_DIR = Join-Path (Join-Path $env:AMOUR_DIR "extern") "java_jdk"

# Set PATH and environment variables
$env:ANDROID_HOME = $env:ANDROID_SDK_ROOT
$env:JAVA_HOME = Join-Path $env:JAVA_DIR "Contents/Home"
$env:PATH = "$($env:JAVA_HOME)\bin;$($env:ANDROID_HOME)\platform-tools;$env:PATH"

# Determine OS platform
switch -Regex ([System.Environment]::OSVersion.VersionString) {
    { $_ -match "Windows" } { $OS_PLATFORM = "win32" }
    default { $OS_PLATFORM = "win32" } # Assuming Windows for PowerShell usage
}
$env:OS_PLATFORM = $OS_PLATFORM

# cmdline-tools URL
switch ($env:OS_PLATFORM) {
    "macos" {
        $env:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-mac-8512546_latest.zip"
    }
    "linux" {
        $env:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip"
    }
    "win32" {
        $env:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-8512546_latest.zip"
    }
}

function Fix-Permissions($path) {
    # Windows typically doesn't require chmod/chown as on Unix.
    # You can ensure directories exist and rely on default permissions.
    # If needed, you can adjust ACLs here.
    Write-Host "Fixing permissions for $path (not typically required on Windows)"
}
