. "$PSScriptRoot/lib/Common.ps1"
# Ultimate System Maintenance Menu

Assert-Admin
$ScriptPath = $PSScriptRoot

function Run-Script ($Number) {
    $script = Get-ChildItem "$ScriptPath\$Number`_*.ps1" | Select-Object -First 1
    if ($script) {
        Clear-Host
        Write-Log "Launching: $($script.Name)..." "Cyan"
        & $script.FullName
    } else {
        Show-Error "Script #$Number not found."
        Start-Sleep -Seconds 1
    }
}

function Show-Header {
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "      ULTIMATE SYSTEM MAINTENANCE TOOLKIT (v80)       " -ForegroundColor White
    Write-Host "======================================================" -ForegroundColor Cyan
}

function Show-Help {
    Clear-Host
    if (Test-Path "$PSScriptRoot\..\HELP.md") {
        Get-Content "$PSScriptRoot\..\HELP.md" | More
    } elseif (Test-Path "$PSScriptRoot\HELP.md") {
        Get-Content "$PSScriptRoot\HELP.md" | More
    } else {
        Show-Error "Help file not found."
    }
    if (-not [Console]::IsInputRedirected) { Pause }
}

function Show-SubMenu ($Category) {
    Show-Header
    switch ($Category) {
        "CLEAN" {
            Write-Section "CLEANING & MAINTENANCE"
            Write-Host "2.  Install Cleaners (Malwarebytes/BleachBit)"
            Write-Host "4.  Deep Disk Cleanup"
            Write-Host "5.  Safe Debloat (Remove Junk Apps)"
            Write-Host "13. Nuclear Temp Clean"
            Write-Host "35. Scan Recycle Bin Content"
            Write-Host "45. Delete Empty Folders"
            Write-Host "50. Find Duplicate Files"
            Write-Host "68. SSD Trim Optimization"
            Write-Host "75. Clear Browser Cache"
        }
        "REPAIR" {
            Write-Section "REPAIR & FIXES"
            Write-Host "1.  Create Restore Point"
            Write-Host "3.  System Repair (SFC / DISM)"
            Write-Host "10. Restore Win10 Context Menu"
            Write-Host "12. Rebuild Icon Cache"
            Write-Host "14. Fix Time Sync"
            Write-Host "16. Reset Windows Update"
            Write-Host "18. Rebuild Font Cache"
            Write-Host "25. Fix Stuck Printer"
            Write-Host "36. Clear Pending Updates (Boot Loop Fix)"
            Write-Host "38. Restart Audio Services"
            Write-Host "51. Fix 'Access Denied' Permissions"
            Write-Host "56. Clean PATH Variables"
            Write-Host "62. Fix Windows Store"
        }
        "HARDWARE" {
            Write-Section "HARDWARE & DIAGNOSTICS"
            Write-Host "9.  Check Disk Health (SMART)"
            Write-Host "11. Battery Health Report"
            Write-Host "17. Backup Drivers"
            Write-Host "22. Remove Ghost Devices"
            Write-Host "34. Keyboard Input Tester"
            Write-Host "37. Dead Pixel Fixer"
            Write-Host "39. Sleep Study (Battery Drain)"
            Write-Host "40. RAM Memory Test (Reboot)"
            Write-Host "41. CPU Stress Test"
            Write-Host "52. Read Chkdsk Logs"
            Write-Host "64. Check Virtualization (VT-x)"
            Write-Host "65. Disable USB Suspend (Fix Lag)"
        }
        "NETWORK" {
            Write-Section "NETWORK & INTERNET"
            Write-Host "7.  Network Reset (Flush DNS/IP)"
            Write-Host "19. Show Wi-Fi Passwords"
            Write-Host "20. DNS Speed Benchmark"
            Write-Host "30. Local Port Scanner"
            Write-Host "47. Network Heartbeat Monitor"
            Write-Host "53. Optimize Internet Speed"
            Write-Host "58. Block Website (Hosts)"
            Write-Host "67. Wi-Fi Scanner (Nearby Networks)"
            Write-Host "69. Wireless Network Report"
            Write-Host "71. Firewall Audit (Rules Check)"
            Write-Host "79. Process Connections (Netstat)"
            Write-Host "80. Flush DNS Cache"
        }
        "SECURITY" {
            Write-Section "SECURITY & PRIVACY"
            Write-Host "8.  Privacy Hardening (Telemetry)"
            Write-Host "21. Audit Scheduled Tasks"
            Write-Host "24. Get BitLocker Keys"
            Write-Host "31. USB Write Protection"
            Write-Host "32. Verify File Hash"
            Write-Host "42. Audit Non-Microsoft Services"
            Write-Host "48. Audit User Accounts"
            Write-Host "49. Securely Wipe File (DoD)"
            Write-Host "59. Panic Button (Hide All)"
            Write-Host "78. User Login History"
        }
        "UTILS" {
            Write-Section "UTILITIES & TOOLS"
            Write-Host "6.  Update All Software"
            Write-Host "15. Clear Event Logs"
            Write-Host "23. Find Large Files"
            Write-Host "26. Clear Clipboard"
            Write-Host "27. Check System Stability (Crashes)"
            Write-Host "28. Get BIOS Windows Key"
            Write-Host "29. Process Freezer"
            Write-Host "33. Enable God Mode"
            Write-Host "43. Analyze Boot Time"
            Write-Host "44. Export Installed App List"
            Write-Host "46. Quick Backup (Robocopy)"
            Write-Host "54. Sleep Timer"
            Write-Host "55. Toggle Dark Mode"
            Write-Host "57. Turn Off Monitor"
            Write-Host "60. Emergency Restart"
            Write-Host "61. Check Activation Status"
            Write-Host "63. Install Essential Apps"
            Write-Host "70. Export System Spec (Detailed Info)"
            Write-Host "73. Startup Apps Manager"
            Write-Host "74. Windows Update History"
            Write-Host "76. System Stability Score"
            Write-Host "77. Reset Windows Search Index"
        }
    }
    Write-Host "------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "B. Back to Main Menu" -ForegroundColor Cyan
    $choice = Read-Host "Enter Script Number"
    if ($choice -eq 'B' -or $choice -eq 'b') { return }
    Run-Script $choice
    if (-not [Console]::IsInputRedirected) {
        Pause
    }
}

# Main Loop
do {
    Show-Header
    Write-Host "SELECT A CATEGORY:" -ForegroundColor Green
    Write-Host "1. CLEANING     (Disk, Temp, Bloatware)"
    Write-Host "2. REPAIR       (System, Icons, Store, Updates)"
    Write-Host "3. HARDWARE     (Battery, Drivers, RAM, CPU)"
    Write-Host "4. NETWORK      (Wi-Fi, DNS, Speed)"
    Write-Host "5. SECURITY     (Privacy, Audits, USB)"
    Write-Host "6. UTILITIES    (Backups, Updates, Tools)"
    Write-Host "H. Help / About"
    Write-Host "Q. Quit"
    Write-Host "======================================================"

    $mainChoice = Read-Host "Choice"

    switch ($mainChoice) {
        '1' { Show-SubMenu "CLEAN" }
        '2' { Show-SubMenu "REPAIR" }
        '3' { Show-SubMenu "HARDWARE" }
        '4' { Show-SubMenu "NETWORK" }
        '5' { Show-SubMenu "SECURITY" }
        '6' { Show-SubMenu "UTILS" }
        'H' { Show-Help }
        'h' { Show-Help }
        'Q' { Exit }
        'q' { Exit }
    }
} until ($mainChoice -eq 'Q')
