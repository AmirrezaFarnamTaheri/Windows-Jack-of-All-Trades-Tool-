. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Rebuilding Icon and Thumbnail Cache"
Write-Log "Warning: Windows Explorer will restart. Save open work." "Yellow"

try {
    # 1. Stop Explorer
    Write-Log "Stopping Windows Explorer..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    # Wait for it to actually die
    Start-Sleep -Seconds 2

    # 2. Delete Caches
    $paths = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*"
    )

    foreach ($p in $paths) {
        Write-Log "Clearing: $p"
        Remove-Item -Path $p -Force -ErrorAction SilentlyContinue
    }

    # 3. Legacy IconCache.db
    $legacy = "$env:LOCALAPPDATA\IconCache.db"
    if (Test-Path $legacy) {
        Remove-Item -Path $legacy -Force -ErrorAction SilentlyContinue
        Write-Log "Cleared legacy IconCache.db"
    }

    # 4. Restart Explorer
    Write-Log "Restarting Explorer..."
    Start-Process explorer.exe

    Write-Log "--- Success ---" "Green"

} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
    # Ensure explorer comes back
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer.exe
    }
}

Pause-If-Interactive
