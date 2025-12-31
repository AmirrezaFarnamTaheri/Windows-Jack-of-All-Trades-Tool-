. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "USB Write Protection"
$choice = Read-Host "Enable Write Protect (Y/N)?"

try {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
    if (-not (Test-Path $key)) { New-Item $key -Force | Out-Null }

    if ($choice -eq "Y") {
        Set-ItemProperty -Path $key -Name "WriteProtect" -Value 1 -Type DWord
        Write-Log "USB Write Protection ENABLED." "Green"
    } else {
        Set-ItemProperty -Path $key -Name "WriteProtect" -Value 0 -Type DWord
        Write-Log "USB Write Protection DISABLED." "Green"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
