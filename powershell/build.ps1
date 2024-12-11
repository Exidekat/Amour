Set-StrictMode -Version Latest

# Import variables. We assume build.ps1 is in PROJECT/Amour/powershell
. (Join-Path $PSScriptRoot "variables.ps1")

# Remove old build artifacts
if (Test-Path $env:BUILD_DIR) {
    Remove-Item "$env:BUILD_DIR\*" -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $env:BUILD_DIR -Force | Out-Null
}

Write-Host "Building love2d game archive"
Push-Location $env:GAMEDATA_DIR

# Compress entire gamedata directory into a .zip, then rename to .love
$zipPath = Join-Path $env:BUILD_DIR "$($env:GAME_NAME).zip"
$lovePath = Join-Path $env:BUILD_DIR "$($env:GAME_NAME).love"

Compress-Archive -Path * -DestinationPath $zipPath -CompressionLevel Optimal -Force

Pop-Location

# Rename .zip to .love
Move-Item $zipPath $lovePath -Force

#======================================
# Creates the win32 executable
#--------------------------------------
if (Test-Path $env:LOVE_WIN32_DIR) {
    Write-Host "$env:LOVE_WIN32_DIR already exists"
} else {
    Write-Host "Downloading and setting up love_win32 version $env:LOVE_VER at $env:LOVE_WIN32_DIR..."
    $win32Zip = "$env:LOVE_WIN32_DIR.zip"
    Invoke-WebRequest -Uri "https://github.com/love2d/love/releases/download/$($env:LOVE_VER)/love-$($env:LOVE_VER)-win32.zip" -OutFile $win32Zip
    $tempWin32 = Join-Path $env:AMOUR_DIR "extern\temp_love_win32"
    Expand-Archive $win32Zip -DestinationPath $tempWin32 -Force
    New-Item -ItemType Directory -Path $env:LOVE_WIN32_DIR -Force | Out-Null
    Move-Item (Join-Path $tempWin32 "love-$($env:LOVE_VER)-win32\*") $env:LOVE_WIN32_DIR
    Remove-Item $win32Zip,$tempWin32 -Recurse -Force
    Write-Host "love_win32 version $($env:LOVE_VER) setup complete"
}

Write-Host "Assembling Windows 32-bit executable"
[Byte[]]$exeBytes = [System.IO.File]::ReadAllBytes((Join-Path $env:LOVE_WIN32_DIR "love.exe"))
[Byte[]]$loveBytes = [System.IO.File]::ReadAllBytes($lovePath)
[Byte[]]$combined = $exeBytes + $loveBytes
[System.IO.File]::WriteAllBytes((Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32.exe"), $combined)

$win32Output = Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32"
if (Test-Path $win32Output) {
    Remove-Item $win32Output -Recurse -Force
}
New-Item -ItemType Directory -Path $win32Output -Force | Out-Null
Copy-Item "$env:LOVE_WIN32_DIR\*" $win32Output -Recurse -Force
Move-Item (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win32.exe") (Join-Path $win32Output "$($env:GAME_NAME).exe")

#======================================
# Creates the win64 executable
#--------------------------------------
if (Test-Path $env:LOVE_WIN64_DIR) {
    Write-Host "$env:LOVE_WIN64_DIR already exists"
} else {
    Write-Host "Downloading and setting up love_win64 version $env:LOVE_VER at $env:LOVE_WIN64_DIR..."
    $win64Zip = "$env:LOVE_WIN64_DIR.zip"
    Invoke-WebRequest -Uri "https://github.com/love2d/love/releases/download/$($env:LOVE_VER)/love-$($env:LOVE_VER)-win64.zip" -OutFile $win64Zip
    $tempWin64 = Join-Path $env:AMOUR_DIR "extern\temp_love_win64"
    Expand-Archive $win64Zip -DestinationPath $tempWin64 -Force
    New-Item -ItemType Directory -Path $env:LOVE_WIN64_DIR -Force | Out-Null
    Move-Item (Join-Path $tempWin64 "love-$($env:LOVE_VER)-win64\*") $env:LOVE_WIN64_DIR
    Remove-Item $win64Zip,$tempWin64 -Recurse -Force
    Write-Host "love_win64 version $($env:LOVE_VER) setup complete"
}

Write-Host "Assembling Windows 64-bit executable"
[Byte[]]$exe64Bytes = [System.IO.File]::ReadAllBytes((Join-Path $env:LOVE_WIN64_DIR "love.exe"))
[Byte[]]$combined64 = $exe64Bytes + $loveBytes
[System.IO.File]::WriteAllBytes((Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64.exe"), $combined64)

$win64Output = Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64"
if (Test-Path $win64Output) {
    Remove-Item $win64Output -Recurse -Force
}
New-Item -ItemType Directory -Path $win64Output -Force | Out-Null
Copy-Item "$env:LOVE_WIN64_DIR\*" $win64Output -Recurse -Force
Move-Item (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-win64.exe") (Join-Path $win64Output "$($env:GAME_NAME).exe")

#======================================
# Creates the MacOS executable (Optional on Windows)
#--------------------------------------
if ($env:OS_PLATFORM -eq "macos") {
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
    Copy-Item $lovePath (Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-macos.app/Contents/Resources/") -Force

    # Modify Info.plist
    $InfoPlist = Join-Path $env:BUILD_DIR "$($env:GAME_NAME)-macos.app/Contents/Info.plist"
    if (Test-Path $InfoPlist) {
        [xml]$plist = Get-Content $InfoPlist
        ($plist.plist.dict.children() | Where-Object {$_.Name -eq "CFBundleIdentifier"}).'#text' = "com.SuperCompany.$($env:GAME_NAME)"
        ($plist.plist.dict.children() | Where-Object {$_.Name -eq "CFBundleName"}).'#text' = "$($env:GAME_NAME)"

        $utexp = $plist.plist.dict.children() | Where-Object {$_.Name -eq "UTExportedTypeDeclarations"}
        if ($utexp) {
            $utexp.ParentNode.RemoveChild($utexp) | Out-Null
        }

        $plist.Save($InfoPlist)
    }

    Write-Host "Zipping the macOS app folder..."
    Push-Location $env:BUILD_DIR
    Copy-Item "$($env:GAME_NAME)-macos.app" "$($env:GAME_NAME).app" -Recurse -Force
    Compress-Archive "$($env:GAME_NAME).app" "$($env:GAME_NAME)_macos.zip" -CompressionLevel Optimal -Force
    Remove-Item "$($env:GAME_NAME).app" -Recurse -Force
    Pop-Location
}

Write-Host "Zipping the win32 executable..."
Push-Location $env:BUILD_DIR
Compress-Archive "$($env:GAME_NAME)-win32" "$($env:GAME_NAME)_win32.zip" -CompressionLevel Optimal -Force

Write-Host "Zipping the win64 executable..."
Compress-Archive "$($env:GAME_NAME)-win64" "$($env:GAME_NAME)_win64.zip" -CompressionLevel Optimal -Force
Pop-Location

Write-Host "Starting Android build..."
. (Join-Path $PSScriptRoot "android-build.ps1")

Write-Host "Build complete!"
