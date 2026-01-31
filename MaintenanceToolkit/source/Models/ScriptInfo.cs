using System;

namespace SystemMaintenance.Models
{
    public class ScriptInfo
    {
        public string FileName { get; set; }
        public string DisplayName { get; set; }
        public string Description { get; set; }
        public bool IsInteractive { get; set; }
        public bool IsDestructive { get; set; }

        public ScriptInfo(string file, string name, string desc, bool interactive = false, bool destructive = false)
        {
            FileName = file;
            DisplayName = name;
            Description = desc;
            IsInteractive = interactive;
            IsDestructive = destructive;
        }
    }
}
