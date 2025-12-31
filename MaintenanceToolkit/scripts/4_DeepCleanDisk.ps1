Write-Host "--- Starting Deep Disk Cleanup ---" -ForegroundColor Cyan

# This sets registry keys to select all cleanup options
Write-Host "Configuring cleanup settings..." -ForegroundColor Yellow
$cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
if (Test-Path $cleanmgrKey) {
    Get-ChildItem $cleanmgrKey | ForEach-Object {
        New-ItemProperty -Path $_.PSPath -Name StateFlags0001 -Value 2 -PropertyType DWord -Force | Out-Null
    }
}

# Run Disk Cleanup silently with these settings
Write-Host "Running Disk Cleanup Tool (This runs in background)..." -ForegroundColor Green
cleanmgr /sagerun:1

Write-Host "Cleanup initiated. It will close automatically when finished." -ForegroundColor Green