. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Applying Privacy & Telemetry Tweaks"
Get-SystemSummary
Write-Section "Warning"
Write-Log "Modifying Registry settings for privacy." "Yellow"

try {
    Write-Section "Backing up Registry"
    # Only backup if keys exist to avoid errors
    if (Test-Path "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection") {
        Backup-RegistryKey "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    }
    if (Test-Path "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo") {
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    }

    Write-Section "Applying Tweaks"

    # 1. Advertising ID
    Write-Log "Disabling Advertising ID..."
    Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord

    # 2. Telemetry (AllowTelemetry = 0 [Security] or 1 [Basic])
    # Note: 0 works on Enterprise only, Home/Pro ignore it often, but we set it.
    Write-Log "Restricting Telemetry..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 1 -Type DWord

    # 3. Tailored Experiences
    Write-Log "Disabling Tailored Experiences..."
    Set-RegKey -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -Type DWord

    # 4. Cortana
    Write-Log "Restricting Cortana..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord

    # 5. Disable Web Search in Start Menu
    Write-Log "Disabling Bing Search in Start Menu..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1 -Type DWord
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord

    # 6. Disable Windows Tips (Soft Landing)
    Write-Log "Disabling Windows Tips..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value 1 -Type DWord

    # 7. Disable Windows Consumer Features (Spotlight/Candy Crush install)
    Write-Log "Disabling Windows Consumer Features..."
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord

    # 8. Disable Game DVR (Performance)
    Write-Log "Disabling Game DVR (Background Recording)..."
    Set-RegKey -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
    Set-RegKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord

    Write-Section "Complete"
    Show-Success "Privacy settings applied."
    Write-Log "A restart is recommended for all policies to take effect." "Cyan"

} catch {
    Show-Error "Error applying privacy settings: $($_.Exception.Message)"
}

Pause-If-Interactive
