. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fixing Stuck Printer Spooler"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Stopping Print Spooler..."
    Stop-ServiceSafe "Spooler" -ErrorAction SilentlyContinue

    Write-Log "Clearing Spooler Queue..."
    $spoolDir = "$env:WINDIR\System32\spool\PRINTERS"
    if (Test-Path $spoolDir) {
        Remove-Item "$spoolDir\*" -Force -Recurse -ErrorAction SilentlyContinue
        Write-Log "Deleted pending print jobs." "Gray"
    }

    Write-Log "Restarting Print Spooler..."
    Start-Service Spooler -ErrorAction SilentlyContinue

    Show-Success "Printer Spooler Reset."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
