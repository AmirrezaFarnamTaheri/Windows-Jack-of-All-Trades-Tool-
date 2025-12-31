. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Block Website via Hosts File"
$site = Read-Host "Enter domain to block (e.g. facebook.com)"

if ([string]::IsNullOrWhiteSpace($site)) {
    Write-Log "No domain entered." "Red"
    Pause-If-Interactive
    Exit
}

try {
    $hosts = "$env:WINDIR\System32\drivers\etc\hosts"
    if (-not (Test-Path $hosts)) {
        New-Item -Path $hosts -ItemType File -Force | Out-Null
    }

    $entry = "127.0.0.1       $site"
    $content = Get-Content $hosts -Raw
    if ($content -match $site) {
        Write-Log "$site is already blocked." "Yellow"
    } else {
        Add-Content -Path $hosts -Value "`r`n$entry" -Force
        Write-Log "Blocked $site." "Green"
        ipconfig /flushdns | Out-Null
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
