# Ultimate System Maintenance Toolkit

## Overview
This toolkit contains 65 specialized PowerShell scripts and a Modern C# GUI Application to manage the health, security, and performance of your Windows PC.

## Structure
- **scripts/**: Contains all 65 modular scripts.
- **source/**: Contains the C# source code for the GUI.
- **BuildTool.ps1**: A script to compile the C# application without needing Visual Studio.
- **MaintenanceTool.exe**: The final application (after building).
- **HELP.md**: Detailed documentation of all scripts and categories.

## How to Build the App
1. You do **not** need to install Visual Studio or any development tools.
2. Simply double-click `BuildTool.ps1` (or Right-Click -> Run with PowerShell).
3. It will generate `MaintenanceTool.exe` in this folder.

Alternatively, the GitHub Actions workflow included in `.github/workflows/build-release.yml` automatically builds the application on push.

## How to Use
1. Right-Click `MaintenanceTool.exe` and select **Run as Administrator**.
2. Navigate the tabs (Clean, Repair, Hardware, Network, Security, Utils).
3. Click a button to execute the corresponding script.
4. View the real-time logs at the bottom.
5. Use the "Toggle Dark Mode" button for a dark theme (preference is saved).
6. Use the "Help / About" button for more information.

## Features
- **Modern GUI:** Clean, responsive interface with Dark Mode.
- **Progress Tracking:** Real-time logging and indeterminate progress bar.
- **Safety First:** Destructive actions require confirmation.
- **Search:** Quickly find tools by name or description.
- **Cancellation:** Stop long-running non-interactive scripts.
- **CLI Mode:** Includes `_MasterMenu.ps1` for command-line usage.

## Safety
- All scripts are open-source (you can open the `.ps1` files in Notepad to read them).
- Always create a **Restore Point** (Tab: Repair -> Create Restore Point) before running aggressive cleaning tools.

## Requirements
- Windows 10 or Windows 11.
- PowerShell 5.1 (Built-in) or newer.
- .NET Framework 4.5+ (Built-in).
