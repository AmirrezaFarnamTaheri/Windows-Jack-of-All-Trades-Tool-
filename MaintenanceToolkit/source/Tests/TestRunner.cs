using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using SystemMaintenance.Core;
using SystemMaintenance.Models;

namespace SystemMaintenance.Tests
{
    public class TestRunner
    {
        public static void Main(string[] args)
        {
            Console.WriteLine("--- Running Maintenance Toolkit Tests ---");
            int passed = 0;
            int failed = 0;

            try { TestConfigManager_Load(); Console.WriteLine("[PASS] ConfigManager Load"); passed++; } catch (Exception e) { Console.WriteLine("[FAIL] ConfigManager Load: " + e.Message); failed++; }

            try { TestScriptInfo_Parsing(); Console.WriteLine("[PASS] ScriptInfo Parsing"); passed++; } catch (Exception e) { Console.WriteLine("[FAIL] ScriptInfo Parsing: " + e.Message); failed++; }

            try { TestSystemInfo_NotNull(); Console.WriteLine("[PASS] SystemInfo Basic"); passed++; } catch (Exception e) { Console.WriteLine("[FAIL] SystemInfo Basic: " + e.Message); failed++; }

            Console.WriteLine("\nTest Summary: {0} Passed, {1} Failed", passed, failed);

            if (failed > 0) Environment.Exit(1);
        }

        static void TestConfigManager_Load()
        {
            // Setup dummy file
            File.WriteAllText("settings.cfg", "DarkMode=True\nSafeMode=False");
            ConfigManager.Load();
            if (!ConfigManager.IsDarkMode) throw new Exception("DarkMode should be true");
            if (ConfigManager.IsSafeMode) throw new Exception("SafeMode should be false");
        }

        static void TestScriptInfo_Parsing()
        {
            var s = new ScriptInfo("test.ps1", "Test Script", "Description", true, true);
            if (s.FileName != "test.ps1") throw new Exception("FileName mismatch");
            if (!s.IsInteractive) throw new Exception("Interactive mismatch");
            if (!s.IsDestructive) throw new Exception("Destructive mismatch");
        }

        static void TestSystemInfo_NotNull()
        {
            // Just ensure it doesn't crash on init
            var instance = SystemStatsService.Instance;
            if (instance == null) throw new Exception("SystemStatsService instance is null");
        }
    }
}
