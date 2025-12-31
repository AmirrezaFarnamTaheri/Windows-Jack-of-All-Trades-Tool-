# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Scanning for Duplicate Files ---" -ForegroundColor Cyan
$target = Read-Host "Enter folder path to scan"

if (Test-Path $target) {
    Write-Host "Hashing files (this takes time)..." -ForegroundColor Yellow
    Get-ChildItem -Path $target -Recurse -File |
    Get-FileHash -Algorithm MD5 |
    Group-Object Hash |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object {
        Write-Host "`nDuplicate Found (Hash: $($_.Name))" -ForegroundColor Red
        $_.Group | Select-Object Path | Format-Table -HideTableHeaders
    }
}