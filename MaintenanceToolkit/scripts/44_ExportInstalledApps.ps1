. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Exporting Installed Apps"
Get-SystemSummary

$out = "$env:USERPROFILE\Desktop\InstalledApps_$(Get-Date -Format 'yyyyMMdd').csv"

try {
    Write-Section "Gathering Data"
    Write-Log "Gathering App List..." "Cyan"

    $apps = @()

    # Try PackageManagement first (Better)
    if (Get-Module -ListAvailable PackageManagement) {
        Write-Log "Using PackageManagement..." "Gray"
        $pkgs = Get-Package -ErrorAction SilentlyContinue
        if ($pkgs) {
            $apps = $pkgs | Select-Object Name, Version, ProviderName, Source
        }
    }

    # Fallback to Registry if empty
    if ($apps.Count -eq 0) {
        Write-Log "Using Registry Fallback..." "Gray"
        $regApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object @{N='Name';E={$_.DisplayName}}, @{N='Version';E={$_.DisplayVersion}}, @{N='ProviderName';E={$_.Publisher}}, @{N='Source';E={'Registry'}}
        $regApps += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object @{N='Name';E={$_.DisplayName}}, @{N='Version';E={$_.DisplayVersion}}, @{N='ProviderName';E={$_.Publisher}}, @{N='Source';E={'Registry'}}
        $apps = $regApps | Where-Object { $_.Name }
    }

    Write-Section "Exporting"
    if ($apps.Count -gt 0) {
        $apps | Sort-Object Name | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
        Show-Success "Exported $($apps.Count) apps to: $out"
        Invoke-Item $out
    } else {
        Show-Warning "No installed applications found to export."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
