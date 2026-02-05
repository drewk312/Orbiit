# WiiGC-Fusion Complete Build Script
# Builds both native library and Flutter app

Write-Host "=== WiiGC-Fusion Build Script ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build native library
Write-Host "[1/3] Building native library..." -ForegroundColor Green
Push-Location forge_core

if (Test-Path "build") {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item "build" -Recurse -Force
}

New-Item -ItemType Directory -Path "build" -Force | Out-Null
Push-Location build

Write-Host "Running CMake..." -ForegroundColor Cyan
cmake .. 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "CMake configuration failed!" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

Write-Host "Building with CMake..." -ForegroundColor Cyan
cmake --build . --config Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Native library build failed!" -ForegroundColor Red
    Pop-Location
    Pop-Location
    exit 1
}

Pop-Location
Pop-Location

# Step 2: Copy DLL to project root
Write-Host "[2/3] Copying native library..." -ForegroundColor Green
Copy-Item "forge_core\build\libforge_core.dll" -Destination "forge_core.dll" -Force
Write-Host "✓ forge_core.dll ready" -ForegroundColor Green

# Step 3: Build Flutter app
Write-Host "[3/3] Building Flutter app..." -ForegroundColor Green
& "..\flutter-sdk\bin\flutter.bat" clean
& "..\flutter-sdk\bin\flutter.bat" build windows --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Build Complete ===" -ForegroundColor Green
    Write-Host "Run '.\deploy.ps1' to package for distribution" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "=== Build Failed ===" -ForegroundColor Red
    exit 1
}

# Step 4: Check for Inno Setup compiler
$iscc = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path "installer.iss") {
    Write-Host ""
    Write-Host "[Optional] Compile Installer..." -ForegroundColor Cyan
    
    if (Test-Path $iscc) {
        Write-Host "Inno Setup found! Compiling installer..." -ForegroundColor Green
        # Ensure deploy has run first? Users should run deploy.ps1 first usually.
        # Actually, let's just make a 'release.ps1' that does everything?
        # For now, just logging availability.
        Write-Host "Run 'ISCC installer.iss' to generate Setup.exe" -ForegroundColor Yellow
    } else {
        Write-Host "Inno Setup (ISCC.exe) not found at standard location." -ForegroundColor DarkGray
        Write-Host "Install Inno Setup to generate .exe installer: https://jrsoftware.org/isdl.php" -ForegroundColor DarkGray
    }
}
