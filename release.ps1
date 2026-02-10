# release.ps1 - Orbiit Release Builder

Write-Host "Starting Orbiit Release Build..." -ForegroundColor Cyan

# 1. Clean and Build
Write-Host "Cleaning project..." -ForegroundColor Yellow
flutter clean
Write-Host "⚙️ Generating code..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs
Write-Host "🔨 Building Windows Release..." -ForegroundColor Yellow
flutter build windows --release

# Check if build succeeded
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

# 2. Prepare Release Folder
$buildDir = "build\windows\x64\runner\release"
$releaseDir = "release"
$zipName = "Orbiit_v1.0.1_Windows.zip"

if (Test-Path $releaseDir) {
    Remove-Item $releaseDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

# 3. Copy Native DLLs
$forgeCoreSrc = "native\build\bin\libforge_core.dll"
$forgeCoreDest = "$buildDir\forge_core.dll"

if (Test-Path $forgeCoreSrc) {
    Write-Host "Copying forge_core.dll..." -ForegroundColor Green
    Copy-Item $forgeCoreSrc $forgeCoreDest -Force
} else {
    Write-Warning "forge_core.dll not found. Ensure C++ project is built."
}

# 3.5 Rename Executable (Output is likely wiigc_fusion.exe based on pubspec)
$originalExe = "wiigc_fusion.exe"
$targetExe = "Orbiit.exe"

if (Test-Path "$buildDir\$originalExe") {
    Write-Host "Renaming $originalExe to $targetExe..." -ForegroundColor Green
    Rename-Item -Path "$buildDir\$originalExe" -NewName $targetExe -Force
} elseif (Test-Path "$buildDir\$targetExe") {
    Write-Host "Executable already named $targetExe." -ForegroundColor Green
} else {
    Write-Warning "Executable not found! Expected $originalExe or $targetExe in $buildDir"
}

# 4. Create ZIP
Write-Host "Zipping release..." -ForegroundColor Yellow
Compress-Archive -Path "$buildDir\*" -DestinationPath "$releaseDir\$zipName" -Force

Write-Host "Release Ready: $releaseDir\$zipName" -ForegroundColor Green
Write-Host "---------------------------------------------------"
Write-Host "To install:"
Write-Host "1. Extract ZIP"
Write-Host "2. Run Orbiit.exe"
