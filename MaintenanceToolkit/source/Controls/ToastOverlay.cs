using System;
using System.Drawing;
using System.Windows.Forms;
using SystemMaintenance.Core;

namespace SystemMaintenance.Controls
{
    public class ToastOverlay : Form
    {
        private Timer _timer;
        private int _lifeTime = 3000; // 3 seconds

        public ToastOverlay(string message, string type = "INFO")
        {
            this.FormBorderStyle = FormBorderStyle.None;
            this.StartPosition = FormStartPosition.Manual;
            this.Size = new Size(300, 60);
            this.ShowInTaskbar = false;
            this.TopMost = true;

            Color bg = (type == "ERROR") ? Color.IndianRed : (type == "SUCCESS" ? Color.SeaGreen : ThemeManager.ColAccent);
            this.BackColor = bg;

            Label lbl = new Label();
            lbl.Text = message;
            lbl.ForeColor = Color.White;
            lbl.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
            lbl.Dock = DockStyle.Fill;
            lbl.TextAlign = ContentAlignment.MiddleCenter;
            this.Controls.Add(lbl);

            _timer = new Timer();
            _timer.Interval = _lifeTime;
            _timer.Tick += (s, e) => {
                _timer.Stop();
                this.Close();
            };
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            // Position bottom right of working area
            Rectangle workingArea = Screen.PrimaryScreen.WorkingArea;
            this.Location = new Point(workingArea.Right - this.Width - 20, workingArea.Bottom - this.Height - 20);
            _timer.Start();
        }

        public static void Show(string message, string type="INFO")
        {
            // Run on UI thread if possible, but creating a form requires a message loop.
            // We'll just launch it.
            try {
                new ToastOverlay(message, type).Show();
            } catch {}
        }
    }
}
