. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Host "--- CPU Stress Test (Stability Check) ---" -ForegroundColor Red
Write-Host "Press CTRL+C to stop the test." -ForegroundColor Yellow
Write-Host "If your PC shuts down, you have an overheating problem." -ForegroundColor White

$start = Get-Date
$job = Start-Job -ScriptBlock {
    $result = 1; foreach ($i in 1..2147483647) { $result = $result * $i }
}

Write-Host "Load started on background thread. Monitor Task Manager." -ForegroundColor Green
while ($true) {
    $elapsed = New-TimeSpan -Start $start -End (Get-Date)
    Write-Host "Stress Testing: $($elapsed.ToString("mm\:ss")) - Press CTRL+C to Stop" -NoNewline -ForegroundColor Red
    Start-Sleep -Seconds 1
    [Console]::SetCursorPosition(0, [Console]::CursorTop)
}