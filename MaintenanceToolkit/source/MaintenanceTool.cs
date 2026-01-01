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
        private TextBox txtSearch;
        private SplitContainer splitContainer;
        private Button btnCancel;
        private Button btnDarkMode;

        // Caches
        private Dictionary<string, Panel> scriptCardCache = new Dictionary<string, Panel>();
        private Panel dashboardPanel; // Cached Dashboard
        private Panel helpPanel;      // Cached Help

        // Data
        private Dictionary<string, List<ScriptInfo>> categories = new Dictionary<string, List<ScriptInfo>>();
        private string currentCategory = "DASHBOARD";

        // Batch Mode Controls
        private CheckBox chkBatchMode;
        private CheckBox chkVerbose;
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
        private int scriptRunning = 0;
        private object processLock = new object();
        private const string SETTINGS_FILE = "settings.cfg";
        private CancellationTokenSource batchCts;
        private string tempScriptDir = null;

        // Colors (Modern Flat Theme)
        private Color colSidebarDark = Color.FromArgb(37, 37, 38);
        private Color colSidebarLight = Color.FromArgb(240, 240, 240);
        private Color colContentDark = Color.FromArgb(30, 30, 30);
        private Color colContentLight = Color.White;
        private Color colCardDark = Color.FromArgb(45, 45, 48);
        private Color colCardLight = Color.WhiteSmoke;
        private Color colCardHoverDark = Color.FromArgb(65, 65, 68);
        private Color colCardHoverLight = Color.FromArgb(230, 230, 230);
        private Color colAccent = Color.FromArgb(0, 122, 204);
        private Color colTextDark = Color.FromArgb(241, 241, 241);
        private Color colTextLight = Color.FromArgb(30, 30, 30);

        public MainForm()
        {
            LoadSettings();
            InitializeData();

            // --- UI Setup ---
            this.Text = "Ultimate System Maintenance Toolkit";
            this.Size = new Size(1100, 750);
            this.MinimumSize = new Size(900, 600);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Icon = SystemIcons.Shield;
            this.Font = new Font("Segoe UI", 9F, FontStyle.Regular);
            this.DoubleBuffered = true;
            this.KeyPreview = true; // For shortcuts

            // Check Admin
            if (!IsAdministrator())
            {
                MessageBox.Show("Please restart this application as Administrator for full functionality.", "Admin Rights Needed", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }

            InitializeLayout();
            ApplyTheme();
            LoadCategory("DASHBOARD");

            this.FormClosing += OnFormClosing;
            this.KeyDown += OnKeyDown;
        }

        private void OnKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Control && e.KeyCode == Keys.F)
            {
                txtSearch.Focus();
                e.Handled = true;
            }
        }

        private void OnFormClosing(object sender, FormClosingEventArgs e)
        {
            // Dispose all cached script cards to prevent memory leaks
            foreach (var card in scriptCardCache.Values)
            {
                card.Dispose();
            }
            scriptCardCache.Clear();

            // Cleanup temporary script directory
            if (tempScriptDir != null && Directory.Exists(tempScriptDir))
            {
                try {
                    lock (processLock)
                    {
                        if (currentProcess != null && !currentProcess.HasExited)
                        {
                            try { currentProcess.Kill(); } catch { }
                            currentProcess = null;
                            Interlocked.Exchange(ref scriptRunning, 0);
                        }
                    }

                    Directory.Delete(tempScriptDir, true);
                    tempScriptDir = null;
                } catch (Exception ex) {
                    Debug.WriteLine("Failed to cleanup temp dir: " + ex.Message);
                }
            }
        }

        private void InitializeLayout()
        {
            // Root Container
            TableLayoutPanel mainLayout = new TableLayoutPanel();
            mainLayout.Dock = DockStyle.Fill;
            mainLayout.ColumnCount = 2;
            mainLayout.RowCount = 1;
            mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 220F)); // Sidebar
            mainLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F)); // Content
            this.Controls.Add(mainLayout);

            // 1. Sidebar
            sidebarPanel = new Panel { Dock = DockStyle.Fill, Padding = new Padding(0) };

            // Sidebar Header
            Panel sidebarHeader = new Panel { Dock = DockStyle.Top, Height = 70 };
            Label lblTitle = new Label {
                Text = "TOOLKIT",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Segoe UI", 14F, FontStyle.Bold),
                ForeColor = Color.White
            };
            sidebarHeader.Controls.Add(lblTitle);
            sidebarPanel.Controls.Add(sidebarHeader);

            // Categories with Icons
            var cats = new Dictionary<string, string> {
                {"DASHBOARD", "🏠 Dashboard"},
                {"FAVORITES", "★ Favorites"},
                {"CLEAN", "🧹 Clean"},
                {"REPAIR", "🔧 Repair"},
                {"HARDWARE", "💻 Hardware"},
                {"NETWORK", "🌐 Network"},
                {"SECURITY", "🛡 Security"},
                {"UTILS", "🧰 Utils"},
                {"HELP", "❓ Help"}
            };

            foreach (var kvp in cats)
            {
                Button btn = CreateSidebarButton(kvp.Key, kvp.Value);
                sidebarPanel.Controls.Add(btn);
                sidebarButtons.Add(btn);
            }
            // Correct Order (Dock Top stacks reversed)
            sidebarHeader.SendToBack();

            // Sidebar Footer
            Panel sidebarFooter = new Panel { Dock = DockStyle.Bottom, Height = 100 };

            Button btnOpenScripts = CreateSidebarButton("OPEN_SCRIPTS", "📂 Scripts Folder");
            btnOpenScripts.Dock = DockStyle.Top;
            btnOpenScripts.Click -= SidebarButton_Click;
            btnOpenScripts.Click += (s, e) => {
                string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scripts");
                if (!Directory.Exists(path)) path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "MaintenanceToolkit", "scripts");
                if (Directory.Exists(path)) Process.Start(path);
                else MessageBox.Show("Scripts folder not found.");
            };

            btnDarkMode = CreateSidebarButton("TOGGLE THEME", "🌗 Toggle Theme");
            btnDarkMode.Dock = DockStyle.Bottom;
            btnDarkMode.Click -= SidebarButton_Click;
            btnDarkMode.Click += (s,e) => ToggleTheme();

            sidebarFooter.Controls.Add(btnOpenScripts);
            sidebarFooter.Controls.Add(btnDarkMode);
            sidebarPanel.Controls.Add(sidebarFooter);

            mainLayout.Controls.Add(sidebarPanel, 0, 0);

            // 2. Content Panel
            contentPanel = new Panel { Dock = DockStyle.Fill };
            mainLayout.Controls.Add(contentPanel, 1, 0);

            // Content Header
            Panel contentHeader = new Panel { Dock = DockStyle.Top, Height = 50, Padding = new Padding(5) };

            // Search
            Panel searchPanel = new Panel { Dock = DockStyle.Right, Width = 250, Padding = new Padding(5) };
            txtSearch = new TextBox { Dock = DockStyle.Fill, Font = new Font("Segoe UI", 10F) };
            txtSearch.TextChanged += TxtSearch_TextChanged;
            Label lblSearch = new Label { Text = "Search:", Dock = DockStyle.Left, AutoSize = true, TextAlign = ContentAlignment.MiddleRight, Padding = new Padding(0,5,5,0) };
            searchPanel.Controls.Add(txtSearch);
            searchPanel.Controls.Add(lblSearch);

            // Batch Controls
            chkBatchMode = new CheckBox { Text = "Batch Mode", Dock = DockStyle.Left, Width = 100, Appearance = Appearance.Button, TextAlign = ContentAlignment.MiddleCenter, FlatStyle = FlatStyle.Flat };
            chkBatchMode.CheckedChanged += ChkBatchMode_CheckedChanged;

            // Verbose Control
            chkVerbose = new CheckBox { Text = "Verbose", Dock = DockStyle.Left, Width = 80, Appearance = Appearance.Button, TextAlign = ContentAlignment.MiddleCenter, FlatStyle = FlatStyle.Flat };
            chkVerbose.CheckedChanged += (s,e) => {
                chkVerbose.BackColor = chkVerbose.Checked ? colAccent : Color.Transparent;
                chkVerbose.ForeColor = chkVerbose.Checked ? Color.White : (isDarkMode ? colTextDark : colTextLight);
            };

            btnSelectAll = new Button { Text = "All", Dock = DockStyle.Left, Width = 50, FlatStyle = FlatStyle.Flat, Visible = false };
            btnSelectAll.Click += (s, e) => SetAllBatchSelection(true);
            btnSelectNone = new Button { Text = "None", Dock = DockStyle.Left, Width = 50, FlatStyle = FlatStyle.Flat, Visible = false };
            btnSelectNone.Click += (s, e) => SetAllBatchSelection(false);
            btnRunBatch = new Button { Text = "RUN BATCH", Dock = DockStyle.Left, Width = 120, BackColor = colAccent, ForeColor = Color.White, FlatStyle = FlatStyle.Flat, Visible = false, Font = new Font("Segoe UI", 9F, FontStyle.Bold) };
            btnRunBatch.Click += BtnRunBatch_Click;

            contentHeader.Controls.Add(searchPanel);
            contentHeader.Controls.Add(btnRunBatch);
            contentHeader.Controls.Add(btnSelectNone);
            contentHeader.Controls.Add(btnSelectAll);
            contentHeader.Controls.Add(chkVerbose);
            contentHeader.Controls.Add(chkBatchMode);

            contentPanel.Controls.Add(contentHeader);

            // Split Container (Scripts / Logs)
            splitContainer = new SplitContainer { Dock = DockStyle.Fill, Orientation = Orientation.Horizontal, SplitterDistance = 450 };

            // Script Flow Panel
            scriptsPanel = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoScroll = true, Padding = new Padding(10) };
            scriptsPanel.Resize += ScriptsPanel_Resize; // Handle resizing for full-width panels
            splitContainer.Panel1.Controls.Add(scriptsPanel);

            // Logs
            Panel logHeader = new Panel { Dock = DockStyle.Top, Height = 30 };
            Label lblLog = new Label { Text = "System Log", Dock = DockStyle.Left, Font = new Font("Segoe UI", 9F, FontStyle.Bold), Padding = new Padding(5) };
            btnCancel = new Button { Text = "CANCEL PROCESS", Dock = DockStyle.Right, Width = 120, BackColor = Color.IndianRed, ForeColor = Color.White, FlatStyle = FlatStyle.Flat, Visible = false };
            btnCancel.Click += BtnCancel_Click;

            Button btnCopyLog = new Button { Text = "Copy", Dock = DockStyle.Right, Width = 60, FlatStyle = FlatStyle.Flat };
            btnCopyLog.Click += (s,e) => {
                if (!string.IsNullOrEmpty(txtLog.Text)) {
                    try {
                        Clipboard.SetText(txtLog.Text);
                    } catch (System.Runtime.InteropServices.ExternalException) {
                        MessageBox.Show("Failed to copy to clipboard.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                }
            };

            Button btnSaveLog = new Button { Text = "Save", Dock = DockStyle.Right, Width = 60, FlatStyle = FlatStyle.Flat };
            btnSaveLog.Click += (s,e) => SaveLogToFile();

            logHeader.Controls.Add(btnCancel);
            logHeader.Controls.Add(btnCopyLog);
            logHeader.Controls.Add(btnSaveLog);
            logHeader.Controls.Add(lblLog);

            txtLog = new TextBox { Multiline = true, Dock = DockStyle.Fill, ReadOnly = true, ScrollBars = ScrollBars.Vertical, Font = new Font("Consolas", 9F), BackColor = Color.Black, ForeColor = Color.LightGray };

            splitContainer.Panel2.Controls.Add(txtLog);
            splitContainer.Panel2.Controls.Add(logHeader);

            contentPanel.Controls.Add(splitContainer);
            contentHeader.SendToBack(); // Ensure header is at top

            // Status Strip
            statusStrip = new StatusStrip();
            statusLabel = new ToolStripStatusLabel("Ready") { Spring = true, TextAlign = ContentAlignment.MiddleLeft };
            progressBar = new ToolStripProgressBar { Visible = false, Style = ProgressBarStyle.Marquee };
            statusStrip.Items.Add(statusLabel);
            statusStrip.Items.Add(progressBar);
            this.Controls.Add(statusStrip);
        }

        private void ScriptsPanel_Resize(object sender, EventArgs e)
        {
            // Responsive width adjustment for full-width panels (Dashboard, Help)
            // Defensive check for small widths to avoid exceptions
            if (scriptsPanel.Controls.Count > 0 && scriptsPanel.Width > 40)
            {
                foreach(Control c in scriptsPanel.Controls)
                {
                    if (c == dashboardPanel || c == helpPanel)
                    {
                        c.Width = scriptsPanel.Width - 40;
                    }
                }
            }
        }

        // --- Layout Helpers ---
        private Button CreateSidebarButton(string tag, string text)
        {
            Button btn = new Button();
            btn.Text = text;
            btn.Dock = DockStyle.Top;
            btn.Height = 45;
            btn.FlatStyle = FlatStyle.Flat;
            btn.FlatAppearance.BorderSize = 0;
            btn.TextAlign = ContentAlignment.MiddleLeft;
            btn.Padding = new Padding(15, 0, 0, 0);
            btn.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
            btn.Tag = tag;
            btn.Cursor = Cursors.Hand;
            btn.AccessibleName = text;
            btn.AccessibleRole = AccessibleRole.PushButton;
            btn.Click += SidebarButton_Click;
            return btn;
        }

        // --- Core Logic ---

        private void SidebarButton_Click(object sender, EventArgs e)
        {
            Button btn = sender as Button;
            if (btn != null) LoadCategory(btn.Tag.ToString());
        }

        private Panel GetOrAddCard(ScriptInfo s) {
            if (!scriptCardCache.ContainsKey(s.FileName)) {
                scriptCardCache[s.FileName] = CreateScriptCard(s);
            }
            return scriptCardCache[s.FileName];
        }

        private void LoadCategory(string category)
        {
            currentCategory = category;

            // Use SuspendLayout to prevent flickering during heavy UI updates
            this.SuspendLayout();
            scriptsPanel.SuspendLayout();

            // Just remove controls from view, do not dispose cached cards!
            scriptsPanel.Controls.Clear();

            // Update Sidebar UI
            foreach(var b in sidebarButtons) {
                bool isActive = (string)b.Tag == category;
                if (isActive) {
                    b.BackColor = isDarkMode ? Color.FromArgb(60,60,60) : Color.LightGray;
                    b.ForeColor = colAccent; // Highlight text
                    b.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
                } else {
                    b.BackColor = Color.Transparent;
                    b.ForeColor = isDarkMode ? Color.White : Color.Black;
                    b.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
                }
            }

            if (category == "DASHBOARD") RenderDashboard();
            else if (category == "HELP") RenderHelp();
            else
            {
                List<ScriptInfo> scripts = new List<ScriptInfo>();
                if (categories.ContainsKey(category)) scripts = categories[category];

                foreach(var s in scripts) {
                    scriptsPanel.Controls.Add(GetOrAddCard(s));
                }
            }

            ChkBatchMode_CheckedChanged(null, null); // Re-apply batch visibility
            scriptsPanel.ResumeLayout(true);
            this.ResumeLayout(true);
        }

        private void RenderDashboard()
        {
            // Re-create dashboard panel if missing or if we want to ensure fresh layout
            if (dashboardPanel == null) {
                dashboardPanel = new Panel { Width = Math.Max(100, scriptsPanel.Width - 40), AutoSize = true, Padding = new Padding(0,0,0,20) };

                // Header Section
                Label lblHeader = new Label { Text = "System Dashboard", Font = new Font("Segoe UI", 20F, FontStyle.Light), AutoSize = true, Location = new Point(0, 0), ForeColor = isDarkMode ? colTextDark : colTextLight, Tag = "THEMEABLE" };
                dashboardPanel.Controls.Add(lblHeader);

                Button btnRefresh = new Button { Text = "↻ Refresh Stats", Size = new Size(120, 30), Location = new Point(dashboardPanel.Width - 130, 10), FlatStyle = FlatStyle.Flat, BackColor = colAccent, ForeColor = Color.White };
                btnRefresh.Anchor = AnchorStyles.Top | AnchorStyles.Right;

                dashboardPanel.Controls.Add(btnRefresh);

                // System Info Card
                Panel infoCard = new Panel {
                    Location = new Point(0, 50),
                    Size = new Size(dashboardPanel.Width, 220), // Slightly taller for more info
                    BackColor = isDarkMode ? colCardDark : colCardLight,
                    Tag = "THEMEABLE_CARD"
                };

                Label lblInfo = new Label {
                    Text = GetDetailedSystemInfo(),
                    Font = new Font("Consolas", 10F),
                    AutoSize = true,
                    Location = new Point(20, 20),
                    ForeColor = isDarkMode ? colTextDark : colTextLight,
                    Tag = "THEMEABLE"
                };
                infoCard.Controls.Add(lblInfo);
                dashboardPanel.Controls.Add(infoCard);

                // Wire up refresh
                btnRefresh.Click += (s, e) => {
                     lblInfo.Text = "Refreshing...";
                     Application.DoEvents(); // Force UI update
                     lblInfo.Text = GetDetailedSystemInfo();
                };

                // Quick Actions Section
                Label lblQuick = new Label { Text = "Quick Maintenance", Font = new Font("Segoe UI", 14F, FontStyle.Regular), AutoSize = true, Location = new Point(0, infoCard.Bottom + 25), ForeColor = isDarkMode ? colTextDark : colTextLight, Tag = "THEMEABLE" };
                dashboardPanel.Controls.Add(lblQuick);

                FlowLayoutPanel quickFlow = new FlowLayoutPanel { Location = new Point(0, lblQuick.Bottom + 15), Width = dashboardPanel.Width, Height = 180, AutoScroll = false, Tag = "QUICK_FLOW" };

                // Added a few more useful quick actions
                string[] quickScripts = { "70_DetailedSysInfo.ps1", "2_InstallCleaningTools.ps1", "1_CreateRestorePoint.ps1", "9_DiskHealthCheck.ps1" };
                foreach(var s in quickScripts) {
                    ScriptInfo info = null;
                    foreach(var list in categories.Values) {
                        info = list.FirstOrDefault(x => x.FileName == s);
                        if (info != null) break;
                    }
                    if (info != null) quickFlow.Controls.Add(GetOrAddCard(info));
                }
                dashboardPanel.Controls.Add(quickFlow);
            }

            // Layout Updates
            if (scriptsPanel.Width > 40) {
                dashboardPanel.Width = scriptsPanel.Width - 40;
                // Update internal widths
                foreach(Control c in dashboardPanel.Controls) {
                    if (c.Tag != null && c.Tag.ToString() == "THEMEABLE_CARD") c.Width = dashboardPanel.Width;
                    if (c.Tag != null && c.Tag.ToString() == "QUICK_FLOW") c.Width = dashboardPanel.Width;
                }
            }

            scriptsPanel.Controls.Add(dashboardPanel);
        }

        private void RenderHelp()
        {
            if (helpPanel == null) {
                string helpPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "HELP.md");
                if (!File.Exists(helpPath)) helpPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "HELP.md");
                if (!File.Exists(helpPath)) helpPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "MaintenanceToolkit", "HELP.md");

                string content = null;
                if (File.Exists(helpPath)) content = File.ReadAllText(helpPath);

                // Fallback to embedded resource
                if (content == null) {
                    try {
                        var assembly = System.Reflection.Assembly.GetExecutingAssembly();
                        using (Stream stream = assembly.GetManifestResourceStream("HELP.md")) {
                            if (stream != null) {
                                using (StreamReader reader = new StreamReader(stream)) {
                                    content = reader.ReadToEnd();
                                }
                            }
                        }
                    } catch {}
                }

                if (content == null) content = "# Error\nHelp file not found.";

                // Basic Markdown to HTML
                string html = "<html><body style='font-family:Segoe UI; padding:20px; color:" + (isDarkMode ? "#EEE" : "#222") + "; background-color:" + (isDarkMode ? "#222" : "#FFF") + "'>";
                bool inList = false;

                foreach (var line in content.Split('\n')) {
                    string l = line.Trim();
                    string safe = System.Net.WebUtility.HtmlEncode(l);

                    if (l.StartsWith("# ")) {
                        if (inList) { html += "</ul>"; inList = false; }
                        html += "<h1>" + System.Net.WebUtility.HtmlEncode(l.Substring(2)) + "</h1>";
                    }
                    else if (l.StartsWith("## ")) {
                        if (inList) { html += "</ul>"; inList = false; }
                        html += "<h2>" + System.Net.WebUtility.HtmlEncode(l.Substring(3)) + "</h2>";
                    }
                    else if (l.StartsWith("### ")) {
                        if (inList) { html += "</ul>"; inList = false; }
                        html += "<h3>" + System.Net.WebUtility.HtmlEncode(l.Substring(4)) + "</h3>";
                    }
                    else if (l.StartsWith("- ")) {
                        if (!inList) { html += "<ul>"; inList = true; }
                        html += "<li>" + System.Net.WebUtility.HtmlEncode(l.Substring(2)) + "</li>";
                    }
                    else if (l.Length > 0) {
                        if (inList) { html += "</ul>"; inList = false; }
                        html += "<p>" + safe + "</p>";
                    }
                }

                if (inList) html += "</ul>";
                html += "</body></html>";

                WebBrowser web = new WebBrowser { Dock = DockStyle.Fill, MinimumSize = new Size(20,20), Tag = "WEB_HELP" };
                web.DocumentText = html;

                // Wrapper Panel to set size in flow layout
                helpPanel = new Panel { Width = Math.Max(100, scriptsPanel.Width - 40), Height = 600 };
                helpPanel.Controls.Add(web);
            }

            if (scriptsPanel.Width > 40) helpPanel.Width = scriptsPanel.Width - 40;

            scriptsPanel.Controls.Add(helpPanel);
        }

        private Panel CreateScriptCard(ScriptInfo script)
        {
            Panel card = new Panel();
            card.Size = new Size(280, 150);
            card.BackColor = isDarkMode ? colCardDark : colCardLight;
            card.Margin = new Padding(10);
            card.Tag = script;
            card.AccessibleName = script.DisplayName;
            card.AccessibleDescription = script.Description;
            card.AccessibleRole = AccessibleRole.Client;

            // Labels
            Label lblTitle = new Label { Text = script.DisplayName, Font = new Font("Segoe UI", 10F, FontStyle.Bold), Location = new Point(10, 10), AutoSize = true, ForeColor = isDarkMode ? colTextDark : colTextLight, Tag = "THEMEABLE" };
            Label lblDesc = new Label { Text = script.Description, Font = new Font("Segoe UI", 9F), Location = new Point(10, 35), Size = new Size(260, 60), ForeColor = isDarkMode ? Color.Gray : Color.DimGray, Tag = "THEMEABLE_DESC" };

            // Badges
            if (script.IsDestructive) { lblTitle.ForeColor = Color.Red; lblTitle.Text += " (!)"; }
            if (script.IsInteractive) { lblTitle.Text += " *"; }

            // Controls
            Button btnRun = new Button { Text = "RUN", Size = new Size(80, 30), Location = new Point(180, 110), FlatStyle = FlatStyle.Flat, BackColor = colAccent, ForeColor = Color.White };
            btnRun.AccessibleName = "Run " + script.DisplayName;
            btnRun.AccessibleRole = AccessibleRole.PushButton;
            btnRun.Click += (s, e) => {
                 if (script.IsDestructive && MessageBox.Show(string.Format("Warning: {0} is destructive.\nProceed?", script.DisplayName), "Warning", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.No) return;
                 RunScript(script);
            };

            CheckBox chkBatch = new CheckBox { Text = "Select", Location = new Point(10, 115), AutoSize = true, Visible = isBatchMode, Tag = "BATCH_CHK" };
            chkBatch.AccessibleName = "Select " + script.DisplayName + " for Batch";

            // Favorite Star
            Label lblFav = new Label { Text = favoriteScripts.Contains(script.FileName) ? "★" : "☆", Location = new Point(250, 5), AutoSize = true, Font = new Font("Segoe UI", 12F), Cursor = Cursors.Hand, ForeColor = Color.Gold };
            lblFav.AccessibleName = "Toggle Favorite for " + script.DisplayName;
            lblFav.AccessibleRole = AccessibleRole.PushButton;
            lblFav.Click += (s,e) => {
                ToggleFavorite(script);
                lblFav.Text = favoriteScripts.Contains(script.FileName) ? "★" : "☆";
            };

            card.Controls.Add(lblTitle);
            card.Controls.Add(lblDesc);
            card.Controls.Add(btnRun);
            card.Controls.Add(chkBatch);
            card.Controls.Add(lblFav);

            // Events for interactivity
            EventHandler hoverEnter = (s, e) => card.BackColor = isDarkMode ? colCardHoverDark : colCardHoverLight;
            EventHandler hoverLeave = (s, e) => card.BackColor = isDarkMode ? colCardDark : colCardLight;
            EventHandler doubleClick = (s, e) => {
                if (!isBatchMode) {
                     if (script.IsDestructive && MessageBox.Show(string.Format("Warning: {0} is destructive.\nProceed?", script.DisplayName), "Warning", MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.No) return;
                     RunScript(script);
                }
            };

            card.MouseEnter += hoverEnter;
            card.MouseLeave += hoverLeave;
            card.DoubleClick += doubleClick;

            foreach (Control c in card.Controls)
            {
                if (!(c is Button) && !(c is CheckBox)) // Don't override interactive controls
                {
                    c.MouseEnter += hoverEnter;
                    c.MouseLeave += hoverLeave;
                    c.DoubleClick += doubleClick;
                }
            }

            return card;
        }

        private void ToggleFavorite(ScriptInfo script)
        {
            if (favoriteScripts.Contains(script.FileName)) favoriteScripts.Remove(script.FileName);
            else favoriteScripts.Add(script.FileName);
            SaveSettings();

            // Rebuild favorites category from the updated set
            categories["FAVORITES"].Clear();
            foreach(var kvp in categories.Where(k => k.Key != "FAVORITES"))
            {
                foreach(var s in kvp.Value)
                {
                    if (favoriteScripts.Contains(s.FileName))
                        categories["FAVORITES"].Add(s);
                }
            }

            if (currentCategory == "FAVORITES") LoadCategory("FAVORITES");
        }

        // --- Execution Logic ---

        private void RunScript(ScriptInfo script)
        {
            if (Interlocked.CompareExchange(ref scriptRunning, 1, 0) != 0)
            {
                MessageBox.Show("A script is already running.");
                return;
            }

            Log("Starting: " + script.DisplayName);
            statusLabel.Text = "Running: " + script.DisplayName;
            progressBar.Visible = true;
            btnCancel.Visible = !script.IsInteractive;

            Task.Run(() => {
                try {
                    ExecuteScriptInternal(script);
                } finally {
                    if (!IsDisposed && IsHandleCreated) {
                        BeginInvoke((Action)(() => {
                            Log("Finished: " + script.DisplayName);
                            statusLabel.Text = "Ready";
                            progressBar.Visible = false;
                            btnCancel.Visible = false;
                        }));
                    }
                    Interlocked.Exchange(ref scriptRunning, 0);
                }
            });
        }

        private void ExtractEmbeddedScripts()
        {
            if (tempScriptDir != null) return;

            try {
                tempScriptDir = Path.Combine(Path.GetTempPath(), "SysMaintToolkit_" + Guid.NewGuid().ToString("N").Substring(0, 8));
                Directory.CreateDirectory(tempScriptDir);

                var assembly = System.Reflection.Assembly.GetExecutingAssembly();
                foreach (string resourceName in assembly.GetManifestResourceNames())
                {
                    if (resourceName.StartsWith("scripts/"))
                    {
                        // Resource name is like "scripts/lib/Common.ps1"
                        // We map this to tempScriptDir/lib/Common.ps1
                        // Note: fileName in resource is forward slash separated as we defined in BuildTool

                        string relPath = resourceName.Substring("scripts/".Length);
                        string fullPath = Path.Combine(tempScriptDir, relPath.Replace("/", Path.DirectorySeparatorChar.ToString()));

                        string dir = Path.GetDirectoryName(fullPath);
                        if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

                        using (Stream stream = assembly.GetManifestResourceStream(resourceName))
                        {
                            if (stream == null) {
                                if (!IsDisposed && IsHandleCreated)
                                    BeginInvoke((Action)(() => Log("Error: Missing resource stream for " + resourceName)));
                                else
                                    Debug.WriteLine("Error: Missing resource stream for " + resourceName);
                                continue;
                            }
                            using (FileStream fileStream = new FileStream(fullPath, FileMode.Create))
                            {
                                stream.CopyTo(fileStream);
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                Invoke((Action)(() => Log("Error extracting embedded scripts: " + ex.Message)));
            }
        }

        private string FindScriptPath(string fileName)
        {
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;

            // Priority 1: Local scripts folder (Development / portable extraction)
            // Restricted search order to prevent untrusted path execution risks.
            // We only search specifically adjacent 'scripts' or 'MaintenanceToolkit/scripts' folders.
            string[] localPaths = new string[] {
                Path.Combine(baseDir, "scripts", fileName),
                Path.Combine(baseDir, "MaintenanceToolkit", "scripts", fileName)
            };

            foreach (string p in localPaths)
            {
                if (File.Exists(p)) return p;
            }

            // Priority 2: Embedded Scripts (Standalone EXE)
            ExtractEmbeddedScripts();
            if (tempScriptDir != null)
            {
                string tempPath = Path.Combine(tempScriptDir, fileName);
                if (File.Exists(tempPath)) return tempPath;
            }

            return null;
        }

        private void ExecuteScriptInternal(ScriptInfo script)
        {
            string path = FindScriptPath(script.FileName);

            if (path == null) {
                Invoke((Action)(() => Log("Error: Script file not found: " + script.FileName)));
                return;
            }

            try {
                string args = string.Format("-NoProfile -ExecutionPolicy Bypass {0} -File \"{1}\"", script.IsInteractive ? "-NoExit" : "-NonInteractive", path);

                ProcessStartInfo psi = new ProcessStartInfo("powershell.exe", args);

                // Ensure we can set environment variables (requires UseShellExecute = false)
                psi.UseShellExecute = false;

                // If interactive, we want a window. If not, no window.
                psi.CreateNoWindow = !script.IsInteractive;

                // Set Diagnostic Env Var
                if (chkVerbose.Checked) {
                    psi.EnvironmentVariables["MAINTENANCE_DIAG"] = "1";
                } else {
                    if (psi.EnvironmentVariables.ContainsKey("MAINTENANCE_DIAG")) {
                        psi.EnvironmentVariables.Remove("MAINTENANCE_DIAG");
                    }
                }
                if (!script.IsInteractive) {
                    psi.StandardOutputEncoding = Encoding.UTF8;
                    psi.StandardErrorEncoding = Encoding.UTF8;
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                }

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
            } catch (Exception ex) { Invoke((Action)(()=>Log("Error launching process: " + ex.Message))); }
        }

        private async void BtnRunBatch_Click(object sender, EventArgs e)
        {
            var queue = new List<ScriptInfo>();
            // Iterate cache to find selected
            foreach(var card in scriptCardCache.Values) {
                foreach(Control c in card.Controls) {
                    if (c is CheckBox && ((CheckBox)c).Checked && ((CheckBox)c).Tag.ToString() == "BATCH_CHK") {
                        queue.Add((ScriptInfo)card.Tag);
                    }
                }
            }
            if (queue.Count == 0) return;

            if (MessageBox.Show(string.Format("Ready to execute {0} scripts?\nThis process will run sequentially.", queue.Count), "Confirm Batch Run", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes)
                return;

            if (Interlocked.CompareExchange(ref scriptRunning, 1, 0) != 0)
            {
                MessageBox.Show("A script is already running.");
                return;
            }

            batchCts = new CancellationTokenSource();
            btnRunBatch.Enabled = false;
            progressBar.Visible = true;
            btnCancel.Visible = true;

            try {
                progressBar.Style = ProgressBarStyle.Continuous;
                progressBar.Maximum = queue.Count;
                progressBar.Value = 0;

                int i=0;
                foreach(var s in queue) {
                     if (batchCts.IsCancellationRequested) break;
                     statusLabel.Text = string.Format("Batch: ({0}/{1}) {2}", i+1, queue.Count, s.DisplayName);
                     await Task.Run(() => ExecuteScriptInternal(s));
                     i++;
                     progressBar.Value = i;
                }
                Log("Batch Execution Completed.");
            } finally {
                btnRunBatch.Enabled = true;
                progressBar.Visible = false;
                btnCancel.Visible = false;
                statusLabel.Text = "Ready";
                progressBar.Style = ProgressBarStyle.Marquee; // Reset for single runs
                Interlocked.Exchange(ref scriptRunning, 0);
            }
        }

        private void BtnCancel_Click(object sender, EventArgs e) {
            if (batchCts != null) batchCts.Cancel();
            lock(processLock) {
                if (currentProcess != null && !currentProcess.HasExited) {
                    try {
                        currentProcess.Kill();
                        Log("Process cancelled by user.");
                        currentProcess = null;
                        Interlocked.Exchange(ref scriptRunning, 0);
                    } catch (Exception ex) {
                        Log("Error cancelling process: " + ex.Message);
                    }
                }
            }
        }

        // --- Helper Logic ---
        private void Log(string msg) {
            if (txtLog.InvokeRequired) { txtLog.Invoke((Action)(()=>Log(msg))); return; }
            txtLog.AppendText(string.Format("[{0}] {1}\r\n", DateTime.Now.ToShortTimeString(), msg));
            txtLog.ScrollToCaret();
        }

        private void TxtSearch_TextChanged(object sender, EventArgs e) {
            string q = txtSearch.Text.Trim().ToLower();
            if (string.IsNullOrWhiteSpace(q)) {
                 LoadCategory(currentCategory);
                 return;
            }

            scriptsPanel.SuspendLayout();
            scriptsPanel.Controls.Clear();

            HashSet<string> seen = new HashSet<string>();
            foreach(var cat in categories.Values) {
                foreach(var s in cat) {
                    if ((s.DisplayName.ToLower().Contains(q) || s.Description.ToLower().Contains(q)) && seen.Add(s.FileName)) {
                        scriptsPanel.Controls.Add(GetOrAddCard(s));
                    }
                }
            }
            scriptsPanel.ResumeLayout();
        }

        private void ChkBatchMode_CheckedChanged(object sender, EventArgs e) {
            isBatchMode = chkBatchMode.Checked;
            chkBatchMode.BackColor = isBatchMode ? colAccent : Color.Transparent;
            chkBatchMode.ForeColor = isBatchMode ? Color.White : (isDarkMode ? colTextDark : colTextLight);

            btnRunBatch.Visible = isBatchMode;
            btnSelectAll.Visible = isBatchMode;
            btnSelectNone.Visible = isBatchMode;

            // Update all cached cards
            foreach(var card in scriptCardCache.Values) {
                foreach(Control c in card.Controls) {
                    if (c is CheckBox && c.Tag != null && c.Tag.ToString() == "BATCH_CHK") c.Visible = isBatchMode;
                }
            }
        }

        private void SetAllBatchSelection(bool val) {
             // Update all cached cards
             foreach(var card in scriptCardCache.Values) {
                foreach(Control c in card.Controls) {
                    if (c is CheckBox && c.Tag != null && c.Tag.ToString() == "BATCH_CHK") ((CheckBox)c).Checked = val;
                }
            }
        }

        private void ToggleTheme() {
            isDarkMode = !isDarkMode;
            SaveSettings();

            // Dispose old full-width panels to avoid memory leaks if we recreate them
            if (dashboardPanel != null) { dashboardPanel.Dispose(); dashboardPanel = null; }
            if (helpPanel != null) { helpPanel.Dispose(); helpPanel = null; }

            ApplyTheme();

            if (currentCategory == "DASHBOARD") RenderDashboard();
            else if (currentCategory == "HELP") RenderHelp();
            else LoadCategory(currentCategory);
        }

        private void ApplyTheme() {
            if (SystemInformation.HighContrast) return; // Respect system HC

            Color bg = isDarkMode ? colContentDark : colContentLight;
            Color fg = isDarkMode ? colTextDark : colTextLight;

            this.BackColor = bg;
            this.ForeColor = fg;

            sidebarPanel.BackColor = isDarkMode ? colSidebarDark : colSidebarLight;

            // Sidebar buttons
            foreach(var b in sidebarButtons) {
                b.ForeColor = isDarkMode ? Color.White : Color.Black;
                if ((string)b.Tag == currentCategory) b.BackColor = isDarkMode ? Color.FromArgb(60,60,60) : Color.LightGray;
                else b.BackColor = Color.Transparent;
            }

            txtLog.BackColor = isDarkMode ? Color.Black : Color.White;
            txtLog.ForeColor = isDarkMode ? Color.LimeGreen : Color.Black;

            statusStrip.BackColor = isDarkMode ? Color.FromArgb(45,45,48) : Color.WhiteSmoke;
            statusStrip.ForeColor = isDarkMode ? Color.White : Color.Black;

            chkBatchMode.ForeColor = isBatchMode ? Color.White : fg;
            chkVerbose.ForeColor = chkVerbose.Checked ? Color.White : fg;
            chkVerbose.BackColor = chkVerbose.Checked ? colAccent : Color.Transparent;

            // Update Cached Cards
            foreach(var card in scriptCardCache.Values) {
                card.BackColor = isDarkMode ? colCardDark : colCardLight;
                foreach(Control c in card.Controls) {
                    if (c.Tag != null && c.Tag.ToString() == "THEMEABLE") c.ForeColor = isDarkMode ? colTextDark : colTextLight;
                    if (c.Tag != null && c.Tag.ToString() == "THEMEABLE_DESC") c.ForeColor = isDarkMode ? Color.Gray : Color.DimGray;
                }
            }
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

        private void SaveLogToFile()
        {
            using (SaveFileDialog sfd = new SaveFileDialog())
            {
                sfd.Filter = "Text Files|*.txt";
                sfd.FileName = "Log_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".txt";
                if (sfd.ShowDialog() == DialogResult.OK) {
                    try { File.WriteAllText(sfd.FileName, txtLog.Text); } catch(Exception ex) { MessageBox.Show("Error: "+ex.Message); }
                }
            }
        }

        public static bool IsAdministrator()
        {
            using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
            {
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            }
        }

        private string GetDetailedSystemInfo()
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("   OS:       " + GetOSFriendlyName());
            sb.AppendLine("   Machine:  " + Environment.MachineName);
            sb.AppendLine("   User:     " + Environment.UserName);
            sb.AppendLine("   Uptime:   " + GetUptime());

            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Name, NumberOfCores, NumberOfLogicalProcessors FROM Win32_Processor"))
                {
                    foreach (var item in searcher.Get())
                    {
                        string cpu = item["Name"].ToString();
                        // Truncate CPU name if too long for cleaner display
                        if (cpu.Length > 40) cpu = cpu.Substring(0, 37) + "...";
                        sb.AppendLine("   CPU:      " + cpu);
                        sb.AppendLine(string.Format("   Cores:    {0} | Threads: {1}", item["NumberOfCores"], item["NumberOfLogicalProcessors"]));
                    }
                }

                try {
                    using (var searcher = new ManagementObjectSearcher("SELECT Name, DriverVersion FROM Win32_VideoController"))
                    {
                        foreach (var item in searcher.Get())
                        {
                            sb.AppendLine("   GPU:      " + item["Name"].ToString());
                        }
                    }
                } catch {}

                using (var searcher = new ManagementObjectSearcher("SELECT TotalVisibleMemorySize, FreePhysicalMemory FROM Win32_OperatingSystem"))
                {
                    foreach (var item in searcher.Get())
                    {
                        long totalRam = Convert.ToInt64(item["TotalVisibleMemorySize"]) / 1024;
                        long freeRam = Convert.ToInt64(item["FreePhysicalMemory"]) / 1024;
                        double percentFree = (double)freeRam / totalRam * 100;
                        sb.AppendLine(string.Format("   RAM:      {0} MB Free / {1} MB Total ({2:F1}% Free)", freeRam, totalRam, percentFree));
                    }
                }

                // Check Pending Reboot
                bool reboot = false;
                try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")) { if (key != null) reboot = true; } } catch {}
                try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")) { if (key != null) reboot = true; } } catch {}

                if (reboot) sb.AppendLine("   STATUS:   Pending Reboot (!)");

                sb.AppendLine("   --------------------------------------------------");
                foreach (var drive in DriveInfo.GetDrives()) {
                    if (drive.IsReady && drive.DriveType == DriveType.Fixed) {
                        long freeGb = drive.TotalFreeSpace / 1073741824;
                        long totalGb = drive.TotalSize / 1073741824;
                        double percentFree = (double)drive.TotalFreeSpace / drive.TotalSize * 100;
                        sb.AppendLine(string.Format("   Disk ({0}): {1} GB Free / {2} GB Total ({3:F1}% Free)", drive.Name, freeGb, totalGb, percentFree));
                    }
                }
            } catch (Exception ex) {
                sb.AppendLine("Error gathering info: " + ex.Message);
            }
            return sb.ToString();
        }

        private string GetOSFriendlyName()
        {
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Caption FROM Win32_OperatingSystem"))
                {
                    foreach (var item in searcher.Get()) return item["Caption"].ToString();
                }
            } catch {}
            return Environment.OSVersion.ToString();
        }

        private string GetUptime()
        {
            try {
                using (var uptime = new PerformanceCounter("System", "System Up Time"))
                {
                    uptime.NextValue();
                    TimeSpan ts = TimeSpan.FromSeconds(uptime.NextValue());
                    return string.Format("{0}d {1}h {2}m", ts.Days, ts.Hours, ts.Minutes);
                }
            } catch { return "Unknown"; }
        }

        private void InitializeData()
        {
            string[] cats = { "CLEAN", "REPAIR", "HARDWARE", "NETWORK", "SECURITY", "UTILS" };
            foreach (var c in cats) categories[c] = new List<ScriptInfo>();
            categories["FAVORITES"] = new List<ScriptInfo>();

            // CLEAN
            categories["CLEAN"].Add(new ScriptInfo("2_InstallCleaningTools.ps1", "Install Cleaners", "Installs Malwarebytes and BleachBit via Winget."));
            categories["CLEAN"].Add(new ScriptInfo("4_DeepCleanDisk.ps1", "Deep Disk Cleanup", "Runs Windows Disk Cleanup with advanced options."));
            categories["CLEAN"].Add(new ScriptInfo("75_ClearBrowserCache.ps1", "Clear Browser Cache", "Clears cache for Chrome, Edge, and Firefox."));
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
            categories["HARDWARE"].Add(new ScriptInfo("84_DriverVersionAudit.ps1", "Audit Drivers", "Lists third-party drivers."));
            categories["HARDWARE"].Add(new ScriptInfo("22_RemoveGhostDevices.ps1", "Remove Ghost Devices", "Helps remove unused hidden devices."));
            categories["HARDWARE"].Add(new ScriptInfo("34_KeyTester.ps1", "Keyboard Tester", "Displays raw key input codes.", true));
            categories["HARDWARE"].Add(new ScriptInfo("37_PixelFixer.ps1", "Dead Pixel Fixer", "Flashes colors to unstuck pixels.", true));
            categories["HARDWARE"].Add(new ScriptInfo("39_SleepStudy.ps1", "Sleep Study", "Analyzes battery drain during sleep."));
            categories["HARDWARE"].Add(new ScriptInfo("40_RunRamTest.ps1", "RAM Memory Test", "Schedules a memory test on reboot.", true));
            categories["HARDWARE"].Add(new ScriptInfo("41_CpuStressTest.ps1", "CPU Stress Test", "High load test for stability.", true));
            categories["HARDWARE"].Add(new ScriptInfo("52_ReadChkdskLogs.ps1", "Read Chkdsk Logs", "Reads the latest Check Disk result from logs."));
            categories["HARDWARE"].Add(new ScriptInfo("64_CheckVirtualization.ps1", "Check Virtualization", "Checks if VT-x/AMD-V is enabled."));
            categories["HARDWARE"].Add(new ScriptInfo("65_DisableUsbSuspend.ps1", "Disable USB Suspend", "Fixes USB lag issues."));
            categories["HARDWARE"].Add(new ScriptInfo("66_HardwareMonitor.ps1", "Hardware Monitor", "Real-time CPU/RAM/Disk monitor.", true));
            categories["HARDWARE"].Add(new ScriptInfo("68_SSDTrim.ps1", "SSD Trim Optimization", "Forces a re-trim of the C: drive."));
            categories["HARDWARE"].Add(new ScriptInfo("72_ResetBluetooth.ps1", "Reset Bluetooth", "Restarts Bluetooth services."));

            // NETWORK
            categories["NETWORK"].Add(new ScriptInfo("7_NetworkReset.ps1", "Network Reset", "Flushes DNS and resets IP/Winsock."));
            categories["NETWORK"].Add(new ScriptInfo("19_GetWifiPasswords.ps1", "Show Wi-Fi Passwords", "Decrypts saved Wi-Fi passwords."));
            categories["NETWORK"].Add(new ScriptInfo("20_DnsBenchmark.ps1", "DNS Benchmark", "Tests speed of DNS providers."));
            categories["NETWORK"].Add(new ScriptInfo("30_LocalPortScan.ps1", "Local Port Scanner", "Scans for open listening ports."));
            categories["NETWORK"].Add(new ScriptInfo("47_NetworkHeartbeat.ps1", "Network Heartbeat", "Monitors ping and packet loss.", true));
            categories["NETWORK"].Add(new ScriptInfo("53_OptimizeNetwork.ps1", "Optimize Internet", "Tunes TCP receive window."));
            categories["NETWORK"].Add(new ScriptInfo("58_BlockWebsite.ps1", "Block Website", "Blocks a domain via Hosts file.", true));
            categories["NETWORK"].Add(new ScriptInfo("67_WifiScanner.ps1", "Wi-Fi Scanner", "Scans for nearby Wi-Fi networks.", true));
            categories["NETWORK"].Add(new ScriptInfo("69_WlanReport.ps1", "Wireless Report", "Generates a detailed HTML Wi-Fi report."));
            categories["NETWORK"].Add(new ScriptInfo("71_FirewallAudit.ps1", "Firewall Audit", "Checks firewall profiles and rules."));
            categories["NETWORK"].Add(new ScriptInfo("79_ProcessConnections.ps1", "Process Connections", "Lists apps using the network.", true));
            categories["NETWORK"].Add(new ScriptInfo("80_FlushDNSCache.ps1", "Flush DNS Cache", "Quickly flushes DNS and ARP caches."));

            // SECURITY
            categories["SECURITY"].Add(new ScriptInfo("8_PrivacyHardening.ps1", "Privacy Hardening", "Disables telemetry and ad ID."));
            categories["SECURITY"].Add(new ScriptInfo("21_AuditScheduledTasks.ps1", "Audit Scheduled Tasks", "Lists suspicious scheduled tasks."));
            categories["SECURITY"].Add(new ScriptInfo("24_GetBitLockerKey.ps1", "Get BitLocker Key", "Retrieves BitLocker recovery key."));
            categories["SECURITY"].Add(new ScriptInfo("31_UsbWriteProtect.ps1", "USB Write Protect", "Sets USB drives to Read-Only.", true));
            categories["SECURITY"].Add(new ScriptInfo("32_VerifyFileHash.ps1", "Verify File Hash", "Calculates SHA256 hash of a file.", true));
            categories["SECURITY"].Add(new ScriptInfo("42_AuditNonMsServices.ps1", "Audit Services", "Lists non-Microsoft running services."));
            categories["SECURITY"].Add(new ScriptInfo("48_AuditUserAccounts.ps1", "Audit Users", "Lists local user accounts."));
            categories["SECURITY"].Add(new ScriptInfo("78_UserLoginHistory.ps1", "Login History", "Audits recent user logins.", true));
            categories["SECURITY"].Add(new ScriptInfo("49_SecureDelete.ps1", "Secure Delete", "Wipes a file (3 passes).", true, true));
            categories["SECURITY"].Add(new ScriptInfo("59_PanicButton.ps1", "Panic Button", "Mutes, clears clipboard, minimizes all."));

            // UTILS
            categories["UTILS"].Add(new ScriptInfo("6_OptimizeAndUpdate.ps1", "Update All Software", "Runs Winget upgrade all."));
            categories["UTILS"].Add(new ScriptInfo("74_WindowsUpdateHistory.ps1", "Update History", "Lists recent Windows Updates.", true));
            categories["UTILS"].Add(new ScriptInfo("15_ClearEventLogs.ps1", "Clear Event Logs", "Clears all Windows Event Logs."));
            categories["UTILS"].Add(new ScriptInfo("23_FindLargeFiles.ps1", "Find Large Files", "Scans user profile for large files."));
            categories["UTILS"].Add(new ScriptInfo("26_ClearClipboard.ps1", "Clear Clipboard", "Wipes clipboard history."));
            categories["UTILS"].Add(new ScriptInfo("77_ResetWindowsSearch.ps1", "Reset Search Index", "Rebuilds Windows Search database."));
            categories["UTILS"].Add(new ScriptInfo("27_CheckStability.ps1", "Check Stability", "Checks for recent crashes/BSODs."));
            categories["UTILS"].Add(new ScriptInfo("76_SystemStabilityScore.ps1", "Stability Score", "View System Stability Index history.", true));
            categories["UTILS"].Add(new ScriptInfo("28_GetBiosKey.ps1", "Get BIOS Key", "Retrieves OEM Windows Key."));
            categories["UTILS"].Add(new ScriptInfo("29_ProcessFreezer.ps1", "Process Freezer", "Suspends/Resumes processes.", true));
            categories["UTILS"].Add(new ScriptInfo("73_StartupAppsManager.ps1", "Startup Manager", "Lists startup applications.", true));
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
            categories["UTILS"].Add(new ScriptInfo("70_DetailedSysInfo.ps1", "Export System Spec", "Dumps full system info to a text file."));

            // Populate Favorites
            foreach(var kvp in categories) {
                if (kvp.Key == "FAVORITES") continue;
                foreach(var s in kvp.Value) {
                    if (favoriteScripts.Contains(s.FileName)) categories["FAVORITES"].Add(s);
                }
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
