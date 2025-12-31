. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Checking Drive Health (S.M.A.R.T. Status)"

$disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size

foreach ($disk in $disks) {
    Write-Host "`nDrive Name: " $disk.FriendlyName -ForegroundColor White
    Write-Host "Type:       " $disk.MediaType

    if ($disk.HealthStatus -eq "Healthy") {
        Write-Host "Status:      HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "Status:      WARNING ($($disk.HealthStatus))" -ForegroundColor Red
        Write-Host "ACTION:      Backup your data immediately!" -ForegroundColor Red
    }
}
Write-Host "`n--- Check Complete ---" -ForegroundColor Cyan