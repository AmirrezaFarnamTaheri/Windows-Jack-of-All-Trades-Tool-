. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Nuclear Temporary File Cleanup"
Get-SystemSummary

# Safety Check
Assert-Destructive "This script aggressively deletes temporary files and empties the Recycle Bin."

Write-Section "Analyzing Disk Usage"
Write-Log "Calculating reclaimable space..." "Cyan"

# Define Targets
$targets = @(
    @{ Name="User Temp"; Path="$env:TEMP" },
    @{ Name="Windows Temp"; Path="$env:WINDIR\Temp" },
    @{ Name="Prefetch"; Path="$env:WINDIR\Prefetch" },
    @{ Name="Windows Update"; Path="$env:WINDIR\SoftwareDistribution\Download" }
)

# Analyze Before
$totalInitial = 0
foreach ($t in $targets) {
    $size = Get-FolderSize $t.Path
    $t.Size = $size
    $totalInitial += $size
    Write-Log "$($t.Name): $(Format-Size $size)" "Gray"
}

Write-Log "--------------------------------" "DarkGray"
Write-Log "Total Potential Reclaim: $(Format-Size $totalInitial)" "White"
Write-Log "--------------------------------" "DarkGray"

if ($totalInitial -eq 0) {
    Show-Info "Nothing to clean."
    Pause-If-Interactive
    exit
}

Write-Section "Execution"
Write-Log "Closing applications is recommended." "Yellow"
Start-Sleep -Seconds 2

# Clean Targets
foreach ($t in $targets) {
    Write-Log "Cleaning $($t.Name)..." "Cyan"

    $p = $t.Path
    if ([string]::IsNullOrWhiteSpace($p)) {
        Show-Warning "Skipping $($t.Name): empty path."
        continue
    }

    $resolved = (Resolve-Path -LiteralPath $p -ErrorAction SilentlyContinue).Path
    if (-not $resolved) {
        Write-Diagnostic "Skipping $($t.Name): path not found ($p)."
        continue
    }

    # Safety: Ensure we aren't deleting root
    $root = [System.IO.Path]::GetPathRoot($resolved)
    if ($resolved.TrimEnd('\') -eq $root.TrimEnd('\')) {
        Show-Warning "Skipping $($t.Name): refusing to clean drive root ($resolved)."
        continue
    }

    # Special Handling for Windows Update
    $wuWasRunning = $false
    $bitsWasRunning = $false

    if ($t.Name -eq "Windows Update") {
        $wuSvc = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        $bitsSvc = Get-Service -Name "bits" -ErrorAction SilentlyContinue

        $wuWasRunning = ($wuSvc -and $wuSvc.Status -eq 'Running')
        $bitsWasRunning = ($bitsSvc -and $bitsSvc.Status -eq 'Running')

        try {
            Stop-ServiceSafe "wuauserv"
            Stop-ServiceSafe "bits"
        } catch {
            Write-Log "Could not stop update services. Some files may be locked." "Yellow"
        }
    }

    try {
        Get-ChildItem -Path $resolved -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    } finally {
        if ($t.Name -eq "Windows Update") {
            # Restart only if they were running
            if ($wuWasRunning) { Start-Service "wuauserv" -ErrorAction SilentlyContinue }
            if ($bitsWasRunning) { Start-Service "bits" -ErrorAction SilentlyContinue }
        }
    }
}

# Clean Recycle Bin
try {
    Write-Log "Emptying Recycle Bin..." "Cyan"
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
} catch {}

Write-Section "Results"
$totalFinal = 0
foreach ($t in $targets) {
    $size = Get-FolderSize $t.Path
    $totalFinal += $size
}

$reclaimed = $totalInitial - $totalFinal
if ($reclaimed -lt 0) { $reclaimed = 0 } # Sanity check (e.g. if new files created)

Show-Success "Space Reclaimed: $(Format-Size $reclaimed)"

Pause-If-Interactive
