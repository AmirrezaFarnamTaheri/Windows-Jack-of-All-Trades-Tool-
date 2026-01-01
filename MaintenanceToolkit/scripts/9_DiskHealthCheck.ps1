. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Disk Health Check (S.M.A.R.T.)"
Get-SystemSummary

try {
    Write-Section "Scan Results"

    $disks = Get-PhysicalDisk | Sort-Object DeviceId
    $diskReport = @()

    foreach ($disk in $disks) {
        $status = $disk.HealthStatus
        $media = $disk.MediaType
        $bus = $disk.BusType

        # Color logic for HTML
        $statusHtml = $status
        if ($status -eq "Healthy") { $statusHtml = "<span class='status-pass'>Healthy</span>" }
        else { $statusHtml = "<span class='status-fail'>$status</span>" }

        $wear = "N/A"
        $temp = "N/A"

        # Try to get wear indicators for SSDs
        if ($media -eq "SSD") {
             $counters = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
             if ($counters) {
                 if ($counters.Wear) { $wear = "$($counters.Wear)%" }
                 if ($counters.Temperature) { $temp = "$($counters.Temperature) C" }
             }
        }

        $diskReport += [PSCustomObject]@{
            ID = $disk.DeviceId
            Name = $disk.FriendlyName
            Type = "$media ($bus)"
            Health = $statusHtml
            "SSD Wear" = $wear
            Temp = $temp
            Size = Format-Size $disk.Size
        }

        # Console output as well for immediate feedback
        Write-Log "Disk $($disk.DeviceId): $($disk.FriendlyName) - $status" "White"
    }

    New-Report "Disk Health Report (S.M.A.R.T.)"
    Add-ReportSection "Physical Disks" $diskReport "Table"

    $outHtml = "$env:USERPROFILE\Desktop\DiskHealth_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    Export-Report-Html $outHtml

    Show-Success "Full report exported to $outHtml"
    Invoke-Item $outHtml

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
