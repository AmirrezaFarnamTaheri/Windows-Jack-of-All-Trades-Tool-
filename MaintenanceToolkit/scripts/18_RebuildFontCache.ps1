. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Rebuilding Font Cache"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Stopping Font Cache Service..."
    Stop-ServiceSafe "FontCache" -ErrorAction SilentlyContinue

    Write-Log "Deleting Font Cache files..."
    Get-ChildItem "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Include "*.dat" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\System32\FNTCACHE.DAT" -Force -ErrorAction SilentlyContinue

    Write-Log "Starting Font Cache Service..."
    Start-Service "FontCache" -ErrorAction SilentlyContinue

    Show-Success "Font Cache Rebuilt. A restart is recommended."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
