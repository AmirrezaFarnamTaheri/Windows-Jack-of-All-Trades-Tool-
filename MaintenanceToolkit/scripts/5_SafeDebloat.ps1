. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Safe Bloatware Removal"

$BloatwareList = @(
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

foreach ($App in $BloatwareList) {
    $Package = Get-AppxPackage -Name $App
    if ($Package) {
        Write-Host "Removing $App..." -ForegroundColor Yellow
        Get-AppxPackage -Name $App | Remove-AppxPackage
        Write-Host "$App Removed." -ForegroundColor Green
    } else {
        Write-Host "$App not found (already clean)." -ForegroundColor DarkGray
    }
}

Write-Host "--- Debloat Complete ---" -ForegroundColor Green