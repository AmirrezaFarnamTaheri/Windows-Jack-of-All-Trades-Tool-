. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Aggressive Temp File Cleanup"

$tempPaths = @(
    $env:TEMP,
    "$env:SystemRoot\Temp"
)
$totalFreed = 0
$filesDeleted = 0

Write-Log "Targeting folders: $($tempPaths -join ', ')" "Yellow"

foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        Write-Log "Scanning: $path" "White"
        $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            try {
                if (-not $file.PSIsContainer) {
                    $size = $file.Length
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    $totalFreed += $size
                    $filesDeleted++
                    # Write-Host "Deleted: $($file.Name)" -ForegroundColor DarkGray # Reduce noise
                }
            }
            catch {
                # Skip in-use
            }
        }
    }
}

$mbFreed = [math]::round($totalFreed / 1MB, 2)
Write-Log "--- Cleanup Complete ---" "Green"
Write-Log "Files Deleted: $filesDeleted" "White"
Write-Log "Total Space Reclaimed: $mbFreed MB" "Yellow"

Pause-If-Interactive
