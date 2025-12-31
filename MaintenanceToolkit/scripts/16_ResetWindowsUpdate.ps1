Write-Host "--- Resetting Windows Update Components ---" -ForegroundColor Cyan
Write-Host "This fixes stuck updates and download errors." -ForegroundColor Yellow

Write-Host "Stopping Services..." -ForegroundColor White
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service cryptSvc -Force -ErrorAction SilentlyContinue
Stop-Service bits -Force -ErrorAction SilentlyContinue
Stop-Service msiserver -Force -ErrorAction SilentlyContinue

Write-Host "Renaming SoftwareDistribution Folder..." -ForegroundColor White
Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue

Write-Host "Renaming Catroot2 Folder..." -ForegroundColor White
Rename-Item -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old" -ErrorAction SilentlyContinue

Write-Host "Restarting Services..." -ForegroundColor White
Start-Service wuauserv
Start-Service cryptSvc
Start-Service bits
Start-Service msiserver

Write-Host "--- Windows Update Reset Complete ---" -ForegroundColor Green