# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(200,200)
$form.Text = "Drag over Pixel"
$form.TopMost = $true

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