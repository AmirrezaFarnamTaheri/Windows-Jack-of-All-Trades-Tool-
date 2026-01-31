using System;
using System.Collections.Generic;

namespace SystemMaintenance.Models
{
    public class SystemStatsData {
         public string OS { get; set; }
         public string Uptime { get; set; }
         public string CPU { get; set; }
         public int Cores { get; set; }
         public int Threads { get; set; }
         public string GPU { get; set; }
         public long RamTotal { get; set; }
         public long RamFree { get; set; }
         public bool RebootPending { get; set; }
         public List<DriveInfoData> Drives { get; set; }

         public SystemStatsData() { Drives = new List<DriveInfoData>(); }
    }

    public class DriveInfoData {
         public string Name { get; set; }
         public long TotalSize { get; set; } // GB
         public long FreeSpace { get; set; } // GB
         public double PercentFree { get; set; }
    }
}
