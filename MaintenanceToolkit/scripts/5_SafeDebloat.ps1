. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Safe Bloatware Removal"
Get-SystemSummary

Assert-Destructive "This script removes pre-installed Windows applications."

Write-Section "Configuration"
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

Write-Log "Targeting $( $BloatwareList.Count ) known bloatware apps." "Gray"

try {
    Write-Section "Scanning & Removing"
    $removedCount = 0
    $foundCount = 0

    foreach ($App in $BloatwareList) {
        $Package = Get-AppxPackage -Name $App -ErrorAction SilentlyContinue

        if ($Package) {
            $foundCount++
            Write-Log "Found: $($Package.Name)" "Yellow"

            try {
                # Remove for Current User
                Get-AppxPackage -Name $App | Remove-AppxPackage -ErrorAction Stop

                # Optional: Remove Provisioned Package (prevents return on new user)
                # Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $App | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

                Show-Success "Removed: $App"
                $removedCount++
            } catch {
                Show-Error "Failed to remove ${App}: $($_.Exception.Message)"
            }
        }
    }

    Write-Section "Summary"
    if ($foundCount -eq 0) {
        Show-Success "System appears clean. No target apps found."
    } else {
        Show-Success "Cleaned $removedCount / $foundCount apps."
    }

} catch {
    Show-Error "Error during debloat process: $($_.Exception.Message)"
}

Pause-If-Interactive
