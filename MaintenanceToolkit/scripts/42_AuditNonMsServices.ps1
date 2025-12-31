# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Auditing Non-Microsoft Services ---" -ForegroundColor Cyan

$services = Get-WmiObject Win32_Service | Where-Object {
    $_.State -eq 'Running' -and
    $_.DisplayName -notmatch "Microsoft" -and
    $_.DisplayName -notmatch "Windows" -and
    $_.DisplayName -notmatch "Intel" -and
    $_.DisplayName -notmatch "AMD"
} | Select-Object DisplayName, Name, StartMode, PathName

if ($services) {
    $services | Format-Table -AutoSize
    Write-Host "Review the list above. If you don't recognize it, Google it." -ForegroundColor Yellow
} else {
    Write-Host "No obvious 3rd party services running." -ForegroundColor Green
}