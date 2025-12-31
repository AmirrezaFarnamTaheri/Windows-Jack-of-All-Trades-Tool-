# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Retrieving BitLocker Recovery Keys ---" -ForegroundColor Cyan

$bitlocker = Get-BitLockerVolume -MountPoint "C:"
if ($bitlocker.ProtectionStatus -eq "On") {
    $key = $bitlocker.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
    Write-Host "Volume ID: $($bitlocker.MountPoint)"
    Write-Host "Recovery Key: $($key.RecoveryPassword)" -ForegroundColor Green
    Write-Host "SAVE THIS KEY IMMEDIATELY." -ForegroundColor Red
} else {
    Write-Host "BitLocker is NOT enabled on drive C:." -ForegroundColor Yellow
}