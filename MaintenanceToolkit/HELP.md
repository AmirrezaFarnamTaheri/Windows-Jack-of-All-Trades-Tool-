# System Maintenance Toolkit - User Guide

## Introduction
The **System Maintenance Toolkit** is a powerful, modular utility designed to help IT professionals and power users maintain, optimize, and troubleshoot Windows systems. It combines a robust library of PowerShell scripts with a modern, responsive C# GUI.

## 🚀 Key Features
*   **Modular Architecture:** Over 80 specialized scripts covering cleaning, repair, network, and security.
*   **Modern UI:** Responsive dashboard with dark mode support.
*   **HTML Reporting:** Generates detailed, professional HTML reports for audits, updates, and system health.
*   **Batch Mode:** Run multiple scripts sequentially with a single click.
*   **Safety First:** Destructive scripts require confirmation; "Safe Mode" defaults are prioritized.

## 🛠️ Usage

### Dashboard
The **Dashboard** provides an at-a-glance view of your system:
*   **System Specs:** OS Version, CPU, RAM usage, and Disk Space.
*   **Status Indicators:** Alerts you to "Pending Reboot" states.
*   **Quick Actions:** One-click access to common maintenance tasks.

### Running Scripts
1.  Navigate to a category using the sidebar.
2.  **Single Run:** Double-click a card or click the **RUN** button.
3.  **Batch Run:**
    *   Toggle **Batch Mode** (Top Right).
    *   Select multiple scripts using the checkboxes.
    *   Click **RUN BATCH** to execute them in order.

### Favorites
Right-click the "Star" icon on any script card to add it to your **Favorites** tab for quick access.

### Search
Use the search bar (Shortcut: `Ctrl+F`) to instantly filter scripts by name or description.

---

## 🌟 Best Practices for Routine Maintenance
To keep your system running optimally, consider this schedule:

### Weekly
1.  **Dashboard Check:** Look for "Pending Reboot" flags or low disk space.
2.  **Clean:** Run *Deep Disk Cleanup* and *Clear Browser Cache*.
3.  **Update:** Run *Update All Software* (Winget) and check *Windows Update History*.

### Monthly
1.  **Health Check:** Run *Disk Health Check* and *Battery Report*.
2.  **Security:** Review *Startup Manager* and *Audit Scheduled Tasks* for unwanted persistence.
3.  **Repair:** Run *System Repair (SFC/DISM)* to ensure OS integrity.

### Quarterly / As Needed
1.  **Privacy:** Run *Privacy Hardening* after major Windows feature updates.
2.  **Backup:** Run *Backup Drivers* and *Export Installed Apps* for documentation.

---

## 📂 Script Categories

### 1. 🧹 CLEAN
*Tools to free up disk space and remove clutter.*
*   **Install Cleaners:** Installs trusted tools (BleachBit) via Winget.
*   **Deep Disk Cleanup:** Automates Windows Disk Cleanup with advanced flags.
*   **Clear Browser Cache:** Wipes caches for Chrome, Edge, and Firefox.
*   **Nuclear Temp Clean:** Aggressively removes temporary files (Use with caution).
*   **Safe Debloat:** Removes non-essential pre-installed apps safely.
*   **Find Duplicates:** Identifies duplicate files by content hash.

### 2. 🔧 REPAIR
*Fixes for common Windows issues and corruptions.*
*   **System Repair:** Runs DISM and SFC to repair system files.
*   **Reset Windows Update:** Clears the update cache to fix download errors.
*   **Fix Printer:** Restarts the print spooler to clear stuck jobs.
*   **Time Sync Fix:** Forces a resync with NTP servers.
*   **Restore Classic Menu:** Restores the Windows 10 context menu on Windows 11.

### 3. 💻 HARDWARE
*Diagnostics and hardware information.*
*   **Disk Health Check:** HTML report of S.M.A.R.T. status, SSD wear, and temps.
*   **Battery Report:** Generates a detailed battery health history.
*   **Driver Audit:** Lists third-party drivers in a structured HTML report.
*   **CPU Stress Test:** simple mathematical load test for stability.
*   **SSD Trim:** Forces a re-trim operation on SSDs.

### 4. 🌐 NETWORK
*Optimization and troubleshooting for connectivity.*
*   **Network Reset:** Flushes DNS, ARP, and resets the IP stack.
*   **DNS Benchmark:** Tests response times of Google, Cloudflare, and Quad9.
*   **Wi-Fi Scanner:** Lists nearby networks and signal strength.
*   **Firewall Audit:** HTML report flagging risky "Allow All" inbound rules.
*   **Process Connections:** Maps active network connections to applications.

### 5. 🛡 SECURITY
*Privacy and security hardening.*
*   **Audit Scheduled Tasks:** HTML report highlighting suspicious or root-path tasks.
*   **Startup Manager:** HTML report validating startup items (flags MISSING files).
*   **User Login History:** Audits recent interactive logons.
*   **Secure Delete:** Wipes files to prevent recovery.
*   **Panic Button:** Emergency privacy mode (Mute, Clear Clipboard, Minimize).

### 6. 🧰 UTILS
*General purpose utilities.*
*   **Export Installed Apps:** Generates a full HTML inventory of installed software.
*   **Windows Update History:** HTML report of recent update success/failure rates.
*   **Sleep Timer:** Schedules a system shutdown.
*   **Toggle Dark Mode:** Switches Windows and App theme.

---

## ❓ Troubleshooting

### "Script execution failed"
*   **Execution Policy:** Ensure you have permission to run scripts. The tool attempts to bypass this, but GPO may block it.
*   **Antivirus:** Some scripts (e.g., WiFi Password Recovery) may be flagged as "HackTools". These are false positives; the code is open source and local-only.

### "UI is frozen"
*   Heavy operations (like `chkdsk` log reading or deep cleaning) may pause the UI briefly. Please wait for the progress bar to complete.

### "Report not opening"
*   Reports are saved to the Desktop or Temp folder. Ensure you have a default browser associated with `.html` files.

---

## 📜 License
MIT License. Free for personal and commercial use.
