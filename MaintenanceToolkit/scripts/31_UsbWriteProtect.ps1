. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "USB Write Protection"
Get-SystemSummary
Write-Section "Configuration"

do {
    $choice = Read-Host "Enable USB Write Protection? (Y/N)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "N" }
} until ($choice.ToUpper() -match '^(Y|N)$')

try {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
    if (-not (Test-Path $key)) { New-Item $key -Force | Out-Null }

    if ($choice.ToUpper() -eq "Y") {
        Set-ItemProperty -Path $key -Name "WriteProtect" -Value 1 -Type DWord
        Show-Success "USB Write Protection ENABLED."
    } else {
        Set-ItemProperty -Path $key -Name "WriteProtect" -Value 0 -Type DWord
        Show-Success "USB Write Protection DISABLED."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
