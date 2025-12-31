. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "PANIC BUTTON"

try {
    Write-Log "Muting Audio..."
    (New-Object -ComObject WScript.Shell).SendKeys([char]173)

    Write-Log "Clearing Clipboard..."
    Set-Clipboard $null

    Write-Log "Minimizing All Windows..."
    (New-Object -ComObject Shell.Application).MinimizeAll()

    Write-Log "Panic Actions Executed." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
