# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$file = Read-Host "Drag and drop the file here to verify"
$file = $file -replace '"', ''

if (Test-Path $file) {
    Write-Host "Calculating SHA256 Hash..." -ForegroundColor Yellow
    $hash = Get-FileHash -Path $file -Algorithm SHA256
    Write-Host "Hash: $($hash.Hash)" -ForegroundColor Green
    Set-Clipboard -Value $hash.Hash
    Write-Host "(Hash copied to clipboard)" -ForegroundColor DarkGray
} else {
    Write-Host "File not found." -ForegroundColor Red
}