# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Scanning for Large Files (Top 20 in User Profile) ---" -ForegroundColor Cyan
Write-Host "This may take a minute..." -ForegroundColor DarkGray

Get-ChildItem -Path $env:USERPROFILE -Recurse -File -ErrorAction SilentlyContinue |
Sort-Object Length -Descending |
Select-Object -First 20 |
Select-Object Name, @{Name="Size(MB)";Expression={[math]::round($_.Length / 1MB, 2)}}, Directory |
Format-Table -AutoSize