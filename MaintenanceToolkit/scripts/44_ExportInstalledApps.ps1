. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Exporting Installed Apps"

$out = "$env:USERPROFILE\Desktop\InstalledApps_$(Get-Date -Format 'yyyyMMdd').csv"

try {
    Write-Log "Gathering App List (Registry + Winget)..."
    # Basic Reg Method
    $apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    $apps += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

    $apps | Where-Object { $_.DisplayName } | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8

    Write-Log "List exported to: $out" "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
