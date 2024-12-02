#!/bin/bash
set -e

# Game Name
export GAME_NAME="Duoble"

# Orientation (for mobile)
export ORIENTATION="landscape"

# Love2D Version
LOVE_VER="11.5"

# Absolute path to the project directory
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# Absolute path to the Amour, gamedata, and build directories
AMOUR_DIR="${PROJECT_DIR}/Amour"
GAMEDATA_DIR="${PROJECT_DIR}/gamedata"
BUILD_DIR="${PROJECT_DIR}/build"

# Directories for Love2D versions
mkdir -p "${AMOUR_DIR}/extern"
LOVE_WIN32_DIR="${AMOUR_DIR}/extern/love_${LOVE_VER}_win32"
LOVE_WIN64_DIR="${AMOUR_DIR}/extern/love_${LOVE_VER}_win64"
LOVE_MACOS_DIR="${AMOUR_DIR}/extern/love_${LOVE_VER}_macos"
LOVE_ANDROID_DIR="${AMOUR_DIR}/extern/love_android"

# Directories for SDK and JDK
#ANDROID_SDK_ROOT="$PROJECT_DIR/extern/android_sdk"
ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"

JAVA_VERSION="17"
JAVA_DIR="${AMOUR_DIR}/extern/java_jdk"

# More Environment variables
export ANDROID_HOME="/Users/exide/Library/Android/sdk"
export ANDROID_NDK_HOME="/Users/exide/Library/Android/sdk/ndk/28.0.12674087"
export JAVA_HOME="$JAVA_DIR/Contents/Home"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

# URL for cmdline-tools
case "$(uname)" in
    Darwin)
        OS_PLATFORM="macos"
        CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-8512546_latest.zip"
        ;;
    Linux)
        OS_PLATFORM="linux"
        CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        OS_PLATFORM="win32"
        CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-win-8512546_latest.zip"
        ;;
    *)
        echo "Unsupported operating system: $(uname)"
        exit 1
        ;;
esac

# Permissions function
fix_permissions() {
    chmod -R 755 "$1"
    chown -R "$(whoami)" "$1" || echo "Warning: Unable to change ownership for $1. Skipping."
}
