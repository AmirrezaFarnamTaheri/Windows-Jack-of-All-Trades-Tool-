using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Security.Principal;
using System.Windows.Forms;

namespace SystemMaintenance
{
    public class MainForm : Form
    {
        private TextBox txtLog;
        private TabControl tabs;
        private StatusStrip statusStrip;
        private ToolStripStatusLabel statusLabel;
        private bool isDarkMode = false;
        private List<Button> allButtons = new List<Button>();

        public MainForm()
        {
            // --- UI Setup ---
            this.Text = "Ultimate System Maintenance Toolkit";
            this.Size = new Size(1000, 700);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Icon = SystemIcons.Shield;
            this.Font = new Font("Segoe UI", 9F, FontStyle.Regular);

            // Check Admin
            if (!IsAdministrator())
            {
                MessageBox.Show("Please restart this application as Administrator for full functionality.", "Admin Rights Needed", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }

            // Tabs
            tabs = new TabControl { Dock = DockStyle.Top, Height = 500 };

            // Build Categories and Scripts
            BuildTabs();

            // Logger
            GroupBox grpLog = new GroupBox { Text = "Activity Log", Dock = DockStyle.Fill };
            txtLog = new TextBox {
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.LimeGreen,
                Font = new Font("Consolas", 10)
            };
            grpLog.Controls.Add(txtLog);

            // Log Container to handle resizing
            Panel logPanel = new Panel { Dock = DockStyle.Fill, Padding = new Padding(10) };
            logPanel.Controls.Add(grpLog);

            // Status Strip
            statusStrip = new StatusStrip();
            statusLabel = new ToolStripStatusLabel("Ready");
            statusStrip.Items.Add(statusLabel);

            // Dark Mode Toggle
            Button btnDarkMode = new Button { Text = "Toggle Dark Mode", Dock = DockStyle.Bottom, Height = 30 };
            btnDarkMode.Click += (s, e) => ToggleTheme();

            // Main Layout
            Panel mainPanel = new Panel { Dock = DockStyle.Fill };
            mainPanel.Controls.Add(logPanel);
            mainPanel.Controls.Add(tabs);

            this.Controls.Add(mainPanel);
            this.Controls.Add(btnDarkMode);
            this.Controls.Add(statusStrip);

            ApplyTheme();
        }

        private void BuildTabs()
        {
            var categories = new Dictionary<string, List<ScriptInfo>>();

            // Initialize Categories
            string[] cats = { "CLEAN", "REPAIR", "HARDWARE", "NETWORK", "SECURITY", "UTILS" };
            foreach (var c in cats) categories[c] = new List<ScriptInfo>();

            // Populate Scripts
            // CLEAN
            categories["CLEAN"].Add(new ScriptInfo("2_InstallCleaningTools.ps1", "Install Cleaners", "Installs Malwarebytes and BleachBit via Winget."));
            categories["CLEAN"].Add(new ScriptInfo("4_DeepCleanDisk.ps1", "Deep Disk Cleanup", "Runs Windows Disk Cleanup with advanced options."));
            categories["CLEAN"].Add(new ScriptInfo("5_SafeDebloat.ps1", "Safe Debloat", "Removes common bloatware apps safely."));
            categories["CLEAN"].Add(new ScriptInfo("13_NuclearTempClean.ps1", "Nuclear Temp Clean", "Aggressively cleans temporary files."));
            categories["CLEAN"].Add(new ScriptInfo("35_ListRecycleBin.ps1", "Scan Recycle Bin", "Lists hidden deleted files in Recycle Bin."));
            categories["CLEAN"].Add(new ScriptInfo("45_DeleteEmptyFolders.ps1", "Delete Empty Folders", "Recursively deletes empty directories.", true));
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
            categories["SECURITY"].Add(new ScriptInfo("49_SecureDelete.ps1", "Secure Delete", "Wipes a file (3 passes).", true));
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
            categories["UTILS"].Add(new ScriptInfo("60_EmergencyRestart.ps1", "Emergency Restart", "Forces immediate reboot.", true));
            categories["UTILS"].Add(new ScriptInfo("61_CheckActivation.ps1", "Check Activation", "Checks license expiry."));
            categories["UTILS"].Add(new ScriptInfo("63_InstallEssentials.ps1", "Install Essentials", "Installs Chrome, VLC, 7Zip, etc."));


            foreach (var cat in categories)
            {
                TabPage page = new TabPage(cat.Key);
                page.UseVisualStyleBackColor = false;

                FlowLayoutPanel panel = new FlowLayoutPanel();
                panel.Dock = DockStyle.Fill;
                panel.AutoScroll = true;
                panel.Padding = new Padding(10);

                foreach (var script in cat.Value)
                {
                    Button btn = CreateButton(script);
                    panel.Controls.Add(btn);
                    allButtons.Add(btn);
                }

                page.Controls.Add(panel);
                tabs.TabPages.Add(page);
            }
        }

        private Button CreateButton(ScriptInfo script)
        {
            Button btn = new Button();
            btn.Text = script.DisplayName;
            btn.Tag = script;
            btn.Width = 220;
            btn.Height = 60;
            btn.Margin = new Padding(5);
            btn.FlatStyle = FlatStyle.Flat;
            btn.TextAlign = ContentAlignment.MiddleLeft;

            // Tooltip
            ToolTip tt = new ToolTip();
            tt.SetToolTip(btn, script.Description + (script.IsInteractive ? " (Opens new window)" : ""));

            // Visual indicator for interactive scripts
            if (script.IsInteractive)
            {
                btn.Text += " *";
            }

            btn.Click += (s, e) => {
                RunScript(script);
            };

            return btn;
        }

        private void RunScript(ScriptInfo script)
        {
            Log($"Starting: {script.DisplayName}...");
            statusLabel.Text = $"Running: {script.DisplayName}";

            // Locate script
            string scriptPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scripts", script.FileName);
            if (!File.Exists(scriptPath))
            {
                scriptPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, script.FileName);
            }

            if (!File.Exists(scriptPath))
            {
                Log($"Error: Script file not found: {script.FileName}");
                statusLabel.Text = "Error: File not found";
                return;
            }

            try
            {
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "powershell.exe";

                if (script.IsInteractive)
                {
                    // For interactive scripts, launch in a visible window
                    psi.Arguments = $"-NoProfile -ExecutionPolicy Bypass -NoExit -File \"{scriptPath}\"";
                    psi.UseShellExecute = true; // Use shell to ensure window creation
                    psi.CreateNoWindow = false;

                    Process.Start(psi);
                    Log($"Launched {script.DisplayName} in external window.");
                    statusLabel.Text = "Ready";
                }
                else
                {
                    // For non-interactive, run hidden and capture output
                    // We add -NonInteractive to prevent hanging on Pause/Read-Host if we missed any
                    psi.Arguments = $"-NoProfile -ExecutionPolicy Bypass -NonInteractive -File \"{scriptPath}\"";
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                    psi.UseShellExecute = false;
                    psi.CreateNoWindow = true;

                    System.Threading.Tasks.Task.Run(() => {
                        using (Process p = new Process())
                        {
                            p.StartInfo = psi;
                            p.OutputDataReceived += (s, e) => { if (e.Data != null) Log(e.Data); };
                            p.ErrorDataReceived += (s, e) => { if (e.Data != null) Log("ERR: " + e.Data); };

                            p.Start();
                            p.BeginOutputReadLine();
                            p.BeginErrorReadLine();
                            p.WaitForExit();

                            this.Invoke(new Action(() => {
                                Log($"Finished: {script.DisplayName}");
                                Log("------------------------------------------------");
                                statusLabel.Text = "Ready";
                            }));
                        }
                    });
                }
            }
            catch (Exception ex)
            {
                Log($"Error executing script: {ex.Message}");
            }
        }

        private void Log(string msg)
        {
            if (txtLog.InvokeRequired) { txtLog.Invoke(new Action<string>(Log), msg); return; }
            txtLog.AppendText($"[{DateTime.Now.ToShortTimeString()}] {msg}\r\n");
        }

        private void ToggleTheme()
        {
            isDarkMode = !isDarkMode;
            ApplyTheme();
        }

        private void ApplyTheme()
        {
            Color backColor = isDarkMode ? Color.FromArgb(45, 45, 48) : Color.WhiteSmoke;
            Color foreColor = isDarkMode ? Color.White : Color.Black;
            Color btnBack = isDarkMode ? Color.FromArgb(60, 60, 60) : Color.White;
            Color btnHover = isDarkMode ? Color.FromArgb(80, 80, 80) : Color.LightGray;

            this.BackColor = backColor;
            this.ForeColor = foreColor;

            tabs.BackColor = backColor;
            tabs.ForeColor = foreColor;

            foreach (TabPage page in tabs.TabPages)
            {
                page.BackColor = backColor;
                page.ForeColor = foreColor;
            }

            foreach (Button btn in allButtons)
            {
                btn.BackColor = btnBack;
                btn.ForeColor = foreColor;
                btn.FlatAppearance.BorderColor = isDarkMode ? Color.Gray : Color.Silver;
            }

            // Log box always dark
            statusStrip.BackColor = isDarkMode ? Color.Black : Color.WhiteSmoke;
            statusStrip.ForeColor = isDarkMode ? Color.White : Color.Black;
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

        public ScriptInfo(string file, string name, string desc, bool interactive = false)
        {
            FileName = file;
            DisplayName = name;
            Description = desc;
            IsInteractive = interactive;
        }
    }
}
