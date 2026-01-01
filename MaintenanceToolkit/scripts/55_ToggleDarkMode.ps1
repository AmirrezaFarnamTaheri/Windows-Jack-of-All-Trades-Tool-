. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Toggle System Dark Mode"
Get-SystemSummary
Write-Section "Execution"

try {
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }

    $val = Get-ItemProperty -Path $reg -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
    $current = if ($null -ne $val -and $null -ne $val.AppsUseLightTheme) { [int]$val.AppsUseLightTheme } else { 1 }

    if ($current -eq 1) {
        Write-Log "Switching to Dark Mode..."
        Set-ItemProperty -Path $reg -Name "AppsUseLightTheme" -Value 0
        Set-ItemProperty -Path $reg -Name "SystemUsesLightTheme" -Value 0
        Show-Success "Dark Mode Enabled."
    } else {
        Write-Log "Switching to Light Mode..."
        Set-ItemProperty -Path $reg -Name "AppsUseLightTheme" -Value 1
        Set-ItemProperty -Path $reg -Name "SystemUsesLightTheme" -Value 1
        Show-Success "Light Mode Enabled."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
