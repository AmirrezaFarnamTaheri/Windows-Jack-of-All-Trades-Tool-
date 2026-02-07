# Common.ps1 - Shared functions for Maintenance Toolkit

function Assert-Admin {
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
        if (-not [Console]::IsInputRedirected) { Pause }
        Exit 1
    }
}

function Assert-Destructive {
    param($Message = "This action is potentially destructive.")
    # Safe Mode check (controlled by environment variable set by GUI)
    if ($env:MAINTENANCE_SAFE_MODE -eq '1') {
        Show-Error "Action blocked by Safe Mode: $Message"
        throw "SafeModeBlock"
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
    $targets = @("8.8.8.8", "1.1.1.1", "www.microsoft.com")
    foreach ($target in $targets) {
        try {
            $ping = Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction SilentlyContinue
            if ($ping) { return $true }
        } catch {}
    }

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

function Install-WingetApp {
    param(
        [string]$Id,
        [string]$Name
    )

    if (-not (Test-IsWingetAvailable)) {
        Show-Error "Winget is not installed."
        return $false
    }

    Write-Log "Checking $Name ($Id)..." "Cyan"

    # Check if installed
    $list = winget list --id $Id --exact -e 2>$null
    if ($list -match $Id) {
        Show-Success "$Name is already installed."
        return $true
    }

    Write-Log "Installing $Name..." "Yellow"
    winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements

    if ($LASTEXITCODE -eq 0) {
        Show-Success "$Name installed successfully."
        return $true
    } else {
        Show-Error "Failed to install $Name (Exit Code: $LASTEXITCODE)."
        return $false
    }
}

function Assert-SystemRestoreEnabled {
    try {
        # Check if System Restore is enabled for C:
        $rpoint = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        # This only lists points. We need to enable it.
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

function New-ProgressBarHtml ($Percent, $Label="") {
    # Ensure percent is between 0 and 100
    $p = [math]::Min(100, [math]::Max(0, [int]$Percent))
    $color = "#007acc"
    if ($p -gt 80) { $color = "#d9534f" } # Red if high usage
    elseif ($p -gt 60) { $color = "#f0ad4e" } # Orange if medium

    return "<div class='bar-container'><div class='bar-fill' style='width:$p%; background-color:$color;'>$Label</div></div>"
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
        [string]$Type = "Text", # Text, List, Table, KeyValue, RawHtml
        [object]$ChartData = $null # Optional: Hash @{ Label="Name"; Value="Size" } for charts
    )
    $Report.Sections += @{
        Header = $Header
        Content = $Content
        Type = $Type
        ChartData = $ChartData
    }
    return $Report
}

function Export-Report-Html {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Report,
        [string]$Path
    )

    $hasInternet = Test-IsConnected
    $chartScript = if ($hasInternet) { '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>' } else { '<!-- Offline Mode: Charts Disabled -->' }

    $css = @"
<style>
:root {
    --bg-color: #1e1e1e;
    --text-color: #f1f1f1;
    --section-bg: #252526;
    --accent: #007acc;
    --border: #3e3e42;
    --hover: #2d2d30;
}
@media (prefers-color-scheme: light) {
    :root {
        --bg-color: #f0f0f0;
        --text-color: #202020;
        --section-bg: #ffffff;
        --accent: #0078d4;
        --border: #cccccc;
        --hover: #f5f5f5;
    }
}
body { font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif; background-color: var(--bg-color); color: var(--text-color); margin: 0; padding: 40px; }
h1 { color: var(--accent); font-weight: 300; font-size: 2.5em; margin-bottom: 5px; }
.meta { color: #888; font-size: 0.9em; margin-bottom: 40px; border-bottom: 1px solid #333; padding-bottom: 10px; }
.section { background: var(--section-bg); padding: 25px; margin-bottom: 25px; border-radius: 4px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
h2 { color: #4ec9b0; margin-top: 0; border-bottom: 1px solid var(--border); padding-bottom: 15px; font-weight: 400; font-size: 1.5em; }
p { line-height: 1.6; color: inherit; }
table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 0.95em; }
th { text-align: left; background: #333; padding: 12px; border-bottom: 2px solid var(--accent); color: #fff; font-weight: 600; cursor: pointer; }
td { padding: 12px; border-bottom: 1px solid var(--border); color: inherit; }
tr:hover { background: var(--hover); }
.key-value { display: flex; margin-bottom: 8px; border-bottom: 1px solid var(--border); padding-bottom: 4px; }
.key { width: 250px; color: #888; font-weight: 600; }
.val { flex: 1; color: inherit; }
ul { line-height: 1.6; }
li { margin-bottom: 5px; }
.status-pass { color: #4caf50; font-weight: bold; }
.status-fail { color: #f44336; font-weight: bold; }
.status-warn { color: #ffeb3b; font-weight: bold; }
.bar-container { background-color: #444; width: 100%; height: 20px; border-radius: 4px; overflow: hidden; position: relative; }
.bar-fill { height: 100%; background-color: var(--accent); text-align: center; color: white; font-size: 11px; line-height: 20px; white-space: nowrap; }
.chart-box { width: 100%; max-width: 600px; height: 300px; margin: 20px auto; }
</style>
$chartScript
<script>
document.addEventListener('DOMContentLoaded', function() {
    const getCellValue = (tr, idx) => tr.children[idx].innerText || tr.children[idx].textContent;
    const comparer = (idx, asc) => (a, b) => ((v1, v2) =>
        v1 !== '' && v2 !== '' && !isNaN(v1) && !isNaN(v2) ? v1 - v2 : v1.toString().localeCompare(v2)
    )(getCellValue(asc ? a : b, idx), getCellValue(asc ? b : a, idx));

    document.querySelectorAll('th').forEach(th => th.addEventListener('click', (() => {
        const table = th.closest('table');
        Array.from(table.querySelectorAll('tr:nth-child(n+2)'))
            .sort(comparer(Array.from(th.parentNode.children).indexOf(th), this.asc = !this.asc))
            .forEach(tr => table.appendChild(tr) );
    })));
});
</script>
"@

    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$($Report.Title)</title>
$css
</head>
<body>
<h1>$($Report.Title)</h1>
<div class="meta">Generated: $($Report.Date) | Host: $($Report.Host) | User: $($Report.User)</div>
"@

    $chartId = 0
    foreach ($sec in $Report.Sections) {
        $html += "<div class='section'><h2>$($sec.Header)</h2>"

        # Chart Render (Simple Bar)
        if ($sec.ChartData) {
            if ($hasInternet) {
                $cData = $sec.Content # Expecting array of objects
                $labels = @()
                $values = @()

                # Simple reflection for properties
                # ChartData should be hash: @{ Label="PropName"; Value="PropName" }
                $lProp = $sec.ChartData.Label
                $vProp = $sec.ChartData.Value

                foreach($obj in $cData) {
                    if ($obj -eq $null) { continue }
                    $labels += "'$($obj.$lProp)'"
                    # Strip units if string (e.g. "10 GB" -> 10)
                    $val = $obj.$vProp
                    if ($val -is [string]) { $val = $val -replace '[^0-9.]','' }
                    $values += $val
                }

                $lStr = $labels -join ","
                $vStr = $values -join ","
                $cid = "chart_$chartId"
                $chartId++

                $html += @"
                <div class="chart-box"><canvas id="$cid"></canvas></div>
                <script>
                new Chart(document.getElementById('$cid'), {
                    type: 'bar',
                    data: {
                        labels: [$lStr],
                        datasets: [{
                            label: 'Data',
                            data: [$vStr],
                            backgroundColor: 'rgba(0, 122, 204, 0.6)',
                            borderColor: 'rgba(0, 122, 204, 1)',
                            borderWidth: 1
                        }]
                    },
                    options: { responsive: true, maintainAspectRatio: false }
                });
                </script>
"@
            } else {
                 $html += "<p><em>Chart unavailable in offline mode.</em></p>"
            }
        }

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
                    $tableHtml = $sec.Content | ConvertTo-Html -Fragment
                    $tableHtml = $tableHtml `
                        -replace '&lt;(span\s+class=(&quot;|&#39;)status-(?:pass|fail|warn)\2)&gt;', '<$1>' `
                        -replace '&lt;(/span)&gt;', '<$1>' `
                        -replace '&lt;(/?strong)&gt;', '<$1>' `
                        -replace '&lt;(div\s+class=(&quot;|&#39;)(?:bar-container|bar-fill)\2(?:\s+style=(&quot;|&#39;)[^&]*\3)?)&gt;', '<$1>' `
                        -replace '&lt;(/div)&gt;', '<$1>' `
                        -replace '&lt;/a&gt;', '</a>' `
                        -replace '&lt;a href=(&quot;|&#39;)([^&]+?)\1&gt;', '<a href="$2">'
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
