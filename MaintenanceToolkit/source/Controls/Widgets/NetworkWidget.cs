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
            this.MinimumSize = new Size(200, 110);

            lblInterface = new Label {
                Left = 10,
                Top = 10,
                AutoSize = true,
                Text = "Interface: Auto",
                ForeColor = Color.Gray,
                Font = new Font("Segoe UI", 8F)
            };

            lblUpload = new Label { Left = 10, AutoSize = true, Text = "Upload: ..." };
            lblDownload = new Label { Left = 10, AutoSize = true, Text = "Download: ..." };

            pnlContent.Controls.Add(lblInterface);
            pnlContent.Controls.Add(lblUpload);
            pnlContent.Controls.Add(lblDownload);
            pnlContent.Resize += (s, e) => LayoutContent();
            LayoutContent();
        }

        private void LayoutContent()
        {
            int pad = 10;
            int cw = Math.Max(80, pnlContent.ClientSize.Width - 2 * pad);
            lblInterface.MaximumSize = new Size(cw, 0);
            lblInterface.Left = pad;
            lblInterface.Top = pad;
            lblInterface.PerformLayout();
            lblUpload.MaximumSize = new Size(cw, 0);
            lblUpload.Left = pad;
            lblUpload.Top = lblInterface.Bottom + 4;
            lblUpload.PerformLayout();
            lblDownload.MaximumSize = new Size(cw, 0);
            lblDownload.Left = pad;
            lblDownload.Top = lblUpload.Bottom + 4;
            lblDownload.PerformLayout();
            int innerBottom = lblDownload.Bottom + pad;
            int h = lblHeader.Height + pnlContent.Padding.Vertical + innerBottom + this.Padding.Vertical + 2;
            if (h < MinimumSize.Height) h = MinimumSize.Height;
            this.Height = h;
        }

        public override void UpdateData(SystemStatsData data)
        {
            if (data == null) return;

            lblUpload.Text = string.Format("▲ Upload: {0}/s", FormatSize(data.NetSent));
            lblDownload.Text = string.Format("▼ Download: {0}/s", FormatSize(data.NetRecv));
            LayoutContent();
        }

        private string FormatSize(long bytes)
        {
            if (bytes > 1024 * 1024) return string.Format("{0:F1} MB", bytes / 1024.0 / 1024.0);
            if (bytes > 1024) return string.Format("{0:F1} KB", bytes / 1024.0);
            return string.Format("{0} B", bytes);
        }
    }
}
