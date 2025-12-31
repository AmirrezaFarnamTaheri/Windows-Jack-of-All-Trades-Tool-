# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Extracting Saved Wi-Fi Passwords ---" -ForegroundColor Cyan

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