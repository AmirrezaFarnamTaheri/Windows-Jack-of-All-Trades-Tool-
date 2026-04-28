using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Diagnostics;
using System.Windows.Forms;
using SystemMaintenance.Core;

namespace SystemMaintenance.Controls
{
    public class ReportViewerControl : UserControl
    {
        private ListView lstReports;
        private Label lblHeader;
        private Button btnRefresh;
        private Button btnOpenEvidence;

        public ReportViewerControl()
        {
            this.Dock = DockStyle.Fill;
            this.BackColor = ThemeManager.GetContentColor(ConfigManager.IsDarkMode);

            Panel headerBar = new Panel { Dock = DockStyle.Top, Height = 52, Padding = new Padding(10, 8, 10, 8) };
            headerBar.BackColor = ThemeManager.GetContentColor(ConfigManager.IsDarkMode);

            lblHeader = new Label {
                Text = "Maintenance Reports",
                Font = new Font("Segoe UI", 16F, FontStyle.Regular),
                Dock = DockStyle.Left,
                AutoSize = true,
                TextAlign = ContentAlignment.MiddleLeft,
                ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode)
            };

            btnRefresh = new Button {
                Text = "Refresh",
                Dock = DockStyle.Right,
                Width = 90,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeManager.ColAccent,
                ForeColor = Color.White
            };
            btnRefresh.FlatAppearance.BorderSize = 0;
            btnRefresh.Click += (s, e) => RefreshReports();

            btnOpenEvidence = new Button {
                Text = "Evidence Folder",
                Dock = DockStyle.Right,
                Width = 130,
                FlatStyle = FlatStyle.Flat
            };
            btnOpenEvidence.FlatAppearance.BorderSize = 0;
            btnOpenEvidence.Click += (s, e) => {
                try {
                    string evidenceRoot = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                        "MaintenanceToolkit",
                        "Evidence");
                    if (!Directory.Exists(evidenceRoot)) Directory.CreateDirectory(evidenceRoot);
                    Process.Start(evidenceRoot);
                } catch {
                    MessageBox.Show("Could not open evidence folder.");
                }
            };

            headerBar.Controls.Add(btnRefresh);
            headerBar.Controls.Add(btnOpenEvidence);
            headerBar.Controls.Add(lblHeader);

            lstReports = new ListView {
                Dock = DockStyle.Fill,
                View = View.Details,
                FullRowSelect = true,
                BackColor = ThemeManager.GetCardColor(ConfigManager.IsDarkMode),
                ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode),
                BorderStyle = BorderStyle.None
            };

            lstReports.Columns.Add("Date", 150);
            lstReports.Columns.Add("Report Name", 400);
            lstReports.Columns.Add("Size", 100);

            lstReports.DoubleClick += (s, e) => {
                if (lstReports.SelectedItems.Count > 0) {
                    string path = (string)lstReports.SelectedItems[0].Tag;
                    try { Process.Start(path); } catch { MessageBox.Show("Could not open report."); }
                }
            };

            this.Controls.Add(lstReports);
            this.Controls.Add(headerBar);

            this.Resize += (s, e) => { SizeReportListColumns(); };
            RefreshReports();
        }

        private void SizeReportListColumns()
        {
            if (lstReports == null || !lstReports.IsHandleCreated) return;
            if (lstReports.Columns.Count < 3) return;
            int w = lstReports.ClientSize.Width - 24;
            if (w < 200) return;
            int c0 = 150;
            int c2 = 90;
            int c1 = w - c0 - c2;
            if (c1 < 120) c1 = 120;
            lstReports.Columns[0].Width = c0;
            lstReports.Columns[1].Width = c1;
            lstReports.Columns[2].Width = c2;
        }

        public void RefreshReports()
        {
            lstReports.Items.Clear();
            string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
            string evidenceRootPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "MaintenanceToolkit",
                "Evidence");

            // Collect HTML reports from Desktop + Evidence bundles (including Diagnostics Center)
            var files = Directory.GetFiles(desktop, "*.html")
                                 .Select(f => new FileInfo(f))
                                 .ToList();

            try {
                if (Directory.Exists(evidenceRootPath)) {
                    files.AddRange(Directory.GetFiles(evidenceRootPath, "*.html", SearchOption.AllDirectories)
                                            .Select(f => new FileInfo(f)));
                }
            } catch {}

            files = files.OrderByDescending(f => f.LastWriteTime).ToList();

            foreach (var f in files)
            {
                // Simple heuristics: keep reports that match our typical naming patterns
                bool looksLikeToolkitReport =
                    f.Name.Contains("_202") ||
                    f.Name.StartsWith("DiagnosticsCenter_", StringComparison.OrdinalIgnoreCase) ||
                    f.Name.IndexOf("Report", StringComparison.OrdinalIgnoreCase) >= 0;

                if (looksLikeToolkitReport && f.Name.EndsWith(".html"))
                {
                    var item = new ListViewItem(f.LastWriteTime.ToString("g"));
                    item.SubItems.Add(f.Name);
                    item.SubItems.Add(FormatSize(f.Length));
                    item.Tag = f.FullName;
                    lstReports.Items.Add(item);
                }
            }
            SizeReportListColumns();
        }

        public void ApplyTheme()
        {
            this.BackColor = ThemeManager.GetContentColor(ConfigManager.IsDarkMode);
            lblHeader.ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode);
            lstReports.BackColor = ThemeManager.GetCardColor(ConfigManager.IsDarkMode);
            lstReports.ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode);
            if (btnRefresh != null) btnRefresh.BackColor = ThemeManager.ColAccent;
            if (btnRefresh != null) btnRefresh.ForeColor = Color.White;
        }

        private string FormatSize(long bytes)
        {
            if (bytes > 1024 * 1024) return (bytes / 1024 / 1024) + " MB";
            if (bytes > 1024) return (bytes / 1024) + " KB";
            return bytes + " B";
        }
    }
}
