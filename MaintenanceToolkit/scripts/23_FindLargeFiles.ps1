Write-Host "--- Scanning for Large Files (Top 20 in User Profile) ---" -ForegroundColor Cyan
Write-Host "This may take a minute..." -ForegroundColor DarkGray

Get-ChildItem -Path $env:USERPROFILE -Recurse -File -ErrorAction SilentlyContinue |
Sort-Object Length -Descending |
Select-Object -First 20 |
Select-Object Name, @{Name="Size(MB)";Expression={[math]::round($_.Length / 1MB, 2)}}, Directory |
Format-Table -AutoSize