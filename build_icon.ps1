# ═══════════════════════════════════════════════════════════════════════════
# Orbiit Icon Builder
# Automatically converts SVG icon to ICO and rebuilds the app
# ═══════════════════════════════════════════════════════════════════════════

Write-Host "🚀 Orbiit Icon Builder" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

# Step 1: Check for ImageMagick
Write-Host "[1/4] Checking for ImageMagick..." -ForegroundColor Yellow
$magickPath = Get-Command magick -ErrorAction SilentlyContinue

if (-not $magickPath) {
    Write-Host "   ⚠ ImageMagick not found. Installing via winget..." -ForegroundColor Red
    
    try {
        winget install --id ImageMagick.ImageMagick -e --silent --accept-source-agreements --accept-package-agreements
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        $magickPath = Get-Command magick -ErrorAction SilentlyContinue
        
        if (-not $magickPath) {
            Write-Host "   ❌ Failed to install ImageMagick. Please install manually:" -ForegroundColor Red
            Write-Host "      https://imagemagick.org/script/download.php" -ForegroundColor White
            exit 1
        }
        
        Write-Host "   ✓ ImageMagick installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Installation failed: $_" -ForegroundColor Red
        Write-Host "      Please install ImageMagick manually from:" -ForegroundColor White
        Write-Host "      https://imagemagick.org/script/download.php" -ForegroundColor White
        exit 1
    }
}
else {
    Write-Host "   ✓ ImageMagick found: $($magickPath.Source)" -ForegroundColor Green
}

Write-Host ""

# Step 2: Convert SVG to ICO
Write-Host "[2/4] Converting SVG to ICO..." -ForegroundColor Yellow

$svgPath = "assets\orbiit_icon.svg"
$icoPath = "windows\runner\resources\app_icon.ico"

if (-not (Test-Path $svgPath)) {
    Write-Host "   ❌ SVG file not found: $svgPath" -ForegroundColor Red
    exit 1
}

# Backup old icon
if (Test-Path $icoPath) {
    $backupPath = "windows\runner\resources\app_icon.ico.bak"
    Copy-Item $icoPath $backupPath -Force
    Write-Host "   📦 Backed up old icon to: $backupPath" -ForegroundColor Gray
}

try {
    # Convert with multiple icon sizes for Windows
    & magick $svgPath -background none `
        -define icon:auto-resize=256,128,96,64,48,32,16 `
        $icoPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Icon generated successfully!" -ForegroundColor Green
        Write-Host "     Sizes: 256x256, 128x128, 96x96, 64x64, 48x48, 32x32, 16x16" -ForegroundColor Gray
    }
    else {
        throw "ImageMagick conversion failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Host "   ❌ Conversion failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Clean and rebuild
Write-Host "[3/4] Cleaning build artifacts..." -ForegroundColor Yellow

try {
    flutter clean | Out-Null
    Write-Host "   ✓ Build cleaned" -ForegroundColor Green
}
catch {
    Write-Host "   ⚠ Clean failed (continuing anyway)" -ForegroundColor Yellow
}

Write-Host ""

# Step 4: Get dependencies
Write-Host "[4/4] Getting dependencies..." -ForegroundColor Yellow

try {
    flutter pub get | Out-Null
    Write-Host "   ✓ Dependencies updated" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Failed to get dependencies: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "✨ Icon build complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: flutter run -d windows --release" -ForegroundColor White
Write-Host "  2. Check the taskbar for your new Orbiit icon!" -ForegroundColor White
Write-Host ""
Write-Host "Note: You may need to close and reopen the app to see the new icon." -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
