Write-Host "--- Starting Aggressive Temp File Cleanup ---" -ForegroundColor Cyan

$tempPath = $env:TEMP
$totalFreed = 0

$files = Get-ChildItem -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue

foreach ($file in $files) {
    try {
        $size = $file.Length
        Remove-Item -Path $file.FullName -Force -Recurse -ErrorAction Stop
        $totalFreed += $size
        Write-Host "Deleted: $($file.Name)" -ForegroundColor DarkGray
    }
    catch {
        # Skip in-use
    }
}

$mbFreed = [math]::round($totalFreed / 1MB, 2)
Write-Host "`n--- Cleanup Complete ---" -ForegroundColor Green
Write-Host "Total Space Reclaimed: $mbFreed MB" -ForegroundColor Yellow