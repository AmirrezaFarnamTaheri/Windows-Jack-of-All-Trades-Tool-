. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Resetting Windows Update Components"

try {
    $services = "wuauserv", "cryptSvc", "bits", "msiserver"

    foreach ($svc in $services) {
        Stop-ServiceSafe $svc
    }

    Write-Log "Renaming SoftwareDistribution and Catroot2..."
    Rename-Item "$env:WINDIR\SoftwareDistribution" "SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
    Rename-Item "$env:WINDIR\System32\catroot2" "catroot2.old" -Force -ErrorAction SilentlyContinue

    foreach ($svc in $services) {
        Write-Log "Starting $svc..."
        Start-Service $svc -ErrorAction SilentlyContinue
    }

    Write-Log "Windows Update Components Reset." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
