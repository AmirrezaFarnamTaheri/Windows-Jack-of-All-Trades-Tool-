. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Privacy Hardening"
Get-SystemSummary

Assert-Destructive "This script modifies Registry policies to restrict Telemetry and Tracking."

Write-Section "Backing up Registry"
# Only backup if keys exist to avoid errors
if (Test-Path "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection") {
    Backup-RegistryKey "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
}

try {
    Write-Section "Applying Policies"

    # 1. Advertising ID
    Write-Log "Disabling Advertising ID..."
    Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force

    # 2. Telemetry (AllowTelemetry = 0 [Security] or 1 [Basic])
    Write-Log "Restricting Telemetry..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 1 -Type DWord -Force

    # 3. Tailored Experiences
    Write-Log "Disabling Tailored Experiences..."
    Set-RegKey -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -Type DWord -Force

    # 4. Cortana & Search
    Write-Log "Restricting Cortana & Bing Search..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -Force
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -Type DWord -Force
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force

    # 5. Tips & Suggestions
    Write-Log "Disabling Windows Tips & Consumer Features..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value 1 -Type DWord -Force
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force

    # 6. Location Tracking
    Write-Log "Disabling Location Tracking..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Type DWord -Force

    Show-Success "Privacy hardening applied."
    Write-Log "A reboot is required for Group Policies to take full effect." "Magenta"

} catch {
    Show-Error "Error applying policies: $($_.Exception.Message)"
}

Pause-If-Interactive
