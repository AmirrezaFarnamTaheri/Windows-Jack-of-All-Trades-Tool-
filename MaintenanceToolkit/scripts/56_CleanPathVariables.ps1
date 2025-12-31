# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Cleaning System PATH ---" -ForegroundColor Cyan

$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
$entries = $path -split ";"
$newPath = @()

foreach ($entry in $entries) {
    if (Test-Path $entry) {
        $newPath += $entry
    } else {
        Write-Host "Removing Dead Path: $entry" -ForegroundColor Red
    }
}

$final = $newPath -join ";"
[Environment]::SetEnvironmentVariable("Path", $final, "Machine")
Write-Host "PATH Cleaned." -ForegroundColor Green