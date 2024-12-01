#! /bin/bash
set -e

source "Amour/bash/variables.sh"

rm -rf build/*

#======================================
# Creates the platform independent LOVE executable
#--------------------------------------

echo "Building love2d game archive"
(cd "${GAMEDATA_DIR}" && zip -9 -r "${BUILD_DIR}/${GAME_NAME}.love" ./)

# Sanity check
# love build/${GAME_NAME}.love


#======================================
# Creates the win32 executable
#--------------------------------------

# Checks if the win32 love.exe is present (downloads if not)
if [ -d "$LOVE_WIN32_DIR" ]; then
    echo "$LOVE_WIN32_DIR already exists"
else
    echo "Downloading and setting up love_win32 version $LOVE_VER at $LOVE_WIN32_DIR..."
    # Download the ZIP file
    curl -L "https://github.com/love2d/love/releases/download/$LOVE_VER/love-$LOVE_VER-win32.zip" --output $LOVE_WIN32_DIR.zip
    # Unzip to a temporary directory
    unzip $LOVE_WIN32_DIR.zip -d extern/temp_love_win32
    # Move contents of the extracted folder into the love_win32 directory
    mkdir -p $LOVE_WIN32_DIR
    mv extern/temp_love_win32/love-$LOVE_VER-win32/* $LOVE_WIN32_DIR
    # Clean up temporary files and folders
    rm -rf $LOVE_WIN32_DIR.zip extern/temp_love_win32
    echo "love_win32 version $LOVE_VER setup complete"
fi

echo "assembling Windows 32-bit executable"
cat "${LOVE_WIN32_DIR}/love.exe" "${BUILD_DIR}/${GAME_NAME}.love" > "${BUILD_DIR}/${GAME_NAME}-win32.exe"

# Copy love2d files
if [ -d "${BUILD_DIR}/${GAME_NAME}-win32" ]; then
    rm -rf "${BUILD_DIR}/${GAME_NAME}-win32"
fi
mkdir -p "${BUILD_DIR}/${GAME_NAME}-win32"
cp -rf "${LOVE_WIN32_DIR}/" "${BUILD_DIR}/${GAME_NAME}-win32"
mv "${BUILD_DIR}/${GAME_NAME}-win32.exe" "${BUILD_DIR}/${GAME_NAME}-win32/${GAME_NAME}.exe"


#======================================
# Creates the win64 executable
#--------------------------------------

# Checks if the win64 love.exe is present (downloads if not)
if [ -d "$LOVE_WIN64_DIR" ]; then
    echo "$LOVE_WIN64_DIR already exists"
else
    echo "Downloading and setting up love_win64 version $LOVE_VER at $LOVE_WIN64_DIR..."
    # Download the ZIP file
    curl -L "https://github.com/love2d/love/releases/download/$LOVE_VER/love-$LOVE_VER-win64.zip" --output $LOVE_WIN64_DIR.zip
    # Unzip to a temporary directory
    unzip $LOVE_WIN64_DIR.zip -d extern/temp_love_win64
    # Move contents of the extracted folder into the love_win64 directory
    mkdir -p $LOVE_WIN64_DIR
    mv extern/temp_love_win64/love-$LOVE_VER-win64/* $LOVE_WIN64_DIR
    # Clean up temporary files and folders
    rm -rf $LOVE_WIN64_DIR.zip extern/temp_love_win64
    echo "love_win64 version $LOVE_VER setup complete"
fi

echo "assembling Windows 64-bit executable"
cat "${LOVE_WIN64_DIR}/love.exe" "${BUILD_DIR}/${GAME_NAME}.love" > "${BUILD_DIR}/${GAME_NAME}-win64.exe"

# Copy love2d files
if [ -d "${BUILD_DIR}/${GAME_NAME}-win64" ]; then
    rm -rf "${BUILD_DIR}/${GAME_NAME}-win64"
fi
mkdir -p "${BUILD_DIR}/${GAME_NAME}-win64"
cp -rf "${LOVE_WIN64_DIR}/" "${BUILD_DIR}/${GAME_NAME}-win64"
mv "${BUILD_DIR}/${GAME_NAME}-win64.exe" "${BUILD_DIR}/${GAME_NAME}-win64/${GAME_NAME}.exe"


#======================================
# Creates the MacOS executable
#--------------------------------------

# Checks if the MacOS love.exe is present (downloads if not)
if [ -d "$LOVE_MACOS_DIR" ]; then
    echo "$LOVE_MACOS_DIR already exists"
else
    echo "Downloading and setting up love_macos version $LOVE_VER at $LOVE_MACOS_DIR..."
    # Download the ZIP file
    curl -L "https://github.com/love2d/love/releases/download/$LOVE_VER/love-$LOVE_VER-macos.zip" --output $LOVE_MACOS_DIR.zip
    # Unzip to a temporary directory
    unzip $LOVE_MACOS_DIR.zip -d $LOVE_MACOS_DIR
    # Clean up temporary files and folders
    rm -rf $LOVE_MACOS_DIR.zip
    echo "love_macos version $LOVE_VER setup complete"
fi

# Fuse love.app with game archive
echo "Fusing ${GAME_NAME} with love.app..."
cp -rf "${LOVE_MACOS_DIR}/love.app" "${BUILD_DIR}/${GAME_NAME}-macos.app"
cp -rf "${BUILD_DIR}/${GAME_NAME}.love" "${BUILD_DIR}/${GAME_NAME}-macos.app/Contents/Resources/"

# Update Info.plist
INFO_PLIST="${BUILD_DIR}/${GAME_NAME}-macos.app/Contents/Info.plist"
echo "Modifying Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.SuperCompany.${GAME_NAME}" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Set :CFBundleName ${GAME_NAME}" "${INFO_PLIST}"
/usr/libexec/PlistBuddy -c "Delete :UTExportedTypeDeclarations" "${INFO_PLIST}" || true  # Safely remove if exists


#======================================
# Compress platform executables
#--------------------------------------

# Zip the win32 executable
echo "Zipping the win32 executable..."
(cd "${BUILD_DIR}" && zip -9 -r "${GAME_NAME}_win32.zip" "${GAME_NAME}-win32" -y)

# Zip the win64 executable
echo "Zipping the win64 executable..."
(cd "${BUILD_DIR}" && zip -9 -r "${GAME_NAME}_win64.zip" "${GAME_NAME}-win64" -y)

# Zip the macOS app folder
echo "Zipping the macOS app folder..."
cd build
cp -rf "${GAME_NAME}-macos.app" "${GAME_NAME}.app"
zip -9 -r "${GAME_NAME}_macos.zip" "${GAME_NAME}.app" -y
rm -rf "${GAME_NAME}.app"
cd ..


#======================================
# Create Android APK & AAB
#--------------------------------------

#source "android-build.sh"


echo "Build complete!"