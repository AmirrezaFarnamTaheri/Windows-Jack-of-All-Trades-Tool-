. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Active Process Connections"
Get-SystemSummary
Write-Section "Scanning Network Activity"

try {
    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' }

    if ($connections) {
        $connections | ForEach-Object {
            $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
            $name = if ($proc) { $proc.ProcessName } else { "Unknown" }

            Write-Host "$name " -NoNewline -ForegroundColor Cyan
            Write-Host "($($_.OwningProcess)) " -NoNewline -ForegroundColor Gray
            Write-Host "-> $($_.RemoteAddress):$($_.RemotePort)" -ForegroundColor White
        }
        Show-Success "Scan Complete."
    } else {
        Write-Log "No active TCP connections found." "Yellow"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
