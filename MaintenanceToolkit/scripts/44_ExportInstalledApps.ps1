. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Exporting Installed Apps"
Get-SystemSummary

$out = "$env:USERPROFILE\Desktop\InstalledApps_$(Get-Date -Format 'yyyyMMdd').csv"

try {
    Write-Section "Gathering Data"
    Write-Log "Gathering App List (Registry + Winget)..." "Cyan"

    # Basic Reg Method
    $apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    $apps += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

    Write-Section "Exporting"
    $apps | Where-Object { $_.DisplayName } | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8

    Show-Success "List exported to: $out"
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
