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
        // UI Controls - Sidebar
        private Panel sidebarPanel;
        private Panel contentPanel;
        private FlowLayoutPanel scriptsPanel;
        private List<Button> sidebarButtons = new List<Button>();

        // UI Controls - Content
        private TextBox txtLog;
        private StatusStrip statusStrip;
        private ToolStripStatusLabel statusLabel;
        private ToolStripProgressBar progressBar;
        private List<Button> allScriptButtons = new List<Button>();
        private TextBox txtSearch;
        private Panel descPanel;
        private Label lblDescTitle;
        private Label lblDescText;
        private SplitContainer splitContainer;
        private Button btnCancel;
        private Button btnDarkMode;

        // Data
        private Dictionary<string, List<ScriptInfo>> categories = new Dictionary<string, List<ScriptInfo>>();
        private string currentCategory = "FAVORITES";

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

        // Colors (Modern Flat Theme)
        private Color colSidebarDark = Color.FromArgb(45, 45, 48);
        private Color colSidebarLight = Color.FromArgb(240, 240, 240);
        private Color colContentDark = Color.FromArgb(30, 30, 30);
        private Color colContentLight = Color.White;
        private Color colBtnHoverDark = Color.FromArgb(62, 62, 66);
        private Color colBtnHoverLight = Color.FromArgb(220, 220, 220);
        private Color colAccent = Color.FromArgb(0, 122, 204);

        public MainForm()
        {
            LoadSettings();
            InitializeData();

            // --- UI Setup ---
            this.Text = "Ultimate System Maintenance Toolkit";
            this.Size = new Size(1200, 850);
            this.MinimumSize = new Size(900, 650);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Icon = SystemIcons.Shield;
            this.Font = new Font("Segoe UI", 9F, FontStyle.Regular);

            // Check Admin
            if (!IsAdministrator())
            {
                MessageBox.Show("Please restart this application as Administrator for full functionality.", "Admin Rights Needed", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }

            // --- Root Layout ---
            sidebarPanel = new Panel { Dock = DockStyle.Left, Width = 220, Padding = new Padding(0) };
            contentPanel = new Panel { Dock = DockStyle.Fill };

            this.Controls.Add(contentPanel);
            this.Controls.Add(sidebarPanel);

            // --- Sidebar Construction ---
            Panel sidebarHeader = new Panel { Dock = DockStyle.Top, Height = 80, BackColor = Color.Transparent };
            Button btnMenu = new Button {
                Text = "≡",
                Dock = DockStyle.Left,
                Width = 50,
                FlatStyle = FlatStyle.Flat,
                FlatAppearance = { BorderSize = 0 },
                Font = new Font("Segoe UI", 14F),
                ForeColor = Color.White
            };
            btnMenu.Click += (s,e) => {
                sidebarPanel.Width = sidebarPanel.Width == 220 ? 60 : 220;
                foreach(Control c in sidebarPanel.Controls) {
                    if (c is Button && c.Tag != null) ((Button)c).Text = sidebarPanel.Width == 220 ? c.Tag.ToString() : "";
                }
            };

            Label lblTitle = new Label {
                Text = "TOOLKIT",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Segoe UI", 12F, FontStyle.Bold),
                ForeColor = Color.White
            };
            sidebarHeader.Controls.Add(lblTitle);
            sidebarHeader.Controls.Add(btnMenu);
            sidebarPanel.Controls.Add(sidebarHeader);

            // Categories
            string[] cats = { "DASHBOARD", "FAVORITES", "CLEAN", "REPAIR", "HARDWARE", "NETWORK", "SECURITY", "UTILS" };
            foreach (var cat in cats)
            {
                Button btn = CreateSidebarButton(cat);
                sidebarPanel.Controls.Add(btn);
                sidebarButtons.Add(btn);
            }

            // Fix Sidebar Order (Dock adds to bottom of stack, so first added is bottom visually if we don't handle it)
            // Actually Dock.Top stacks from top. So first added is top.
            // We want Header first.
            sidebarHeader.BringToFront();

            // Sidebar Footer (Help/Theme)
            Panel sidebarFooter = new Panel { Dock = DockStyle.Bottom, Height = 100 };
            Button btnHelp = CreateSidebarButton("HELP / ABOUT");
            btnHelp.Dock = DockStyle.Top;
            btnHelp.Click -= SidebarButton_Click; // Remove default handler
            btnHelp.Click += (s,e) => ShowHelp();

            btnDarkMode = CreateSidebarButton("TOGGLE THEME");
            btnDarkMode.Dock = DockStyle.Top;
            btnDarkMode.Click -= SidebarButton_Click;
            btnDarkMode.Click += (s,e) => ToggleTheme();

            sidebarFooter.Controls.Add(btnHelp); // Bottom most due to Dock.Top stacking? No.
            // Dock Top means:
            // 1. Add btnHelp -> Tops
            // 2. Add btnDarkMode -> Below btnHelp
            // We want help at bottom.

            // Let's just reset footer controls with specific dock
            btnHelp.Dock = DockStyle.Bottom;
            btnDarkMode.Dock = DockStyle.Bottom;
            sidebarFooter.Controls.Add(btnDarkMode); // Above help
            sidebarFooter.Controls.Add(btnHelp);     // Very bottom

            sidebarPanel.Controls.Add(sidebarFooter);

            // --- Content Area Construction ---

            // 1. Header (Search + SysInfo)
            Panel contentHeader = new Panel { Dock = DockStyle.Top, Height = 60, Padding = new Padding(10) };

            // Search
            Panel searchContainer = new Panel { Dock = DockStyle.Right, Width = 300 };
            txtSearch = new TextBox { Dock = DockStyle.Fill, Font = new Font("Segoe UI", 11F), BorderStyle = BorderStyle.FixedSingle };
            txtSearch.TextChanged += TxtSearch_TextChanged;
            Button btnClearSearch = new Button { Text = "X", Dock = DockStyle.Right, Width = 30, FlatStyle = FlatStyle.Flat };
            btnClearSearch.FlatAppearance.BorderSize = 0;
            btnClearSearch.Click += (s, e) => txtSearch.Text = "";

            searchContainer.Controls.Add(txtSearch);
            searchContainer.Controls.Add(btnClearSearch);

            Label lblSearchLabel = new Label { Text = "Search:", Dock = DockStyle.Left, Width = 60, TextAlign = ContentAlignment.MiddleRight };
            searchContainer.Controls.Add(lblSearchLabel); // Actually logic needs fixing for Dock order
            // Re-ordering for Dock Right: Add Rightmost first.
            searchContainer.Controls.Clear();
            searchContainer.Controls.Add(btnClearSearch);
            searchContainer.Controls.Add(txtSearch);
            searchContainer.Controls.Add(lblSearchLabel);

            // Batch Controls in Header
            chkBatchMode = new CheckBox { Text = "Batch Mode", Dock = DockStyle.Left, Width = 120, Appearance = Appearance.Button, TextAlign = ContentAlignment.MiddleCenter, FlatStyle = FlatStyle.Flat };
            chkBatchMode.CheckedChanged += ChkBatchMode_CheckedChanged;

            btnSelectAll = new Button { Text = "All", Dock = DockStyle.Left, Width = 50, FlatStyle = FlatStyle.Flat, Visible = false };
            btnSelectAll.Click += (s, e) => SetAllBatchSelection(true);

            btnSelectNone = new Button { Text = "None", Dock = DockStyle.Left, Width = 50, FlatStyle = FlatStyle.Flat, Visible = false };
            btnSelectNone.Click += (s, e) => SetAllBatchSelection(false);

            contentHeader.Controls.Add(searchContainer);
            contentHeader.Controls.Add(btnSelectNone);
            contentHeader.Controls.Add(btnSelectAll);
            contentHeader.Controls.Add(chkBatchMode);

            // 2. Split Container (Scripts + Log)
            splitContainer = new SplitContainer { Dock = DockStyle.Fill, Orientation = Orientation.Horizontal, SplitterDistance = 450, FixedPanel = FixedPanel.Panel2 };

            // Scripts Panel
            scriptsPanel = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoScroll = true, Padding = new Padding(10) };

            // Description Panel (Bottom of Scripts)
            descPanel = new Panel { Dock = DockStyle.Bottom, Height = 70, Padding = new Padding(5), BorderStyle = BorderStyle.FixedSingle };
            lblDescTitle = new Label { Dock = DockStyle.Top, Height = 20, Font = new Font("Segoe UI", 10F, FontStyle.Bold), Text = "Hover over a tool to see details." };
            lblDescText = new Label { Dock = DockStyle.Fill, Text = "", Font = new Font("Segoe UI", 9F) };
            btnRunBatch = new Button { Text = "RUN BATCH", Dock = DockStyle.Right, Width = 140, BackColor = colAccent, ForeColor = Color.White, FlatStyle = FlatStyle.Flat, Visible = false, Font = new Font("Segoe UI", 9F, FontStyle.Bold) };
            btnRunBatch.Click += BtnRunBatch_Click;

            descPanel.Controls.Add(btnRunBatch);
            descPanel.Controls.Add(lblDescText);
            descPanel.Controls.Add(lblDescTitle);

            Panel upperContent = new Panel { Dock = DockStyle.Fill };
            upperContent.Controls.Add(scriptsPanel);
            upperContent.Controls.Add(descPanel);

            splitContainer.Panel1.Controls.Add(upperContent);

            // Log Area
            GroupBox grpLog = new GroupBox { Text = "System Log", Dock = DockStyle.Fill, Padding = new Padding(5) };
            txtLog = new TextBox { Multiline = true, Dock = DockStyle.Fill, ReadOnly = true, ScrollBars = ScrollBars.Vertical, Font = new Font("Consolas", 9F) };

            Panel logTools = new Panel { Dock = DockStyle.Right, Width = 90 };
            btnCancel = new Button { Text = "CANCEL", Dock = DockStyle.Top, Height = 30, BackColor = Color.IndianRed, ForeColor = Color.White, FlatStyle = FlatStyle.Flat, Visible = false };
            btnCancel.Click += BtnCancel_Click;
            Button btnSave = new Button { Text = "Save", Dock = DockStyle.Bottom, Height = 25, FlatStyle = FlatStyle.Flat };
            btnSave.Click += (s,e) => SaveLogToFile();

            logTools.Controls.Add(btnCancel);
            logTools.Controls.Add(btnSave);

            grpLog.Controls.Add(txtLog);
            grpLog.Controls.Add(logTools);
            splitContainer.Panel2.Controls.Add(grpLog);

            contentPanel.Controls.Add(splitContainer);
            contentPanel.Controls.Add(contentHeader);

            // Status Strip
            statusStrip = new StatusStrip();
            statusLabel = new ToolStripStatusLabel("Ready") { Spring = true, TextAlign = ContentAlignment.MiddleLeft };
            progressBar = new ToolStripProgressBar { Visible = false, Style = ProgressBarStyle.Marquee };
            statusStrip.Items.Add(statusLabel);
            statusStrip.Items.Add(progressBar);
            this.Controls.Add(statusStrip);

            // Finalize
            ApplyTheme();
            LoadCategory("DASHBOARD"); // Default
        }

        private Button CreateSidebarButton(string text)
        {
            Button btn = new Button();
            btn.Text = text;
            btn.Dock = DockStyle.Top;
            btn.Height = 50;
            btn.FlatStyle = FlatStyle.Flat;
            btn.FlatAppearance.BorderSize = 0;
            btn.TextAlign = ContentAlignment.MiddleLeft;
            btn.Padding = new Padding(20, 0, 0, 0);
            btn.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
            btn.Tag = text; // Category name
            btn.Click += SidebarButton_Click;
            return btn;
        }

        private void SidebarButton_Click(object sender, EventArgs e)
        {
            Button btn = sender as Button;
            if (btn == null) return;
            LoadCategory(btn.Tag.ToString());
        }

        private Dictionary<string, List<Button>> buttonCache = new Dictionary<string, List<Button>>();

        private void LoadCategory(string category)
        {
            currentCategory = category;
            scriptsPanel.SuspendLayout();
            scriptsPanel.Controls.Clear();

            // We use allScriptButtons to track the *visible* buttons for search and batch actions in current view
            allScriptButtons.Clear();

            // Highlight Sidebar Button
            foreach(var b in sidebarButtons) {
                b.Font = new Font("Segoe UI", 10F, (string)b.Tag == category ? FontStyle.Bold : FontStyle.Regular);
                b.BackColor = (string)b.Tag == category ? (isDarkMode ? Color.FromArgb(60,60,60) : Color.LightGray) : Color.Transparent;
            }

            // Create buttons if not cached or empty (since we initialize empty lists)
            if (!buttonCache.ContainsKey(category) || buttonCache[category].Count == 0) {
                buttonCache[category] = new List<Button>();
                if (categories.ContainsKey(category)) {
                     foreach(var script in categories[category]) {
                         buttonCache[category].Add(CreateScriptButton(script));
                     }
                }
            }

            // Special Dashboard Handling
            if (category == "DASHBOARD") {
                RenderDashboard();
            }
            // Add cached buttons to panel
            else if (buttonCache.ContainsKey(category))
            {
                foreach(var btn in buttonCache[category])
                {
                    scriptsPanel.Controls.Add(btn);
                    allScriptButtons.Add(btn);
                }
            }

            // Re-apply batch mode state to new buttons (visiblity only)
            // State (Checked) is preserved in the CheckBox control itself which stays in memory via buttonCache
            ChkBatchMode_CheckedChanged(null, null);
            scriptsPanel.ResumeLayout();
        }

        private void RenderDashboard() {
            Panel dash = new Panel { Dock = DockStyle.Top, Height = 400, Padding = new Padding(20) };

            Label lblWelcome = new Label { Text = "System Status", Font = new Font("Segoe UI", 16F, FontStyle.Bold), Dock = DockStyle.Top, Height = 40, ForeColor = isDarkMode ? Color.White : Color.Black };
            Label lblStats = new Label { Text = GetDetailedSystemInfo(), Font = new Font("Segoe UI", 11F), Dock = DockStyle.Top, Height = 100, AutoSize = false, ForeColor = isDarkMode ? Color.LightGray : Color.DarkSlateGray };

            Label lblQuick = new Label { Text = "Quick Actions", Font = new Font("Segoe UI", 14F, FontStyle.Bold), Dock = DockStyle.Top, Height = 40, ForeColor = isDarkMode ? Color.White : Color.Black };

            FlowLayoutPanel quickPanel = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 150, AutoScroll = false };
            // Add top 3 scripts
            string[] quickScripts = { "2_InstallCleaningTools.ps1", "9_DiskHealthCheck.ps1", "1_CreateRestorePoint.ps1" };
            foreach(var s in quickScripts) {
                // Find script info - inefficient but works
                foreach(var cat in categories.Values) {
                    var script = cat.FirstOrDefault(x => x.FileName == s);
                    if(script != null) {
                        quickPanel.Controls.Add(CreateScriptButton(script));
                        break;
                    }
                }
            }

            dash.Controls.Add(quickPanel);
            dash.Controls.Add(lblQuick);
            dash.Controls.Add(lblStats);
            dash.Controls.Add(lblWelcome);

            scriptsPanel.Controls.Add(dash);
        }

        private void InitializeData()
        {
            string[] cats = { "CLEAN", "REPAIR", "HARDWARE", "NETWORK", "SECURITY", "UTILS" };
            categories["FAVORITES"] = new List<ScriptInfo>();
            categories["DASHBOARD"] = new List<ScriptInfo>(); // Dashboard is special, but needs a key
            foreach (var c in cats) categories[c] = new List<ScriptInfo>();

            // Initialize Cache
            foreach (var c in cats) buttonCache[c] = new List<Button>();
            buttonCache["FAVORITES"] = new List<Button>();
            buttonCache["DASHBOARD"] = new List<Button>();

            // --- DEFINITIONS (Same as before) ---
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

            // Populate Favorites
            foreach (var kvp in categories) {
                if (kvp.Key == "FAVORITES") continue;
                foreach (var s in kvp.Value) {
                    if (favoriteScripts.Contains(s.FileName)) categories["FAVORITES"].Add(s);
                }
            }
        }

        private Button CreateScriptButton(ScriptInfo script)
        {
            Button btn = new Button();
            btn.Text = script.DisplayName;
            btn.Tag = script;
            btn.Width = 280; // Slightly wider
            btn.Height = 85;
            btn.Margin = new Padding(8);
            btn.FlatStyle = FlatStyle.Flat;
            btn.FlatAppearance.BorderSize = 1; // Subtle border in content area
            btn.TextAlign = ContentAlignment.MiddleLeft;

            // Batch Mode Checkbox
            CheckBox chk = new CheckBox();
            chk.Tag = script;
            chk.Parent = btn;
            chk.Location = new Point(255, 5);
            chk.Size = new Size(20, 20);
            chk.Visible = isBatchMode;
            chk.BackColor = Color.Transparent;
            chk.CheckedChanged += (s, e) => UpdateBatchButton();

            // Accessibility
            btn.AccessibleName = script.DisplayName;
            btn.AccessibleRole = AccessibleRole.PushButton;
            btn.AccessibleDescription = script.Description;

            // Visual indicators
            if (script.IsDestructive) btn.ForeColor = isDarkMode ? Color.LightCoral : Color.Red;
            if (script.IsInteractive) btn.Text += " *";
            if (script.IsDestructive) btn.Text += " (!)";

            btn.MouseEnter += (s, e) => {
                lblDescTitle.Text = script.DisplayName;
                lblDescText.Text = script.Description;
                if (script.IsInteractive) lblDescText.Text += "\n[Opens separate window]";
                if (script.IsDestructive) lblDescText.Text += "\n[WARNING: This action cannot be undone]";
            };

            ContextMenuStrip ctx = new ContextMenuStrip();
            ctx.Items.Add("View Script Source", null, (s, e) => ViewScriptSource(script));
            bool isFav = favoriteScripts.Contains(script.FileName);
            ctx.Items.Add(isFav ? "Remove from Favorites" : "Add to Favorites", null, (s, e) => ToggleFavorite(script));
            btn.ContextMenuStrip = ctx;

            btn.Click += (s, e) => {
                if (isBatchMode) { chk.Checked = !chk.Checked; return; }
                if (script.IsDestructive && MessageBox.Show(string.Format("Warning: {0} is destructive.\nProceed?", script.DisplayName), "Warning", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.No) return;
                RunScript(script);
            };

            return btn;
        }

        private void ToggleFavorite(ScriptInfo script)
        {
            if (favoriteScripts.Contains(script.FileName)) favoriteScripts.Remove(script.FileName);
            else favoriteScripts.Add(script.FileName);
            SaveSettings();

            // Reload if currently on favorites, or just refresh data
            InitializeData(); // Inefficient but safe logic reuse
            if (currentCategory == "FAVORITES") LoadCategory("FAVORITES");
        }

        private void LoadSettings()
        {
            try {
                if (File.Exists(SETTINGS_FILE)) isDarkMode = File.ReadAllText(SETTINGS_FILE).Contains("DarkMode=True");
                if (File.Exists(FAVORITES_FILE)) favoriteScripts = new HashSet<string>(File.ReadAllLines(FAVORITES_FILE).Where(l => !string.IsNullOrWhiteSpace(l)));
            } catch {}
        }

        private void SaveSettings()
        {
            try {
                File.WriteAllText(SETTINGS_FILE, string.Format("DarkMode={0}", isDarkMode));
                File.WriteAllLines(FAVORITES_FILE, favoriteScripts);
            } catch {}
        }

        // --- Batch Mode Logic (Similar to previous) ---
        private void ChkBatchMode_CheckedChanged(object sender, EventArgs e)
        {
            isBatchMode = chkBatchMode.Checked;
            chkBatchMode.BackColor = isBatchMode ? colAccent : Color.Transparent;
            chkBatchMode.ForeColor = isBatchMode ? Color.White : (isDarkMode ? Color.White : Color.Black);
            btnRunBatch.Visible = isBatchMode;
            btnSelectAll.Visible = isBatchMode;
            btnSelectNone.Visible = isBatchMode;

            foreach (var btn in allScriptButtons)
            {
                foreach (Control c in btn.Controls) if (c is CheckBox) c.Visible = isBatchMode;
            }
        }

        private void SetAllBatchSelection(bool selected) {
             foreach (var btn in allScriptButtons) {
                 if (!btn.Visible) continue;
                 foreach (Control c in btn.Controls) if (c is CheckBox) ((CheckBox)c).Checked = selected;
             }
        }

        private void UpdateBatchButton() {
            int count = 0;
            // Iterate all cached buttons to allow cross-category execution
            foreach(var cat in buttonCache.Values) {
                foreach(var btn in cat) {
                    foreach (Control c in btn.Controls) if (c is CheckBox && ((CheckBox)c).Checked) count++;
                }
            }
            btnRunBatch.Text = string.Format("RUN BATCH ({0})", count);
        }

        private async void BtnRunBatch_Click(object sender, EventArgs e)
        {
             var scriptsToRun = new List<ScriptInfo>();
             // Iterate all cached buttons
             foreach(var cat in buttonCache.Values) {
                 foreach(var btn in cat) {
                    foreach (Control c in btn.Controls) if (c is CheckBox && ((CheckBox)c).Checked) scriptsToRun.Add((ScriptInfo)btn.Tag);
                 }
             }
             // Deduplicate by filename (Favorites vs Category)
             scriptsToRun = scriptsToRun.GroupBy(s => s.FileName).Select(g => g.First()).ToList();

             if (scriptsToRun.Count == 0) return;

             batchCts = new CancellationTokenSource();
             btnRunBatch.Enabled = false;
             progressBar.Visible = true;
             btnCancel.Visible = true;

             try {
                 int i = 0;
                 foreach(var s in scriptsToRun) {
                     if (batchCts.IsCancellationRequested) break;
                     statusLabel.Text = string.Format("Batch: Running {0} of {1}...", i+1, scriptsToRun.Count);
                     await RunScriptAsync(s, batchCts.Token);
                     i++;
                 }
             } finally {
                 btnRunBatch.Enabled = true;
                 progressBar.Visible = false;
                 btnCancel.Visible = false;
                 statusLabel.Text = "Batch Complete";
             }
        }

        // --- Execution Logic (Same as previous) ---
        private void ViewScriptSource(ScriptInfo script) {
             string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scripts", script.FileName);
             if (File.Exists(path)) {
                 new Form { Text = script.FileName, Size = new Size(800,600), Controls = {
                     new TextBox { Multiline=true, Dock=DockStyle.Fill, ScrollBars=ScrollBars.Vertical, ReadOnly=true, Text=File.ReadAllText(path), Font=new Font("Consolas",10) }
                 }}.ShowDialog();
             }
        }

        private void FilterButtons(string query) {
             scriptsPanel.SuspendLayout();
             if (string.IsNullOrWhiteSpace(query)) {
                 // Restore current category view
                 if (currentCategory == "SEARCH_RESULTS") LoadCategory("DASHBOARD"); // Or previous
                 else LoadCategory(currentCategory);
             } else {
                 // Switch to search mode
                 currentCategory = "SEARCH_RESULTS";
                 scriptsPanel.Controls.Clear();
                 allScriptButtons.Clear();

                 var seen = new HashSet<string>();
                 // Iterate all categories
                 foreach(var cat in categories) {
                     if (cat.Key == "FAVORITES" || cat.Key == "DASHBOARD") continue; // Skip dups
                     foreach(var s in cat.Value) {
                         if (s.DisplayName.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0 && seen.Add(s.FileName)) {
                             Button btn = CreateScriptButton(s);
                             scriptsPanel.Controls.Add(btn);
                             allScriptButtons.Add(btn);
                         }
                     }
                 }
                 // If no results
                 if (allScriptButtons.Count == 0) {
                     Label lbl = new Label { Text = "No results found.", AutoSize = true, ForeColor = isDarkMode ? Color.White : Color.Black, Font = new Font("Segoe UI", 12F) };
                     scriptsPanel.Controls.Add(lbl);
                 }
             }
             scriptsPanel.ResumeLayout();
        }
        private void TxtSearch_TextChanged(object sender, EventArgs e) => FilterButtons(txtSearch.Text);
        private void BtnCancel_Click(object sender, EventArgs e) {
            if (batchCts!=null) batchCts.Cancel();
            lock(processLock) { if (currentProcess != null && !currentProcess.HasExited) currentProcess.Kill(); }
        }

        private Task RunScriptAsync(ScriptInfo script, CancellationToken token) {
            return Task.Run(() => {
                if (token.IsCancellationRequested) return;
                Invoke((Action)(() => { Log("Starting: " + script.DisplayName); statusLabel.Text = "Running " + script.DisplayName; progressBar.Visible = true; }));
                ExecuteScriptInternal(script);
                Invoke((Action)(() => { Log("Completed: " + script.DisplayName); if (!isBatchMode) { statusLabel.Text = "Ready"; progressBar.Visible = false; } }));
            });
        }

        private void RunScript(ScriptInfo script) {
            if (currentProcess != null && !currentProcess.HasExited) { MessageBox.Show("Busy."); return; }
            Log("Starting: " + script.DisplayName);
            statusLabel.Text = "Running: " + script.DisplayName;
            progressBar.Visible = true;
            btnCancel.Visible = !script.IsInteractive;
            Task.Run(() => {
                ExecuteScriptInternal(script);
                Invoke((Action)(() => { Log("Finished."); statusLabel.Text = "Ready"; progressBar.Visible = false; btnCancel.Visible = false; }));
            });
        }

        private void ExecuteScriptInternal(ScriptInfo script) {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scripts", script.FileName);
            if (!File.Exists(path)) path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, script.FileName);
            if (!File.Exists(path)) { Invoke((Action)(()=>Log("Script not found."))); return; }

            try {
                ProcessStartInfo psi = new ProcessStartInfo("powershell.exe",
                    string.Format("-NoProfile -ExecutionPolicy Bypass {0} -File \"{1}\"", script.IsInteractive ? "-NoExit" : "-NonInteractive", path));
                psi.UseShellExecute = script.IsInteractive;
                psi.CreateNoWindow = !script.IsInteractive;
                psi.StandardOutputEncoding = Encoding.UTF8;
                psi.StandardErrorEncoding = Encoding.UTF8;
                if (!script.IsInteractive) { psi.RedirectStandardOutput = true; psi.RedirectStandardError = true; }

                using (Process p = new Process { StartInfo = psi }) {
                    if (!script.IsInteractive) {
                        lock(processLock) currentProcess = p;
                        p.OutputDataReceived += (s,e) => { if (e.Data!=null) Log(e.Data); };
                        p.ErrorDataReceived += (s,e) => { if (e.Data!=null) Log("ERR: "+e.Data); };
                        p.Start();
                        p.BeginOutputReadLine(); p.BeginErrorReadLine();
                        p.WaitForExit();
                        lock(processLock) currentProcess = null;
                    } else {
                        Process.Start(psi);
                    }
                }
            } catch (Exception ex) { Invoke((Action)(()=>Log("Error: " + ex.Message))); }
        }

        private void Log(string msg) {
            if (txtLog.InvokeRequired) { txtLog.Invoke((Action)(()=>Log(msg))); return; }
            txtLog.AppendText(string.Format("[{0}] {1}\r\n", DateTime.Now.ToShortTimeString(), msg));
            try { File.AppendAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs", $"log_{DateTime.Now:yyyyMMdd}.txt"), $"[{DateTime.Now}] {msg}\r\n"); } catch {}
        }

        private void ShowHelp() {
            MessageBox.Show("Ultimate System Maintenance Toolkit v68\n\nSidebar Navigation: Select a category.\nBatch Mode: Select multiple scripts in the current view to run.\nLogging: Logs are saved automatically.", "Help");
        }

        private void ToggleTheme() {
            isDarkMode = !isDarkMode;
            SaveSettings();
            ApplyTheme();
        }

        private void ApplyTheme() {
            if (SystemInformation.HighContrast) return;

            Color bg = isDarkMode ? colContentDark : colContentLight;
            Color fg = isDarkMode ? Color.White : Color.Black;
            Color sbBg = isDarkMode ? colSidebarDark : colSidebarDark; // Sidebar always dark? Or varies. Let's make sidebar always dark for modern look.
            Color sbFg = Color.White;

            this.BackColor = bg;
            this.ForeColor = fg;

            sidebarPanel.BackColor = sbBg;

            // Buttons in sidebar
            foreach(Control c in sidebarPanel.Controls) {
                if (c is Button) {
                    c.ForeColor = sbFg;
                    // Reset highlight
                    if ((string)c.Tag == currentCategory) c.BackColor = isDarkMode ? Color.FromArgb(60,60,60) : Color.Gray;
                    else c.BackColor = Color.Transparent;
                }
            }

            // Content
            scriptsPanel.BackColor = bg;
            descPanel.BackColor = isDarkMode ? Color.FromArgb(40,40,40) : Color.WhiteSmoke;
            descPanel.ForeColor = fg;

            // Script Buttons
            foreach(Button b in allScriptButtons) {
                b.BackColor = isDarkMode ? Color.FromArgb(50,50,50) : Color.WhiteSmoke;
                b.ForeColor = ((ScriptInfo)b.Tag).IsDestructive ? (isDarkMode ? Color.LightCoral : Color.Red) : fg;
                b.FlatAppearance.BorderColor = isDarkMode ? Color.Gray : Color.Silver;
            }

            // Logs
            txtLog.BackColor = isDarkMode ? Color.FromArgb(20,20,20) : Color.FromArgb(240,240,240);
            txtLog.ForeColor = isDarkMode ? Color.LimeGreen : Color.Black;

            statusStrip.BackColor = isDarkMode ? Color.Black : Color.White;
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
