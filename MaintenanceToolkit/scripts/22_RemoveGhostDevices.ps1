Write-Host "--- Checking for Unused (Ghost) Devices ---" -ForegroundColor Cyan

Write-Host "Enabling 'Show Non-Present Devices' variable..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("DEVMGR_SHOW_NONPRESENT_DEVICES", "1", "User")

Write-Host "Opening Device Manager..." -ForegroundColor Green
Write-Host "ACTION: Go to 'View' -> 'Show hidden devices'. Grayed out icons are ghost devices." -ForegroundColor Magenta
devmgmt.msc