. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Safe Bloatware Removal"
Write-Log "Scanning for common bloatware..."

# Safer list - removing core apps like Calculator or Photos is risky/annoying.
# We focus on promotional/junk apps.
$BloatwareList = @(
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.3DBuilder",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingFinance",
    "Microsoft.WindowsFeedbackHub",
    "SpotifyAB.SpotifyMusic"
)

try {
    $removedCount = 0
    foreach ($App in $BloatwareList) {
        $Package = Get-AppxPackage -Name $App -ErrorAction SilentlyContinue
        if ($Package) {
            Write-Log "Removing $App..." "Yellow"
            try {
                Get-AppxPackage -Name $App | Remove-AppxPackage -ErrorAction Stop
                Write-Log "Success: $App removed." "Green"
                $removedCount++
            } catch {
                Write-Log "Failed to remove ${App}: $($_.Exception.Message)" "Red"
            }
        } else {
            # Verbose logging only, to keep UI clean
            # Write-Log "$App not found (already clean)." "Gray"
        }
    }

    if ($removedCount -eq 0) {
        Write-Log "System appears clean. No common bloatware found." "Green"
    } else {
        Write-Log "Removal Complete. $removedCount apps removed." "Cyan"
    }

} catch {
    Write-Log "Error during debloat process: $($_.Exception.Message)" "Red" "ERROR"
}

Write-Log "--- Safe Debloat Finished ---" "White"
Pause-If-Interactive
