. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Find Large Files (>1GB)"
Get-SystemSummary
Write-Section "Configuration"

$path = Read-Host "Enter path to scan (default: $env:USERPROFILE)"
if ([string]::IsNullOrWhiteSpace($path)) { $path = $env:USERPROFILE }

try {
    Write-Section "Scanning"
    if (Test-Path $path) {
        Write-Log "Scanning $path (This takes time)..." "Cyan"

        $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1GB }

        if ($files) {
            Write-Log "Found $($files.Count) large files." "Green"
            Write-Section "Results"

            $files | Sort-Object Length -Descending | ForEach-Object {
                $sizeGB = [math]::Round($_.Length / 1GB, 2)
                Write-Host "$sizeGB GB" -NoNewline -ForegroundColor Yellow
                Write-Host " - $($_.FullName)" -ForegroundColor White
            }
            Show-Success "Scan Complete."
        } else {
            Show-Success "No files larger than 1GB found."
        }
    } else {
        Show-Error "Path not found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
