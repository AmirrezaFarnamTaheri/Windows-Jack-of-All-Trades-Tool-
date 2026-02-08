using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management;
using System.Threading.Tasks;
using SystemMaintenance.Models;

namespace SystemMaintenance.Core
{
    public class SystemStatsService
    {
        private static readonly Lazy<SystemStatsService> _instance = new Lazy<SystemStatsService>(() => new SystemStatsService());
        public static SystemStatsService Instance => _instance.Value;

        private readonly AsyncLazy<string> _cpuName;
        private readonly AsyncLazy<string> _gpuName;
        private readonly AsyncLazy<string> _osName;

        private int _cores;
        private int _threads;
        private long _ramTotal;

        // Network Counters
        private PerformanceCounter _netSent;
        private PerformanceCounter _netRecv;
        private string _activeInterface;

        private SystemStatsService()
        {
            _cpuName = new AsyncLazy<string>(() => Task.Run(() => GetCpuInfo()));
            _gpuName = new AsyncLazy<string>(() => Task.Run(() => GetGpuInfo()));
            _osName = new AsyncLazy<string>(() => Task.Run(() => GetOsInfo()));
            InitializeNetworkCounters();
        }

        private void InitializeNetworkCounters()
        {
            try {
                var cat = new PerformanceCounterCategory("Network Interface");
                var instances = cat.GetInstanceNames();

                // Prioritize Ethernet/Wi-Fi over Loopback/Pseudo
                foreach(var inst in instances) {
                    string lower = inst.ToLower();
                    if (lower.Contains("loopback") || lower.Contains("pseudo") || lower.Contains("isatap") || lower.Contains("teredo")) continue;

                    // Simple validation: Try creating counter
                    try {
                        using(var pc = new PerformanceCounter("Network Interface", "Bytes Sent/sec", inst)) {
                            pc.NextValue(); // Check if readable
                        }
                        _activeInterface = inst;
                        break;
                    } catch {}
                }

                if (_activeInterface != null) {
                    _netSent = new PerformanceCounter("Network Interface", "Bytes Sent/sec", _activeInterface);
                    _netRecv = new PerformanceCounter("Network Interface", "Bytes Received/sec", _activeInterface);
                }
            } catch {}
        }

        public async Task<SystemStatsData> GetStatsAsync()
        {
            var data = new SystemStatsData();

            // Set a timeout for WMI initialization tasks to prevent hanging
            var tCPU = _cpuName.GetValueAsync();
            var tGPU = _gpuName.GetValueAsync();
            var tOS = _osName.GetValueAsync();

            await Task.WhenAny(Task.WhenAll(tCPU, tGPU, tOS), Task.Delay(2000));

            data.CPU = tCPU.IsCompleted ? tCPU.Result : "Loading...";
            data.GPU = tGPU.IsCompleted ? tGPU.Result : "Loading...";
            data.OS = tOS.IsCompleted ? tOS.Result : "Loading...";

            data.Cores = _cores;
            data.Threads = _threads;
            data.RamTotal = _ramTotal;

            // Execute synchronous property getters with timeouts/safeguards
            await Task.Run(() => {
                data.Uptime = GetUptime();
                GetRamUsage(data);
                GetDriveUsage(data);
                GetRebootStatus(data);
                GetNetworkUsage(data);
            });

            return data;
        }

        private string GetCpuInfo()
        {
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Name, NumberOfCores, NumberOfLogicalProcessors FROM Win32_Processor"))
                {
                    foreach (var item in searcher.Get())
                    {
                        _cores = Convert.ToInt32(item["NumberOfCores"]);
                        _threads = Convert.ToInt32(item["NumberOfLogicalProcessors"]);
                        string name = item["Name"].ToString();
                        return name.Length > 40 ? name.Substring(0, 37) + "..." : name;
                    }
                }
            } catch {}
            return "Unknown CPU";
        }

        private string GetGpuInfo()
        {
            try {
                 using (var searcher = new ManagementObjectSearcher("SELECT Name FROM Win32_VideoController"))
                 {
                     foreach (var item in searcher.Get()) return item["Name"].ToString();
                 }
            } catch {}
            return "Basic Display Adapter";
        }

        private string GetOsInfo()
        {
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Caption, TotalVisibleMemorySize FROM Win32_OperatingSystem"))
                {
                    foreach (var item in searcher.Get()) {
                        _ramTotal = Convert.ToInt64(item["TotalVisibleMemorySize"]) / 1024;
                        return item["Caption"].ToString();
                    }
                }
            } catch {}
            return Environment.OSVersion.ToString();
        }

        private string GetUptime()
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

        private void GetRamUsage(SystemStatsData data)
        {
            try {
                // WMI is slow, but PerformanceCounter is fast
                using (var pc = new PerformanceCounter("Memory", "Available MBytes")) {
                    data.RamFree = (long)pc.NextValue();
                }
            } catch {
                // Fallback to WMI
                try {
                    using (var searcher = new ManagementObjectSearcher("SELECT FreePhysicalMemory FROM Win32_OperatingSystem"))
                    {
                        foreach (var item in searcher.Get())
                        {
                            data.RamFree = Convert.ToInt64(item["FreePhysicalMemory"]) / 1024;
                        }
                    }
                } catch {}
            }
        }

        private void GetDriveUsage(SystemStatsData data)
        {
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
        }

        private void GetRebootStatus(SystemStatsData data)
        {
            try {
                 bool reboot = false;
                 try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")) { if (key != null) reboot = true; } } catch {}
                 try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")) { if (key != null) reboot = true; } } catch {}
                 data.RebootPending = reboot;
            } catch {}
        }

        private void GetNetworkUsage(SystemStatsData data)
        {
            if (_netSent != null && _netRecv != null) {
                try {
                    // Returns bytes/sec. We convert to KB/s
                    data.NetSent = (long)_netSent.NextValue();
                    data.NetRecv = (long)_netRecv.NextValue();
                } catch {}
            }
        }
    }

    public class AsyncLazy<T> : Lazy<Task<T>>
    {
        public AsyncLazy(Func<T> valueFactory) : base(() => Task.Factory.StartNew(valueFactory)) { }
        public AsyncLazy(Func<Task<T>> taskFactory) : base(() => Task.Factory.StartNew(() => taskFactory()).Unwrap()) { }
        public System.Runtime.CompilerServices.TaskAwaiter<T> GetAwaiter() { return Value.GetAwaiter(); }
    }
}
