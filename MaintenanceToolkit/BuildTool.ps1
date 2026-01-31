Write-Host "--- Building System Maintenance GUI (v2.0) ---" -ForegroundColor Cyan

# Define paths
$SourceDir = Join-Path $PSScriptRoot "source"
$OutputFile = Join-Path $PSScriptRoot "MaintenanceTool.exe"
$ManifestFile = Join-Path $PSScriptRoot "app.manifest"

# Find C# Sources
$SourceFiles = Get-ChildItem -Path $SourceDir -Filter "*.cs" -Recurse | Select-Object -ExpandProperty FullName

if ($SourceFiles.Count -eq 0) {
    Write-Host "Error: No .cs files found in $SourceDir" -ForegroundColor Red
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}

Write-Host "Found $($SourceFiles.Count) source files." -ForegroundColor Gray

# Find the C# Compiler (csc.exe)
$CSC = Get-ChildItem -Path "$env:windir\Microsoft.NET\Framework64\v4*" -Filter "csc.exe" -Recurse | Select-Object -Last 1

if (-not $CSC) {
    Write-Host "Error: Could not find C# Compiler (CSC.exe)." -ForegroundColor Red
    if (-not [Console]::IsInputRedirected) { Pause }
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
    "/r:System.Management.dll",
    "/r:System.dll",
    "/r:System.Core.dll",
    "/r:System.Data.dll",
    "/r:System.Xml.dll",
    "/r:System.Xml.Linq.dll"
)

# Collect Embedded Resources (Scripts)
$ScriptDir = Join-Path $PSScriptRoot "scripts"
if (Test-Path $ScriptDir) {
    Get-ChildItem -Path $ScriptDir -Recurse -File | ForEach-Object {
        # Calculate relative path (e.g. scripts/lib/Common.ps1)
        $RelPath = $_.FullName.Substring($ScriptDir.Length + 1).Replace("\", "/")
        $ResName = "scripts/$RelPath"
        $BuildArgs += "/resource:`"$($_.FullName)`",$ResName"
        Write-Host "Embedding: $ResName" -ForegroundColor Gray
    }
}

# Embed HELP.md
$HelpFile = Join-Path $PSScriptRoot "HELP.md"
if (Test-Path $HelpFile) {
    $BuildArgs += "/resource:`"$HelpFile`",HELP.md"
    Write-Host "Embedding: HELP.md" -ForegroundColor Gray
}

# Add Source Files (quoted)
foreach ($file in $SourceFiles) {
    $BuildArgs += "`"$file`""
}

# Compile Command
Write-Host "Compiling..." -ForegroundColor Cyan
try {
    # Using Start-Process to handle quoting arguments properly
    $p = Start-Process -FilePath $CSC.FullName -ArgumentList $BuildArgs -PassThru -NoNewWindow -Wait

    if ($p.ExitCode -eq 0 -and (Test-Path $OutputFile)) {
        Write-Host "`nSUCCESS! Application created: $OutputFile" -ForegroundColor Green
        Write-Host "Remember to Right-Click > Run as Administrator" -ForegroundColor Magenta
    } else {
        Write-Host "`nCompilation Failed. Exit Code: $($p.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "Error executing compiler: $_" -ForegroundColor Red
}

if (-not [Console]::IsInputRedirected) { Pause }
