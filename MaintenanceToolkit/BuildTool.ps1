Write-Host "--- Building System Maintenance GUI ---" -ForegroundColor Cyan

# Define filenames
$SourceFile = ".\source\MaintenanceTool.cs"
$OutputFile = ".\MaintenanceTool.exe"
$ManifestFile = ".\app.manifest"

# Check if source exists
if (-not (Test-Path $SourceFile)) {
    Write-Host "Error: Could not find $SourceFile" -ForegroundColor Red
    Pause
    Exit
}

# Find the C# Compiler (csc.exe)
$CSC = Get-ChildItem -Path "$env:windir\Microsoft.NET\Framework64\v4*" -Filter "csc.exe" -Recurse | Select-Object -Last 1

if (-not $CSC) {
    Write-Host "Error: Could not find C# Compiler." -ForegroundColor Red
    Pause
    Exit
}

Write-Host "Using Compiler: $($CSC.FullName)" -ForegroundColor DarkGray

# Collect Build Arguments
$BuildArgs = @(
    "/target:winexe",
    "/out:$OutputFile",
    "/win32manifest:$ManifestFile",
    "/r:System.Windows.Forms.dll",
    "/r:System.Drawing.dll",
    "/r:System.Management.dll"
)

# Collect Embedded Resources (Scripts)
$ScriptDir = Join-Path $PSScriptRoot "scripts"
if (Test-Path $ScriptDir) {
    Get-ChildItem -Path $ScriptDir -Recurse -File | ForEach-Object {
        # Calculate relative path (e.g. scripts/lib/Common.ps1)
        # We need to preserve the folder structure in the resource name
        $RelPath = $_.FullName.Substring($ScriptDir.Length + 1).Replace("\", "/")
        $ResName = "scripts/$RelPath"
        $BuildArgs += "/resource:$($_.FullName),$ResName"
        Write-Host "Embedding: $ResName" -ForegroundColor Gray
    }
}

# Embed HELP.md
$HelpFile = Join-Path $PSScriptRoot "HELP.md"
if (Test-Path $HelpFile) {
    $BuildArgs += "/resource:$HelpFile,HELP.md"
    Write-Host "Embedding: HELP.md" -ForegroundColor Gray
}

# Add Source File
$BuildArgs += $SourceFile

# Compile Command
& $CSC.FullName @BuildArgs

if (Test-Path $OutputFile) {
    Write-Host "`nSUCCESS! Application created: $OutputFile" -ForegroundColor Green
    Write-Host "You can now delete the .cs and .ps1 files if you want." -ForegroundColor Yellow
    Write-Host "Remember to Right-Click > Run as Administrator" -ForegroundColor Magenta
} else {
    Write-Host "Compilation Failed." -ForegroundColor Red
}

Pause
