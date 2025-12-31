. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Keyboard Input Tester"
Write-Host "Press any key to see its code. Press ESC to quit." -ForegroundColor Yellow

while ($true) {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 27) { break }
        Write-Host "Key: $($key.Character)  |  Code: $($key.VirtualKeyCode)" -ForegroundColor Green
    }
}