using System;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;

namespace SystemMaintenance.Core
{
    /// <summary>
    /// Converts HELP.md (subset of Markdown) to HTML for the WinForms WebBrowser.
    /// </summary>
    public static class HelpMarkdownRenderer
    {
        private const char DStrong0 = '\x0001';
        private const char DStrong1 = '\x0002';
        private const char DCode0 = '\x0003';
        private const char DCode1 = '\x0004';
        private const char DEm0 = '\x0005';
        private const char DEm1 = '\x0006';

        public static string ToHtml(string markdown, bool darkMode)
        {
            if (string.IsNullOrEmpty(markdown))
                return "<!DOCTYPE html><html><head><meta charset='utf-8'/></head><body></body></html>";

            string bg = darkMode ? "#1e1e1e" : "#ffffff";
            string fg = darkMode ? "#e8e8e8" : "#1a1a1a";
            string codeBg = darkMode ? "#2d2d2d" : "#f0f0f0";
            string border = darkMode ? "#444" : "#ccc";

            StringBuilder html = new StringBuilder(8192);
            html.Append("<!DOCTYPE html><html><head><meta charset='utf-8'/><title>Help</title><style type='text/css'>");
            html.Append("body{font-family:'Segoe UI',Tahoma,Arial,sans-serif;padding:20px 28px;max-width:900px;margin:0 auto;");
            html.Append("line-height:1.55;font-size:14px;color:").Append(fg).Append(";background:").Append(bg).Append(";");
            html.Append("}h1{font-size:1.75em;font-weight:600;margin:0.35em 0 0.5em;}h2{font-size:1.3em;font-weight:600;margin:1.05em 0 0.4em;}");
            html.Append("h3{font-size:1.08em;font-weight:600;margin:0.85em 0 0.3em;}");
            html.Append("p{margin:0.45em 0;}ul,ol{margin:0.4em 0 0.65em;padding-left:1.45em;}");
            html.Append("li{margin:0.25em 0;}code{font-family:Consolas,monospace;background:").Append(codeBg);
            html.Append(";padding:0.12em 0.35em;border-radius:3px;font-size:0.92em;}");
            html.Append("strong{font-weight:600;}em{font-style:italic;}");
            html.Append("hr{border:none;border-top:1px solid ").Append(border).Append(";margin:1.15em 0;}");
            html.Append("</style></head><body>");

            string normalized = markdown.Replace("\r\n", "\n");
            string[] lines = normalized.Split(new char[] { '\n' });
            bool inUl = false;
            bool inOl = false;

            for (int i = 0; i < lines.Length; i++)
            {
                string l = lines[i].Trim();
                if (l.Length == 0)
                {
                    CloseLists(html, ref inUl, ref inOl);
                    continue;
                }
                if (l == "---")
                {
                    CloseLists(html, ref inUl, ref inOl);
                    html.Append("<hr/>");
                    continue;
                }

                if (l.StartsWith("### ", StringComparison.Ordinal))
                {
                    CloseLists(html, ref inUl, ref inOl);
                    html.Append("<h3>").Append(FormatInline(l.Substring(4))).Append("</h3>");
                    continue;
                }
                if (l.StartsWith("## ", StringComparison.Ordinal) && !l.StartsWith("###", StringComparison.Ordinal))
                {
                    CloseLists(html, ref inUl, ref inOl);
                    html.Append("<h2>").Append(FormatInline(l.Substring(3))).Append("</h2>");
                    continue;
                }
                if (l.StartsWith("# ", StringComparison.Ordinal))
                {
                    CloseLists(html, ref inUl, ref inOl);
                    html.Append("<h1>").Append(FormatInline(l.Substring(2))).Append("</h1>");
                    continue;
                }

                Match mNum = Regex.Match(l, @"^(\d+)\.\s+(.+)$");
                if (mNum.Success)
                {
                    if (inUl) { html.Append("</ul>"); inUl = false; }
                    if (!inOl) { html.Append("<ol>"); inOl = true; }
                    html.Append("<li>").Append(FormatInline(mNum.Groups[2].Value)).Append("</li>");
                    continue;
                }

                // * item or - item (e.g. "*   **x**")
                Match mBull = Regex.Match(l, @"^(\*|-)\s+(.+)$");
                if (mBull.Success)
                {
                    if (inOl) { html.Append("</ol>"); inOl = false; }
                    if (!inUl) { html.Append("<ul>"); inUl = true; }
                    html.Append("<li>").Append(FormatInline(mBull.Groups[2].Value)).Append("</li>");
                    continue;
                }

                CloseLists(html, ref inUl, ref inOl);
                html.Append("<p>").Append(FormatInline(l)).Append("</p>");
            }

            CloseLists(html, ref inUl, ref inOl);
            html.Append("</body></html>");
            return html.ToString();
        }

        private static void CloseLists(StringBuilder html, ref bool inUl, ref bool inOl)
        {
            if (inUl) { html.Append("</ul>"); inUl = false; }
            if (inOl) { html.Append("</ol>"); inOl = false; }
        }

        /// <summary>Inline: **bold**, `code`, *italic*</summary>
        public static string FormatInline(string s)
        {
            if (string.IsNullOrEmpty(s)) return string.Empty;

            // 1) `code` (may contain * — handle first)
            s = Regex.Replace(s, @"`([^`]+)`", m => new string(new char[] { DCode0 }) + m.Groups[1].Value + new string(new char[] { DCode1 }));

            // 2) **bold**
            s = Regex.Replace(s, @"\*\*([^*]+?)\*\*", m => new string(new char[] { DStrong0 }) + m.Groups[1].Value + new string(new char[] { DStrong1 }));

            // 3) *italic* (single asterisk pairs, non-greedy; ** already replaced)
            s = Regex.Replace(s, @"(?<!\*)\*([^*]+?)\*(?!\*)", m => new string(new char[] { DEm0 }) + m.Groups[1].Value + new string(new char[] { DEm1 }));

            var o = new StringBuilder(s.Length + 32);
            int i = 0;
            while (i < s.Length)
            {
                char c = s[i];
                if (c == DCode0)
                {
                    o.Append(FlushSegment(s, ref i, DCode1, "<code>", "</code>"));
                    continue;
                }
                if (c == DStrong0)
                {
                    o.Append(FlushSegment(s, ref i, DStrong1, "<strong>", "</strong>"));
                    continue;
                }
                if (c == DEm0)
                {
                    o.Append(FlushSegment(s, ref i, DEm1, "<em>", "</em>"));
                    continue;
                }
                o.Append(WebUtility.HtmlEncode(c.ToString()));
                i++;
            }
            return o.ToString();
        }

        private static string FlushSegment(string s, ref int i, char endMark, string openTag, string closeTag)
        {
            int start = i + 1;
            int e = s.IndexOf(endMark, start);
            if (e < 0)
            {
                i++;
                return WebUtility.HtmlEncode(s[i - 1].ToString());
            }
            string inner = s.Substring(start, e - start);
            i = e + 1;
            return openTag + WebUtility.HtmlEncode(inner) + closeTag;
        }
    }
}
