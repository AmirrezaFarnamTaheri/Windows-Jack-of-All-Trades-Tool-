. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Battery Health Analysis"
Get-SystemSummary

try {
    # Check if this is a laptop (BatteryStatus)
    $hasBattery = (Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue)
    if (-not $hasBattery) {
        Write-Log "No battery detected. This script is intended for laptops/tablets." "Yellow"
    }

    Write-Section "Generating Report"
    $tempPath = "$env:TEMP\battery_report.html"
    $destPath = "$env:USERPROFILE\Desktop\BatteryReport_$(Get-Date -Format 'yyyyMMdd_HHmm').html"

    Write-Log "Invoking powercfg..." "Cyan"

    # powercfg generates an HTML file directly
    $p = Start-Process powercfg -ArgumentList "/batteryreport", "/output", "`"$tempPath`"" -Wait -PassThru -NoNewWindow

    if ($p.ExitCode -eq 0 -and (Test-Path $tempPath)) {
        # Optional: Inject our header/style if we wanted, but powercfg HTML is complex.
        # Instead, we just move it.

        Move-Item -Path $tempPath -Destination $destPath -Force
        Show-Success "Report saved to Desktop: $destPath"
        Invoke-Item $destPath
    } else {
        Show-Error "PowerCfg failed to generate report. Exit Code: $($p.ExitCode)"
        if ($p.ExitCode -eq 1) {
            Write-Log "Tip: Ensure you are running as Administrator." "Yellow"
        }
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}

Pause-If-Interactive
