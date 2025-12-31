Write-Host "--- Fix 'Access Denied' Errors ---" -ForegroundColor Cyan
$path = Read-Host "Enter folder path to unlock"
$path = $path -replace '"', ''

if (Test-Path $path) {
    Write-Host "Taking Ownership..." -ForegroundColor Yellow
    takeown /f "$path" /r /d y

    Write-Host "Granting Permissions..." -ForegroundColor Yellow
    icacls "$path" /grant "$($env:USERNAME):(OI)(CI)F" /t

    Write-Host "Folder Unlocked." -ForegroundColor Green
}