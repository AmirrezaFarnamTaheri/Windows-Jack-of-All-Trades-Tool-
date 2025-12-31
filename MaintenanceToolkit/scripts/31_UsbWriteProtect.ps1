# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- USB Security Control ---" -ForegroundColor Cyan
Write-Host "1. Enable Write Protection (Read-Only Mode)"
Write-Host "2. Disable Write Protection (Normal Mode)"
$choice = Read-Host "Select"

$path = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"

if ($choice -eq "1") {
    if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "WriteProtect" -Value 1
    Write-Host "USB Drives are now READ ONLY." -ForegroundColor Red
}
elseif ($choice -eq "2") {
    Set-ItemProperty -Path $path -Name "WriteProtect" -Value 0
    Write-Host "USB Drives are now Normal." -ForegroundColor Green
}
Write-Host "You may need to re-plug your USB drive."