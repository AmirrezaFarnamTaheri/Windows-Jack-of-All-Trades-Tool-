. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Deep Disk Cleanup"

try {
    # This sets registry keys to select all cleanup options
    Write-Log "Configuring cleanup settings in Registry..." "Yellow"
    $cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

    if (Test-Path $cleanmgrKey) {
        Get-ChildItem $cleanmgrKey | ForEach-Object {
            try {
                New-ItemProperty -Path $_.PSPath -Name StateFlags0001 -Value 2 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Log "Warning: Could not set flag for $($_.PSChildName)" "Yellow"
            }
        }
    } else {
        throw "VolumeCaches registry key not found."
    }

    # Run Disk Cleanup silently with these settings
    Write-Log "Running Disk Cleanup Tool (cleanmgr.exe)..." "Green"

    $process = Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -PassThru -NoNewWindow

    Write-Log "Cleanup initiated with PID: $($process.Id)" "Green"
    Write-Log "The process is running in the background. It will close automatically when finished." "White"

} catch {
    Write-Log "Error during Disk Cleanup: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
