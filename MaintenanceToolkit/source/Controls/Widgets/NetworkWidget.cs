using System;
using System.Drawing;
using System.Windows.Forms;
using SystemMaintenance.Models;
using SystemMaintenance.Core;

namespace SystemMaintenance.Controls.Widgets
{
    public class NetworkWidget : DashboardWidget
    {
        private Label lblUpload;
        private Label lblDownload;
        private Label lblInterface;

        public NetworkWidget() : base("Network Activity")
        {
            this.Height = 100;

            lblInterface = new Label {
                Location = new Point(10, 10),
                AutoSize = true,
                Text = "Interface: Auto",
                ForeColor = Color.Gray,
                Font = new Font("Segoe UI", 8F)
            };

            lblUpload = new Label { Location = new Point(10, 35), AutoSize = true, Text = "Upload: ..." };
            lblDownload = new Label { Location = new Point(10, 60), AutoSize = true, Text = "Download: ..." };

            pnlContent.Controls.Add(lblInterface);
            pnlContent.Controls.Add(lblUpload);
            pnlContent.Controls.Add(lblDownload);
        }

        public override void UpdateData(SystemStatsData data)
        {
            if (data == null) return;

            lblUpload.Text = string.Format("▲ Upload: {0}/s", FormatSize(data.NetSent));
            lblDownload.Text = string.Format("▼ Download: {0}/s", FormatSize(data.NetRecv));
        }

        private string FormatSize(long bytes)
        {
            if (bytes > 1024 * 1024) return string.Format("{0:F1} MB", bytes / 1024.0 / 1024.0);
            if (bytes > 1024) return string.Format("{0:F1} KB", bytes / 1024.0);
            return string.Format("{0} B", bytes);
        }
    }
}
