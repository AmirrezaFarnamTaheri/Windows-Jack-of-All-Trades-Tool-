. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Startup Applications Manager"
Get-SystemSummary
Write-Section "Scanning Startup Items"

try {
    $startupItems = @()

    # Helper to check file existence
    function Get-FileStatus ($path) {
        if ([string]::IsNullOrWhiteSpace($path)) { return "Empty" }

        $executablePath = $null
        # Regex to find a path to an .exe, handling quotes and spaces
        if ($path -match '(?i)(".*?\.(?:exe|bat|cmd|vbs)"|[\w\:\\\/ -]+\.(?:exe|bat|cmd|vbs))') {
            $executablePath = $matches[0].Trim('"')
        } else {
            # Fallback for paths without extensions (e.g., shortcuts)
            $executablePath = $path.Trim('"')
        }

        if (Test-Path $executablePath -ErrorAction SilentlyContinue) { return "<span class='status-pass'>Found</span>" }
        return "<span class='status-fail'>MISSING</span>"
    }

    # Registry - Machine Run
    $reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $reg) {
        Get-ItemProperty $reg | Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider, PSDrive, PSIsContainer | Get-Member -MemberType NoteProperty | ForEach-Object {
            $val = (Get-ItemProperty $reg).($_.Name)
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$val; Location="HKLM Run"; Status=(Get-FileStatus $val) }
        }
    }

    # Registry - User Run
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $reg) {
        Get-ItemProperty $reg | Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider, PSDrive, PSIsContainer | Get-Member -MemberType NoteProperty | ForEach-Object {
            $val = (Get-ItemProperty $reg).($_.Name)
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$val; Location="HKCU Run"; Status=(Get-FileStatus $val) }
        }
    }

    # Startup Folder (Common)
    $path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $path) {
        Get-ChildItem $path -File | ForEach-Object {
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$_.FullName; Location="Startup Folder (All Users)"; Status=(Get-FileStatus $_.FullName) }
        }
    }

    # Startup Folder (User)
    $path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $path) {
        Get-ChildItem $path -File | ForEach-Object {
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$_.FullName; Location="Startup Folder (User)"; Status=(Get-FileStatus $_.FullName) }
        }
    }

    if ($startupItems.Count -gt 0) {
        $report = New-Report "Startup Applications Report"
        $report | Add-ReportSection "Startup Items" $startupItems "Table"

        $outFile = "$env:USERPROFILE\Desktop\StartupApps_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Found $($startupItems.Count) startup items. Report exported."
        Invoke-Item $outFile
    } else {
        Show-Success "No startup items found in standard locations."
    }

} catch {
    Show-Error "Error scanning startup items: $($_.Exception.Message)"
}
Pause-If-Interactive
