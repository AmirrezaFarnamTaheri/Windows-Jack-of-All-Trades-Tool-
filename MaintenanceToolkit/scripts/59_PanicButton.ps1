# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$obj = New-Object -ComObject WScript.Shell
$obj.SendKeys([char]173)

Set-Clipboard -Value $null

$shell = New-Object -ComObject Shell.Application
$shell.MinimizeAll()