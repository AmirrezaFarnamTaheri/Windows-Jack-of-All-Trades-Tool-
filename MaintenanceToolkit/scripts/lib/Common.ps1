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
    if ($VerbosePreference -eq 'Continue' -or $env:MAINTENANCE_DIAG -eq '1') {
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

function Get-FolderSize ($Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $size = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($size) { return $size } else { return 0 }
}

function Format-Size ($Bytes) {
    if (-not $Bytes) { return "0 B" }
    if ($Bytes -ge 1GB) { return "$([math]::Round($Bytes / 1GB, 2)) GB" }
    if ($Bytes -ge 1MB) { return "$([math]::Round($Bytes / 1MB, 2)) MB" }
    if ($Bytes -ge 1KB) { return "$([math]::Round($Bytes / 1KB, 2)) KB" }
    return "$Bytes B"
}

# --- Reporting Module ---

function New-Report {
    param($Title)
    $report = @{
        Title = $Title
        Sections = @()
        Date = Get-Date
        Host = $env:COMPUTERNAME
        User = $env:USERNAME
    }
    return $report
}

function Add-ReportSection {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Report,
        [string]$Header,
        [object]$Content,
        [string]$Type = "Text" # Text, List, Table, KeyValue, RawHtml
    )
    $Report.Sections += @{
        Header = $Header
        Content = $Content
        Type = $Type
    }
    return $Report
}

function Export-Report-Html {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Report,
        [string]$Path
    )

    $css = @"
<style>
body { font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif; background-color: #1e1e1e; color: #f1f1f1; margin: 0; padding: 40px; }
h1 { color: #007acc; font-weight: 300; font-size: 2.5em; margin-bottom: 5px; }
.meta { color: #888; font-size: 0.9em; margin-bottom: 40px; border-bottom: 1px solid #333; padding-bottom: 10px; }
.section { background: #252526; padding: 25px; margin-bottom: 25px; border-radius: 4px; box-shadow: 0 2px 5px rgba(0,0,0,0.2); }
h2 { color: #4ec9b0; margin-top: 0; border-bottom: 1px solid #3e3e42; padding-bottom: 15px; font-weight: 400; font-size: 1.5em; }
p { line-height: 1.6; color: #ccc; }
table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 0.95em; }
th { text-align: left; background: #333; padding: 12px; border-bottom: 2px solid #007acc; color: #fff; font-weight: 600; }
td { padding: 12px; border-bottom: 1px solid #3e3e42; color: #ddd; }
tr:hover { background: #2d2d30; }
.key-value { display: flex; margin-bottom: 8px; border-bottom: 1px solid #333; padding-bottom: 4px; }
.key { width: 250px; color: #aaa; font-weight: 600; }
.val { flex: 1; color: #fff; }
ul { color: #ccc; line-height: 1.6; }
li { margin-bottom: 5px; }
.status-pass { color: #4caf50; font-weight: bold; }
.status-fail { color: #f44336; font-weight: bold; }
.status-warn { color: #ffeb3b; font-weight: bold; }
</style>
"@

    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>$($Report.Title)</title>
$css
</head>
<body>
<h1>$($Report.Title)</h1>
<div class="meta">Generated: $($Report.Date) | Host: $($Report.Host) | User: $($Report.User)</div>
"@

    foreach ($sec in $Report.Sections) {
        $html += "<div class='section'><h2>$($sec.Header)</h2>"

        switch ($sec.Type) {
            "Text" {
                $html += "<p>$($sec.Content)</p>"
            }
            "List" {
                $html += "<ul>"
                foreach ($item in $sec.Content) { $html += "<li>$item</li>" }
                $html += "</ul>"
            }
            "Table" {
                if ($sec.Content) {
                    # Convert object array to HTML fragments
                    $tableHtml = $sec.Content | ConvertTo-Html -Fragment

                    # Allow limited, intentional markup inside cells (generated by our scripts)
                    $tableHtml = $tableHtml `
                        -replace '&lt;(/?span\b[^&]*)&gt;', '<$1>' `
                        -replace '&lt;(/?strong)&gt;', '<$1>' `
                        -replace '&lt;/a&gt;', '</a>' `
                        -replace '&lt;a href=(&quot;|&#39;)([^&]+?)\1&gt;', '<a href="$2">'

                    # Clean up PowerShell's default styles if any
                    $tableHtml = $tableHtml -replace '<table>', '<table>'
                    $html += $tableHtml
                } else {
                    $html += "<p>No data available.</p>"
                }
            }
            "KeyValue" {
                if ($sec.Content -is [System.Collections.IDictionary]) {
                    foreach ($key in $sec.Content.Keys) {
                        $html += "<div class='key-value'><div class='key'>$key</div><div class='val'>$($sec.Content[$key])</div></div>"
                    }
                }
            }
            "RawHtml" {
                $html += $sec.Content
            }
        }
        $html += "</div>"
    }

    $html += "</body></html>"
    $html | Out-File $Path -Encoding UTF8
    return $Path
}
