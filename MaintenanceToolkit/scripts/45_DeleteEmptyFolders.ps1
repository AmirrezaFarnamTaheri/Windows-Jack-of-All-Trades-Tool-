# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Cleaning Empty Folders ---" -ForegroundColor Cyan
$target = Read-Host "Enter full path to scan (e.g. C:\Users\YourName\Documents) - WARNING: Be specific!"

if (Test-Path $target) {
    Write-Host "Scanning $target..." -ForegroundColor Yellow
    $folders = Get-ChildItem -Path $target -Recurse -Directory | Sort-Object FullName -Descending

    foreach ($folder in $folders) {
        if ((Get-ChildItem $folder.FullName -Recurse -Force).Count -eq 0) {
            Remove-Item $folder.FullName -Force
            Write-Host "Deleted Empty: $($folder.FullName)" -ForegroundColor DarkGray
        }
    }
    Write-Host "Done." -ForegroundColor Green
} else {
    Write-Host "Invalid path." -ForegroundColor Red
}