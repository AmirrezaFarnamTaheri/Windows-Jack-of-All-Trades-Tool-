. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Wireless Network Report"
Get-SystemSummary
Write-Section "Generating Report"

try {
    Write-Log "Running netsh wlan show wlanreport..." "Cyan"

    # This command saves report to C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html
    # It requires administrative privileges
    $p = Start-Process "netsh.exe" -ArgumentList "wlan show wlanreport" -Wait -NoNewWindow -PassThru

    if ($p.ExitCode -eq 0) {
        $reportPath = "$env:ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"
        $destPath = "$env:USERPROFILE\Desktop\WlanReport_$(Get-Date -Format 'yyyyMMdd_HHmm').html"

        if (Test-Path $reportPath) {
            Copy-Item -Path $reportPath -Destination $destPath -Force
            Show-Success "Report generated and copied to Desktop."
            Invoke-Item $destPath
        } else {
            Show-Error "Report generated but file not found at expected path."
        }
    } else {
        Show-Error "Netsh failed to generate report."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
