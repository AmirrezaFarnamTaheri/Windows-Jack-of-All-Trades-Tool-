using System;
using System.IO;

namespace SystemMaintenance.Core
{
    public static class TelemetryLogger
    {
        private static readonly string LOG_DIR = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MaintenanceToolkit");
        private static readonly string LOG_FILE = Path.Combine(LOG_DIR, "telemetry.log");
        private static readonly object _lock = new object();

        static TelemetryLogger()
        {
            try
            {
                if (!Directory.Exists(LOG_DIR))
                    Directory.CreateDirectory(LOG_DIR);
            }
            catch { }
        }

        public static void Log(string message)
        {
            try
            {
                lock (_lock)
                {
                    File.AppendAllText(LOG_FILE, $"[{DateTime.UtcNow:O}] INFO: {message}{Environment.NewLine}");
                }
            }
            catch
            {
                System.Diagnostics.Debug.WriteLine($"Telemetry Logger Failed: {message}");
            }
        }

        public static void LogException(Exception ex, string context = "")
        {
            try
            {
                lock (_lock)
                {
                    string ctx = string.IsNullOrEmpty(context) ? "" : $" [{context}]";
                    File.AppendAllText(LOG_FILE, $"[{DateTime.UtcNow:O}] ERROR{ctx}: {ex.Message}{Environment.NewLine}{ex.StackTrace}{Environment.NewLine}");
                }
            }
            catch
            {
                System.Diagnostics.Debug.WriteLine($"Telemetry Logger Exception Failed: {ex.Message}");
            }
        }
    }
}