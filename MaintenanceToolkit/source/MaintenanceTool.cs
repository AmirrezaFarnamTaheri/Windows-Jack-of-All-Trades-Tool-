using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Management;
using System.Security.Principal;
using System.Windows.Forms;
using System.Threading;
using System.Threading.Tasks;
using System.Text;

namespace SystemMaintenance
{
    public class MainForm : Form
    {
        // UI Controls
        private TextBox txtLog;
        private TabControl tabs;
        private StatusStrip statusStrip;
        private ToolStripStatusLabel statusLabel;
        private ToolStripProgressBar progressBar;
        private List<Button> allButtons = new List<Button>();
        private TextBox txtSearch;
        private Panel descPanel;
        private Label lblDescTitle;
        private Label lblDescText;
        private SplitContainer splitContainer;
        private Button btnCancel;
        private Button btnDarkMode;

        // Batch Mode Controls
        private CheckBox chkBatchMode;
        private Button btnRunBatch;
        private Button btnSelectAll;
        private Button btnSelectNone;

        // Favorites
        private HashSet<string> favoriteScripts = new HashSet<string>();
        private const string FAVORITES_FILE = "favorites.cfg";

        // State
        private bool isDarkMode = false;
        private bool isBatchMode = false;
        private Process currentProcess;
        private object processLock = new object();
        private const string SETTINGS_FILE = "settings.cfg";
        private CancellationTokenSource batchCts;

        public MainForm()
        {
            LoadSettings();

            // --- UI Setup ---
            this.Text = "Ultimate System Maintenance Toolkit";
            this.Size = new Size(1200, 850);
            this.MinimumSize = new Size(800, 600);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Icon = SystemIcons.Shield;
            this.Font = new Font("Segoe UI", 9F, FontStyle.Regular);

            // Check Admin
            if (!IsAdministrator())
            {
                MessageBox.Show("Please restart this application as Administrator for full functionality.", "Admin Rights Needed", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }

            // --- Header (System Info & Search) ---
            Panel headerPanel = new Panel { Dock = DockStyle.Top, Height = 95, Padding = new Padding(15) };

            Label lblSysInfo = new Label {
                Text = GetDetailedSystemInfo(),
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft,
                Font = new Font("Segoe UI", 10F, FontStyle.Bold),
                AutoEllipsis = true
            };

            // Right Header Container
            Panel rightHeader = new Panel { Dock = DockStyle.Right, Width = 380 };

            // Search Box
            GroupBox searchGroup = new GroupBox { Text = "Search Tools", Dock = DockStyle.Top, Height = 50 };
            txtSearch = new TextBox { Dock = DockStyle.Fill, BorderStyle = BorderStyle.None, Font = new Font("Segoe UI", 11F), TabIndex = 0 };
            txtSearch.TextChanged += TxtSearch_TextChanged;

            Button btnClearSearch = new Button { Text = "X", Dock = DockStyle.Right, Width = 25, FlatStyle = FlatStyle.Flat, BackColor = Color.Transparent, ForeColor = Color.Gray };
            btnClearSearch.FlatAppearance.BorderSize = 0;
            btnClearSearch.Click += (s, e) => txtSearch.Text = "";

            searchGroup.Controls.Add(txtSearch);
            searchGroup.Controls.Add(btnClearSearch);

            txtSearch.Location = new Point(5, 18);
            txtSearch.Width = 345;
            txtSearch.Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Top;

            // Batch Mode Controls
            chkBatchMode = new CheckBox { Text = "Batch Mode", Dock = DockStyle.Right, Width = 100, Appearance = Appearance.Button, TextAlign = ContentAlignment.MiddleCenter, FlatStyle = FlatStyle.Flat, TabIndex = 2 };
            chkBatchMode.CheckedChanged += ChkBatchMode_CheckedChanged;

            btnSelectAll = new Button { Text = "All", Dock = DockStyle.Right, Width = 40, FlatStyle = FlatStyle.Flat, Visible = false, Font = new Font("Segoe UI", 8F) };
            btnSelectAll.Click += (s, e) => SetAllBatchSelection(true);

            btnSelectNone = new Button { Text = "None", Dock = DockStyle.Right, Width = 40, FlatStyle = FlatStyle.Flat, Visible = false, Font = new Font("Segoe UI", 8F) };
            btnSelectNone.Click += (s, e) => SetAllBatchSelection(false);

            // Help Button
            Button btnHelp = new Button { Text = "Help", Dock = DockStyle.Left, Width = 60, FlatStyle = FlatStyle.Flat, TabIndex = 3 };
            btnHelp.Click += (s, e) => ShowHelp();

            Panel toolBar = new Panel { Dock = DockStyle.Bottom, Height = 30 };
            toolBar.Controls.Add(btnSelectNone);
            toolBar.Controls.Add(btnSelectAll);
            toolBar.Controls.Add(chkBatchMode);
            toolBar.Controls.Add(btnHelp);

            rightHeader.Controls.Add(searchGroup);
            rightHeader.Controls.Add(new Panel { Dock = DockStyle.Top, Height = 5 }); // Spacer
            rightHeader.Controls.Add(toolBar);

            headerPanel.Controls.Add(lblSysInfo);
            headerPanel.Controls.Add(rightHeader);

            // --- Main Split Container ---
            splitContainer = new SplitContainer { Dock = DockStyle.Fill, Orientation = Orientation.Horizontal, SplitterDistance = 500, FixedPanel = FixedPanel.Panel2 };

            // --- Tabs (Top Half) ---
            tabs = new TabControl { Dock = DockStyle.Fill, Padding = new Point(12, 6), ItemSize = new Size(100, 30), TabIndex = 1 };
            BuildTabs(); // Now includes Favorites tab
            tabs.SelectedIndexChanged += (s, e) => FilterButtons(txtSearch.Text);

            // --- Description Panel ---
            descPanel = new Panel { Dock = DockStyle.Bottom, Height = 80, Padding = new Padding(10), BorderStyle = BorderStyle.FixedSingle };
            lblDescTitle = new Label { Dock = DockStyle.Top, Height = 25, Font = new Font("Segoe UI", 11F, FontStyle.Bold), Text = "Hover over a tool to see details." };
            lblDescText = new Label { Dock = DockStyle.Fill, Text = "", Font = new Font("Segoe UI", 9.5F) };

            btnRunBatch = new Button { Text = "RUN SELECTED (0)", Dock = DockStyle.Right, Width = 150, BackColor = Color.SeaGreen, ForeColor = Color.White, Visible = false, FlatStyle = FlatStyle.Flat, Font = new Font("Segoe UI", 9F, FontStyle.Bold), TabIndex = 4 };
            btnRunBatch.Click += BtnRunBatch_Click;

            descPanel.Controls.Add(btnRunBatch);
            descPanel.Controls.Add(lblDescText);
            descPanel.Controls.Add(lblDescTitle);

            Panel topContainer = new Panel { Dock = DockStyle.Fill };
            topContainer.Controls.Add(tabs);
            topContainer.Controls.Add(descPanel);
            splitContainer.Panel1.Controls.Add(topContainer);

            // --- Logs (Bottom Half) ---
            GroupBox grpLog = new GroupBox { Text = "Activity Log", Dock = DockStyle.Fill, Padding = new Padding(10) };

            Panel logControls = new Panel { Dock = DockStyle.Right, Width = 100 };
            btnCancel = new Button { Text = "Cancel", Dock = DockStyle.Top, Height = 40, BackColor = Color.Firebrick, ForeColor = Color.White, Visible = false, FlatStyle = FlatStyle.Flat, TabIndex = 6 };
            btnCancel.Click += BtnCancel_Click;

            Button btnSaveLog = new Button { Text = "Save Log", Dock = DockStyle.Bottom, Height = 30, FlatStyle = FlatStyle.Flat };
            btnSaveLog.Click += (s, e) => SaveLogToFile();

            logControls.Controls.Add(btnCancel);
            logControls.Controls.Add(new Panel { Dock = DockStyle.Top, Height = 5 });
            logControls.Controls.Add(btnSaveLog);

            txtLog = new TextBox {
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.LimeGreen,
                Font = new Font("Consolas", 10),
                TabIndex = 5
            };

            grpLog.Controls.Add(txtLog);
            grpLog.Controls.Add(logControls);
            splitContainer.Panel2.Controls.Add(grpLog);

            // --- Status Strip ---
            statusStrip = new StatusStrip();
            statusLabel = new ToolStripStatusLabel("Ready") { Spring = true, TextAlign = ContentAlignment.MiddleLeft };
            progressBar = new ToolStripProgressBar { Visible = false, Style = ProgressBarStyle.Marquee };
            statusStrip.Items.Add(statusLabel);
            statusStrip.Items.Add(progressBar);

            // Dark Mode Toggle
            btnDarkMode = new Button { Text = "Toggle Dark Mode", Dock = DockStyle.Bottom, Height = 35, FlatStyle = FlatStyle.Flat };
            btnDarkMode.Click += (s, e) => ToggleTheme();

            // Assemble Form
            this.Controls.Add(splitContainer);
            this.Controls.Add(headerPanel);
            this.Controls.Add(btnDarkMode);
            this.Controls.Add(statusStrip);

            ApplyTheme();
        }

        private void LoadSettings()
        {
            try
            {
                if (File.Exists(SETTINGS_FILE))
                {
                    string content = File.ReadAllText(SETTINGS_FILE);
                    isDarkMode = content.Contains("DarkMode=True");
                }
                if (File.Exists(FAVORITES_FILE))
                {
                    favoriteScripts = new HashSet<string>(File.ReadAllLines(FAVORITES_FILE).Where(l => !string.IsNullOrWhiteSpace(l)));
                }
            }
            catch { /* Ignore errors */ }
        }

        private void SaveSettings()
        {
            try
            {
                File.WriteAllText(SETTINGS_FILE, string.Format("DarkMode={0}", isDarkMode));
                File.WriteAllLines(FAVORITES_FILE, favoriteScripts);
            }
            catch { /* Ignore */ }
        }

        private void ShowHelp()
        {
            string helpText =
                "Ultimate System Maintenance Toolkit\n" +
                "Version: 67 (Refined)\n\n" +
                "FEATURES:\n" +
                "- FAVORITES: Right-click any script to Add/Remove from Favorites tab.\n" +
                "- BATCH MODE: Select multiple scripts to run sequentially.\n" +
                "- LOGGING: Save logs anytime. Logs auto-scroll.\n\n" +
                "CATEGORIES:\n" +
                "- CLEAN: Free up disk space.\n" +
                "- REPAIR: Fix Windows issues (Updates, SFC, etc).\n" +
                "- HARDWARE: Diagnostics (RAM, Battery, CPU).\n" +
                "- NETWORK: Internet optimization and troubleshooting.\n" +
                "- SECURITY: Privacy hardening and audits.\n" +
                "- UTILS: General tools (Backup, Updates).\n\n" +
                "SYMBOLS:\n" +
                "(!) - Destructive Action (Warning)\n" +
                " *  - Interactive (Opens new window)\n\n" +
                "Note: All scripts run with Administrator privileges.";

            MessageBox.Show(helpText, "Help / About", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private string GetDetailedSystemInfo()
        {
            string osName = "Unknown OS";
            string totalRam = "Unknown RAM";
            string cpuName = "Unknown CPU";
            string freeSpace = "Unknown Disk";

            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Caption FROM Win32_OperatingSystem")) {
                    foreach (var item in searcher.Get()) { if (item["Caption"] != null) osName = item["Caption"].ToString(); break; }
                }
            } catch { }

            try {
                using (var searcher = new ManagementObjectSearcher("SELECT TotalVisibleMemorySize FROM Win32_OperatingSystem")) {
                    foreach (var item in searcher.Get()) {
                        if (item["TotalVisibleMemorySize"] != null) {
                            long ramBytes = Convert.ToInt64(item["TotalVisibleMemorySize"]) * 1024;
                            totalRam = Math.Round(ramBytes / (1024.0 * 1024.0 * 1024.0), 1) + " GB";
                        }
                        break;
                    }
                }
            } catch { }

            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Name FROM Win32_Processor")) {
                    foreach (var item in searcher.Get()) { if (item["Name"] != null) cpuName = item["Name"].ToString(); break; }
                }
            } catch { }

            try {
                DriveInfo drive = new DriveInfo("C");
                if (drive.IsReady) {
                    long free = drive.AvailableFreeSpace;
                    long total = drive.TotalSize;
                    freeSpace = string.Format("C: {0} GB Free / {1} GB", Math.Round(free / (1024.0 * 1024.0 * 1024.0), 1), Math.Round(total / (1024.0 * 1024.0 * 1024.0), 1));
                }
            } catch { }

            return string.Format("{0}\n{1} | {2} RAM\n{3}", osName, cpuName, totalRam, freeSpace);
        }

        private void BuildTabs()
        {
            tabs.TabPages.Clear();
            allButtons.Clear();

            var categories = new Dictionary<string, List<ScriptInfo>>();

            // Special Favorites Category
            categories["FAVORITES"] = new List<ScriptInfo>();

            string[] cats = { "CLEAN", "REPAIR", "HARDWARE", "NETWORK", "SECURITY", "UTILS" };
            foreach (var c in cats) categories[c] = new List<ScriptInfo>();

            // --- DEFINITIONS ---
            // CLEAN
            categories["CLEAN"].Add(new ScriptInfo("2_InstallCleaningTools.ps1", "Install Cleaners", "Installs Malwarebytes and BleachBit via Winget."));
            categories["CLEAN"].Add(new ScriptInfo("4_DeepCleanDisk.ps1", "Deep Disk Cleanup", "Runs Windows Disk Cleanup with advanced options."));
            categories["CLEAN"].Add(new ScriptInfo("5_SafeDebloat.ps1", "Safe Debloat", "Removes common bloatware apps safely."));
            categories["CLEAN"].Add(new ScriptInfo("13_NuclearTempClean.ps1", "Nuclear Temp Clean", "Aggressively cleans temporary files.", false, true));
            categories["CLEAN"].Add(new ScriptInfo("35_ListRecycleBin.ps1", "Scan Recycle Bin", "Lists hidden deleted files in Recycle Bin."));
            categories["CLEAN"].Add(new ScriptInfo("45_DeleteEmptyFolders.ps1", "Delete Empty Folders", "Recursively deletes empty directories.", true, true));
            categories["CLEAN"].Add(new ScriptInfo("50_FindDuplicates.ps1", "Find Duplicates", "Finds duplicate files by content hash.", true));

            // REPAIR
            categories["REPAIR"].Add(new ScriptInfo("1_CreateRestorePoint.ps1", "Create Restore Point", "Creates a System Restore Point."));
            categories["REPAIR"].Add(new ScriptInfo("3_SystemRepair.ps1", "System Repair (SFC/DISM)", "Runs DISM and SFC to fix corrupt Windows files."));
            categories["REPAIR"].Add(new ScriptInfo("10_RestoreClassicMenu.ps1", "Restore Win10 Menu", "Restores the classic context menu on Windows 11."));
            categories["REPAIR"].Add(new ScriptInfo("12_RebuildIconCache.ps1", "Rebuild Icon Cache", "Fixes blank or broken icons."));
            categories["REPAIR"].Add(new ScriptInfo("14_TimeSyncFix.ps1", "Fix Time Sync", "Resyncs system clock with time servers."));
            categories["REPAIR"].Add(new ScriptInfo("16_ResetWindowsUpdate.ps1", "Reset Windows Update", "Fixes stuck updates and download errors."));
            categories["REPAIR"].Add(new ScriptInfo("18_RebuildFontCache.ps1", "Rebuild Font Cache", "Fixes font rendering issues."));
            categories["REPAIR"].Add(new ScriptInfo("25_FixPrinter.ps1", "Fix Stuck Printer", "Resets the print spooler."));
            categories["REPAIR"].Add(new ScriptInfo("36_ClearPendingUpdates.ps1", "Clear Pending Updates", "Fixes boot loops caused by updates."));
            categories["REPAIR"].Add(new ScriptInfo("38_RestartAudio.ps1", "Restart Audio Services", "Fixes no sound issues without reboot."));
            categories["REPAIR"].Add(new ScriptInfo("51_TakeOwnership.ps1", "Fix Permissions", "Takes ownership of a folder (Access Denied fix).", true));
            categories["REPAIR"].Add(new ScriptInfo("56_CleanPathVariables.ps1", "Clean PATH", "Removes dead links from System PATH."));
            categories["REPAIR"].Add(new ScriptInfo("62_FixWindowsStore.ps1", "Fix Windows Store", "Resets and re-registers the Microsoft Store."));

            // HARDWARE
            categories["HARDWARE"].Add(new ScriptInfo("9_DiskHealthCheck.ps1", "Check Disk Health", "Checks SMART status of drives."));
            categories["HARDWARE"].Add(new ScriptInfo("11_BatteryHealthReport.ps1", "Battery Report", "Generates an HTML battery health report."));
            categories["HARDWARE"].Add(new ScriptInfo("17_BackupDrivers.ps1", "Backup Drivers", "Exports all installed drivers to Desktop."));
            categories["HARDWARE"].Add(new ScriptInfo("22_RemoveGhostDevices.ps1", "Remove Ghost Devices", "Helps remove unused hidden devices."));
            categories["HARDWARE"].Add(new ScriptInfo("34_KeyTester.ps1", "Keyboard Tester", "Displays raw key input codes.", true));
            categories["HARDWARE"].Add(new ScriptInfo("37_PixelFixer.ps1", "Dead Pixel Fixer", "Flashes colors to unstuck pixels.", true));
            categories["HARDWARE"].Add(new ScriptInfo("39_SleepStudy.ps1", "Sleep Study", "Analyzes battery drain during sleep."));
            categories["HARDWARE"].Add(new ScriptInfo("40_RunRamTest.ps1", "RAM Memory Test", "Schedules a memory test on reboot.", true));
            categories["HARDWARE"].Add(new ScriptInfo("41_CpuStressTest.ps1", "CPU Stress Test", "High load test for stability.", true));
            categories["HARDWARE"].Add(new ScriptInfo("52_ReadChkdskLogs.ps1", "Read Chkdsk Logs", "Reads the latest Check Disk result from logs."));
            categories["HARDWARE"].Add(new ScriptInfo("64_CheckVirtualization.ps1", "Check Virtualization", "Checks if VT-x/AMD-V is enabled."));
            categories["HARDWARE"].Add(new ScriptInfo("65_DisableUsbSuspend.ps1", "Disable USB Suspend", "Fixes USB lag issues."));

            // NETWORK
            categories["NETWORK"].Add(new ScriptInfo("7_NetworkReset.ps1", "Network Reset", "Flushes DNS and resets IP/Winsock."));
            categories["NETWORK"].Add(new ScriptInfo("19_GetWifiPasswords.ps1", "Show Wi-Fi Passwords", "Decrypts saved Wi-Fi passwords."));
            categories["NETWORK"].Add(new ScriptInfo("20_DnsBenchmark.ps1", "DNS Benchmark", "Tests speed of DNS providers."));
            categories["NETWORK"].Add(new ScriptInfo("30_LocalPortScan.ps1", "Local Port Scanner", "Scans for open listening ports."));
            categories["NETWORK"].Add(new ScriptInfo("47_NetworkHeartbeat.ps1", "Network Heartbeat", "Monitors ping and packet loss.", true));
            categories["NETWORK"].Add(new ScriptInfo("53_OptimizeNetwork.ps1", "Optimize Internet", "Tunes TCP receive window."));
            categories["NETWORK"].Add(new ScriptInfo("58_BlockWebsite.ps1", "Block Website", "Blocks a domain via Hosts file.", true));

            // SECURITY
            categories["SECURITY"].Add(new ScriptInfo("8_PrivacyHardening.ps1", "Privacy Hardening", "Disables telemetry and ad ID."));
            categories["SECURITY"].Add(new ScriptInfo("21_AuditScheduledTasks.ps1", "Audit Scheduled Tasks", "Lists suspicious scheduled tasks."));
            categories["SECURITY"].Add(new ScriptInfo("24_GetBitLockerKey.ps1", "Get BitLocker Key", "Retrieves BitLocker recovery key."));
            categories["SECURITY"].Add(new ScriptInfo("31_UsbWriteProtect.ps1", "USB Write Protect", "Sets USB drives to Read-Only.", true));
            categories["SECURITY"].Add(new ScriptInfo("32_VerifyFileHash.ps1", "Verify File Hash", "Calculates SHA256 hash of a file.", true));
            categories["SECURITY"].Add(new ScriptInfo("42_AuditNonMsServices.ps1", "Audit Services", "Lists non-Microsoft running services."));
            categories["SECURITY"].Add(new ScriptInfo("48_AuditUserAccounts.ps1", "Audit Users", "Lists local user accounts."));
            categories["SECURITY"].Add(new ScriptInfo("49_SecureDelete.ps1", "Secure Delete", "Wipes a file (3 passes).", true, true));
            categories["SECURITY"].Add(new ScriptInfo("59_PanicButton.ps1", "Panic Button", "Mutes, clears clipboard, minimizes all."));

            // UTILS
            categories["UTILS"].Add(new ScriptInfo("6_OptimizeAndUpdate.ps1", "Update All Software", "Runs Winget upgrade all."));
            categories["UTILS"].Add(new ScriptInfo("15_ClearEventLogs.ps1", "Clear Event Logs", "Clears all Windows Event Logs."));
            categories["UTILS"].Add(new ScriptInfo("23_FindLargeFiles.ps1", "Find Large Files", "Scans user profile for large files."));
            categories["UTILS"].Add(new ScriptInfo("26_ClearClipboard.ps1", "Clear Clipboard", "Wipes clipboard history."));
            categories["UTILS"].Add(new ScriptInfo("27_CheckStability.ps1", "Check Stability", "Checks for recent crashes/BSODs."));
            categories["UTILS"].Add(new ScriptInfo("28_GetBiosKey.ps1", "Get BIOS Key", "Retrieves OEM Windows Key."));
            categories["UTILS"].Add(new ScriptInfo("29_ProcessFreezer.ps1", "Process Freezer", "Suspends/Resumes processes.", true));
            categories["UTILS"].Add(new ScriptInfo("33_EnableGodMode.ps1", "Enable God Mode", "Creates God Mode folder on Desktop."));
            categories["UTILS"].Add(new ScriptInfo("43_CheckBootTime.ps1", "Analyze Boot Time", "Checks BIOS boot duration."));
            categories["UTILS"].Add(new ScriptInfo("44_ExportInstalledApps.ps1", "Export App List", "Saves installed apps to CSV."));
            categories["UTILS"].Add(new ScriptInfo("46_QuickBackup.ps1", "Quick Backup", "Robocopy mirror of Documents.", true));
            categories["UTILS"].Add(new ScriptInfo("54_SleepTimer.ps1", "Sleep Timer", "Sets a shutdown timer.", true));
            categories["UTILS"].Add(new ScriptInfo("55_ToggleDarkMode.ps1", "Toggle System Dark Mode", "Toggles Windows Theme."));
            categories["UTILS"].Add(new ScriptInfo("57_TurnOffMonitor.ps1", "Turn Off Monitor", "Turns off display signal."));
            categories["UTILS"].Add(new ScriptInfo("60_EmergencyRestart.ps1", "Emergency Restart", "Forces immediate reboot.", true, true));
            categories["UTILS"].Add(new ScriptInfo("61_CheckActivation.ps1", "Check Activation", "Checks license expiry."));
            categories["UTILS"].Add(new ScriptInfo("63_InstallEssentials.ps1", "Install Essentials", "Installs Chrome, VLC, 7Zip, etc."));

            // --- POPULATE FAVORITES ---
            // Just duplicate references.
            // We need to iterate all cats to find matching filenames.
            foreach (var kvp in categories)
            {
                if (kvp.Key == "FAVORITES") continue;
                foreach (var s in kvp.Value)
                {
                    if (favoriteScripts.Contains(s.FileName))
                    {
                        categories["FAVORITES"].Add(s);
                    }
                }
            }

            // Create Tabs
            // Add Favorites first
            if (categories["FAVORITES"].Count > 0)
            {
                TabPage favPage = CreateTabPage("FAVORITES", categories["FAVORITES"]);
                tabs.TabPages.Add(favPage);
            }

            foreach (var cat in cats)
            {
                TabPage page = CreateTabPage(cat, categories[cat]);
                tabs.TabPages.Add(page);
            }
        }

        private TabPage CreateTabPage(string title, List<ScriptInfo> scripts)
        {
            TabPage page = new TabPage(title);
            page.UseVisualStyleBackColor = false;

            FlowLayoutPanel panel = new FlowLayoutPanel();
            panel.Dock = DockStyle.Fill;
            panel.AutoScroll = true;
            panel.Padding = new Padding(10);

            foreach (var script in scripts)
            {
                // We must create NEW buttons because a script object might appear in multiple tabs (e.g. favorites)
                // and a Control can only have one parent.
                Button btn = CreateButton(script);
                panel.Controls.Add(btn);
                allButtons.Add(btn);
            }

            page.Controls.Add(panel);
            return page;
        }

        private Button CreateButton(ScriptInfo script)
        {
            Button btn = new Button();
            btn.Text = script.DisplayName;
            btn.Tag = script;
            btn.Width = 240;
            btn.Height = 75;
            btn.Margin = new Padding(8);
            btn.FlatStyle = FlatStyle.Flat;
            btn.TextAlign = ContentAlignment.MiddleLeft;

            // Accessibility
            btn.AccessibleName = script.DisplayName;
            btn.AccessibleRole = AccessibleRole.PushButton;
            btn.AccessibleDescription = script.Description + (script.IsDestructive ? " Warning: Destructive Action." : "");

            // Batch Mode Checkbox
            CheckBox chk = new CheckBox();
            chk.Tag = script;
            chk.Parent = btn;
            chk.Location = new Point(215, 5);
            chk.Size = new Size(20, 20);
            chk.Visible = false;
            chk.BackColor = Color.Transparent;
            chk.CheckedChanged += (s, e) => UpdateBatchButton();

            // We can't store the checkbox in ScriptInfo anymore because there are multiple buttons per script (Favorites)
            // But for batch mode, if I check it in Favorites, should it check in Clean?
            // For simplicity, let's treat them as separate instances.
            // But we need a way to link them for 'Batch' running.
            // Actually, we iterate 'allButtons' which contains ALL buttons.
            // So if I have the same script in Fav and Clean, and check both, it runs twice.
            // This is a side effect. We should probably dedup execution, but for now, user beware.

            // Visual indicators
            if (script.IsDestructive) btn.ForeColor = Color.OrangeRed;
            if (script.IsInteractive) btn.Text += " *";
            if (script.IsDestructive) btn.Text += " (!)";

            btn.MouseEnter += (s, e) => {
                lblDescTitle.Text = script.DisplayName;
                lblDescText.Text = script.Description;
                if (script.IsInteractive) lblDescText.Text += "\n[Opens separate window]";
                if (script.IsDestructive) lblDescText.Text += "\n[WARNING: This action cannot be undone]";
            };

            // Context Menu
            ContextMenuStrip ctx = new ContextMenuStrip();
            ctx.Items.Add("View Script Source", null, (s, e) => ViewScriptSource(script));

            bool isFav = favoriteScripts.Contains(script.FileName);
            string favText = isFav ? "Remove from Favorites" : "Add to Favorites";
            ctx.Items.Add(favText, null, (s, e) => ToggleFavorite(script));

            btn.ContextMenuStrip = ctx;

            btn.Click += (s, e) => {
                if (isBatchMode) {
                    chk.Checked = !chk.Checked;
                    return;
                }

                if (script.IsDestructive)
                {
                    var result = MessageBox.Show(string.Format("Warning: {0} will permanently modify or delete data.\n\nAre you sure you want to proceed?", script.DisplayName), "Safety Check", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                    if (result == DialogResult.No) return;
                }
                RunScript(script);
            };

            return btn;
        }

        private void ToggleFavorite(ScriptInfo script)
        {
            if (favoriteScripts.Contains(script.FileName))
                favoriteScripts.Remove(script.FileName);
            else
                favoriteScripts.Add(script.FileName);

            SaveSettings();

            // Refresh Tabs
            // Preserve selection?
            int idx = tabs.SelectedIndex;
            BuildTabs();
            if (idx < tabs.TabCount) tabs.SelectedIndex = idx;
            ApplyTheme(); // Re-apply theme to new buttons
        }

        private void SaveLogToFile()
        {
            try {
                using (SaveFileDialog sfd = new SaveFileDialog()) {
                    sfd.Filter = "Text Files (*.txt)|*.txt";
                    sfd.FileName = string.Format("MaintenanceLog_{0:yyyyMMdd_HHmm}.txt", DateTime.Now);
                    if (sfd.ShowDialog() == DialogResult.OK) {
                        File.WriteAllText(sfd.FileName, txtLog.Text);
                        MessageBox.Show("Log saved successfully.", "Saved", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            } catch (Exception ex) {
                MessageBox.Show("Error saving log: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void ChkBatchMode_CheckedChanged(object sender, EventArgs e)
        {
            isBatchMode = chkBatchMode.Checked;
            chkBatchMode.BackColor = isBatchMode ? (isDarkMode ? Color.FromArgb(100, 149, 237) : Color.LightSkyBlue) : Color.Transparent;
            btnRunBatch.Visible = isBatchMode;
            btnSelectAll.Visible = isBatchMode;
            btnSelectNone.Visible = isBatchMode;

            foreach (var btn in allButtons)
            {
                // Access child checkbox
                foreach (Control c in btn.Controls) {
                    if (c is CheckBox) c.Visible = isBatchMode;
                }
            }
        }

        private void SetAllBatchSelection(bool selected)
        {
            foreach (var btn in allButtons)
            {
                if (!btn.Visible) continue; // Only affect visible buttons (current tab / filter)
                foreach (Control c in btn.Controls) {
                    CheckBox chk = c as CheckBox;
                    if (chk != null) chk.Checked = selected;
                }
            }
        }

        private void UpdateBatchButton()
        {
            // Count checked checkboxes
            int count = 0;
            foreach (var btn in allButtons) {
                foreach (Control c in btn.Controls) {
                    CheckBox chk = c as CheckBox;
                    if (chk != null && chk.Checked) count++;
                }
            }
            btnRunBatch.Text = string.Format("RUN SELECTED ({0})", count);
        }

        private async void BtnRunBatch_Click(object sender, EventArgs e)
        {
            // Gather scripts
            // De-duplication logic: Use FileName as key
            var scriptsToRun = new List<ScriptInfo>();
            var seenFiles = new HashSet<string>();

            foreach (var btn in allButtons) {
                foreach (Control c in btn.Controls) {
                    CheckBox chk = c as CheckBox;
                    if (chk != null && chk.Checked) {
                        ScriptInfo s = btn.Tag as ScriptInfo;
                        if (!seenFiles.Contains(s.FileName)) {
                            scriptsToRun.Add(s);
                            seenFiles.Add(s.FileName);
                        }
                    }
                }
            }

            if (scriptsToRun.Count == 0) return;

            if (MessageBox.Show(string.Format("Run {0} scripts sequentially?", scriptsToRun.Count), "Confirm Batch", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.No)
                return;

            batchCts = new CancellationTokenSource();
            btnRunBatch.Enabled = false;
            chkBatchMode.Enabled = false;
            btnSelectAll.Enabled = false;
            btnSelectNone.Enabled = false;
            btnCancel.Visible = true;

            progressBar.Style = ProgressBarStyle.Continuous;
            progressBar.Maximum = scriptsToRun.Count;
            progressBar.Value = 0;
            progressBar.Visible = true;

            try
            {
                int processed = 0;
                foreach (var script in scriptsToRun)
                {
                    if (batchCts.Token.IsCancellationRequested) break;

                    statusLabel.Text = string.Format("Running {0} of {1}: {2}", processed + 1, scriptsToRun.Count, script.DisplayName);
                    await RunScriptAsync(script, batchCts.Token);
                    processed++;
                    progressBar.Value = processed;
                }
            }
            finally
            {
                btnRunBatch.Enabled = true;
                chkBatchMode.Enabled = true;
                btnSelectAll.Enabled = true;
                btnSelectNone.Enabled = true;
                btnCancel.Visible = false;
                progressBar.Visible = false;
                progressBar.Style = ProgressBarStyle.Marquee;
                statusLabel.Text = "Batch Execution Finished";
                Log("--- Batch Execution Finished ---");

                if (batchCts != null) { batchCts.Dispose(); batchCts = null; }
            }
        }

        private void ViewScriptSource(ScriptInfo script)
        {
             string scriptPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scripts", script.FileName);
             if (File.Exists(scriptPath))
             {
                 Form viewer = new Form { Text = script.FileName, Size = new Size(800, 600), StartPosition = FormStartPosition.CenterParent };
                 TextBox txt = new TextBox {
                     Multiline = true,
                     Dock = DockStyle.Fill,
                     ScrollBars = ScrollBars.Vertical,
                     ReadOnly = true,
                     Font = new Font("Consolas", 11),
                     Text = File.ReadAllText(scriptPath)
                 };
                 viewer.Controls.Add(txt);
                 viewer.ShowDialog();
             }
        }

        private void FilterButtons(string query)
        {
            if (tabs.SelectedTab == null) return;

            FlowLayoutPanel panel = tabs.SelectedTab.Controls.OfType<FlowLayoutPanel>().FirstOrDefault();
            if (panel == null) return;

            string[] tokens = string.IsNullOrWhiteSpace(query)
                ? new string[0]
                : query.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

            panel.SuspendLayout();
            foreach (Control c in panel.Controls)
            {
                Button btn = c as Button;
                if (btn != null)
                {
                    ScriptInfo info = btn.Tag as ScriptInfo;
                    if (info != null)
                    {
                        bool match = true;
                        if (tokens.Length > 0)
                        {
                            foreach (var token in tokens)
                            {
                                bool tokenMatch = info.DisplayName.IndexOf(token, StringComparison.OrdinalIgnoreCase) >= 0 ||
                                                  info.Description.IndexOf(token, StringComparison.OrdinalIgnoreCase) >= 0;
                                if (!tokenMatch)
                                {
                                    match = false;
                                    break;
                                }
                            }
                        }
                        c.Visible = match;
                    }
                }
            }
            panel.ResumeLayout();
        }

        private void TxtSearch_TextChanged(object sender, EventArgs e)
        {
            FilterButtons(txtSearch.Text);
        }

        private void BtnCancel_Click(object sender, EventArgs e)
        {
            if (batchCts != null) batchCts.Cancel();

            lock (processLock)
            {
                if (currentProcess != null && !currentProcess.HasExited)
                {
                    try
                    {
                        currentProcess.Kill();
                        Log("Process cancelled by user.");
                    }
                    catch (Exception ex)
                    {
                        Log(string.Format("Error cancelling process: {0}", ex.Message));
                    }
                }
            }
        }

        // --- Core Execution Logic ---

        private Task RunScriptAsync(ScriptInfo script, CancellationToken token)
        {
            return Task.Run(() => {
                if (token.IsCancellationRequested) return;

                this.Invoke(new Action(() => {
                     Log(string.Format("Starting: {0}...", script.DisplayName));
                     if (!progressBar.Visible) {
                        statusLabel.Text = string.Format("Running: {0}", script.DisplayName);
                        progressBar.Visible = true;
                     }
                }));

                ExecuteScriptInternal(script);

                this.Invoke(new Action(() => {
                     Log(string.Format("Completed: {0}", script.DisplayName));
                     if (!isBatchMode) statusLabel.Text = "Ready";
                }));
            });
        }

        private void RunScript(ScriptInfo script)
        {
            if (currentProcess != null && !currentProcess.HasExited)
            {
                MessageBox.Show("A script is already running. Please wait or cancel it.", "Busy", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            Log(string.Format("Starting: {0}...", script.DisplayName));
            statusLabel.Text = string.Format("Running: {0}", script.DisplayName);
            progressBar.Visible = true;
            btnCancel.Visible = !script.IsInteractive;

            System.Threading.Tasks.Task.Run(() => {
                ExecuteScriptInternal(script);
                this.Invoke(new Action(() => {
                    Log(string.Format("Finished: {0}", script.DisplayName));
                    Log("------------------------------------------------");
                    statusLabel.Text = "Ready";
                    progressBar.Visible = false;
                    btnCancel.Visible = false;
                }));
            });
        }

        private void ExecuteScriptInternal(ScriptInfo script)
        {
            string scriptPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scripts", script.FileName);
            if (!File.Exists(scriptPath))
            {
                scriptPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, script.FileName);
            }

            if (!File.Exists(scriptPath))
            {
                this.Invoke(new Action(() => {
                    Log(string.Format("Error: Script file not found: {0}", script.FileName));
                }));
                return;
            }

            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";

                // Try to use UTF8 to catch emoji/unicode logs
                psi.StandardOutputEncoding = Encoding.UTF8;
                psi.StandardErrorEncoding = Encoding.UTF8;

                if (script.IsInteractive)
                {
                    psi.Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -NoExit -File \"{0}\"", scriptPath);
                    psi.UseShellExecute = true;

                    Process.Start(psi);
                    this.Invoke(new Action(() => {
                        Log(string.Format("Launched {0} in external window.", script.DisplayName));
                    }));
                }
                else
                {
                    psi.Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -NonInteractive -File \"{0}\"", scriptPath);
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                    psi.UseShellExecute = false;
                    psi.CreateNoWindow = true;

                    using (Process p = new Process())
                    {
                        lock (processLock) { currentProcess = p; }
                        p.StartInfo = psi;
                        p.OutputDataReceived += (s, e) => { if (e.Data != null) Log(e.Data); };
                        p.ErrorDataReceived += (s, e) => { if (e.Data != null) Log("ERR: " + e.Data); };

                        p.Start();
                        p.BeginOutputReadLine();
                        p.BeginErrorReadLine();
                        p.WaitForExit();
                        lock (processLock) { currentProcess = null; }
                    }
                }
            }
            catch (Exception ex)
            {
                this.Invoke(new Action(() => {
                    Log(string.Format("Error executing script: {0}", ex.Message));
                }));
            }
        }

        private void Log(string msg)
        {
            string line = string.Format("[{0}] {1}", DateTime.Now.ToShortTimeString(), msg);

            if (txtLog.InvokeRequired) { txtLog.Invoke(new Action<string>(Log), msg); return; }

            txtLog.AppendText(line + "\r\n");

            txtLog.SelectionStart = txtLog.Text.Length;
            txtLog.ScrollToCaret();

            try {
                string logDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
                if (!Directory.Exists(logDir)) Directory.CreateDirectory(logDir);
                File.AppendAllText(Path.Combine(logDir, string.Format("log_{0:yyyyMMdd}.txt", DateTime.Now)), line + Environment.NewLine);
            } catch { }
        }

        private void ToggleTheme()
        {
            isDarkMode = !isDarkMode;
            SaveSettings();
            ApplyTheme();
        }

        private void ApplyTheme()
        {
            if (SystemInformation.HighContrast) return;

            Color backColor = isDarkMode ? Color.FromArgb(32, 33, 36) : Color.WhiteSmoke;
            Color foreColor = isDarkMode ? Color.FromArgb(232, 234, 237) : Color.Black;

            Color panelBack = isDarkMode ? Color.FromArgb(41, 42, 45) : Color.White;
            Color btnBack = isDarkMode ? Color.FromArgb(60, 64, 67) : Color.White;
            Color btnBorder = isDarkMode ? Color.FromArgb(95, 99, 104) : Color.Silver;

            this.BackColor = backColor;
            this.ForeColor = foreColor;

            tabs.BackColor = backColor;
            tabs.ForeColor = foreColor;

            foreach (TabPage page in tabs.TabPages)
            {
                page.BackColor = backColor;
                page.ForeColor = foreColor;

                // Refresh buttons inside panel
                foreach(Control c in page.Controls) {
                    FlowLayoutPanel p = c as FlowLayoutPanel;
                    if (p != null) {
                        foreach(Control btn in p.Controls) {
                            Button b = btn as Button;
                            if (b != null) {
                                b.BackColor = btnBack;
                                b.ForeColor = ((ScriptInfo)b.Tag).IsDestructive ? (isDarkMode ? Color.LightCoral : Color.Red) : foreColor;
                                b.FlatAppearance.BorderColor = btnBorder;
                            }
                        }
                    }
                }
            }

            descPanel.BackColor = panelBack;
            descPanel.ForeColor = foreColor;

            statusStrip.BackColor = isDarkMode ? Color.Black : Color.WhiteSmoke;
            statusStrip.ForeColor = isDarkMode ? Color.White : Color.Black;

            txtSearch.BackColor = isDarkMode ? Color.FromArgb(60, 64, 67) : Color.White;
            txtSearch.ForeColor = isDarkMode ? Color.White : Color.Black;
        }

        public static bool IsAdministrator()
        {
            using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
            {
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            }
        }

        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    public class ScriptInfo
    {
        public string FileName { get; set; }
        public string DisplayName { get; set; }
        public string Description { get; set; }
        public bool IsInteractive { get; set; }
        public bool IsDestructive { get; set; }

        public ScriptInfo(string file, string name, string desc, bool interactive = false, bool destructive = false)
        {
            FileName = file;
            DisplayName = name;
            Description = desc;
            IsInteractive = interactive;
            IsDestructive = destructive;
        }
    }
}
