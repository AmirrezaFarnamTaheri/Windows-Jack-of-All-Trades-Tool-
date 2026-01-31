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
            this.Height = 120;

            lblCpu = new Label { Location = new Point(10, 10), AutoSize = true, Text = "CPU: Loading..." };
            lblRam = new Label { Location = new Point(10, 40), AutoSize = true, Text = "RAM: Loading..." };

            pbRam = new ProgressBar { Location = new Point(10, 70), Height = 15, Width = 200, Style = ProgressBarStyle.Continuous };

            pnlContent.Controls.Add(lblCpu);
            pnlContent.Controls.Add(lblRam);
            pnlContent.Controls.Add(pbRam);

            pnlContent.Resize += (s,e) => pbRam.Width = pnlContent.Width - 20;
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
        }
    }
}
