. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Pending Update Flags"
Remove-Item -Path "C:\Windows\WinSxS\pending.xml" -Force -ErrorAction SilentlyContinue

$wusettings = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
Set-ItemProperty -Path $wusettings -Name "AUOptions" -Value 2 -ErrorAction SilentlyContinue

Write-Host "Pending flags cleared. Please restart." -ForegroundColor Green