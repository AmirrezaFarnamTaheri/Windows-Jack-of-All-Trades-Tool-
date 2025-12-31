Write-Host "--- Restoring Classic Right-Click Menu (Windows 11) ---" -ForegroundColor Cyan

reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

Write-Host "Success! Restarting Explorer to apply changes..." -ForegroundColor Green
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer
}

Write-Host "--- Menu Restored ---" -ForegroundColor Green