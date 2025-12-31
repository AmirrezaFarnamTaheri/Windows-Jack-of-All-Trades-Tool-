. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Applying Privacy & Telemetry Tweaks"
Write-Log "Warning: Modifying Registry settings for privacy." "Yellow"

# Helper to set reg safely
function Set-RegVal ($Path, $Name, $Value, $Type="DWord") {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Log "Set $Name = $Value at $Path" "Gray"
}

try {
    # Only backup if keys exist to avoid errors
    if (Test-Path "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection") {
        Backup-RegistryKey "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    }
    if (Test-Path "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo") {
        Backup-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    }

    # 1. Advertising ID
    Write-Log "Disabling Advertising ID..."
    Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0

    # 2. Telemetry (AllowTelemetry = 0 [Security] or 1 [Basic])
    # Note: 0 works on Enterprise only, Home/Pro ignore it often, but we set it.
    Write-Log "Restricting Telemetry..."
    Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 1

    # 3. Tailored Experiences
    Write-Log "Disabling Tailored Experiences..."
    Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" 1

    # 4. Cortana
    Write-Log "Restricting Cortana..."
    Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0

    # 5. Location Tracking (Optional - risky if user uses Maps)
    # We skip this to be safe, or just disable "Location History"
    # Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny"

    # 6. Wifi Sense (Prevent sharing networks)
    # This feature is largely removed in modern Win10/11 but good cleanup.
    # Set-RegVal "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" 0

    Write-Log "--- Privacy Settings Applied ---" "Green"
    Write-Log "A restart is recommended for all policies to take effect." "Cyan"

} catch {
    Write-Log "Error applying privacy settings: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
