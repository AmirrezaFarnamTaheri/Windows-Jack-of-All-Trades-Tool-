. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Toggling System Dark Mode"

try {
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $current = (Get-ItemProperty $key).AppsUseLightTheme

    $newValue = if ($current -eq 0) { 1 } else { 0 }

    Set-ItemProperty -Path $key -Name "AppsUseLightTheme" -Value $newValue
    Set-ItemProperty -Path $key -Name "SystemUsesLightTheme" -Value $newValue

    Write-Log "Theme Toggled." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
