. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Retrieving BitLocker Recovery Keys"

$bitlocker = Get-BitLockerVolume -MountPoint "C:"
if ($bitlocker.ProtectionStatus -eq "On") {
    $key = $bitlocker.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
    Write-Host "Volume ID: $($bitlocker.MountPoint)"
    Write-Host "Recovery Key: $($key.RecoveryPassword)" -ForegroundColor Green
    Write-Host "SAVE THIS KEY IMMEDIATELY." -ForegroundColor Red
} else {
    Write-Host "BitLocker is NOT enabled on drive C:." -ForegroundColor Yellow
}