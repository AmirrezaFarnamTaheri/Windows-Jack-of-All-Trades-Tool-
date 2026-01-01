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
        $currentSSID = "Unknown"

        # Parse netsh output
        # Format is:
        # SSID 1 : Name
        #     Network type : Infrastructure
        #     Authentication : WPA2-Personal
        #     Encryption : CCMP
        #     BSSID 1 : xx:xx:xx:xx:xx:xx
        #         Signal : 99%
        #         Radio type : 802.11ax
        #         Channel : 6

        # We need to handle multiple BSSIDs per SSID.
        # Let's simplify: List each BSSID as a row or just list SSIDs.
        # Listing BSSIDs is better for a scanner.

        $currentBSSID = @{}

        foreach ($line in $networks) {
            $l = $line.Trim()
            if ($l.StartsWith("SSID")) {
                $currentSSID = $l -replace "SSID \d+ : ", ""
            } elseif ($l.StartsWith("BSSID")) {
                # New access point for current SSID
                $currentBSSID = @{ SSID = $currentSSID; BSSID = ($l -replace "BSSID \d+ : ", "") }
            } elseif ($l.StartsWith("Signal")) {
                if ($currentBSSID.Keys.Count -gt 0) {
                    $currentBSSID["Signal"] = $l -replace "Signal\s+: ", ""
                }
            } elseif ($l.StartsWith("Radio type")) {
                if ($currentBSSID.Keys.Count -gt 0) {
                    $currentBSSID["Radio"] = $l -replace "Radio type\s+: ", ""
                }
            } elseif ($l.StartsWith("Channel")) {
                if ($currentBSSID.Keys.Count -gt 0) {
                    $currentBSSID["Channel"] = $l -replace "Channel\s+: ", ""
                    # End of BSSID block usually
                    $results += [PSCustomObject]$currentBSSID
                    $currentBSSID = @{}
                }
            }
        }

        if ($results.Count -gt 0) {
            $sorted = $results | Sort-Object Signal -Descending

            New-Report "Wi-Fi Network Scan"
            Add-ReportSection "Nearby Networks ($($results.Count))" $sorted "Table"

            $outFile = "$env:USERPROFILE\Desktop\WifiScan_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
            Export-Report-Html $outFile

            Show-Success "Scan finished. Found $($results.Count) access points."
            Invoke-Item $outFile
        } else {
            # Fallback if parsing failed or no BSSIDs
             Write-Host "Parsing failed or no details found. Raw Output:"
             $networks | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
        }
    }
} catch {
    Show-Error "Error scanning Wi-Fi: $($_.Exception.Message)"
}
Pause-If-Interactive
