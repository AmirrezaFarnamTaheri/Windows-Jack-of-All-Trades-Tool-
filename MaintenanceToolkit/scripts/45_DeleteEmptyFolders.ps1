. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Delete Empty Folders"
Get-SystemSummary
Write-Section "Configuration"

$path = Read-Host "Enter path to clean (default: $env:USERPROFILE)"
if ([string]::IsNullOrWhiteSpace($path)) { $path = $env:USERPROFILE }

try {
    Write-Section "Scanning"
    if (Test-Path $path) {
        Write-Log "Scanning $path for empty directories..." "Cyan"

        # Bottom-up approach needed to delete nested empty folders
        $folders = Get-ChildItem -Path $path -Recurse -Directory -ErrorAction SilentlyContinue |
                   Sort-Object FullName -Descending

        $count = 0
        foreach ($f in $folders) {
            try {
                if ((Get-ChildItem $f.FullName -Force | Measure-Object).Count -eq 0) {
                    Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
                    Write-Log "Deleted: $($f.FullName)" "Gray"
                    $count++
                }
            } catch {}
        }

        if ($count -gt 0) {
            Show-Success "Deleted $count empty folders."
        } else {
            Show-Success "No empty folders found."
        }
    } else {
        Show-Error "Path not found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
