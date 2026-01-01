. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Nuclear Temporary File Cleanup"
Get-SystemSummary

function Get-FolderSize ($Path) {
    if (-not (Test-Path $Path)) { return 0 }
    $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($size) { return $size } else { return 0 }
}

function Format-Size ($Bytes) {
    if ($Bytes -gt 1GB) { return "$([math]::Round($Bytes / 1GB, 2)) GB" }
    if ($Bytes -gt 1MB) { return "$([math]::Round($Bytes / 1MB, 2)) MB" }
    return "$([math]::Round($Bytes / 1KB, 2)) KB"
}

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

    # Special Handling
    if ($t.Name -eq "Windows Update") {
        Stop-ServiceSafe "wuauserv"
        Stop-ServiceSafe "bits"
    }

    if (Test-Path $t.Path) {
        Get-ChildItem -Path $t.Path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    if ($t.Name -eq "Windows Update") {
        Start-Service "wuauserv" -ErrorAction SilentlyContinue
        Start-Service "bits" -ErrorAction SilentlyContinue
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
if ($reclaimed -lt 0) { $reclaimed = 0 } # Sanity check

Show-Success "Space Reclaimed: $(Format-Size $reclaimed)"

Pause-If-Interactive
