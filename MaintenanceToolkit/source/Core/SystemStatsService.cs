using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using Microsoft.Win32;
using SystemMaintenance.Models;

namespace SystemMaintenance.Core
{
    public class SystemStatsService
    {
        private static readonly Lazy<SystemStatsService> _instance = new Lazy<SystemStatsService>(() => new SystemStatsService());
        public static SystemStatsService Instance
        {
            get { return _instance.Value; }
        }

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
            _cpuName = new AsyncLazy<string>(() => SafeWmiTask(GetCpuInfo, "Unknown CPU"));
            _gpuName = new AsyncLazy<string>(() => SafeWmiTask(GetGpuInfo, "Basic Display Adapter"));
            _osName = new AsyncLazy<string>(() => SafeWmiTask(GetOsInfo, Environment.OSVersion.ToString()));
            InitializeNetworkCounters();
        }

        private async Task<string> SafeWmiTask(Func<string> wmiCall, string fallback)
        {
            try
            {
                var task = Task.Run(wmiCall);
                if (await Task.WhenAny(task, Task.Delay(2000)) == task)
                {
                    return await task;
                }
                else
                {
                    TelemetryLogger.Log($"WMI Call timed out. Fallback: {fallback}");
                    return fallback;
                }
            }
            catch (Exception ex)
            {
                TelemetryLogger.LogException(ex, "WMI Call");
                return fallback;
            }
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
                    } catch (Exception ex) { TelemetryLogger.LogException(ex); }
                }

                if (_activeInterface != null) {
                    _netSent = new PerformanceCounter("Network Interface", "Bytes Sent/sec", _activeInterface);
                    _netRecv = new PerformanceCounter("Network Interface", "Bytes Received/sec", _activeInterface);
                }
            } catch (Exception ex) { TelemetryLogger.LogException(ex); }
        }

        public async Task<SystemStatsData> GetStatsAsync()
        {
            var data = new SystemStatsData();

            // Set a timeout for WMI initialization tasks to prevent hanging
            Task<string> tCPU = _cpuName.Value;
            Task<string> tGPU = _gpuName.Value;
            Task<string> tOS = _osName.Value;

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

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        private class MEMORYSTATUSEX
        {
            public uint dwLength;
            public uint dwMemoryLoad;
            public ulong ullTotalPhys;
            public ulong ullAvailPhys;
            public ulong ullTotalPageFile;
            public ulong ullAvailPageFile;
            public ulong ullTotalVirtual;
            public ulong ullAvailVirtual;
            public ulong ullAvailExtendedVirtual;
            public MEMORYSTATUSEX() { this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX)); }
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

        private string GetCpuInfo()
        {
            try {
                _cores = Environment.ProcessorCount; // Approximating cores as threads
                _threads = Environment.ProcessorCount;

                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"HARDWARE\DESCRIPTION\System\CentralProcessor\0"))
                {
                    if (key != null)
                    {
                        string name = key.GetValue("ProcessorNameString") as string;
                        if (!string.IsNullOrEmpty(name))
                        {
                            return name.Length > 40 ? name.Substring(0, 37) + "..." : name;
                        }
                    }
                }
            } catch (Exception ex) { TelemetryLogger.LogException(ex); }
            return "Unknown CPU";
        }

        private string GetGpuInfo()
        {
            try {
                 // Fast registry fallback for GPU (First active PCI display adapter)
                 using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"))
                 {
                     if (key != null)
                     {
                         string name = key.GetValue("DriverDesc") as string;
                         if (!string.IsNullOrEmpty(name)) return name;
                     }
                 }
            } catch (Exception ex) { TelemetryLogger.LogException(ex); }
            return "Basic Display Adapter";
        }

        private string GetOsInfo()
        {
            try {
                MEMORYSTATUSEX memStatus = new MEMORYSTATUSEX();
                if (GlobalMemoryStatusEx(memStatus))
                {
                    _ramTotal = (long)(memStatus.ullTotalPhys / 1024);
                }

                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion"))
                {
                    if (key != null)
                    {
                        string productName = key.GetValue("ProductName") as string;
                        string releaseId = key.GetValue("ReleaseId") as string;
                        if (!string.IsNullOrEmpty(productName))
                        {
                            return string.IsNullOrEmpty(releaseId) ? productName : $"{productName} ({releaseId})";
                        }
                    }
                }
            } catch (Exception ex) { TelemetryLogger.LogException(ex); }
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
                using (var pc = new PerformanceCounter("Memory", "Available MBytes")) {
                    data.RamFree = (long)pc.NextValue();
                }
            } catch {
                // Native fallback instead of WMI
                try {
                    MEMORYSTATUSEX memStatus = new MEMORYSTATUSEX();
                    if (GlobalMemoryStatusEx(memStatus))
                    {
                        data.RamFree = (long)(memStatus.ullAvailPhys / 1024 / 1024); // To MB
                    }
                } catch (Exception ex) { TelemetryLogger.LogException(ex); }
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
            } catch (Exception ex) { TelemetryLogger.LogException(ex); }
        }

        private void GetRebootStatus(SystemStatsData data)
        {
            try {
                 bool reboot = false;
                 try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")) { if (key != null) reboot = true; } } catch (Exception ex) { TelemetryLogger.LogException(ex); }
                 try { using (var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")) { if (key != null) reboot = true; } } catch (Exception ex) { TelemetryLogger.LogException(ex); }
                 data.RebootPending = reboot;
            } catch (Exception ex) { TelemetryLogger.LogException(ex); }
        }

        private void GetNetworkUsage(SystemStatsData data)
        {
            if (_netSent != null && _netRecv != null) {
                try {
                    // Returns bytes/sec. We convert to KB/s
                    data.NetSent = (long)_netSent.NextValue();
                    data.NetRecv = (long)_netRecv.NextValue();
                } catch (Exception ex) { TelemetryLogger.LogException(ex); }
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
