. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Applying Privacy Tweaks"

Write-Host "Disabling Advertising ID..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue

Write-Host "Disabling Tailored Experiences..." -ForegroundColor Yellow
if (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent")) {
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -Force

Write-Host "Restricting Cortana..." -ForegroundColor Yellow
if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Force

Write-Host "--- Privacy Settings Applied ---" -ForegroundColor Green