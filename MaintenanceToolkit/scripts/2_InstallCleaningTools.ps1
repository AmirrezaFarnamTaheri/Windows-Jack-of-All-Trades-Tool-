# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Installing Advanced Cleaning Tools via Winget ---" -ForegroundColor Cyan

# Check if Winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget not found. Attempting to install App Installer..." -ForegroundColor Yellow
    # This is tricky to script reliably without interaction, but we warn the user.
    Write-Host "Please install 'App Installer' from the Microsoft Store." -ForegroundColor Red
    return
}

# 1. Malwarebytes
Write-Host "Installing Malwarebytes..." -ForegroundColor Yellow
winget install --id Malwarebytes.Malwarebytes -e --silent --accept-package-agreements --accept-source-agreements

# 2. BleachBit
Write-Host "Installing BleachBit..." -ForegroundColor Yellow
winget install --id BleachBit.BleachBit -e --silent --accept-package-agreements --accept-source-agreements

Write-Host "--- Installation Complete ---" -ForegroundColor Green
Write-Host "ACTION REQUIRED: Please open 'Malwarebytes' manually and run a scan now." -ForegroundColor Magenta