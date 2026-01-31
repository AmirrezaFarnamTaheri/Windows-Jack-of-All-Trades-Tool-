using System;
using System.Drawing;
using System.Windows.Forms;
using SystemMaintenance.Models;
using SystemMaintenance.Core;

namespace SystemMaintenance.Controls.Widgets
{
    public class DriveWidget : DashboardWidget
    {
        private FlowLayoutPanel pnlDrives;

        public DriveWidget() : base("Storage Status")
        {
            this.AutoSize = true;
            this.AutoSizeMode = AutoSizeMode.GrowAndShrink;

            pnlDrives = new FlowLayoutPanel {
                Dock = DockStyle.Top,
                AutoSize = true,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false
            };

            pnlContent.Controls.Add(pnlDrives);
            // Ensure width tracking
            pnlContent.Resize += (s,e) => {
                foreach(Control c in pnlDrives.Controls) c.Width = pnlDrives.Width - 10;
            };
        }

        public override void UpdateData(SystemStatsData data)
        {
            pnlDrives.Controls.Clear();
            foreach(var d in data.Drives)
            {
                Panel p = new Panel { Height = 40, Width = pnlContent.Width - 10 };
                Label l = new Label { Text = string.Format("{0} {1}GB Free", d.Name, d.FreeSpace), AutoSize = true, Location = new Point(0,0), ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode) };

                int usage = 100 - (int)Math.Min(100, Math.Max(0, d.PercentFree));
                ProgressBar pb = new ProgressBar { Location = new Point(0, 20), Width = p.Width, Height = 8, Value = usage };

                p.Controls.Add(l);
                p.Controls.Add(pb);
                pnlDrives.Controls.Add(p);

                // Keep resizing logic simple
                p.Resize += (s,e) => pb.Width = p.Width;
            }
        }
    }
}
