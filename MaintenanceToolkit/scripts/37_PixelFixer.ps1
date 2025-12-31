. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Dead Pixel Fixer"
Write-Log "Opening Pixel Flasher window..."
Write-Log "Drag the flashing window over stuck pixels." "Cyan"
Write-Log "Close the window to stop." "Yellow"

try {
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Size = New-Object System.Drawing.Size(200,200)
    $form.Text = "Drag over Pixel"
    $form.TopMost = $true
    $form.StartPosition = "CenterScreen"

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100
    $colors = @('Red', 'Green', 'Blue', 'White', 'Black')
    $i = 0

    $timer.Add_Tick({
        $form.BackColor = $colors[$script:i % $colors.Count]
        $script:i++
    })

    $timer.Start()
    $form.ShowDialog()

    Write-Log "Pixel Fixer Closed." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
