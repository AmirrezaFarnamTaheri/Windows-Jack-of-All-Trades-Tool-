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
        # Simple parsing of netsh output
        $results = @()
        $currentSSID = ""

        foreach ($line in $networks) {
            $l = $line.Trim()
            if ($l.StartsWith("SSID")) {
                $currentSSID = $l -replace "SSID \d+ : ", ""
            } elseif ($l.StartsWith("Signal")) {
                $sig = $l -replace "Signal\s+: ", ""
                if ($currentSSID) {
                    Write-Log "Found: $currentSSID (Signal: $sig)" "Green"
                    $currentSSID = "" # Reset
                }
            }
        }

        Write-Section "Detailed Report"
        # Dump full output for detail
        $networks | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
    }
} catch {
    Show-Error "Error scanning Wi-Fi: $($_.Exception.Message)"
}
Pause-If-Interactive
