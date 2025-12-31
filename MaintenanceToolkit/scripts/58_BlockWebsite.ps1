. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Website Blocker (Hosts File)"
$site = Read-Host "Enter domain to block (e.g. facebook.com)"
$hostsPath = "$env:windir\System32\drivers\etc\hosts"

if (-not (Select-String -Path $hostsPath -Pattern $site)) {
    Add-Content -Path $hostsPath -Value "`n127.0.0.1       $site"
    Add-Content -Path $hostsPath -Value "127.0.0.1       www.$site"
    Write-Host "$site is now BLOCKED." -ForegroundColor Red
} else {
    Write-Host "$site is already blocked." -ForegroundColor Yellow
}