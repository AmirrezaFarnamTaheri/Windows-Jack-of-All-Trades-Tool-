Write-Host "--- Checking CPU Virtualization Support ---" -ForegroundColor Cyan

$v = Get-CimInstance Win32_Processor | Select-Object Name, VirtualizationFirmwareEnabled
Write-Host "CPU: $($v.Name)"
if ($v.VirtualizationFirmwareEnabled) {
    Write-Host "Virtualization (VT-x/AMD-V): ENABLED" -ForegroundColor Green
} else {
    Write-Host "Virtualization (VT-x/AMD-V): DISABLED (Check BIOS)" -ForegroundColor Red
}