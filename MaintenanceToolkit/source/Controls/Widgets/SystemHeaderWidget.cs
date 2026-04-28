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
            lblOS = new Label { Left = 10, Top = 10, AutoSize = true, Text = "OS: Loading..." };
            lblUptime = new Label { Left = 10, AutoSize = true, Text = "Uptime: ..." };

            lblReboot = new Label {
                Text = "⚠ Reboot Pending",
                AutoSize = true,
                ForeColor = Color.OrangeRed,
                Visible = false,
                Font = new Font("Segoe UI", 10F, FontStyle.Bold)
            };

            pnlContent.Controls.Add(lblOS);
            pnlContent.Controls.Add(lblUptime);
            pnlContent.Controls.Add(lblReboot);
            pnlContent.Resize += (s, e) => LayoutContent();
            LayoutContent();
        }

        private void LayoutContent()
        {
            int pad = 10;
            int cw = Math.Max(80, pnlContent.ClientSize.Width - 2 * pad);
            int reserveRight = lblReboot.Visible ? lblReboot.Width + pad : pad;
            lblOS.MaximumSize = new Size(Math.Max(60, cw - reserveRight), 0);
            lblOS.Left = pad;
            lblOS.Top = pad;
            lblOS.PerformLayout();
            if (lblReboot.Visible)
            {
                lblReboot.Left = pnlContent.ClientSize.Width - lblReboot.Width - pad;
                lblReboot.Top = pad;
            }
            lblUptime.MaximumSize = new Size(cw, 0);
            lblUptime.Left = pad;
            lblUptime.Top = lblOS.Bottom + 6;
            lblUptime.PerformLayout();
            int innerBottom = Math.Max(lblUptime.Bottom, lblReboot.Visible ? lblReboot.Bottom : lblUptime.Bottom) + pad;
            int h = lblHeader.Height + pnlContent.Padding.Vertical + innerBottom + this.Padding.Vertical + 2;
            if (h < MinimumSize.Height) h = MinimumSize.Height;
            this.Height = h;
        }

        public override void UpdateData(SystemStatsData data)
        {
            if (data == null) return;
            lblOS.Text = string.Format("{0} | User: {1}", data.OS, Environment.UserName);
            lblUptime.Text = "Uptime: " + data.Uptime;
            lblReboot.Visible = data.RebootPending;
            LayoutContent();
        }
    }
}
