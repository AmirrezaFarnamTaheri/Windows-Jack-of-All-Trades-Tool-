using System;
using System.Drawing;
using System.Windows.Forms;

namespace SystemMaintenance.Core
{
    public static class ThemeManager
    {
        // Colors (Modern Flat Theme)
        public static readonly Color ColSidebarDark = Color.FromArgb(37, 37, 38);
        public static readonly Color ColSidebarLight = Color.FromArgb(240, 240, 240);
        public static readonly Color ColContentDark = Color.FromArgb(30, 30, 30);
        public static readonly Color ColContentLight = Color.White;
        public static readonly Color ColCardDark = Color.FromArgb(45, 45, 48);
        public static readonly Color ColCardLight = Color.WhiteSmoke;
        public static readonly Color ColCardHoverDark = Color.FromArgb(65, 65, 68);
        public static readonly Color ColCardHoverLight = Color.FromArgb(230, 230, 230);
        public static readonly Color ColAccent = Color.FromArgb(0, 122, 204);
        public static readonly Color ColTextDark = Color.FromArgb(241, 241, 241);
        public static readonly Color ColTextLight = Color.FromArgb(30, 30, 30);

        public static void ApplyTheme(Form form, bool isDarkMode)
        {
            if (SystemInformation.HighContrast) return;

            Color bg = isDarkMode ? ColContentDark : ColContentLight;
            Color fg = isDarkMode ? ColTextDark : ColTextLight;

            form.BackColor = bg;
            form.ForeColor = fg;
        }

        public static Color GetSidebarColor(bool isDarkMode) { return isDarkMode ? ColSidebarDark : ColSidebarLight; }
        public static Color GetContentColor(bool isDarkMode) { return isDarkMode ? ColContentDark : ColContentLight; }
        public static Color GetCardColor(bool isDarkMode) { return isDarkMode ? ColCardDark : ColCardLight; }
        public static Color GetCardHoverColor(bool isDarkMode) { return isDarkMode ? ColCardHoverDark : ColCardHoverLight; }
        public static Color GetTextColor(bool isDarkMode) { return isDarkMode ? ColTextDark : ColTextLight; }
        public static Color GetSecondaryTextColor(bool isDarkMode) { return isDarkMode ? Color.Gray : Color.DimGray; }
    }
}
