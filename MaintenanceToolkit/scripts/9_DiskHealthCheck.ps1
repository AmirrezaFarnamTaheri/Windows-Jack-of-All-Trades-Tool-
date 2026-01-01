. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Disk Health Check (S.M.A.R.T.)"

try {
    $disks = Get-PhysicalDisk | Sort-Object DeviceId
    foreach ($disk in $disks) {
        $status = $disk.HealthStatus
        $media = $disk.MediaType
        $bus = $disk.BusType
        $color = if ($status -eq "Healthy") { "Green" } else { "Red" }

        Write-Log "----------------------------------------" "White"
        Write-Log "Disk $($disk.DeviceId): $($disk.FriendlyName)" "Cyan"
        Write-Log "Type: $media ($bus)" "Gray"
        Write-Log "Health Status: $status" $color

        # Try to get wear indicators for SSDs
        if ($media -eq "SSD") {
             $counters = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
             if ($counters) {
                 $wear = $counters.Wear
                 if ($wear) { Write-Log "Wear Level: $wear%" "White" }
                 $temp = $counters.Temperature
                 if ($temp) { Write-Log "Temperature: $temp C" "White" }
             }
        }
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
