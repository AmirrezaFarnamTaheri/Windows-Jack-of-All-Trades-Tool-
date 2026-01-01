. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Wi-Fi Password Recovery"
Get-SystemSummary
Write-Section "Scanning Saved Profiles"

try {
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

    if ($profiles) {
        $wifiList = @()
        foreach ($p in $profiles) {
            $pass = "N/A"
            $out = netsh wlan show profile name="$p" key=clear
            $line = $out | Select-String "Key Content"
            if ($line) {
                $pass = $line.ToString().Split(":")[1].Trim()
            }

            $wifiList += [PSCustomObject]@{
                SSID     = $p
                Password = $pass
            }
            if ($pass -ne "N/A") {
                Write-Log "Profile: $p | Key: [REDACTED]" "Cyan"
            } else {
                Write-Log "Profile: $p | Open/No Key" "Gray"
            }
        }

        $report = New-Report "Wi-Fi Password Recovery"
        $report | Add-ReportSection "Saved Networks" $wifiList "Table"
        $report | Add-ReportSection "Security Note" "This report contains sensitive cleartext passwords. Delete this file after use." "Text"

        $outFile = "$env:USERPROFILE\Desktop\WifiKeys_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Report saved to $outFile"
        Invoke-Item $outFile
    } else {
        Show-Error "No Wi-Fi profiles found."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
