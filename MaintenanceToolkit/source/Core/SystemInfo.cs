using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Management;
using SystemMaintenance.Models;

namespace SystemMaintenance.Core
{
    public static class SystemInfo
    {
        private static string _cachedOS = null;
        private static string _cachedCPU = null;
        private static int _cachedCores = 0;
        private static int _cachedThreads = 0;
        private static string _cachedGPU = null;

        public static SystemStatsData GetSystemStats()
        {
            var data = new SystemStatsData();
            data.OS = GetOSFriendlyName();
            data.Uptime = GetUptime();

            // CPU (Cached)
            if (_cachedCPU == null)
            {
                try {
                    using (var searcher = new ManagementObjectSearcher("SELECT Name, NumberOfCores, NumberOfLogicalProcessors FROM Win32_Processor"))
                    {
                        foreach (var item in searcher.Get())
                        {
                            string cpu = item["Name"].ToString();
                            if (cpu.Length > 40) cpu = cpu.Substring(0, 37) + "...";
                            _cachedCPU = cpu;
                            _cachedCores = Convert.ToInt32(item["NumberOfCores"]);
                            _cachedThreads = Convert.ToInt32(item["NumberOfLogicalProcessors"]);
                            break;
                        }
                    }
                } catch { _cachedCPU = "Unknown"; }
            }
            data.CPU = _cachedCPU;
            data.Cores = _cachedCores;
            data.Threads = _cachedThreads;

            // GPU (Cached)
            if (_cachedGPU == null)
            {
                try {
                     using (var searcher = new ManagementObjectSearcher("SELECT Name FROM Win32_VideoController"))
                     {
                         foreach (var item in searcher.Get()) {
                             _cachedGPU = item["Name"].ToString();
                             break; // Just get first GPU
                         }
                     }
                } catch { _cachedGPU = ""; }
            }
            data.GPU = _cachedGPU;

            // RAM (Dynamic)
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT TotalVisibleMemorySize, FreePhysicalMemory FROM Win32_OperatingSystem"))
                {
                    foreach (var item in searcher.Get())
                    {
                        data.RamTotal = Convert.ToInt64(item["TotalVisibleMemorySize"]) / 1024;
                        data.RamFree = Convert.ToInt64(item["FreePhysicalMemory"]) / 1024;
                    }
                }
            } catch {}

            // Pending Reboot (Dynamic)
            try {
                 bool reboot = false;
                 try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")) { if (key != null) reboot = true; } } catch {}
                 try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")) { if (key != null) reboot = true; } } catch {}
                 data.RebootPending = reboot;
            } catch {}

            // Drives (Dynamic)
            try {
                foreach (var drive in DriveInfo.GetDrives()) {
                    if (drive.IsReady && drive.DriveType == DriveType.Fixed) {
                        var d = new DriveInfoData {
                             Name = drive.Name,
                             TotalSize = drive.TotalSize / 1073741824,
                             FreeSpace = drive.TotalFreeSpace / 1073741824
                        };
                        d.PercentFree = (double)drive.TotalFreeSpace / drive.TotalSize * 100;
                        data.Drives.Add(d);
                    }
                }
            } catch {}

            return data;
        }

        private static string GetOSFriendlyName()
        {
            if (_cachedOS != null) return _cachedOS;
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Caption FROM Win32_OperatingSystem"))
                {
                    foreach (var item in searcher.Get()) {
                        _cachedOS = item["Caption"].ToString();
                        return _cachedOS;
                    }
                }
            } catch {}
            _cachedOS = Environment.OSVersion.ToString();
            return _cachedOS;
        }

        private static string GetUptime()
        {
            try {
                using (var uptime = new PerformanceCounter("System", "System Up Time"))
                {
                    uptime.NextValue();
                    TimeSpan ts = TimeSpan.FromSeconds(uptime.NextValue());
                    return string.Format("{0}d {1}h {2}m", ts.Days, ts.Hours, ts.Minutes);
                }
            } catch { return "Unknown"; }
        }
    }
}
