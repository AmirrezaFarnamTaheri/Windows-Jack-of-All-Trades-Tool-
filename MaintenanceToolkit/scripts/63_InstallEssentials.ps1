. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Installing Essential Apps"
$apps = @("Google.Chrome", "VideoLAN.VLC", "7zip.7zip", "Notepad++.Notepad++", "Discord.Discord")

foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Yellow
    winget install --id $app -e --silent --accept-package-agreements --accept-source-agreements
}
Write-Host "All Essentials Installed." -ForegroundColor Green