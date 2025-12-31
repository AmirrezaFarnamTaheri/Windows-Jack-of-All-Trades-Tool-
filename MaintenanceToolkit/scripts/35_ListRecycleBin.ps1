# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Scanning Recycle Bin ---" -ForegroundColor Cyan

$drives = Get-PSDrive -PSProvider FileSystem
foreach ($d in $drives) {
    $binPath = "$($d.Root)\`$Recycle.Bin"
    if (Test-Path $binPath) {
        Get-ChildItem -Path $binPath -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$I*" } |
        ForEach-Object {
            Write-Host "Found deleted item: $($_.Name) in $($d.Root)" -ForegroundColor White
        }
    }
}
Write-Host "Use a dedicated recovery tool (like Recuva) to restore these." -ForegroundColor Yellow