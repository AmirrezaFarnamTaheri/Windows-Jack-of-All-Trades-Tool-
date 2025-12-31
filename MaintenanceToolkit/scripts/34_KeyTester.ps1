. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Keyboard Input Tester"
Write-Log "Press any key to see its code. Press ESC to quit." "Yellow"

while ($true) {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 27) { break }
        Write-Host "Key: $($key.Character)  |  Code: $($key.VirtualKeyCode)" -ForegroundColor Green
    }
    Start-Sleep -Milliseconds 50
}
Write-Log "Exited." "Gray"
Pause-If-Interactive
