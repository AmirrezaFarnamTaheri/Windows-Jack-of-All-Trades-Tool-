# Common.ps1 - Shared functions for Maintenance Toolkit

function Assert-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
        if (-not [Console]::IsInputRedirected) { Pause }
        Exit
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
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        return $ping
    } catch {
        return $false
    }
}

function Backup-RegistryKey ($KeyPath, $BackupDir="$env:USERPROFILE\Desktop\RegBackups") {
    if (Test-Path $KeyPath) {
        if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }
        $Name = ($KeyPath -split "\\")[-1]
        $File = "$BackupDir\$Name-$(Get-Date -Format 'yyyyMMdd-HHmm').reg"
        Start-Process "reg.exe" -ArgumentList "export `"$KeyPath`" `"$File`" /y" -Wait -NoNewWindow
        Write-Log "Backed up registry key '$Name' to $File" "Gray"
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
