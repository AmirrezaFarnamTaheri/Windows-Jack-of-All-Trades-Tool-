# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Retrieving OEM BIOS Windows Key ---" -ForegroundColor Cyan

$key = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey

if ($key) {
    Write-Host "BIOS Product Key: $key" -ForegroundColor Green
} else {
    Write-Host "No OEM Key found in BIOS (Retail license used?)." -ForegroundColor Yellow
}