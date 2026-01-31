using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace SystemMaintenance.Core
{
    public static class ConfigManager
    {
        private const string SETTINGS_FILE = "settings.cfg";
        private const string FAVORITES_FILE = "favorites.cfg";

        public static bool IsDarkMode { get; set; } = false;
        public static bool IsSafeMode { get; set; } = false;
        public static HashSet<string> Favorites { get; private set; } = new HashSet<string>();

        public static void Load()
        {
            try {
                if (File.Exists(SETTINGS_FILE))
                {
                    string content = File.ReadAllText(SETTINGS_FILE);
                    IsDarkMode = content.Contains("DarkMode=True");
                    IsSafeMode = content.Contains("SafeMode=True");
                }
                if (File.Exists(FAVORITES_FILE)) Favorites = new HashSet<string>(File.ReadAllLines(FAVORITES_FILE).Where(l => !string.IsNullOrWhiteSpace(l)));
            } catch {}
        }

        public static void Save()
        {
            try {
                File.WriteAllText(SETTINGS_FILE, string.Format("DarkMode={0}\nSafeMode={1}", IsDarkMode, IsSafeMode));
                File.WriteAllLines(FAVORITES_FILE, Favorites);
            } catch {}
        }

        public static void ToggleFavorite(string scriptName)
        {
            if (Favorites.Contains(scriptName)) Favorites.Remove(scriptName);
            else Favorites.Add(scriptName);
            Save();
        }
    }
}
