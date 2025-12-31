# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Schedule Windows Memory Diagnostic ---" -ForegroundColor Cyan
Write-Host "This will restart your computer and run a deep RAM test." -ForegroundColor Red

$choice = Read-Host "Type 'Y' to Restart and Test now, or 'N' to cancel"

if ($choice -eq 'Y') {
    mdsched.exe
} else {
    Write-Host "Cancelled." -ForegroundColor Yellow
}