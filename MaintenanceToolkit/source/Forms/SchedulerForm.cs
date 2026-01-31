using System;
using System.Drawing;
using System.Windows.Forms;
using System.Diagnostics;
using SystemMaintenance.Core;
using SystemMaintenance.Models;

namespace SystemMaintenance.Forms
{
    public class SchedulerForm : Form
    {
        private ScriptInfo _script;
        private ComboBox cmbFrequency;
        private DateTimePicker timePicker;
        private Button btnCreate;
        private Button btnCancel;

        public SchedulerForm(ScriptInfo script)
        {
            _script = script;
            InitializeComponent();
            ThemeManager.ApplyTheme(this, ConfigManager.IsDarkMode);
        }

        private void InitializeComponent()
        {
            this.Text = "Schedule: " + _script.DisplayName;
            this.Size = new Size(400, 250);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;

            Label lblFreq = new Label { Text = "Frequency:", Location = new Point(20, 20), AutoSize = true };
            cmbFrequency = new ComboBox { Location = new Point(120, 18), Width = 200, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbFrequency.Items.AddRange(new object[] { "Daily", "Weekly" });
            cmbFrequency.SelectedIndex = 0;

            Label lblTime = new Label { Text = "Start Time:", Location = new Point(20, 60), AutoSize = true };
            timePicker = new DateTimePicker { Location = new Point(120, 58), Width = 200, Format = DateTimePickerFormat.Time, ShowUpDown = true };

            btnCreate = new Button { Text = "Create Task", Location = new Point(120, 150), Width = 100, Height = 35, FlatStyle = FlatStyle.Flat, BackColor = ThemeManager.ColAccent, ForeColor = Color.White };
            btnCreate.Click += BtnCreate_Click;

            btnCancel = new Button { Text = "Cancel", Location = new Point(230, 150), Width = 80, Height = 35, FlatStyle = FlatStyle.Flat };
            btnCancel.Click += (s, e) => this.Close();

            this.Controls.Add(lblFreq);
            this.Controls.Add(cmbFrequency);
            this.Controls.Add(lblTime);
            this.Controls.Add(timePicker);
            this.Controls.Add(btnCreate);
            this.Controls.Add(btnCancel);
        }

        private void BtnCreate_Click(object sender, EventArgs e)
        {
            try {
                string taskName = "MaintToolkit_" + _script.FileName.Replace(".ps1", "");
                string schedule = cmbFrequency.SelectedItem.ToString().ToUpper(); // DAILY or WEEKLY
                string time = timePicker.Value.ToString("HH:mm");
                string scriptPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "scripts", _script.FileName);

                // Construct command
                // schtasks /Create /TN "Name" /TR "powershell ..." /SC DAILY /ST HH:mm /RL HIGHEST /F

                string psCommand = string.Format("-ExecutionPolicy Bypass -File \\\"{0}\\\"", scriptPath);
                string tr = string.Format("powershell.exe {0}", psCommand);

                string args = string.Format("/Create /TN \"{0}\" /TR \"{1}\" /SC {2} /ST {3} /RL HIGHEST /F /RU SYSTEM",
                    taskName, tr, schedule, time);

                ProcessStartInfo psi = new ProcessStartInfo("schtasks.exe", args);
                psi.UseShellExecute = false;
                psi.CreateNoWindow = true;

                Process p = Process.Start(psi);
                p.WaitForExit();

                if (p.ExitCode == 0) {
                    MessageBox.Show("Task scheduled successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    this.Close();
                } else {
                    MessageBox.Show("Failed to create task. Exit Code: " + p.ExitCode, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }

            } catch (Exception ex) {
                MessageBox.Show("Error: " + ex.Message);
            }
        }
    }
}
