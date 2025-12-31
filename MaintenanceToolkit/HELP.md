# System Maintenance Toolkit - Help & Documentation

## Overview
This toolkit provides a set of automated scripts to maintain, repair, and optimize Windows systems. It includes both a Command-Line Interface (CLI) and a Graphical User Interface (GUI).

## Categories

### 1. CLEAN
Scripts focused on freeing up disk space and removing unnecessary files.
- **Deep Disk Cleanup:** Runs the Windows Disk Cleanup utility with all options enabled.
- **Nuclear Temp Clean:** Aggressively deletes temp files from all users (Use with caution).
- **Safe Debloat:** Removes pre-installed bloatware that is safe to remove.

### 2. REPAIR
Scripts to fix common Windows issues.
- **System Repair (SFC/DISM):** The standard "first step" for fixing Windows corruption.
- **Reset Windows Update:** Clears the `SoftwareDistribution` folder to fix stuck updates.
- **Fix Printer:** Restarts the Spooler service to clear stuck print jobs.

### 3. HARDWARE
Diagnostics and information tools.
- **Battery Health Report:** Generates an HTML report about battery capacity and usage.
- **Check Disk Health:** Uses SMART data to predict drive failure.
- **CPU Stress Test:** Puts the CPU under load to test cooling and stability.

### 4. NETWORK
Tools to optimize and troubleshoot internet connections.
- **Network Reset:** Flushes DNS cache and resets the TCP/IP stack.
- **Wi-Fi Passwords:** Recovers saved Wi-Fi passwords.
- **DNS Benchmark:** Tests response times of major DNS providers.

### 5. SECURITY
Tools to enhance privacy and security.
- **Privacy Hardening:** Disables common telemetry and tracking features.
- **Verify File Hash:** specific file integrity check.
- **Secure Delete:** Overwrites files multiple times to prevent recovery.

### 6. UTILITIES
General purpose tools.
- **Update All Software:** Uses `winget` to update all installed applications.
- **God Mode:** Creates a folder with shortcuts to all Windows administrative settings.
- **Process Freezer:** Temporarily suspends resource-heavy processes.

## Troubleshooting
- **Admin Rights:** All scripts require Administrator privileges. Right-click and "Run as Administrator".
- **Execution Policy:** The toolkit attempts to bypass execution policy, but if scripts fail, run `Set-ExecutionPolicy RemoteSigned -Scope Process` in PowerShell.
- **Antivirus:** Some "debloat" or "password recovery" scripts may be flagged by antivirus software. This is a false positive.

## About
Version: 65
License: MIT
