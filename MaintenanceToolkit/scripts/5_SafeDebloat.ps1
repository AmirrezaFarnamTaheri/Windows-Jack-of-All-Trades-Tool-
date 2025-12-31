# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Safe Bloatware Removal ---" -ForegroundColor Cyan

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