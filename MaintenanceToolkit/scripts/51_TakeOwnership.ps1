. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fix 'Access Denied' Errors"
$path = Read-Host "Enter folder path to unlock"
$path = $path -replace '"', ''

if (Test-Path $path) {
    Write-Host "Taking Ownership..." -ForegroundColor Yellow
    takeown /f "$path" /r /d y

    Write-Host "Granting Permissions..." -ForegroundColor Yellow
    icacls "$path" /grant "$($env:USERNAME):(OI)(CI)F" /t

    Write-Host "Folder Unlocked." -ForegroundColor Green
}