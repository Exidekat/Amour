Set-StrictMode -Version Latest
. .\variables.ps1

Write-Host "Downloading and setting up Java JDK if not present..."
if (!(Test-Path $env:JAVA_DIR)) {
    New-Item -ItemType Directory -Path $env:JAVA_DIR -Force | Out-Null
    switch ($env:OS_PLATFORM) {
        "macos" {
            Invoke-WebRequest "https://download.oracle.com/java/17/archive/jdk-17.0.12_macos-x64_bin.tar.gz" -OutFile "java_jdk.tar.gz"
            tar -xzf java_jdk.tar.gz -C $env:JAVA_DIR --strip-components=1
            Remove-Item java_jdk.tar.gz -Force
        }
        "linux" {
            Invoke-WebRequest "https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz" -OutFile "java_jdk.tar.gz"
            tar -xzf java_jdk.tar.gz -C $env:JAVA_DIR --strip-components=1
            Remove-Item java_jdk.tar.gz -Force
        }
        "win32" {
            Invoke-WebRequest "https://download.oracle.com/java/17/archive/jdk-17.0.12_windows-x64_bin.zip" -OutFile "java_jdk.zip"
            Expand-Archive java_jdk.zip -DestinationPath $env:JAVA_DIR -Force
            Remove-Item java_jdk.zip -Force
        }
    }
    Write-Host "Java JDK setup complete."
} else {
    Write-Host "Java JDK already exists."
}

Write-Host "Downloading and setting up Android SDK if not present..."
if (!(Test-Path $env:ANDROID_SDK_ROOT)) {
    New-Item -ItemType Directory -Path $env:ANDROID_SDK_ROOT -Force | Out-Null
    $sdkZip = "$env:ANDROID_SDK_ROOT.zip"
    Invoke-WebRequest "https://dl.google.com/android/repository/platform-tools-latest-win32.zip" -OutFile $sdkZip # Assuming Windows
    Expand-Archive $sdkZip -DestinationPath (Join-Path $env:AMOUR_DIR "extern\temp_android_sdk") -Force
    Move-Item (Join-Path $env:AMOUR_DIR "extern\temp_android_sdk\platform-tools\*") $env:ANDROID_SDK_ROOT
    Remove-Item $sdkZip, (Join-Path $env:AMOUR_DIR "extern\temp_android_sdk") -Recurse -Force
    Write-Host "Android SDK setup complete."
} else {
    Write-Host "Android SDK already exists."
}

# Ensure cmdline-tools are present
$CMDLINE_TOOLS_DIR = Join-Path $env:ANDROID_SDK_ROOT "cmdline-tools\latest"
if (!(Test-Path $CMDLINE_TOOLS_DIR)) {
    Write-Host "Downloading cmdline-tools..."
    Invoke-WebRequest $env:CMDLINE_TOOLS_URL -OutFile "cmdline-tools.zip"
    Expand-Archive "cmdline-tools.zip" -DestinationPath (Join-Path $env:ANDROID_SDK_ROOT "cmdline-tools") -Force
    Move-Item (Join-Path $env:ANDROID_SDK_ROOT "cmdline-tools\cmdline-tools") $CMDLINE_TOOLS_DIR
    Remove-Item "cmdline-tools.zip" -Force
    Write-Host "cmdline-tools setup complete."
} else {
    Write-Host "cmdline-tools already exist."
}

Write-Host "Accepting licenses..."
# Simulate "yes" input by sending 'y' multiple times.
("y`r`n" * 100) | & "$CMDLINE_TOOLS_DIR\bin\sdkmanager" --licenses

Write-Host "Ensuring required Android NDK components..."
$NDK_COMPONENT = "ndk;$env:ANDROID_NDK_VER"
if (-not (& "$CMDLINE_TOOLS_DIR\bin\sdkmanager" $NDK_COMPONENT)) {
    Write-Host "Error installing $NDK_COMPONENT. Retrying..."
    & "$CMDLINE_TOOLS_DIR\bin\sdkmanager" --update
    & "$CMDLINE_TOOLS_DIR\bin\sdkmanager" $NDK_COMPONENT
}

Write-Host "Downloading and setting up love_android if not present..."
if (!(Test-Path $env:LOVE_ANDROID_DIR)) {
    git clone --recurse-submodules https://github.com/love2d/love-android $env:LOVE_ANDROID_DIR
    # On Windows, ensure gradlew is executable:
    # On Windows, executables aren't permission-based, but we can ignore this step.
    Write-Host "love_android setup complete."
} else {
    Write-Host "love_android already exists."
}

# Copy metadata and configuration for Android app
Remove-Item (Join-Path $env:LOVE_ANDROID_DIR "app\src\main\AndroidManifest.xml") -Force
Copy-Item (Join-Path $env:AMOUR_DIR "mobile_tools\AndroidManifest.xml") (Join-Path $env:LOVE_ANDROID_DIR "app\src\main\AndroidManifest.xml") -Force
Remove-Item (Join-Path $env:LOVE_ANDROID_DIR "gradle.properties") -Force
Copy-Item (Join-Path $env:AMOUR_DIR "mobile_tools\gradle.properties") (Join-Path $env:LOVE_ANDROID_DIR "gradle.properties") -Force

# Copy game data into Love Android app assets
New-Item -ItemType Directory -Force -Path (Join-Path $env:LOVE_ANDROID_DIR "app\src\embed\assets") | Out-Null
Copy-Item (Join-Path $env:GAMEDATA_DIR "*") (Join-Path $env:LOVE_ANDROID_DIR "app\src\embed\assets") -Recurse -Force

Write-Host "Starting clean APK build..."
Set-Location $env:LOVE_ANDROID_DIR
./gradlew assembleEmbedRecord
Move-Item "app/build/outputs/apk/embedRecord/debug/app-embed-record-debug.apk" (Join-Path $env:BUILD_DIR "$($env:GAME_NAME).apk")

Set-Location $env:BUILD_DIR
Write-Host "Starting clean AAB build..."
Set-Location $env:LOVE_ANDROID_DIR
./gradlew bundleEmbedRecord
Move-Item "app/build/outputs/bundle/embedRecordDebug/app-embed-record-debug.aab" (Join-Path $env:BUILD_DIR "$($env:GAME_NAME).aab")

Set-Location $env:PROJECT_DIR
Write-Host "Android build process complete."
