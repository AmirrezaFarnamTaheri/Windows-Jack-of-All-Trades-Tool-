using System;
using System.Drawing;
using System.Windows.Forms;
using SystemMaintenance.Core;
using SystemMaintenance.Models;

namespace SystemMaintenance.Controls.Widgets
{
    public abstract class DashboardWidget : UserControl
    {
        protected Label lblHeader;
        protected Panel pnlContent;

        public DashboardWidget(string title)
        {
            this.BackColor = ThemeManager.GetCardColor(ConfigManager.IsDarkMode);
            this.Size = new Size(300, 150); // Default, but Dashboard will resize
            this.Margin = new Padding(0, 0, 0, 10);

            lblHeader = new Label {
                Text = title,
                Font = new Font("Segoe UI", 10F, FontStyle.Bold),
                ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode),
                Dock = DockStyle.Top,
                Height = 25,
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(10, 0, 0, 0)
            };

            pnlContent = new Panel {
                Dock = DockStyle.Fill,
                Padding = new Padding(10)
            };

            this.Controls.Add(pnlContent);
            this.Controls.Add(lblHeader);
        }

        public virtual void UpdateData(SystemStatsData data) { }

        public virtual void ApplyTheme()
        {
            this.BackColor = ThemeManager.GetCardColor(ConfigManager.IsDarkMode);
            lblHeader.ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode);
            foreach (Control c in pnlContent.Controls) UpdateThemeRecursive(c);
        }

        protected void UpdateThemeRecursive(Control c)
        {
            if (c is Label) c.ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode);
            // Add other controls as needed
        }
    }
}
