. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Export System Event Logs"
Get-SystemSummary
Write-Section "Configuration"

$desktop = [Environment]::GetFolderPath("Desktop")
$dest = "$desktop\EventLogs_$(Get-Date -Format 'yyyyMMdd_HHmm')"

try {
    Write-Log "Creating export directory: $dest" "Cyan"
    New-Item -Path $dest -ItemType Directory -Force | Out-Null

    Write-Section "Exporting Logs"

    $logs = @("System", "Application", "Security")

    foreach ($log in $logs) {
        Write-Log "Exporting $log Log..." "White"
        try {
            $path = "$dest\$log.evtx"
            # wevtutil is reliable for exports
            Start-Process "wevtutil.exe" -ArgumentList "epl $log `"$path`"" -Wait -NoNewWindow
            Write-Log "Saved: $path" "Gray"
        } catch {
            Show-Error "Failed to export $log"
        }
    }

    # Export Critical/Error summary to text
    Write-Log "Generating Error Summary Text Report..." "White"
    $summaryFile = "$dest\ErrorSummary.txt"
    $events = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2} -MaxEvents 500 -ErrorAction SilentlyContinue
    if ($events) {
        $events | Select-Object TimeCreated, LogName, LevelDisplayName, ProviderName, Message | Format-List | Out-File $summaryFile -Encoding UTF8
    } else {
        "No recent critical errors found." | Out-File $summaryFile
    }

    Show-Success "Logs exported to Desktop."
    Invoke-Item $dest

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
