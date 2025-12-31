. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Deleting Empty Folders"
$target = Read-Host "Enter folder path to scan (default is user root)"
if ([string]::IsNullOrWhiteSpace($target)) { $target = $env:USERPROFILE }

try {
    if (Test-Path $target) {
        Write-Log "Scanning $target for empty folders..."

        # Sort by length descending to delete nested empty folders correctly
        $dirs = Get-ChildItem -Path $target -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                Sort-Object -Property FullName -Descending

        $count = 0
        foreach ($dir in $dirs) {
            try {
                if ((Get-ChildItem -Path $dir.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
                    Remove-Item -Path $dir.FullName -Force -ErrorAction SilentlyContinue
                    Write-Log "Deleted: $($dir.FullName)" "Gray"
                    $count++
                }
            } catch {}
        }
        Write-Log "Deleted $count empty folders." "Green"
    } else {
        Write-Log "Path not found." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
