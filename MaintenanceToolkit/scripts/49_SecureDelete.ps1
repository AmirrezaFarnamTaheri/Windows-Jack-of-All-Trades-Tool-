# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$path = Read-Host "Enter full path of file to securely wipe"
$path = $path -replace '"', ''

if (Test-Path $path) {
    Write-Host "Wiping file (3 passes)..." -ForegroundColor Yellow
    $file = Get-Item $path
    $size = $file.Length

    1..3 | ForEach-Object {
        [IO.File]::WriteAllBytes($path, [byte[]](Get-Random -InputObject (0..255) -Count $size))
    }

    Remove-Item $path -Force
    Write-Host "File obliterated." -ForegroundColor Green
} else {
    Write-Host "File not found." -ForegroundColor Red
}