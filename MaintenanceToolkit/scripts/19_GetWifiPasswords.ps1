. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Retrieving Saved Wi-Fi Passwords"

try {
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

    foreach ($p in $profiles) {
        $info = netsh wlan show profile name="$p" key=clear
        $key = $info | Select-String "Key Content"
        if ($key) {
            $pass = $key.ToString().Split(":")[1].Trim()
            Write-Log "SSID: $p  |  Password: $pass" "Cyan"
        } else {
            Write-Log "SSID: $p  |  Password: (Open/No Key)" "Gray"
        }
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
