. "$PSScriptRoot/lib/Common.ps1"
# Define the path to the toolkit relative to this script
# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$ToolkitPath = $PSScriptRoot

# Start Logging
$LogPath = "$ToolkitPath\MaintenanceLog.txt"
$Date = Get-Date
Add-Content $LogPath "[$Date] Starting Weekly Maintenance..."

# 1. Run Deep Disk Clean
try {
    Write-Host "Running Deep Disk Clean..."
    & "$ToolkitPath\4_DeepCleanDisk.ps1"
    Add-Content $LogPath " - Disk Cleanup: Success"
} catch {
    Add-Content $LogPath " - Disk Cleanup: FAILED"
}

# 2. Run Nuclear Temp Clean
try {
    Write-Host "Running Temp Clean..."
    & "$ToolkitPath\13_NuclearTempClean.ps1"
    Add-Content $LogPath " - Temp Clean: Success"
} catch {
    Add-Content $LogPath " - Temp Clean: FAILED"
}

# 3. Update All Software
try {
    Write-Host "Updating Software..."
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
    Add-Content $LogPath " - Software Updates: Success"
} catch {
    Add-Content $LogPath " - Software Updates: FAILED"
}

# 4. Safe Debloat (To catch any new junk Windows installed)
try {
    Write-Host "Checking for Bloatware..."
    & "$ToolkitPath\5_SafeDebloat.ps1"
    Add-Content $LogPath " - Debloat Check: Success"
} catch {
    Add-Content $LogPath " - Debloat Check: FAILED"
}

$EndDate = Get-Date
Add-Content $LogPath "[$EndDate] Maintenance Complete."
Add-Content $LogPath "------------------------------------------------"
