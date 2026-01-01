. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Wireless Network Report"
Get-SystemSummary
Write-Section "Generating Report"

try {
    Write-Log "Running netsh wlan show wlanreport..." "Cyan"

    # This command saves report to C:\ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html
    Start-Process "netsh.exe" -ArgumentList "wlan show wlanreport" -Wait -NoNewWindow

    $reportPath = "$env:ProgramData\Microsoft\Windows\WlanReport\wlan-report-latest.html"

    if (Test-Path $reportPath) {
        Show-Success "Report generated."
        Start-Process $reportPath
    } else {
        Show-Error "Report generation failed."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
