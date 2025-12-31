Write-Host "--- Clearing Pending Update Flags ---" -ForegroundColor Cyan
Remove-Item -Path "C:\Windows\WinSxS\pending.xml" -Force -ErrorAction SilentlyContinue

$wusettings = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
Set-ItemProperty -Path $wusettings -Name "AUOptions" -Value 2 -ErrorAction SilentlyContinue

Write-Host "Pending flags cleared. Please restart." -ForegroundColor Green