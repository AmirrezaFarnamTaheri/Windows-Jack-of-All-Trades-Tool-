. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Toggling System Dark Mode"

try {
    $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }

    $current = (Get-ItemProperty $key -ErrorAction SilentlyContinue).AppsUseLightTheme
    if ($null -eq $current) { $current = 1 } # Default to Light if not found

    $newValue = if ($current -eq 0) { 1 } else { 0 }
    $modeName = if ($newValue -eq 0) { "Dark" } else { "Light" }

    # System Theme (Taskbar, Start)
    Set-RegKey -Path $key -Name "SystemUsesLightTheme" -Value $newValue -Type DWord

    # App Theme (Explorer, Settings)
    Set-RegKey -Path $key -Name "AppsUseLightTheme" -Value $newValue -Type DWord

    Write-Log "Theme switched to $modeName Mode." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
