. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning for Duplicate Files"
$target = Read-Host "Enter folder path to scan"

try {
    if (Test-Path $target) {
        Write-Log "Hashing files (this takes time)..." "Yellow"

        $dupes = Get-ChildItem -Path $target -Recurse -File -ErrorAction SilentlyContinue |
                 Get-FileHash -Algorithm MD5 -ErrorAction SilentlyContinue |
                 Group-Object Hash |
                 Where-Object { $_.Count -gt 1 }

        if ($dupes) {
            foreach ($g in $dupes) {
                Write-Host "`nDuplicate Group (MD5: $($g.Name))" -ForegroundColor Cyan
                foreach ($f in $g.Group) {
                    Write-Host " - $($f.Path)" -ForegroundColor White
                }
            }
        } else {
            Write-Log "No duplicates found." "Green"
        }
    } else {
        Write-Log "Path not found." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
