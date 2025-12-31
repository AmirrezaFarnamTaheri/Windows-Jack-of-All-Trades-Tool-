Write-Host "--- Optimizing TCP Receive Window ---" -ForegroundColor Cyan

$current = Get-NetTCPSetting | Select-Object SettingName, AutoTuningLevelLocal
Write-Host "Current Setting: $($current.AutoTuningLevelLocal)"

netsh int tcp set global autotuninglevel=normal

Write-Host "Network Stack Optimized." -ForegroundColor Green