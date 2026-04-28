. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Diagnostics Center (Safe Read-Only)"
Get-SystemSummary

Write-Section "Purpose"
Write-Log "This tool collects read-only diagnostics and produces a consolidated HTML report." "Gray"

function Get-BitLockerStatusRows {
    $rows = @()
    try {
        if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
            $vols = Get-BitLockerVolume -ErrorAction SilentlyContinue
            foreach ($v in $vols) {
                $rows += [pscustomobject]@{
                    MountPoint = $v.MountPoint
                    ProtectionStatus = $v.ProtectionStatus
                    VolumeStatus   = $v.VolumeStatus
                    EncryptionPercentage = $v.EncryptionPercentage
                }
            }
        }
    } catch {}
    return $rows
}

function Get-SecurityProductRows {
    $rows = @()
    # Security Center 2: registered AV
    try {
        $wsc = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
        foreach ($p in $wsc) {
            $rows += [pscustomobject]@{
                Source   = "SecurityCenter2"
                Name     = $p.displayName
                State    = $p.productState
            }
        }
    } catch {}
    return $rows
}

function Get-DefenderStatus {
    $h = @{}
    try {
        if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
            $s = Get-MpComputerStatus -ErrorAction SilentlyContinue
            if ($s) {
                $h["RealTimeEnabled"]   = $s.RealTimeProtectionEnabled
                $h["AMServiceEnabled"]  = $s.AMServiceEnabled
                $h["AntivirusSignatureLastUpdated"] = $s.AntivirusSignatureLastUpdated
                $nis = $s.PSObject.Properties["NISEnabled"]
                $h["NISSignatureLastUpdated"] = if ($nis -and $nis.Value) { $s.NISSignatureLastUpdated } else { "N/A" }
                $h["EngineVersion"]     = $s.AMEngineVersion
                $h["SignatureVersion"]  = $s.AntivirusSignatureVersion
            }
        }
    } catch {}
    return $h
}

function Get-MiniDumpCount {
    try {
        $p = "C:\Windows\Minidump"
        if (Test-Path -LiteralPath $p) {
            $since = (Get-Date).AddDays(-7)
            return (Get-ChildItem -LiteralPath $p -Filter *.dmp -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -ge $since }).Count
        }
    } catch {}
    return $null
}

try {
    $report = New-Report "Diagnostics Center Report"

    # --- Context ---
    $ctx = @{
        "Computer"  = $env:COMPUTERNAME
        "User"      = $env:USERNAME
        "OSVersion" = [Environment]::OSVersion.ToString()
        "PowerShell" = $PSVersionTable.PSVersion.ToString()
        "SafeMode(Env)" = ($env:MAINTENANCE_SAFE_MODE -eq '1')
        "HasInternet"   = (Test-IsConnected)
        "HasWinget"     = (Test-IsWingetAvailable)
    }
    $report | Add-ReportSection "Context" $ctx "KeyValue"

    # OS detail
    $os = $null; $osRows = @()
    try { $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue } catch {}
    if ($os) {
        $osRows += [pscustomobject]@{
            Caption   = $os.Caption
            Build     = $os.BuildNumber
            Install   = $os.InstallDate
            LastBoot  = $os.LastBootUpTime
        }
    }
    $report | Add-ReportSection "Operating System" $osRows "Table"

    # Uptime
    $upStr = "Unknown"
    try {
        if ($os -and $os.LastBootUpTime) {
            $u = (Get-Date) - $os.LastBootUpTime
            $upStr = "{0}d {1}h {2}m" -f $u.Days, $u.Hours, $u.Minutes
        }
    } catch {}
    $upKv = @{ "UptimeApprox" = $upStr }
    $report | Add-ReportSection "Uptime" $upKv "KeyValue"

    # Findings
    $findings = @()
    if (-not $ctx["HasInternet"]) {
        $findings += "WARN: No internet connectivity detected. Network tools and online chart rendering may degrade. Next: run Flush DNS, open Wi-Fi report, or check adapter drivers."
    }
    if (-not $ctx["HasWinget"]) {
        $findings += "WARN: Winget not detected. Install/Update tools may fail. Next: install App Installer from the Microsoft Store."
    }

    # --- Pending reboot ---
    $reboot = @{
        "CBS_RebootPending"  = (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")
        "WU_RebootRequired"    = (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")
    }
    $report | Add-ReportSection "Pending Reboot" $reboot "KeyValue"
    if ($reboot["CBS_RebootPending"] -or $reboot["WU_RebootRequired"]) {
        $findings += "INFO: Pending reboot detected. Next: complete a normal reboot before DISM/SFC or Windows Update repair scripts."
    }

    # --- Disk pressure ---
    $drives = @()
    $lowFree = $false
    try {
        Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
            $name = $_.Name
            $root = if ($_.Root) { $_.Root } else { "" }
            $freeB = 0; $usedB = 0; $totB = 0; $pctFree = $null
            try { $freeB = [long]$_.Free } catch {}
            try { $usedB = [long]$_.Used } catch {}
            $totB = $freeB + $usedB
            if ($totB -gt 0) { $pctFree = [math]::Round(100.0 * $freeB / $totB, 1) }
            if ($null -ne $pctFree -and $pctFree -lt 10) { $lowFree = $true }
            if ($name -match '^[A-Z]$' -and $totB -gt 0) {
                if ($freeB/1GB -lt 5) { $lowFree = $true }
            }
            $drives += [pscustomobject]@{
                Name   = $name
                Root   = $root
                FreeGB = [math]::Round($freeB/1GB, 2)
                UsedGB = [math]::Round($usedB/1GB, 2)
                PctFree = if ($null -eq $pctFree) { "N/A" } else { "$pctFree" }
            }
        }
    } catch {}
    if ($drives.Count -gt 0) {
        $report | Add-ReportSection "Drives (Snapshot)" $drives "Table" @{ Label="Name"; Value="FreeGB" }
    }
    if ($lowFree) {
        $findings += "WARN: Low free space on one or more drives (<10% free and/or <5GB on a letter drive). Next: run Deep Disk Cleanup, clear browser cache, then review large files."
    }

    # Security products + Defender
    $avRows = Get-SecurityProductRows
    if ($avRows.Count -gt 0) {
        $report | Add-ReportSection "Security Products (Security Center)" $avRows "Table"
    } else {
        $findings += "INFO: No anti-malware products returned by Security Center query (this can be normal on some SKUs; check Windows Security manually)."
    }

    $def = Get-DefenderStatus
    if ($def.Count -gt 0) {
        $report | Add-ReportSection "Microsoft Defender (Get-MpComputerStatus)" $def "KeyValue"
        if ($def.ContainsKey("RealTimeEnabled") -and -not $def["RealTimeEnabled"]) {
            $findings += "WARN: Defender real-time protection appears disabled. Next: re-enable in Windows Security or investigate policy/AV replacement."
        }
    }

    # BitLocker
    $bl = Get-BitLockerStatusRows
    if ($bl.Count -gt 0) { $report | Add-ReportSection "BitLocker (Volumes)" $bl "Table" }

    # Firewall
    $fw = @()
    try {
        if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
            Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
                $fw += [pscustomobject]@{
                    Name = $_.Name
                    Enabled = $_.Enabled
                }
            }
        }
    } catch {}
    if ($fw.Count -gt 0) {
        $report | Add-ReportSection "Firewall Profiles" $fw "Table"
        if ($fw | Where-Object { $_.Enabled -eq $false }) {
            $findings += "WARN: One or more firewall profiles are disabled. Next: review Windows Security firewall settings and group policy."
        }
    }

    # Critical service snapshot
    $svcNames = "wuauserv","bits","cryptSvc","Dhcp","Dnscache","BFE"
    $svcRows = @()
    foreach ($n in $svcNames) {
        try {
            $svc = Get-Service -Name $n -ErrorAction SilentlyContinue
            if ($svc) {
                $svcRows += [pscustomobject]@{ Service = $n; Status = $svc.Status.ToString(); StartType = $svc.StartType.ToString() }
            }
        } catch {}
    }
    if ($svcRows.Count -gt 0) { $report | Add-ReportSection "Key Services" $svcRows "Table" }

    # Minidumps (last 7 days)
    $mdc = Get-MiniDumpCount
    if ($null -ne $mdc) {
        $report | Add-ReportSection "BSOD Minidumps" (@([pscustomobject]@{ "MinidumpCount_Last7d" = $mdc })) "Table"
        if ($mdc -gt 0) { $findings += "WARN: $mdc minidump(s) in the last 7 days. Next: use Check Stability and review Event System log for bugchecks." }
    }

    # Events: System
    $sev = @()
    try {
        $sev = Get-WinEvent -FilterHashtable @{ LogName='System'; Level=1,2; StartTime=(Get-Date).AddDays(-7) } -ErrorAction SilentlyContinue |
            Select-Object -First 50 TimeCreated, Id, ProviderName, Message
    } catch {}
    $report | Add-ReportSection "System log — Critical/Error (7d, 50 max)" $sev "Table"

    # Events: Application
    $aev = @()
    try {
        $aev = Get-WinEvent -FilterHashtable @{ LogName='Application'; Level=1,2,3; StartTime=(Get-Date).AddDays(-3) } -ErrorAction SilentlyContinue |
            Select-Object -First 30 TimeCreated, Id, ProviderName, Message
    } catch {}
    $report | Add-ReportSection "Application log — Error/Warning (3d, 30 max)" $aev "Table"

    if ($findings.Count -eq 0) { $findings += "PASS: No common blockers detected in this pass." }
    $report | Add-ReportSection "Findings (Summary)" $findings "List"

    Write-Section "Export"
    $outFile = "$env:USERPROFILE\Desktop\DiagnosticsCenter_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile
    Show-Success "Report saved: $outFile"
} catch {
    Show-Error "Diagnostics failed: $($_.Exception.Message)"
}

Pause-If-Interactive
