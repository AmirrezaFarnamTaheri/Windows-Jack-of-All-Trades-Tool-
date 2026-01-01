. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Dead Pixel Fixer"
Get-SystemSummary
Write-Section "Instructions"
Write-Log "This script will flash colors rapidly to try and unstuck pixels." "Cyan"
Write-Log "Press ESC to stop." "Yellow"
Write-Host "`nPress any key to START..." -ForegroundColor White
if (-not [Console]::IsInputRedirected) { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }

try {
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.WindowState = "Maximized"
    $form.FormBorderStyle = "None"
    $form.TopMost = $true
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100
    $colors = @([System.Drawing.Color]::Red, [System.Drawing.Color]::Green, [System.Drawing.Color]::Blue, [System.Drawing.Color]::White, [System.Drawing.Color]::Black)
    $rnd = New-Object Random

    $timer.Add_Tick({
        $form.BackColor = $colors[$rnd.Next($colors.Count)]
    })

    $form.Add_KeyDown({
        if ($_.KeyCode -eq "Escape") { $form.Close() }
    })

    $timer.Start()
    $form.ShowDialog() | Out-Null

    Show-Success "Pixel Fixer finished."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
