. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Nuclear Temporary File Cleanup"
Get-SystemSummary
Write-Section "Warning"
Write-Log "This script aggressively cleans temporary files." "Yellow"
Write-Log "It is recommended to close other applications before running." "Cyan"

$folders = @(
    "$env:TEMP",
    "$env:WINDIR\Temp",
    "$env:LOCALAPPDATA\Temp"
)

Write-Section "Cleaning Temp Directories"

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Write-Log "Scanning $folder..."
        $files = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        if ($files) {
            $count = $files.Count
            Write-Log "Removing $count items..." "Gray"
            $files | ForEach-Object {
                try {
                    Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction Stop
                } catch {
                    # Ignore locked files
                }
            }
        }
    }
}

# Clear Prefetch
Write-Section "Cleaning System Caches"
Write-Log "Cleaning Prefetch..."
try {
    Get-ChildItem -Path "$env:WINDIR\Prefetch" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
} catch {}

# Clear Windows Update Cache (SoftwareDistribution)
try {
    Write-Log "Cleaning Windows Update Cache..."
    Stop-ServiceSafe "wuauserv"
    Stop-ServiceSafe "bits"

    $wdPath = "$env:WINDIR\SoftwareDistribution\Download"
    if (Test-Path $wdPath) {
        Get-ChildItem -Path $wdPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Log "Windows Update downloads cleared." "Green"
    }

    Start-Service "wuauserv" -ErrorAction SilentlyContinue
    Start-Service "bits" -ErrorAction SilentlyContinue
} catch {
    Show-Error "Failed to clear Windows Update cache: $($_.Exception.Message)"
}

Show-Success "Cleanup Complete."
Pause-If-Interactive
