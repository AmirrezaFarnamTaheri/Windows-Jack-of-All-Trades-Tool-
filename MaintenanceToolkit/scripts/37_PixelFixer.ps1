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