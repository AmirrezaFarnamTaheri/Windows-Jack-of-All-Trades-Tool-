# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Checking Drive Health (S.M.A.R.T. Status) ---" -ForegroundColor Cyan

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