. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Activating God Mode"

$desktop = [Environment]::GetFolderPath("Desktop")
$godModePath = "$desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"

if (-not (Test-Path $godModePath)) {
    New-Item -Path $godModePath -ItemType Directory -Force | Out-Null
    Write-Host "God Mode icon created on your Desktop." -ForegroundColor Green
} else {
    Write-Host "God Mode already exists." -ForegroundColor Yellow
}