using System;
using System.Drawing;
using System.Windows.Forms;
using SystemMaintenance.Models;
using SystemMaintenance.Core;

namespace SystemMaintenance.Controls.Widgets
{
    public class SystemHeaderWidget : DashboardWidget
    {
        private Label lblOS;
        private Label lblUptime;
        private Label lblReboot;

        public SystemHeaderWidget() : base("Operating System")
        {
            this.Height = 80;

            lblOS = new Label { Location = new Point(10, 10), AutoSize = true, Text = "OS: Loading..." };
            lblUptime = new Label { Location = new Point(10, 35), AutoSize = true, Text = "Uptime: ..." };

            lblReboot = new Label {
                Text = "⚠ Reboot Pending",
                Location = new Point(200, 10),
                AutoSize = true,
                ForeColor = Color.OrangeRed,
                Visible = false,
                Font = new Font("Segoe UI", 10F, FontStyle.Bold)
            };

            pnlContent.Controls.Add(lblOS);
            pnlContent.Controls.Add(lblUptime);
            pnlContent.Controls.Add(lblReboot);
        }

        public override void UpdateData(SystemStatsData data)
        {
            if (data == null) return;
            lblOS.Text = string.Format("{0} | User: {1}", data.OS, Environment.UserName);
            lblUptime.Text = "Uptime: " + data.Uptime;
            lblReboot.Visible = data.RebootPending;
        }
    }
}
