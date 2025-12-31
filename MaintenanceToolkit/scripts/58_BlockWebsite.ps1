# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Website Blocker (Hosts File) ---" -ForegroundColor Cyan
$site = Read-Host "Enter domain to block (e.g. facebook.com)"
$hostsPath = "$env:windir\System32\drivers\etc\hosts"

if (-not (Select-String -Path $hostsPath -Pattern $site)) {
    Add-Content -Path $hostsPath -Value "`n127.0.0.1       $site"
    Add-Content -Path $hostsPath -Value "127.0.0.1       www.$site"
    Write-Host "$site is now BLOCKED." -ForegroundColor Red
} else {
    Write-Host "$site is already blocked." -ForegroundColor Yellow
}