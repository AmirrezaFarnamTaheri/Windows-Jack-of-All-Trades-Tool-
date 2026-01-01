. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Nuclear Temporary File Cleanup"
Write-Log "Warning: This script aggressively cleans temporary files." "Yellow"

$folders = @(
    "$env:TEMP",
    "$env:WINDIR\Temp",
    "$env:LOCALAPPDATA\Temp"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Write-Log "Cleaning $folder..."
        Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction Stop
            } catch {
                # Ignore locked files
            }
        }
    }
}

# Clear Prefetch
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
    Write-Log "Failed to clear Windows Update cache: $($_.Exception.Message)" "Red"
}

Write-Log "Cleanup Complete." "Green"
Pause-If-Interactive
