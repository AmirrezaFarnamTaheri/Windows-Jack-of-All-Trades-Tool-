. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Find Duplicate Files"
Get-SystemSummary
Write-Section "Configuration"

if (-not [Console]::IsInputRedirected) {
    $path = Read-Host "Enter path to scan (default: $env:USERPROFILE\Documents)"
}
if ([string]::IsNullOrWhiteSpace($path)) { $path = "$env:USERPROFILE\Documents" }

try {
    if (Test-Path $path) {
        Write-Section "Scanning"
        Write-Log "Scanning $path..." "Cyan"
        Write-Log "Only checking files > 1MB to save time." "Gray"

        $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1MB }

        Write-Log "Found $($files.Count) candidates. Calculating hashes..." "Cyan"

        # Hash Logic
        $hashes = @()
        $i = 0
        foreach ($f in $files) {
            $i++
            if ($i % 10 -eq 0) { Write-Progress -Activity "Hashing Files" -Status "$i / $($files.Count)" -PercentComplete (($i / $files.Count) * 100) }
            try {
                $h = Get-FileHash -Path $f.FullName -Algorithm MD5 -ErrorAction Stop
                $hashes += $h
            } catch {
                Write-Diagnostic "Skipped locked file: $($f.Name)"
            }
        }
        Write-Progress -Activity "Hashing Files" -Completed

        $dupes = $hashes | Group-Object Hash | Where-Object { $_.Count -gt 1 }

        if ($dupes) {
            $reportData = @()

            Write-Section "Duplicate Groups Found"
            foreach ($g in $dupes) {
                Write-Log "Group ($($g.Count)): $($g.Name)" "Yellow"

                # Format for report
                foreach ($f in $g.Group) {
                    $reportData += [PSCustomObject]@{
                        Hash = $g.Name
                        Path = $f.Path
                    }
                    Write-Log "  $($f.Path)" "White"
                }
            }

            $report = New-Report "Duplicate Files Report"
            $report | Add-ReportSection "Duplicates Found" $reportData "Table"
            $outFile = "$env:USERPROFILE\Desktop\DuplicateFiles_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
            $report | Export-Report-Html $outFile

            Show-Success "Found $($dupes.Count) groups of duplicates. Report saved."
            Invoke-Item $outFile
        } else {
            Show-Success "No duplicates found (checked files > 1MB)."
        }
    } else {
        Show-Error "Path not found: $path"
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
