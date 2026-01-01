. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Startup Applications Manager"
Get-SystemSummary
Write-Section "Scanning Startup Items"

try {
    $startupItems = @()

    # Registry - Machine Run
    $reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $reg) {
        $properties = Get-ItemProperty -Path $reg
        $properties.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' -and $_.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider', 'PSIsContainer') } | ForEach-Object {
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$_.Value; Location="HKLM Run" }
        }
    }

    # Registry - User Run
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $reg) {
        $properties = Get-ItemProperty -Path $reg
        $properties.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' -and $_.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider', 'PSIsContainer') } | ForEach-Object {
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$_.Value; Location="HKCU Run" }
        }
    }

    # Startup Folder (Common)
    $path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $path) {
        Get-ChildItem $path -File | ForEach-Object {
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$_.FullName; Location="Startup Folder (All Users)" }
        }
    }

    # Startup Folder (User)
    $path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path $path) {
        Get-ChildItem $path -File | ForEach-Object {
            $startupItems += [PSCustomObject]@{ Name=$_.Name; Command=$_.FullName; Location="Startup Folder (User)" }
        }
    }

    if ($startupItems.Count -gt 0) {
        $startupItems | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White
        Show-Success "Found $($startupItems.Count) startup items."
        Write-Log "Note: To disable items, use Task Manager -> Startup." "Yellow"
    } else {
        Show-Success "No startup items found in standard locations."
    }

} catch {
    Show-Error "Error scanning startup items: $($_.Exception.Message)"
}
Pause-If-Interactive
