. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Restarting Audio Services"

try {
    $services = "Audiosrv", "AudioEndpointBuilder"
    foreach ($svc in $services) {
        Write-Log "Restarting $svc..."
        Restart-Service $svc -Force -ErrorAction SilentlyContinue
    }
    Write-Log "Audio Services Restarted." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
