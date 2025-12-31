. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Disk Health Check (S.M.A.R.T.)"

try {
    $disks = Get-PhysicalDisk | Sort-Object DeviceId
    foreach ($disk in $disks) {
        $status = $disk.HealthStatus
        $color = if ($status -eq "Healthy") { "Green" } else { "Red" }
        Write-Log "Disk $($disk.DeviceId): $($disk.FriendlyName) - Status: $status" $color

        # Try to get reliability counters
        # $counters = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
        # if ($counters) { ... }
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
