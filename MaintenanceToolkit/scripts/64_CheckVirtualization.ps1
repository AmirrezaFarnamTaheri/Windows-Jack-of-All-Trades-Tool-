# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Checking CPU Virtualization Support ---" -ForegroundColor Cyan

$v = Get-CimInstance Win32_Processor | Select-Object Name, VirtualizationFirmwareEnabled
Write-Host "CPU: $($v.Name)"
if ($v.VirtualizationFirmwareEnabled) {
    Write-Host "Virtualization (VT-x/AMD-V): ENABLED" -ForegroundColor Green
} else {
    Write-Host "Virtualization (VT-x/AMD-V): DISABLED (Check BIOS)" -ForegroundColor Red
}