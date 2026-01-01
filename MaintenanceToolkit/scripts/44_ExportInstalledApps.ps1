. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Exporting Installed Apps"
Get-SystemSummary

$outHtml = "$env:USERPROFILE\Desktop\InstalledApps_$(Get-Date -Format 'yyyyMMdd_HHmm').html"

try {
    Write-Section "Gathering Data"
    Write-Log "Gathering App List (Registry)..." "Cyan"

    # Basic Reg Method
    $apps = @()
    $keys = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"

    foreach ($k in $keys) {
        $apps += Get-ItemProperty $k -ErrorAction SilentlyContinue | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    }

    # Filter and Sort
    $cleanApps = $apps | Where-Object { $_.DisplayName } | Sort-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

    $report = New-Report "Installed Applications Inventory"
    $report | Add-ReportSection "Installed Applications ($($cleanApps.Count))" $cleanApps "Table"

    $report | Export-Report-Html $outHtml
    Show-Success "List exported to: $outHtml"
    Invoke-Item $outHtml

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
