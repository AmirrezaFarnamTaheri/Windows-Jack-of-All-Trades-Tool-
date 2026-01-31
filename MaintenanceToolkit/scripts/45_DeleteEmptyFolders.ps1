. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Delete Empty Folders"
Get-SystemSummary

# Destructive Warning (Files are safe, but folder structure changes)
Assert-Destructive "This script recursively deletes empty directories."

Write-Section "Configuration"

if (-not [Console]::IsInputRedirected) {
    $path = Read-Host "Enter path to clean (default: $env:USERPROFILE)"
}
if ([string]::IsNullOrWhiteSpace($path)) { $path = $env:USERPROFILE }

try {
    Write-Section "Scanning"
    if (Test-Path $path) {
        Write-Log "Scanning $path for empty directories..." "Cyan"
        Write-Log "This may take a while for deep structures." "White"

        # Bottom-up approach needed to delete nested empty folders
        $folders = Get-ChildItem -Path $path -Recurse -Directory -ErrorAction SilentlyContinue |
                   Sort-Object FullName -Descending

        $count = 0
        $deleted = @()

        foreach ($f in $folders) {
            try {
                # Check for files (including hidden)
                $hasItems = (Get-ChildItem $f.FullName -Force -ErrorAction SilentlyContinue | Select-Object -First 1)

                if (-not $hasItems) {
                    Remove-Item $f.FullName -Force -ErrorAction Stop
                    Write-Log "Deleted: $($f.FullName)" "Gray"
                    $deleted += $f.FullName
                    $count++
                }
            } catch {
                Write-Diagnostic "Skipped $($f.FullName): $($_.Exception.Message)"
            }
        }

        Write-Section "Results"
        if ($count -gt 0) {
            Show-Success "Deleted $count empty folders."

            $report = New-Report "Deleted Empty Folders"
            $report | Add-ReportSection "Deleted Paths" $deleted "List"
            $outFile = "$env:USERPROFILE\Desktop\EmptyFoldersDeleted_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
            $report | Export-Report-Html $outFile
            Write-Log "Log saved to: $outFile" "Gray"
        } else {
            Show-Success "No empty folders found or deleted."
        }
    } else {
        Show-Error "Path not found: $path"
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
