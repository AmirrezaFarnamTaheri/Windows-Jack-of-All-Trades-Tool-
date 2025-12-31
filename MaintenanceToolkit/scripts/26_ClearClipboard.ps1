. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Clipboard"

try {
    Write-Log "Clearing Clipboard..."
    Set-Clipboard $null
    # Restart clipboard service if needed on Win10/11? Not standard.
    # Just verify
    if (-not (Get-Clipboard)) {
        Write-Log "Clipboard Cleared." "Green"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
