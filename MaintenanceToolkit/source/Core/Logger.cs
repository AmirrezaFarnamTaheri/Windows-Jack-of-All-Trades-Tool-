using System;

namespace SystemMaintenance.Core
{
    public static class Logger
    {
        public static event Action<string, string> OnLogMessage;

        public static void Log(string message, string type = "INFO")
        {
            OnLogMessage?.Invoke(message, type);
        }

        public static void Error(string message) => Log(message, "ERROR");
    }
}
