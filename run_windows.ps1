f# Run Orbiit on Windows (no Flutter in PATH needed)
$flutter = "C:\dev\flutter-sdk\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    Write-Host "Flutter not found at $flutter - edit run_windows.ps1 and set `$flutter to your flutter.bat path" -ForegroundColor Red
    exit 1
}
Set-Location $PSScriptRoot
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $flutter run -d windows
