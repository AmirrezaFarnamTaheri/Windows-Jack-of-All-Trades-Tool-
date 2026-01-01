# Common.ps1 - Shared functions for Maintenance Toolkit

function Assert-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
        if (-not [Console]::IsInputRedirected) { Pause }
        Exit 1
    }
}

function Write-Header ($Title) {
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "   $Title" -ForegroundColor White
    Write-Host "======================================================" -ForegroundColor Cyan
}

function Write-Log ($Message, $Color="White", $Level="INFO") {
    $TimeStamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$TimeStamp] $Message" -ForegroundColor $Color
}

function Pause-If-Interactive {
    if (-not [Console]::IsInputRedirected) {
        Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
        $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Test-IsConnected {
    try {
        $TargetHost = "8.8.8.8"
        $ping = Test-Connection -ComputerName $TargetHost -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($ping) { return $true }
    } catch {}

    # Fallback to HTTP request
    try {
        $request = Invoke-WebRequest -Uri "http://www.google.com" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        return ($request.StatusCode -eq 200)
    } catch {
        return $false
    }
}

function Test-IsWingetAvailable {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}

function Assert-SystemRestoreEnabled {
    try {
        # Check if System Restore is enabled for C:
        $rpoint = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        # This only lists points. We need to enable it.
        # Check registry or just try enabling it.
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        return $true
    } catch {
        Write-Log "Warning: Could not enable System Restore." "Yellow"
        return $false
    }
}

function Backup-RegistryKey ($KeyPath, $BackupDir="$env:USERPROFILE\Desktop\RegBackups") {
    if ([string]::IsNullOrWhiteSpace($KeyPath)) {
        Write-Log "Error: No registry key path provided for backup." "Red"
        return
    }

    if (Test-Path $KeyPath) {
        if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }
        $Name = ($KeyPath -split "\\")[-1]
        $File = "$BackupDir\$Name-$(Get-Date -Format 'yyyyMMdd-HHmm').reg"
        Start-Process "reg.exe" -ArgumentList "export `"$KeyPath`" `"$File`" /y" -Wait -NoNewWindow
        Write-Log "Backed up registry key '$Name' to $File" "Gray"
    } else {
        Write-Log "Warning: Registry key '$KeyPath' not found. Skipping backup." "Yellow"
    }
}

function Wait-ServiceStatus ($ServiceName, $Status, $TimeoutSeconds=30) {
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $svc) { return }

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    while ($svc.Status -ne $Status -and $timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        Start-Sleep -Seconds 1
        $svc.Refresh()
    }
    $timer.Stop()

    if ($svc.Status -ne $Status) {
        Write-Log "Warning: Service '$ServiceName' failed to reach state '$Status'." "Yellow"
    } else {
        Write-Log "Service '$ServiceName' is now $($svc.Status)." "Green"
    }
}
