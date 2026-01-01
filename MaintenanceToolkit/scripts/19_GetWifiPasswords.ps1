. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Retrieving Saved Wi-Fi Passwords"
Get-SystemSummary
Write-Section "Saved Networks"

try {
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

    if ($profiles) {
        foreach ($p in $profiles) {
            $info = netsh wlan show profile name="$p" key=clear
            $keyLine = $info | Select-String "Key Content"

            if ($keyLine) {
                # Compliance: Do not print cleartext passwords to console/logs
                # $pass = $keyLine.ToString().Split(":")[1].Trim()
                Write-Log "SSID: $p" "Cyan"
                Write-Log "Pass: *** (Hidden for Security)" "Green"
                Write-Host "----------------------------------------" -ForegroundColor DarkGray
            } else {
                Write-Log "SSID: $p" "Gray"
                Write-Log "Pass: (Open/No Key)" "DarkGray"
                Write-Host "----------------------------------------" -ForegroundColor DarkGray
            }
        }
        Show-Success "Scan complete."
    } else {
        Write-Log "No Wi-Fi profiles found." "Yellow"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
