. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Resetting Windows Update Components"
Write-Log "This fixes stuck updates and download errors." "Yellow"

$services = "wuauserv", "cryptSvc", "bits", "msiserver"

try {
    # 1. Stop Services
    foreach ($svc in $services) {
        Write-Log "Stopping service: $svc"
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Wait-ServiceStatus -ServiceName $svc -Status "Stopped" -TimeoutSeconds 15
    }

    # 2. Rename Folders
    $folders = @(
        "C:\Windows\SoftwareDistribution",
        "C:\Windows\System32\catroot2"
    )

    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            $backup = "$folder.bak.$(Get-Date -Format 'yyyyMMddHHmm')"
            Write-Log "Renaming $folder to $backup..."
            try {
                Rename-Item -Path $folder -NewName $backup -ErrorAction Stop
                Write-Log "Success." "Green"
            } catch {
                Write-Log "Failed to rename $folder. Access Denied or files in use." "Red"
                # Attempt to clear content if rename fails? No, risky.
            }
        } else {
            Write-Log "$folder does not exist. Skipping." "Gray"
        }
    }

    # 3. Reset BITS/WUA descriptors (Optional but helpful)
    # sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)
    # sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)

    # 4. Restart Services
    foreach ($svc in $services) {
        Write-Log "Starting service: $svc"
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Wait-ServiceStatus -ServiceName $svc -Status "Running"
    }

    Write-Log "--- Windows Update Reset Complete ---" "Green"
    Write-Log "If updates still fail, consider running the 'System Repair' tool." "Cyan"

} catch {
    Write-Log "Critical Error: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
