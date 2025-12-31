Write-Host "--- Keyboard Input Tester ---" -ForegroundColor Cyan
Write-Host "Press any key to see its code. Press ESC to quit." -ForegroundColor Yellow

while ($true) {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 27) { break }
        Write-Host "Key: $($key.Character)  |  Code: $($key.VirtualKeyCode)" -ForegroundColor Green
    }
}