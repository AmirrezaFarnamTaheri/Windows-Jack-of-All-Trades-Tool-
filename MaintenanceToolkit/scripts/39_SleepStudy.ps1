. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Generating System Sleep Study"
Write-Log "Analyzing battery drain during sleep (Duration: 3 days)..." "Yellow"

$path = "$env:USERPROFILE\Desktop\SleepStudy.html"

try {
    powercfg /sleepstudy /output "$path" /duration 3

    if (Test-Path $path) {
        Write-Log "Report generated: $path" "Green"
        Start-Process "$path"
    } else {
        Write-Log "Failed to generate report." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
