. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
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