. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Wi-Fi Network Scanner"
Get-SystemSummary
Write-Section "Scanning"
Write-Log "Scanning for nearby Wi-Fi networks..." "Cyan"

try {
    # Check if WLAN service is running
    $svc = Get-Service "WlanSvc" -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Running') {
        Start-Service "WlanSvc" -ErrorAction SilentlyContinue
    }

    $networks = netsh wlan show networks mode=bssid
    if (-not $networks) {
        Show-Error "No Wi-Fi networks found or interface disabled."
    } else {
        $results = @()
        $currentSSID = "Hidden Network"
        $currentAP = $null

        foreach ($line in $networks) {
            $l = $line.Trim()

            if ($l -match "^SSID \d+ : (.*)") {
                # New SSID block starts.
                # If we were tracking an AP (BSSID), save it.
                if ($currentAP) { $results += [PSCustomObject]$currentAP; $currentAP = $null }

                $ssidName = $matches[1].Trim()
                if ([string]::IsNullOrWhiteSpace($ssidName)) { $ssidName = "Hidden Network" }
                $currentSSID = $ssidName
            }
            elseif ($l -match "^BSSID \d+ : (.*)") {
                # New BSSID (Access Point) starts under current SSID.
                if ($currentAP) { $results += [PSCustomObject]$currentAP }

                $bssid = $matches[1].Trim()
                $currentAP = [ordered]@{
                    SSID = $currentSSID
                    BSSID = $bssid
                    Signal = "0%"
                    Radio = "Unknown"
                    Channel = "Unknown"
                }
            }
            elseif ($l -match "^Signal\s+:\s+(.*)") {
                if ($currentAP) { $currentAP["Signal"] = $matches[1].Trim() }
            }
            elseif ($l -match "^Radio type\s+:\s+(.*)") {
                if ($currentAP) { $currentAP["Radio"] = $matches[1].Trim() }
            }
            elseif ($l -match "^Channel\s+:\s+(.*)") {
                if ($currentAP) { $currentAP["Channel"] = $matches[1].Trim() }
            }
        }

        # Save last one
        if ($currentAP) { $results += [PSCustomObject]$currentAP }

        if ($results.Count -gt 0) {
            # Convert Signal to Int for sorting
            $sorted = $results | Sort-Object @{ Expression = { [int]($_.Signal -replace '%','') } } -Descending

            $report = New-Report "Wi-Fi Network Scan"
            $report | Add-ReportSection "Nearby Access Points ($($results.Count))" $sorted "Table" @{ Label="SSID"; Value="Signal" }

            $outFile = "$env:USERPROFILE\Desktop\WifiScan_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
            $report | Export-Report-Html $outFile

            Show-Success "Scan finished. Found $($results.Count) access points."
            Invoke-Item $outFile
        } else {
            Show-Info "No networks found."
        }
    }
} catch {
    Show-Error "Error scanning Wi-Fi: $($_.Exception.Message)"
}
Pause-If-Interactive
