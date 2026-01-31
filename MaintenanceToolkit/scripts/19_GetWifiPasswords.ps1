. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Wi-Fi Password Recovery"
Get-SystemSummary

try {
    Write-Section "Scanning Saved Profiles"

    # Robust parsing of netsh output
    $profiles = netsh wlan show profiles
    $names = $profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

    if ($names) {
        $wifiList = @()

        foreach ($n in $names) {
            $pass = "N/A"
            $auth = "Unknown"

            # Get details with clear key
            $info = netsh wlan show profile name="$n" key=clear

            # Parse Password
            $keyLine = $info | Select-String "Key Content"
            if ($keyLine) { $pass = $keyLine.ToString().Split(":")[1].Trim() }

            # Parse Auth Type
            $authLine = $info | Select-String "Authentication"
            if ($authLine) { $auth = $authLine.ToString().Split(":")[1].Trim() }

            $wifiList += [PSCustomObject]@{
                SSID = $n
                Authentication = $auth
                Password = $pass
            }

            # Console Security: Don't show password
            Write-Log "Found: $n ($auth)" "Cyan"
        }

        $report = New-Report "Wi-Fi Password Recovery"
        $report | Add-ReportSection "Saved Networks" $wifiList "Table"
        $report | Add-ReportSection "Security Warning" "This file contains clear-text passwords. Delete securely after use." "Text"

        $outFile = "$env:USERPROFILE\Desktop\WifiKeys_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Exported to Desktop."
        Invoke-Item $outFile
    } else {
        Show-Info "No Wi-Fi profiles found."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}

Pause-If-Interactive
