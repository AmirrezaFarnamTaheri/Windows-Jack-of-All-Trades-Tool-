using System;
using System.Drawing;
using System.Windows.Forms;
using SystemMaintenance.Core;
using SystemMaintenance.Models;

namespace SystemMaintenance.Controls
{
    public class ScriptCard : UserControl
    {
        public ScriptInfo Script { get; private set; }
        private Button btnRun;
        private CheckBox chkBatch;
        private Label lblFav;
        private Label lblTitle;
        private Label lblDesc;
        private bool _isHovered = false;

        public event EventHandler<ScriptInfo> OnRunClick;
        public event EventHandler<ScriptInfo> OnFavoriteClick;
        public event EventHandler<ScriptInfo> OnScheduleClick;

        public ScriptCard(ScriptInfo script)
        {
            Script = script;
            InitializeComponent();
            ApplyTheme();
            UpdateSafeModeState();
        }

        private void InitializeComponent()
        {
            this.Size = new Size(280, 150);
            this.Margin = new Padding(10);
            this.AccessibleName = Script.DisplayName;
            this.AccessibleDescription = Script.Description;
            this.AccessibleRole = AccessibleRole.Client;

            // Title
            lblTitle = new Label {
                Text = Script.DisplayName,
                Font = new Font("Segoe UI", 10F, FontStyle.Bold),
                Location = new Point(10, 10),
                AutoSize = true
            };
            if (Script.IsDestructive) { lblTitle.ForeColor = Color.Red; lblTitle.Text += " (!)"; }
            if (Script.IsInteractive) { lblTitle.Text += " *"; }

            // Description
            lblDesc = new Label {
                Text = Script.Description,
                Font = new Font("Segoe UI", 9F),
                Location = new Point(10, 35),
                Size = new Size(260, 60)
            };

            // Run Button
            btnRun = new Button {
                Text = "RUN",
                Size = new Size(80, 30),
                Location = new Point(180, 110),
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand
            };
            btnRun.Click += (s, e) => {
                if (ConfigManager.IsSafeMode && Script.IsDestructive) return;
                OnRunClick?.Invoke(this, Script);
            };

            // Schedule Button (Small Clock Icon or Text)
            // Only non-interactive scripts usually make sense to schedule
            Button btnSchedule = new Button {
                Text = "🕒",
                Size = new Size(30, 30),
                Location = new Point(140, 110),
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand,
                Visible = !Script.IsInteractive
            };
            btnSchedule.FlatAppearance.BorderSize = 0;
            btnSchedule.Click += (s, e) => OnScheduleClick?.Invoke(this, Script);

            // Batch Checkbox
            chkBatch = new CheckBox {
                Text = "Select",
                Location = new Point(10, 115),
                AutoSize = true,
                Visible = false, // Controlled externally
                Tag = "BATCH_CHK"
            };

            // Favorite Star
            lblFav = new Label {
                Text = ConfigManager.Favorites.Contains(Script.FileName) ? "★" : "☆",
                Location = new Point(250, 5),
                AutoSize = true,
                Font = new Font("Segoe UI", 12F),
                Cursor = Cursors.Hand,
                ForeColor = Color.Gold
            };
            lblFav.Click += (s, e) => {
                OnFavoriteClick?.Invoke(this, Script);
                lblFav.Text = ConfigManager.Favorites.Contains(Script.FileName) ? "★" : "☆";
            };

            this.Controls.Add(lblTitle);
            this.Controls.Add(lblDesc);
            this.Controls.Add(btnRun);
            this.Controls.Add(btnSchedule);
            this.Controls.Add(chkBatch);
            this.Controls.Add(lblFav);

            // Events
            this.MouseEnter += (s,e) => SetHover(true);
            this.MouseLeave += (s,e) => SetHover(false);
            this.DoubleClick += (s,e) => {
                if (ConfigManager.IsSafeMode && Script.IsDestructive) return;
                OnRunClick?.Invoke(this, Script);
            };

            // Propagate events from children (except interactive ones)
            foreach(Control c in this.Controls) {
                if(c != btnRun && c != chkBatch && c != lblFav) {
                    c.MouseEnter += (s,e) => SetHover(true);
                    c.MouseLeave += (s,e) => SetHover(false);
                    c.DoubleClick += (s,e) => {
                        if (ConfigManager.IsSafeMode && Script.IsDestructive) return;
                        OnRunClick?.Invoke(this, Script);
                    };
                }
            }
        }

        private void SetHover(bool hover)
        {
            _isHovered = hover;
            this.BackColor = _isHovered ? ThemeManager.GetCardHoverColor(ConfigManager.IsDarkMode) : ThemeManager.GetCardColor(ConfigManager.IsDarkMode);
        }

        public void ApplyTheme()
        {
            this.BackColor = _isHovered ? ThemeManager.GetCardHoverColor(ConfigManager.IsDarkMode) : ThemeManager.GetCardColor(ConfigManager.IsDarkMode);
            lblTitle.ForeColor = ThemeManager.GetTextColor(ConfigManager.IsDarkMode);
            if (Script.IsDestructive) lblTitle.ForeColor = Color.Red;

            lblDesc.ForeColor = ThemeManager.GetSecondaryTextColor(ConfigManager.IsDarkMode);
            btnRun.BackColor = ThemeManager.ColAccent;
            btnRun.ForeColor = Color.White;

            // Refresh Safe Mode visual state which might override button colors
            UpdateSafeModeState();
        }

        public void UpdateSafeModeState()
        {
            if (ConfigManager.IsSafeMode && Script.IsDestructive) {
                 btnRun.Enabled = false;
                 btnRun.Text = "LOCKED";
                 btnRun.BackColor = Color.Gray;
            } else {
                 btnRun.Enabled = true;
                 btnRun.Text = "RUN";
                 btnRun.BackColor = ThemeManager.ColAccent;
            }
        }

        public void SetBatchMode(bool enabled)
        {
            chkBatch.Visible = enabled;
        }

        public bool IsSelectedForBatch => chkBatch.Checked;
        public void SetBatchSelection(bool selected) => chkBatch.Checked = selected;
    }
}
