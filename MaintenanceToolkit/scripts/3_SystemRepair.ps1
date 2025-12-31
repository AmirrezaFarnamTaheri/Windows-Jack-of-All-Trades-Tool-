# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Starting Windows System Repair ---" -ForegroundColor Cyan
Write-Host "This process may take 15-30 minutes. Do not close this window." -ForegroundColor Yellow

# 1. Check Image Health
Write-Host "Step 1: Checking System Image Health (DISM)..." -ForegroundColor White
$dism = DISM /Online /Cleanup-Image /ScanHealth
if ($LASTEXITCODE -eq 0) {
    Write-Host "Image Check Passed." -ForegroundColor Green
} else {
    Write-Host "Image Corruption Found. Attempting Repair..." -ForegroundColor Red
    DISM /Online /Cleanup-Image /RestoreHealth
}

# 2. System File Checker
Write-Host "Step 2: Scanning System Files (SFC)..." -ForegroundColor White
sfc /scannow

Write-Host "--- System Repair Complete ---" -ForegroundColor Green
Write-Host "If SFC said 'found corrupt files and successfully repaired them', restart your PC." -ForegroundColor Magenta