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
        private const string APP_DIR_NAME = "MaintenanceToolkit";

        public static bool IsDarkMode { get; set; }
        public static bool IsSafeMode { get; set; }
        /// <summary>0-1000: upper panel share of split height, or -1 if never saved.</summary>
        public static int UiSplitRatioPermille { get; set; }
        /// <summary>Toolbar / header bar height, or 0 if never saved or use default.</summary>
        public static int UiToolbarHeight { get; set; }
        public static HashSet<string> Favorites { get; private set; }

        static ConfigManager()
        {
            IsDarkMode = false;
            IsSafeMode = false;
            UiSplitRatioPermille = -1;
            UiToolbarHeight = 0;
            Favorites = new HashSet<string>();
        }

        private static string GetAppDataDir()
        {
            // Prefer LocalAppData (does not roam, avoids sync conflicts; safer for logs/evidence too)
            string root = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string dir = Path.Combine(root, APP_DIR_NAME);
            return dir;
        }

        private static string GetSettingsPath() { return Path.Combine(GetAppDataDir(), SETTINGS_FILE); }
        private static string GetFavoritesPath() { return Path.Combine(GetAppDataDir(), FAVORITES_FILE); }

        private static string GetLegacySettingsPath() { return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, SETTINGS_FILE); }
        private static string GetLegacyFavoritesPath() { return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, FAVORITES_FILE); }

        private static void EnsureDir(string dir)
        {
            if (string.IsNullOrEmpty(dir)) return;
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
        }

        private static void TryMigrateLegacyFiles()
        {
            try
            {
                string newDir = GetAppDataDir();
                EnsureDir(newDir);

                string legacySettings = GetLegacySettingsPath();
                string legacyFav = GetLegacyFavoritesPath();

                string newSettings = GetSettingsPath();
                string newFav = GetFavoritesPath();

                // Only migrate if new location doesn't already exist
                if (!File.Exists(newSettings) && File.Exists(legacySettings))
                {
                    File.Copy(legacySettings, newSettings, true);
                }

                if (!File.Exists(newFav) && File.Exists(legacyFav))
                {
                    File.Copy(legacyFav, newFav, true);
                }
            }
            catch
            {
                // Best-effort; don't block app startup
            }
        }

        public static void Load()
        {
            try {
                TryMigrateLegacyFiles();

                string settingsPath = GetSettingsPath();
                string favoritesPath = GetFavoritesPath();

                if (File.Exists(settingsPath))
                {
                    string content = File.ReadAllText(settingsPath);
                    IsDarkMode = content.Contains("DarkMode=True");
                    IsSafeMode = content.Contains("SafeMode=True");
                    UiSplitRatioPermille = -1;
                    UiToolbarHeight = 0;
                    foreach (string line in content.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries))
                    {
                        int idx = line.IndexOf('=');
                        if (idx <= 0) continue;
                        string key = line.Substring(0, idx).Trim();
                        string val = line.Substring(idx + 1).Trim();
                        if (key == "UiSplitRatioPermille")
                        {
                            int t;
                            if (int.TryParse(val, out t) && t >= 0 && t <= 1000) UiSplitRatioPermille = t;
                        }
                        else if (key == "UiToolbarHeight")
                        {
                            int t;
                            if (int.TryParse(val, out t) && t >= 40 && t <= 220) UiToolbarHeight = t;
                        }
                    }
                }
                if (File.Exists(favoritesPath))
                {
                    Favorites = new HashSet<string>(File.ReadAllLines(favoritesPath).Where(l => !string.IsNullOrWhiteSpace(l)));
                }
            } catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"Error: {ex.Message}"); }
        }

        public static void Save()
        {
            try {
                string dir = GetAppDataDir();
                EnsureDir(dir);

                File.WriteAllText(
                    GetSettingsPath(),
                    string.Join(
                        "\r\n",
                        new string[] {
                            "DarkMode=" + (IsDarkMode ? "True" : "False"),
                            "SafeMode=" + (IsSafeMode ? "True" : "False"),
                            "UiSplitRatioPermille=" + (UiSplitRatioPermille < 0 ? 580 : UiSplitRatioPermille),
                            "UiToolbarHeight=" + (UiToolbarHeight <= 0 ? 58 : UiToolbarHeight)
                        }));
                File.WriteAllLines(GetFavoritesPath(), Favorites);
            } catch (Exception ex) { System.Diagnostics.Debug.WriteLine($"Error: {ex.Message}"); }
        }

        public static void ToggleFavorite(string scriptName)
        {
            if (Favorites.Contains(scriptName)) Favorites.Remove(scriptName);
            else Favorites.Add(scriptName);
            Save();
        }
    }
}
