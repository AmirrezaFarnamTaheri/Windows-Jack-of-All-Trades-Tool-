using System;
using System.IO;
using System.Windows.Forms;
using SystemMaintenance.Forms;

namespace SystemMaintenance
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            CleanStaleTempFolders();

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }

        private static void CleanStaleTempFolders()
        {
            try {
                string tempRoot = Path.GetTempPath();
                foreach (var dir in Directory.GetDirectories(tempRoot, "SysMaintToolkit_*"))
                {
                    try {
                        Directory.Delete(dir, true);
                    } catch {
                        // Ignore if locked
                    }
                }
            } catch {}
        }
    }
}
