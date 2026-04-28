using System;
using System.Drawing;
using System.Windows.Forms;
using SystemMaintenance.Models;
using SystemMaintenance.Core;

namespace SystemMaintenance.Controls.Widgets
{
    public class CpuRamWidget : DashboardWidget
    {
        private Label lblCpu;
        private Label lblRam;
        private ProgressBar pbRam;

        public CpuRamWidget() : base("System Performance")
        {
            this.MinimumSize = new Size(200, 130);

            lblCpu = new Label { Left = 10, Top = 10, AutoSize = true, Text = "CPU: Loading..." };
            lblRam = new Label { Left = 10, AutoSize = true, Text = "RAM: Loading..." };

            pbRam = new ProgressBar { Height = 18, Style = ProgressBarStyle.Continuous };

            pnlContent.Controls.Add(lblCpu);
            pnlContent.Controls.Add(lblRam);
            pnlContent.Controls.Add(pbRam);

            pnlContent.Resize += (s, e) => LayoutContent();
            LayoutContent();
        }

        private void LayoutContent()
        {
            int pad = 10;
            int cw = Math.Max(80, pnlContent.ClientSize.Width - 2 * pad);
            lblCpu.MaximumSize = new Size(cw, 0);
            lblCpu.Left = pad;
            lblCpu.Top = pad;
            lblCpu.PerformLayout();
            lblRam.MaximumSize = new Size(cw, 0);
            lblRam.Left = pad;
            lblRam.Top = lblCpu.Bottom + 6;
            lblRam.PerformLayout();
            pbRam.Left = pad;
            pbRam.Top = lblRam.Bottom + 8;
            pbRam.Width = Math.Max(60, pnlContent.ClientSize.Width - 2 * pad);
            int innerBottom = pbRam.Bottom + pad;
            int h = lblHeader.Height + pnlContent.Padding.Vertical + innerBottom + this.Padding.Vertical + 2;
            if (h < MinimumSize.Height) h = MinimumSize.Height;
            this.Height = h;
        }

        public override void UpdateData(SystemStatsData data)
        {
            if (data == null) return;

            lblCpu.Text = string.Format("CPU: {0}\n({1} Cores / {2} Threads)",
                string.IsNullOrEmpty(data.CPU) ? "Unknown" : data.CPU,
                data.Cores, data.Threads);

            double ramPct = 0;
            if (data.RamTotal > 0) ramPct = (1.0 - ((double)data.RamFree / data.RamTotal)) * 100;

            lblRam.Text = string.Format("RAM Usage: {0:F1}% ({1} MB Free)", ramPct, data.RamFree);
            pbRam.Value = (int)Math.Min(100, Math.Max(0, ramPct));
            LayoutContent();
        }
    }
}
