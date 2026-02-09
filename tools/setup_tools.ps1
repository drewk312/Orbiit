Write-Host "Orbiit External Tools Setup" -ForegroundColor Cyan
Write-Host "==========================="

$toolsDir = Join-Path $PSScriptRoot "downloads"
if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

# 1. Wii Mod Lite
Write-Host "`n[1/3] Downloading Wii Mod Lite..."
$wmlUrl = "https://github.com/RiiConnect24/Wii-Mod-Lite/releases/download/v1.7/WiiModLite_v1.7.zip"
$wmlOut = Join-Path $toolsDir "WiiModLite.zip"
try {
    Invoke-WebRequest -Uri $wmlUrl -OutFile $wmlOut
    Write-Host "Success: Downloaded to $wmlOut" -ForegroundColor Green
} catch {
    Write-Host "Error downloading Wii Mod Lite: $_" -ForegroundColor Red
}

# 2. wad2bin (Source Code / Release)
# Note: wad2bin often requires manual setup or Python. We'll download the repo archive.
Write-Host "`n[2/3] Downloading wad2bin..."
$w2bUrl = "https://github.com/DarkMatterCore/wad2bin/archive/refs/tags/v0.7.zip"
$w2bOut = Join-Path $toolsDir "wad2bin.zip"
try {
    Invoke-WebRequest -Uri $w2bUrl -OutFile $w2bOut
    Write-Host "Success: Downloaded to $w2bOut" -ForegroundColor Green
} catch {
    Write-Host "Error downloading wad2bin: $_" -ForegroundColor Red
}

Write-Host "`n[3/3] xyzzy-mod"
Write-Host "NOTE: xyzzy-mod does not have a stable direct download link API." -ForegroundColor Yellow
Write-Host "Please download it manually from: https://wiidatabase.de/downloads/wii-tools/xyzzy/"

Write-Host "`nDone! Check the 'downloads' folder in this directory." -ForegroundColor Cyan
pause
