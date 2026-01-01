. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Restarting Audio Services"
Get-SystemSummary
Write-Section "Execution"

try {
    $services = "Audiosrv", "AudioEndpointBuilder"
    foreach ($svc in $services) {
        Write-Log "Restarting $svc..."
        Restart-Service $svc -Force -ErrorAction SilentlyContinue
    }
    Show-Success "Audio Services Restarted."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
