. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning Recycle Bin"

$drives = Get-PSDrive -PSProvider FileSystem
foreach ($d in $drives) {
    $binPath = "$($d.Root)\`$Recycle.Bin"
    if (Test-Path $binPath) {
        Get-ChildItem -Path $binPath -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$I*" } |
        ForEach-Object {
            Write-Host "Found deleted item: $($_.Name) in $($d.Root)" -ForegroundColor White
        }
    }
}
Write-Host "Use a dedicated recovery tool (like Recuva) to restore these." -ForegroundColor Yellow