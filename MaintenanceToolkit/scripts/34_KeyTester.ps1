. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Keyboard Input Tester"
Write-Log "Press any key to see its code. Press ESC to quit." "Yellow"

try {
    while ($true) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.VirtualKeyCode -eq 27) { break }
            Write-Log "Key: $($key.Character)  |  Code: $($key.VirtualKeyCode)" "Green"
        }
        Start-Sleep -Milliseconds 50
    }
} catch {
    Write-Log "Error reading input: $($_.Exception.Message)" "Red"
}
Write-Log "Exited." "Gray"
Pause-If-Interactive
