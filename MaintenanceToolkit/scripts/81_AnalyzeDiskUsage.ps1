. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Analyze Disk Usage (Top 20 Folders)"
Get-SystemSummary
Write-Section "Configuration"

$path = Read-Host "Enter path to scan (default: C:\)"
if ([string]::IsNullOrWhiteSpace($path)) { $path = "C:\" }

try {
    if (Test-Path $path) {
        Write-Section "Scanning (This may take a while)"

        $folders = @{}

        # Using Get-ChildItem -Recurse is slow for whole drives.
        # We will scan the top level folders recursively to give a breakdown.

        $topLevel = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue

        foreach ($folder in $topLevel) {
            Write-Host "Scanning $($folder.Name)..." -NoNewline -ForegroundColor Gray
            try {
                $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $folders[$folder.FullName] = $size
                Write-Host " $([math]::Round($size/1MB, 0)) MB" -ForegroundColor White
            } catch {
                Write-Host " Access Denied" -ForegroundColor Red
            }
        }

        # Files in root
        try {
            $rootFiles = (Get-ChildItem -Path $path -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $folders["$path (Root Files)"] = $rootFiles
        } catch {}

        Write-Section "Top 20 Largest Folders"
        $folders.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | ForEach-Object {
            $mb = [math]::Round($_.Value / 1MB, 2)
            $gb = [math]::Round($_.Value / 1GB, 2)

            $sizeStr = if ($gb -ge 1) { "$gb GB" } else { "$mb MB" }
            Write-Host "$sizeStr" -NoNewline -ForegroundColor Cyan
            Write-Host " - $($_.Key)" -ForegroundColor White
        }

        Show-Success "Analysis Complete."
    } else {
        Show-Error "Path not found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
