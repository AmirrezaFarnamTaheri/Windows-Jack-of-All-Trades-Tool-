. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Cleaning Empty Folders"
$target = Read-Host "Enter full path to scan (e.g. C:\Users\YourName\Documents) - WARNING: Be specific!"

if (Test-Path $target) {
    Write-Host "Scanning $target..." -ForegroundColor Yellow
    $folders = Get-ChildItem -Path $target -Recurse -Directory | Sort-Object FullName -Descending

    foreach ($folder in $folders) {
        if ((Get-ChildItem $folder.FullName -Recurse -Force).Count -eq 0) {
            Remove-Item $folder.FullName -Force
            Write-Host "Deleted Empty: $($folder.FullName)" -ForegroundColor DarkGray
        }
    }
    Write-Host "Done." -ForegroundColor Green
} else {
    Write-Host "Invalid path." -ForegroundColor Red
}