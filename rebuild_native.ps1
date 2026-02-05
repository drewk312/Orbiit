# Quick Rebuild Script for Native Library
# Rebuilds the C++ library with enhanced HTTP headers

Write-Host "=== Rebuilding Native Library ===" -ForegroundColor Cyan
Write-Host ""

# Check which build system to use
$nativeBuildExists = Test-Path "native\build"
$forgeCoreBuildExists = Test-Path "forge_core\build"

if ($nativeBuildExists) {
    Write-Host "Using native build system..." -ForegroundColor Green
    Push-Location "native\build"
    
    Write-Host "Building with CMake..." -ForegroundColor Cyan
    cmake --build . --config Release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Build successful!" -ForegroundColor Green
        
        # Copy DLL to project root
        $dllPath = "bin\forge_core.dll"
        if (Test-Path $dllPath) {
            Copy-Item $dllPath -Destination "..\..\forge_core.dll" -Force
            Write-Host "✓ DLL copied to project root" -ForegroundColor Green
        }
    } else {
        Write-Host "✗ Build failed!" -ForegroundColor Red
    }
    
    Pop-Location
} elseif ($forgeCoreBuildExists) {
    Write-Host "Using forge_core build system..." -ForegroundColor Green
    Push-Location "forge_core\build"
    
    Write-Host "Building with CMake..." -ForegroundColor Cyan
    cmake --build . --config Release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Build successful!" -ForegroundColor Green
        
        # Copy DLL to project root
        $dllPath = "libforge_core.dll"
        if (Test-Path $dllPath) {
            Copy-Item $dllPath -Destination "..\..\forge_core.dll" -Force
            Write-Host "✓ DLL copied to project root" -ForegroundColor Green
        }
    } else {
        Write-Host "✗ Build failed!" -ForegroundColor Red
    }
    
    Pop-Location
} else {
    Write-Host "No build directory found. Running CMake first..." -ForegroundColor Yellow
    
    if (Test-Path "native\CMakeLists.txt") {
        Push-Location "native"
        New-Item -ItemType Directory -Path "build" -Force | Out-Null
        Push-Location "build"
        
        Write-Host "Configuring CMake..." -ForegroundColor Cyan
        cmake ..
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Building..." -ForegroundColor Cyan
            cmake --build . --config Release
            
            if ($LASTEXITCODE -eq 0) {
                $dllPath = "bin\forge_core.dll"
                if (Test-Path $dllPath) {
                    Copy-Item $dllPath -Destination "..\..\forge_core.dll" -Force
                    Write-Host "✓ Build complete and DLL copied!" -ForegroundColor Green
                }
            }
        }
        
        Pop-Location
        Pop-Location
    }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host "You can now run the Flutter app - downloads should work!" -ForegroundColor Green
