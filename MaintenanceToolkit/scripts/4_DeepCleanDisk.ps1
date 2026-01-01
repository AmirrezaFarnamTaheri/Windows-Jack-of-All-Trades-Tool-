. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Deep Disk Cleanup"
Get-SystemSummary

try {
    # Measure Free Space Before
    $drive = Get-PSDrive C
    $freeBefore = $drive.Free
    Write-Log "Free Space Before: $([math]::Round($freeBefore/1MB, 2)) MB" "Gray"

    Write-Section "Configuration"
    # This sets registry keys to select all cleanup options
    Write-Log "Configuring cleanup settings in Registry..." "Yellow"
    $cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

    if (Test-Path $cleanmgrKey) {
        Get-ChildItem $cleanmgrKey | ForEach-Object {
            try {
                New-ItemProperty -Path $_.PSPath -Name StateFlags0001 -Value 2 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Log "Warning: Could not set flag for $($_.PSChildName). Continuing..." "Yellow"
            }
        }
    } else {
        throw "VolumeCaches registry key not found."
    }

    Write-Section "Execution"
    # Run Disk Cleanup silently with these settings
    Write-Log "Running Disk Cleanup Tool (cleanmgr.exe)..." "Green"

    # /sagerun:1 reads the flags we set above
    # We wait for it to finish to check space
    $process = Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -PassThru -NoNewWindow -Wait

    # Measure Free Space After
    $drive = Get-PSDrive C
    $freeAfter = $drive.Free
    $saved = $freeAfter - $freeBefore

    Write-Log "Free Space After:  $([math]::Round($freeAfter/1MB, 2)) MB" "Gray"

    if ($saved -gt 0) {
        Show-Success "Cleanup finished. Recovered $([math]::Round($saved/1MB, 2)) MB."
    } else {
        Write-Log "Cleanup finished. No significant space change detected." "White"
    }

} catch {
    Show-Error "Error during Disk Cleanup: $($_.Exception.Message)"
}

Pause-If-Interactive
