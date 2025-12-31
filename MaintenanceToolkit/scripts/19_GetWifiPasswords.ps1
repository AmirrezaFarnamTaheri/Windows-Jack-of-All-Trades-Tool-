. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Extracting Saved Wi-Fi Passwords"

$profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }

foreach ($profile in $profiles) {
    $result = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content"
    if ($result) {
        $pass = $result.ToString().Split(":")[1].Trim()
        Write-Host "Network: $profile  |  Password: $pass" -ForegroundColor Green
    } else {
        Write-Host "Network: $profile  |  Password: (None/Open)" -ForegroundColor Yellow
    }
}