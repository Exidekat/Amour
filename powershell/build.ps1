Set-StrictMode -Version Latest
. .\variables.ps1

# Remove old build artifacts
if (Test-Path $env:BUILD_DIR) {
    Remove-Item "$env:BUILD_DIR\*" -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $env:BUILD_DIR -Force | Out-Null
}

Write-Host "Building love2d game archive"
Set-Location $env:GAMEDATA_DIR
# Compress entire gamedata directory into $GAME_NAME.love
Compress-Archive -Path * -DestinationPath "$env:BUILD_DIR\$($env:GAME_NAME).love" -CompressionLevel Optimal -Force
Set-Location $env:PROJECT_DIR

#======================================
# Creates the win32 executable
#--------------------------------------
if (Test-Path $env:LOVE_WIN32_DIR) {
    Write-Host "$env:LOVE_WIN32_DIR already exists"
} else {
    Write-Host "Downloading and setting up love_win32 version $env:LOVE_VER at $env:LOVE_WIN32_DIR..."
    Invoke-WebRequest -Uri "https://github.com/love2d/love/releases/download/$($env:LOVE_VER)/love-$($env:LOVE_VER)-win32.zip" -OutFile "$env:LOVE_WIN32_DIR.zip"
    Expand-Archive "$env:LOVE_WIN32_DIR.zip" -DestinationPath "$env:AMOUR_DIR\extern\temp_love_win32" -Force
    New-Item -ItemType Directory -Path $env:LOVE_WIN32_DIR -Force | Out-Null
    Move-Item "$env:AMOUR_DIR\extern\temp_love_win32\love-$($env:LOVE_VER)-win32\*" $env:LOVE_WIN32_DIR
    Remove-Item "$env:LOVE_WIN32_DIR.zip","$env:AMOUR_DIR\extern\temp_love_win32" -Recurse -Force
    Write-Host "love_win32 version $($env:LOVE_VER) setup complete"
}

Write-Host "Assembling Windows 32-bit executable"
# Binary concatenation
[Byte[]]$exeBytes = [System.IO.File]::ReadAllBytes((Join-Path $env:LOVE_WIN32_DIR "love.exe"))
[Byte[]]$loveBytes = [System.IO.File]::ReadAllBytes((Join-Path $env:BUILD_DIR "$($env:GAME_NAME).love"))
[Byte[]]$combined = $exeBytes + $loveBytes
[System.IO.File]::WriteAllBytes((Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32.exe"), $combined)

if (Test-Path (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32")) {
    Remove-Item (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32") -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32") -Force | Out-Null
Copy-Item "$env:LOVE_WIN32_DIR\*" (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32") -Recurse -Force
Move-Item (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32.exe") (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32\$($env:GAME_NAME).exe")

#======================================
# Creates the win64 executable
#--------------------------------------
if (Test-Path $env:LOVE_WIN64_DIR) {
    Write-Host "$env:LOVE_WIN64_DIR already exists"
} else {
    Write-Host "Downloading and setting up love_win64 version $env:LOVE_VER at $env:LOVE_WIN64_DIR..."
    Invoke-WebRequest -Uri "https://github.com/love2d/love/releases/download/$($env:LOVE_VER)/love-$($env:LOVE_VER)-win64.zip" -OutFile "$env:LOVE_WIN64_DIR.zip"
    Expand-Archive "$env:LOVE_WIN64_DIR.zip" -DestinationPath "$env:AMOUR_DIR\extern\temp_love_win64" -Force
    New-Item -ItemType Directory -Path $env:LOVE_WIN64_DIR -Force | Out-Null
    Move-Item "$env:AMOUR_DIR\extern\temp_love_win64\love-$($env:LOVE_VER)-win64\*" $env:LOVE_WIN64_DIR
    Remove-Item "$env:LOVE_WIN64_DIR.zip","$env:AMOUR_DIR\extern\temp_love_win64" -Recurse -Force
    Write-Host "love_win64 version $($env:LOVE_VER) setup complete"
}

Write-Host "Assembling Windows 64-bit executable"
[Byte[]]$exe64Bytes = [System.IO.File]::ReadAllBytes((Join-Path $env:LOVE_WIN64_DIR "love.exe"))
[Byte[]]$combined64 = $exe64Bytes + $loveBytes
[System.IO.File]::WriteAllBytes((Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64.exe"), $combined64)

if (Test-Path (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64")) {
    Remove-Item (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64") -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64") -Force | Out-Null
Copy-Item "$env:LOVE_WIN64_DIR\*" (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64") -Recurse -Force
Move-Item (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64.exe") (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64\$($env:GAME_NAME).exe")

#======================================
# Creates the MacOS executable (Mac-specific, may not run on Windows)
#--------------------------------------
if (Test-Path $env:LOVE_MACOS_DIR) {
    Write-Host "$env:LOVE_MACOS_DIR already exists"
} else {
    Write-Host "Downloading and setting up love_macos version $env:LOVE_VER at $env:LOVE_MACOS_DIR..."
    Invoke-WebRequest -Uri "https://github.com/love2d/love/releases/download/$($env:LOVE_VER)/love-$($env:LOVE_VER)-macos.zip" -OutFile "$env:LOVE_MACOS_DIR.zip"
    Expand-Archive "$env:LOVE_MACOS_DIR.zip" -DestinationPath $env:LOVE_MACOS_DIR -Force
    Remove-Item "$env:LOVE_MACOS_DIR.zip" -Force
    Write-Host "love_macos version $($env:LOVE_VER) setup complete"
}

Write-Host "Fusing $($env:GAME_NAME) with love.app..."
Copy-Item (Join-Path $env:LOVE_MACOS_DIR "love.app") (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-macos.app") -Recurse -Force
Copy-Item (Join-Path $env:BUILD_DIR "$($env:GAME_NAME).love") (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-macos.app/Contents/Resources/") -Force

# Modify Info.plist (Mac-specific)
$InfoPlist = Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-macos.app/Contents/Info.plist"
if (Test-Path $InfoPlist) {
    [xml]$plist = Get-Content $InfoPlist
    # Update CFBundleIdentifier and CFBundleName
    ($plist.plist.dict.children() | Where-Object {$_.Name -eq "CFBundleIdentifier"}).'#text' = "com.SuperCompany.$($env:GAME_NAME)"
    ($plist.plist.dict.children() | Where-Object {$_.Name -eq "CFBundleName"}).'#text' = "$($env:GAME_NAME)"

    # Remove UTExportedTypeDeclarations if it exists
    $utexp = $plist.plist.dict.children() | Where-Object {$_.Name -eq "UTExportedTypeDeclarations"}
    if ($utexp) {
        $utexp.ParentNode.RemoveChild($utexp) | Out-Null
    }

    $plist.Save($InfoPlist)
}

#======================================
# Compress platform executables
#--------------------------------------

Write-Host "Zipping the win32 executable..."
Set-Location $env:BUILD_DIR
Compress-Archive "$($env:GAME_NAME)-win32" "$($env:GAME_NAME)_win32.zip" -CompressionLevel Optimal -Force

Write-Host "Zipping the win64 executable..."
Compress-Archive "$($env:GAME_NAME)-win64" "$($env:GAME_NAME)_win64.zip" -CompressionLevel Optimal -Force

Write-Host "Zipping the macOS app folder..."
Copy-Item "$($env:GAME_NAME)-macos.app" "$($env:GAME_NAME).app" -Recurse -Force
Compress-Archive "$($env:GAME_NAME).app" "$($env:GAME_NAME)_macos.zip" -CompressionLevel Optimal -Force
Remove-Item "$($env:GAME_NAME).app" -Recurse -Force
Set-Location $env:PROJECT_DIR

#======================================
# Create Android APK & AAB
#--------------------------------------
Write-Host "Starting Android build..."
. .\powershell\android-build.ps1

Write-Host "Build complete!"
