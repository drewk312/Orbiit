# Orbiit Deployment Script
# Copies all necessary files for distribution

param(
    [string]$BuildDir = "build\windows\x64\runner\Release",
    [string]$OutputDir = "dist\Orbiit"
)

Write-Host "=== Orbiit Deployment ===" -ForegroundColor Cyan

# Check if build directory exists
if (!(Test-Path $BuildDir)) {
    Write-Host "Error: Build directory not found: $BuildDir" -ForegroundColor Red
    Write-Host "Please run 'flutter build windows --release' first" -ForegroundColor Yellow
    exit 1
}

# Create output directory
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "Copying Flutter app..." -ForegroundColor Green
if (Test-Path "$BuildDir\wiigc_fusion.exe") {
    Copy-Item "$BuildDir\wiigc_fusion.exe" -Destination "$OutputDir\Orbiit.exe"
} else {
    Write-Warning "wiigc_fusion.exe not found! Checking for Orbiit.exe..."
    if (Test-Path "$BuildDir\Orbiit.exe") {
       Copy-Item "$BuildDir\Orbiit.exe" -Destination "$OutputDir\Orbiit.exe"
    } else {
       Write-Error "No executable found in build dir."
       exit 1
    }
}
Copy-Item "$BuildDir\*.dll" -Destination $OutputDir

# Copy data folder if it exists
if (Test-Path "$BuildDir\data") {
    Write-Host "Copying data folder..." -ForegroundColor Green
    Copy-Item "$BuildDir\data" -Destination $OutputDir -Recurse
}

# Copy native library
Write-Host "Copying native library..." -ForegroundColor Green
if (Test-Path "forge_core.dll") {
    Copy-Item "forge_core.dll" -Destination $OutputDir
} elseif (Test-Path "forge_core\build\libforge_core.dll") {
    Copy-Item "forge_core\build\libforge_core.dll" -Destination "$OutputDir\forge_core.dll"
} else {
    Write-Host "Warning: forge_core.dll not found!" -ForegroundColor Yellow
}

# Copy documentation
Write-Host "Copying documentation..." -ForegroundColor Green
Copy-Item "README.md" -Destination $OutputDir -ErrorAction SilentlyContinue
Copy-Item "LICENSE" -Destination $OutputDir -ErrorAction SilentlyContinue

# Create shortcuts/info file
$version = "1.0.0"
$info = @"
Orbiit v$version
Professional GameCube & Wii Library Manager

Quick Start:
1. Run wiigc_fusion.exe
2. Click 'Add Folder' to scan your game library
3. Enjoy automatic cover art and metadata!

For more information, see README.md
"@

$info | Out-File -FilePath "$OutputDir\INFO.txt" -Encoding UTF8

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Output: $OutputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files included:" -ForegroundColor Yellow
Get-ChildItem $OutputDir -Recurse | Select-Object FullName, Length | Format-Table -AutoSize

Write-Host ""
Write-Host "To distribute, zip the '$OutputDir' folder" -ForegroundColor Cyan
