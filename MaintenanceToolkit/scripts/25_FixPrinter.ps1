. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fixing Stuck Printer Spooler"

try {
    Write-Log "Stopping Print Spooler..."
    Stop-Service Spooler -Force -ErrorAction SilentlyContinue

    Write-Log "Clearing Spooler files..."
    Remove-Item "$env:WINDIR\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue

    Write-Log "Restarting Print Spooler..."
    Start-Service Spooler -ErrorAction SilentlyContinue

    Write-Log "Printer Spooler Reset." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
