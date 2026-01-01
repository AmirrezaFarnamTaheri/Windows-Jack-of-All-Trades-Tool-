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

function Write-Section ($Title) {
    Write-Host "`n--- $Title ---" -ForegroundColor Yellow
}

function Write-Log ($Message, $Color="White", $Level="INFO") {
    $TimeStamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$TimeStamp] $Message" -ForegroundColor $Color
}

function Show-Success ($Message) {
    Write-Log "[SUCCESS] $Message" "Green"
}

function Show-Error ($Message) {
    Write-Log "[ERROR] $Message" "Red"
}

function Show-Warning ($Message) {
    Write-Log "[WARNING] $Message" "Yellow"
}

function Show-Info ($Message) {
    Write-Log "[INFO] $Message" "Cyan"
}

function Write-Diagnostic ($Message) {
    if ($Global:VerbosePreference -eq 'Continue' -or $env:MAINTENANCE_DIAG -eq '1') {
        Write-Log "[DIAG] $Message" "DarkGray"
    }
}

function Get-SystemSummary {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop

        # Uptime
        $boot = $os.LastBootUpTime
        $uptime = (Get-Date) - $boot
        $uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

        # Disk Space (C:)
        $drive = Get-PSDrive C -ErrorAction SilentlyContinue
        $freeGB = "N/A"
        if ($drive) { $freeGB = "$([math]::Round($drive.Free/1GB, 1)) GB" }

        Write-Log "------------------------------------------------------" "DarkGray"
        Write-Log "OS: $($os.Caption) ($($os.OSArchitecture))" "Gray"
        Write-Log "Build: $($os.BuildNumber)" "Gray"
        Write-Log "Uptime: $uptimeStr" "Gray"
        Write-Log "CPU: $($cpu.Name)" "Gray"
        Write-Log "RAM: $([math]::Round($os.FreePhysicalMemory/1024,0)) MB Free / $([math]::Round($os.TotalVisibleMemorySize/1024,0)) MB Total" "Gray"
        Write-Log "Disk (C:): $freeGB Free" "Gray"
        Write-Log "------------------------------------------------------" "DarkGray"
    } catch {
        Write-Log "System Summary Unavailable: $($_.Exception.Message)" "Red"
    }
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
        Show-Error "No registry key path provided for backup."
        return
    }

    if (Test-Path $KeyPath) {
        if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }
        $Name = ($KeyPath -split "\\")[-1]
        $File = "$BackupDir\$Name-$(Get-Date -Format 'yyyyMMdd-HHmm').reg"
        Start-Process "reg.exe" -ArgumentList "export `"$KeyPath`" `"$File`" /y" -Wait -NoNewWindow
        Show-Success "Backed up registry key '$Name' to $File"
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

function Set-RegKey {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value,
        [string]$Type = "String",
        [switch]$Force
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        Write-Log "Registry Set: $Path\$Name = $Value" "Gray"
    } catch {
        Show-Error "Failed to set registry key: $Path\$Name. Error: $($_.Exception.Message)"
    }
}

function Stop-ServiceSafe ($ServiceName) {
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running') {
            Write-Log "Stopping service: $ServiceName..." "Yellow"
            Stop-Service -Name $ServiceName -Force -ErrorAction Stop
            Wait-ServiceStatus $ServiceName "Stopped" 15
        }
    } catch {
        Show-Error "Error stopping service ${ServiceName}: $($_.Exception.Message)"
        throw
    }
}
