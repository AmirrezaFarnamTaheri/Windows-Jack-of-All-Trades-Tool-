# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$key = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$current = (Get-ItemProperty -Path $key).AppsUseLightTheme

if ($current -eq 1) {
    Set-ItemProperty -Path $key -Name "AppsUseLightTheme" -Value 0
    Set-ItemProperty -Path $key -Name "SystemUsesLightTheme" -Value 0
    Write-Host "Switched to DARK Mode" -ForegroundColor Cyan
} else {
    Set-ItemProperty -Path $key -Name "AppsUseLightTheme" -Value 1
    Set-ItemProperty -Path $key -Name "SystemUsesLightTheme" -Value 1
    Write-Host "Switched to LIGHT Mode" -ForegroundColor Yellow
}