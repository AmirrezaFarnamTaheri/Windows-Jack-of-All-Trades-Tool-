. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Disk Health Check (S.M.A.R.T.)"
Get-SystemSummary

try {
    Write-Section "Scanning Storage Devices"
    $disks = Get-PhysicalDisk | Sort-Object DeviceId
    Write-Log "Found $($disks.Count) physical disk(s)." "Cyan"

    $diskReport = @()

    foreach ($disk in $disks) {
        $status = $disk.HealthStatus

        # Color logic
        $statusHtml = if ($status -eq "Healthy") { "<span class='status-pass'>Healthy</span>" } else { "<span class='status-fail'>$status</span>" }

        # Detailed Metrics
        $wear = "N/A"
        $temp = "N/A"
        $readErrs = "N/A"

        # Try Get-StorageReliabilityCounter (Admin required, fails on some controllers)
        try {
            $counters = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction Stop
            if ($counters) {
                if ($counters.Wear) { $wear = "$($counters.Wear)%" }
                if ($counters.Temperature) { $temp = "$($counters.Temperature) °C" }
                if ($counters.ReadErrorsTotal) { $readErrs = $counters.ReadErrorsTotal }
            }
        } catch {
            Write-Diagnostic "SMART counters unavailable for disk $($disk.DeviceId)"
        }

        $model = if (-not [string]::IsNullOrWhiteSpace($disk.Model)) { $disk.Model } else { $disk.FriendlyName }

        $diskReport += [PSCustomObject]@{
            ID = $disk.DeviceId
            Model = $model
            Type = $disk.MediaType
            Bus = $disk.BusType
            Health = $statusHtml
            "SSD Wear" = $wear
            Temp = $temp
            "Read Errors" = $readErrs
            Size = Format-Size $disk.Size
        }

        # Console Feedback
        $color = if ($status -eq "Healthy") { "Green" } else { "Red" }
        Write-Log "[$($disk.MediaType)] $model ($($disk.BusType)) - $status" $color
    }

    $report = New-Report "Disk Health Report (S.M.A.R.T.)"
    $report | Add-ReportSection "Physical Disks" $diskReport "Table"

    $outHtml = "$env:USERPROFILE\Desktop\DiskHealth_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outHtml

    Show-Success "Detailed report saved to Desktop."
    Invoke-Item $outHtml

} catch {
    Show-Error "Scanning failed: $($_.Exception.Message)"
}

Pause-If-Interactive
