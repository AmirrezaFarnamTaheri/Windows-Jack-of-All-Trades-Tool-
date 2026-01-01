. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Find Duplicate Files"
Get-SystemSummary
Write-Section "Configuration"

$path = Read-Host "Enter path to scan (default: $env:USERPROFILE\Documents)"
if ([string]::IsNullOrWhiteSpace($path)) { $path = "$env:USERPROFILE\Documents" }

try {
    if (Test-Path $path) {
        Write-Section "Scanning"
        Write-Log "Hashing files in $path (This is slow)..." "Cyan"

        $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1MB }
        $hashes = $files | Get-FileHash -Algorithm MD5

        $dupes = $hashes | Group-Object Hash | Where-Object { $_.Count -gt 1 }

        if ($dupes) {
            Write-Section "Duplicate Groups Found"
            foreach ($g in $dupes) {
                Write-Log "Hash: $($g.Name)" "Yellow"
                foreach ($f in $g.Group) {
                    Write-Log "  $($f.Path)" "White"
                }
            }
            Show-Success "Found $($dupes.Count) groups of duplicates."
        } else {
            Show-Success "No duplicates found (checked files > 1MB)."
        }
    } else {
        Show-Error "Path not found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
