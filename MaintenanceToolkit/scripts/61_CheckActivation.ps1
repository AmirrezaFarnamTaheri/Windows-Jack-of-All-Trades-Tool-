# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Checking Windows Activation Status ---" -ForegroundColor Cyan
cscript //nologo $env:SystemRoot\System32\slmgr.vbs /xpr
cscript //nologo $env:SystemRoot\System32\slmgr.vbs /dli