. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clear Browser Caches"
Get-SystemSummary

# This is a destructive action (closes apps, deletes files)
Assert-Destructive "Clearing browser cache requires closing browsers and deleting files."

Write-Section "Preparation"
Write-Log "This will close all browsers (Chrome, Edge, Firefox)." "Yellow"
Write-Log "Only CACHE files will be deleted. History/Cookies/Passwords are safe." "White"

if (-not [Console]::IsInputRedirected) {
    $confirm = Read-Host "Type 'Y' to continue"
    if ($confirm.Trim() -notmatch '^[Yy]$') {
        Write-Log "Cancelled by user."
        Exit
    }
}

function Close-And-Clear ($ProcessName, $Name, $CachePaths) {
    try {
        if (Get-Process $ProcessName -ErrorAction SilentlyContinue) {
            Write-Log "Closing $Name..." "Yellow"
            Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }

        $cleared = $false
        foreach ($path in $CachePaths) {
            if (Test-Path $path) {
                Write-Log "Clearing $Name cache at: $path" "Gray"
                Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
                $cleared = $true
            }
        }

        if ($cleared) { Show-Success "$Name Cache Cleared." }
        else { Write-Log "$Name cache not found or already empty." "DarkGray" }

    } catch {
        Show-Error "Failed to clear $Name: $($_.Exception.Message)"
    }
}

try {
    # 1. Chrome
    Close-And-Clear "chrome" "Google Chrome" @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache", "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache")

    # 2. Edge
    Close-And-Clear "msedge" "Microsoft Edge" @("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache")

    # 3. Firefox
    # Firefox profiles are dynamic
    $ffPaths = @()
    $ffRoot = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffRoot) {
        Get-ChildItem $ffRoot -Directory | ForEach-Object {
            $ffPaths += "$($_.FullName)\cache2"
            $ffPaths += "$($_.FullName)\startupCache"
        }
    }
    Close-And-Clear "firefox" "Firefox" $ffPaths

    # 4. Brave (Optional addition)
    Close-And-Clear "brave" "Brave" @("$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache")

} catch {
    Show-Error "Global Error: $($_.Exception.Message)"
}

Pause-If-Interactive
