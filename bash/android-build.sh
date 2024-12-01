#!/bin/bash
set -e

# Source shared variables
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/variables.sh"

# Download and set up Java JDK if not already present
if [ ! -d "$JAVA_DIR" ]; then
    echo "Downloading and setting up Java JDK..."
    mkdir -p "$JAVA_DIR"  # Ensure the target directory exists

    case "$OS_PLATFORM" in
        macos)
            curl -L "https://download.oracle.com/java/17/archive/jdk-17.0.12_macos-x64_bin.tar.gz" --output java_jdk.tar.gz
            tar -xzf java_jdk.tar.gz --strip-components=1 -C "$JAVA_DIR"
            rm -f java_jdk.tar.gz
            ;;
        linux)
            curl -L "https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz" --output java_jdk.tar.gz
            tar -xzf java_jdk.tar.gz --strip-components=1 -C "$JAVA_DIR"
            rm -f java_jdk.tar.gz
            ;;
        win32)
            curl -L "https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.zip" --output java_jdk.zip
            unzip -q java_jdk.zip -d "$JAVA_DIR"
            rm -f java_jdk.zip
            ;;
    esac
    mv $JAVA_DIR/jdk-17.0.12.jdk/* $JAVA_DIR
    rm -rf $JAVA_DIR/jdk-17.0.12.jdk
    echo "Java JDK setup complete."
else
    echo "Java JDK already exists."
fi

# Download and set up Android SDK if not already present
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    echo "Downloading and setting up Android SDK..."
    curl -L "https://dl.google.com/android/repository/platform-tools-latest-$(uname | tr '[:upper:]' '[:lower:]').zip" --output "$ANDROID_SDK_ROOT.zip"
    unzip -q "$ANDROID_SDK_ROOT.zip" -d "$PROJECT_DIR/extern/temp_android_sdk"
    mkdir -p "$ANDROID_SDK_ROOT"
    mv "$PROJECT_DIR/extern/temp_android_sdk/platform-tools/"* "$ANDROID_SDK_ROOT"
    rm -rf "$ANDROID_SDK_ROOT.zip" "$PROJECT_DIR/extern/temp_android_sdk"
    echo "Android SDK setup complete."
else
    echo "Android SDK already exists."
fi

# Ensure cmdline-tools are present
CMDLINE_TOOLS_DIR="$ANDROID_SDK_ROOT/cmdline-tools/latest"
if [ ! -d "$CMDLINE_TOOLS_DIR" ]; then
    echo "Downloading cmdline-tools..."
    curl -L "$CMDLINE_TOOLS_URL" --output cmdline-tools.zip
    unzip -q cmdline-tools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools"
    mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$CMDLINE_TOOLS_DIR"
    rm -f cmdline-tools.zip
    echo "cmdline-tools setup complete."
else
    echo "cmdline-tools already exist."
fi

# Accept licenses
if ! yes | "$CMDLINE_TOOLS_DIR/bin/sdkmanager" --licenses; then
    echo "Failed to accept licenses for Android SDK components."
    exit 1
fi

# Download and set up love_android if not already present
if [ ! -d "$LOVE_ANDROID_DIR" ]; then
    echo "Downloading and setting up love_android..."
    git clone --recurse-submodules https://github.com/love2d/love-android "$LOVE_ANDROID_DIR"
    chmod +x "$LOVE_ANDROID_DIR/gradlew"
    echo "love_android setup complete."
else
    echo "love_android already exists."
fi

# Move in metadata and configuration for Android app
rm -rf "${LOVE_ANDROID_DIR}/app/src/main/AndroidManifest.xml"
cp -rf "${AMOUR_DIR}/mobile_tools/AndroidManifest.xml" "${LOVE_ANDROID_DIR}/app/src/main/AndroidManifest.xml"
rm -rf "${LOVE_ANDROID_DIR}/gradle.properties"
cp -rf "${AMOUR_DIR}/mobile_tools/gradle.properties" "${LOVE_ANDROID_DIR}/gradle.properties"

# Copy game data into Love Android app assets
mkdir -p "${LOVE_ANDROID_DIR}/app/src/assets"
rm -rf "${LOVE_ANDROID_DIR}/app/src/assets/*"
cp -rf "${BUILD_DIR}/${GAME_NAME}.love" "${LOVE_ANDROID_DIR}/app/src/assets/game.love"

# Perform clean build
echo "Starting clean APK build..."
cd "$LOVE_ANDROID_DIR"
./gradlew assembleNormal
#./gradlew assembleEmbedNoRecordRelease
mv "${LOVE_ANDROID_DIR}/app/build/outputs/apk/normalNoRecord/debug/app-normal-noRecord-debug.apk" "${PROJECT_DIR}/build/${GAME_NAME}.apk"
cd "$PROJECT_DIR/build"


echo "Starting clean AAB build..."
cd "$LOVE_ANDROID_DIR"
#./gradlew clean bundleEmbedNoRecordRelease
#mv "${LOVE_ANDROID_DIR}/app/build/outputs/bundle/embedNoRecordRelease/app-embed-noRecord-release.aab" "${PROJECT_DIR}/build/${GAME_NAME}.aab"

cd $PROJECT_DIR

echo "Android build process complete."
