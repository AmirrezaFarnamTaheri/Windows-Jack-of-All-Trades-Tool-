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
        private const int CardPadH = 12;
        private const int CardPadV = 10;
        private const int MinCardWidth = 240;
        private const int BtnRunW = 80;
        private const int BtnIconW = 32;
        private const int BtnGap = 6;

        private Button btnRun;
        private Button btnSchedule;
        private CheckBox chkBatch;
        private Label lblFav;
        private Label lblTitle;
        private Label lblDesc;
        private Button btnHelp;
        private ToolTip toolTip;
        private bool _isHovered = false;

        public event EventHandler<ScriptInfo> OnRunClick;
        public event EventHandler<ScriptInfo> OnFavoriteClick;
        public event EventHandler<ScriptInfo> OnScheduleClick;
        public event EventHandler<ScriptInfo> OnHelpClick;

        public ScriptCard(ScriptInfo script)
        {
            Script = script;
            InitializeComponent();
            ApplyTheme();
            UpdateSafeModeState();
        }

        private void InitializeComponent()
        {
            this.SetStyle(ControlStyles.ResizeRedraw, true);
            this.Margin = new Padding(0, 0, 0, 10);
            this.MinimumSize = new Size(MinCardWidth, 100);
            this.Size = new Size(640, 140);
            this.AccessibleName = Script.DisplayName;
            this.AccessibleDescription = Script.Description;
            this.AccessibleRole = AccessibleRole.Client;

            toolTip = new ToolTip();

            // Title
            lblTitle = new Label {
                Text = Script.DisplayName,
                Font = new Font("Segoe UI", 10F, FontStyle.Bold),
                Location = new Point(CardPadH, CardPadV),
                AutoSize = true
            };
            if (Script.IsDestructive) { lblTitle.ForeColor = Color.Red; lblTitle.Text += " (!)"; }
            if (Script.IsInteractive) { lblTitle.Text += " *"; }
            toolTip.SetToolTip(lblTitle, Script.IsDestructive ? "Destructive tool (Safe Mode may block it)." : "Tool");
            if (Script.IsInteractive) toolTip.SetToolTip(lblTitle, toolTip.GetToolTip(lblTitle) + "\r\nInteractive tool (requires user input).");

            // Description (width set in SetCardWidth)
            lblDesc = new Label {
                Text = Script.Description,
                Font = new Font("Segoe UI", 9F),
                Location = new Point(CardPadH, 36),
                AutoSize = true,
                AutoEllipsis = false
            };

            // Run Button
            btnRun = new Button {
                Text = "RUN",
                Size = new Size(BtnRunW, 32),
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand
            };
            toolTip.SetToolTip(btnRun, "Run this tool now.");
            btnRun.Click += (s, e) => {
                if (ConfigManager.IsSafeMode && Script.IsDestructive) return;
                var runHandler = OnRunClick;
                if (runHandler != null) runHandler(this, Script);
            };

            // Schedule Button (Small Clock Icon or Text)
            // Only non-interactive scripts usually make sense to schedule
            btnSchedule = new Button {
                Text = "🕒",
                Size = new Size(BtnIconW, 32),
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand,
                Visible = !Script.IsInteractive
            };
            btnSchedule.FlatAppearance.BorderSize = 0;
            toolTip.SetToolTip(btnSchedule, "Schedule this tool using Windows Task Scheduler.");
            btnSchedule.Click += (s, e) => {
                var schedHandler = OnScheduleClick;
                if (schedHandler != null) schedHandler(this, Script);
            };

            // Help / Troubleshoot Button
            btnHelp = new Button {
                Text = "?",
                Size = new Size(BtnIconW, 32),
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand
            };
            btnHelp.FlatAppearance.BorderSize = 0;
            toolTip.SetToolTip(btnHelp, "Troubleshoot / how to investigate failures.");
            btnHelp.Click += (s, e) => {
                var helpHandler = OnHelpClick;
                if (helpHandler != null) helpHandler(this, Script);
            };

            // Batch Checkbox
            chkBatch = new CheckBox {
                Text = "Select",
                AutoSize = true,
                Visible = false, // Controlled externally
                Tag = "BATCH_CHK"
            };

            // Favorite Star
            lblFav = new Label {
                Text = ConfigManager.Favorites.Contains(Script.FileName) ? "★" : "☆",
                AutoSize = true,
                Font = new Font("Segoe UI", 12F),
                Cursor = Cursors.Hand,
                ForeColor = Color.Gold
            };
            toolTip.SetToolTip(lblFav, "Toggle Favorite");
            lblFav.Click += (s, e) => {
                var favHandler = OnFavoriteClick;
                if (favHandler != null) favHandler(this, Script);
                lblFav.Text = ConfigManager.Favorites.Contains(Script.FileName) ? "★" : "☆";
            };

            this.Controls.Add(lblTitle);
            this.Controls.Add(lblDesc);
            this.Controls.Add(btnRun);
            this.Controls.Add(btnSchedule);
            this.Controls.Add(btnHelp);
            this.Controls.Add(chkBatch);
            this.Controls.Add(lblFav);

            // Events
            this.MouseEnter += (s,e) => SetHover(true);
            this.MouseLeave += (s,e) => SetHover(false);
            this.DoubleClick += (s,e) => {
                if (ConfigManager.IsSafeMode && Script.IsDestructive) return;
                var runHandler = OnRunClick;
                if (runHandler != null) runHandler(this, Script);
            };

            // Propagate events from children (except interactive ones)
            foreach(Control c in this.Controls) {
                if(c != btnRun && c != chkBatch && c != lblFav) {
                    c.MouseEnter += (s,e) => SetHover(true);
                    c.MouseLeave += (s,e) => SetHover(false);
                    c.DoubleClick += (s,e) => {
                        if (ConfigManager.IsSafeMode && Script.IsDestructive) return;
                        var runHandler = OnRunClick;
                        if (runHandler != null) runHandler(this, Script);
                    };
                }
            }

            SetCardWidth(this.Width);
        }

        /// <summary>Sets full width for this card (stacks in a single column) and relayouts wrapped text and actions.</summary>
        public void SetCardWidth(int width)
        {
            if (width < MinCardWidth) width = MinCardWidth;
            this.SuspendLayout();
            this.Width = width;
            int innerW = width - 2 * CardPadH;
            int titleMaxW = Math.Max(60, innerW - 32);
            lblTitle.MaximumSize = new Size(titleMaxW, 0);
            lblFav.Location = new Point(width - CardPadH - 22, CardPadV - 2);
            lblTitle.Location = new Point(CardPadH, CardPadH);
            lblTitle.PerformLayout();
            int titleBottom = lblTitle.Bottom;
            if (titleBottom < CardPadH + 18) titleBottom = CardPadH + 18;
            int descW = Math.Max(80, innerW);
            lblDesc.MaximumSize = new Size(descW, 0);
            lblDesc.Location = new Point(CardPadH, titleBottom + 4);
            lblDesc.PerformLayout();
            int btnY = Math.Max(lblDesc.Bottom + 8, titleBottom + 8);
            int xRun = width - CardPadH - BtnRunW;
            int xSched = xRun - BtnGap - BtnIconW;
            int xHelp = xSched - BtnGap - BtnIconW;
            btnRun.Location = new Point(xRun, btnY);
            btnSchedule.Location = new Point(xSched, btnY);
            btnHelp.Location = new Point(xHelp, btnY);
            chkBatch.Location = new Point(CardPadH, btnY + 2);
            int h = btnY + 34 + CardPadV;
            if (h < this.MinimumSize.Height) h = this.MinimumSize.Height;
            this.Height = h;
            this.ResumeLayout(true);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            Color edge = ConfigManager.IsDarkMode ? Color.FromArgb(64, 64, 68) : Color.FromArgb(210, 210, 210);
            using (Pen p = new Pen(edge, 1))
            {
                e.Graphics.DrawRectangle(p, 0, 0, this.Width - 1, this.Height - 1);
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

        public bool IsSelectedForBatch
        {
            get { return chkBatch.Checked; }
        }

        public void SetBatchSelection(bool selected)
        {
            chkBatch.Checked = selected;
        }
    }
}
