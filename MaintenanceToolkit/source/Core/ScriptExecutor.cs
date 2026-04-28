using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using SystemMaintenance.Models;

namespace SystemMaintenance.Core
{
    public class ScriptExecutor : IDisposable
    {
        private Process _currentProcess;
        private readonly object _processLock = new object();
        private string _tempScriptDir;
        private int _scriptRunning = 0;
        private bool _disposed = false;

        public bool IsScriptRunning { get { return _scriptRunning == 1; } }

        public event Action<string> OnOutput;
        public event Action<string> OnError;

        public event Action<int, TimeSpan> OnCompleted;

        public ScriptExecutor()
        {
        }

        public async Task RunScriptAsync(ScriptInfo script, bool verbose, CancellationToken ct)
        {
            if (_disposed) throw new ObjectDisposedException("ScriptExecutor");
            if (Interlocked.CompareExchange(ref _scriptRunning, 1, 0) != 0)
                throw new InvalidOperationException("Script already running.");

            try
            {
                await Task.Run(() => ExecuteScriptInternal(script, verbose, ct));
            }
            finally
            {
                Interlocked.Exchange(ref _scriptRunning, 0);
            }
        }

        private void ExecuteScriptInternal(ScriptInfo script, bool verbose, CancellationToken ct)
        {
            string path = FindScriptPath(script.FileName);

            if (path == null) {
                var err = OnError;
                if (err != null) err("Script file not found: " + script.FileName);
                return;
            }

            DateTime start = DateTime.UtcNow;
            int exitCode = -1;

            try {
                string args;
                if (script.IsInteractive)
                {
                    // Interactive: Launch in new window
                    args = string.Format("-NoProfile -ExecutionPolicy Bypass -NoExit -File \"{0}\"", path);
                }
                else
                {
                    // Non-Interactive: Capture output
                    args = string.Format("-NoProfile -ExecutionPolicy Bypass -NonInteractive -File \"{0}\"", path);
                }

                ProcessStartInfo psi = new ProcessStartInfo("powershell.exe", args);

                // Common Environment Variables
                if (verbose) psi.EnvironmentVariables["MAINTENANCE_DIAG"] = "1";
                else if (psi.EnvironmentVariables.ContainsKey("MAINTENANCE_DIAG")) psi.EnvironmentVariables.Remove("MAINTENANCE_DIAG");

                if (ConfigManager.IsSafeMode) psi.EnvironmentVariables["MAINTENANCE_SAFE_MODE"] = "1";
                else if (psi.EnvironmentVariables.ContainsKey("MAINTENANCE_SAFE_MODE")) psi.EnvironmentVariables.Remove("MAINTENANCE_SAFE_MODE");

                // Captured-output runs have no console for ReadKey / Pause; scripts must skip blocking prompts (see Common.ps1).
                if (!script.IsInteractive) psi.EnvironmentVariables["MAINTENANCE_GUI_HOST"] = "1";
                else if (psi.EnvironmentVariables.ContainsKey("MAINTENANCE_GUI_HOST")) psi.EnvironmentVariables.Remove("MAINTENANCE_GUI_HOST");

                if (script.IsInteractive)
                {
                    psi.UseShellExecute = false;
                    psi.CreateNoWindow = false;

                    using (Process p = new Process { StartInfo = psi })
                    {
                         lock(_processLock) _currentProcess = p;
                         p.Start();
                         p.WaitForExit();
                         try { exitCode = p.ExitCode; } catch {}
                         lock(_processLock) _currentProcess = null;
                    }
                }
                else
                {
                    psi.UseShellExecute = false;
                    psi.CreateNoWindow = true;
                    psi.StandardOutputEncoding = Encoding.UTF8;
                    psi.StandardErrorEncoding = Encoding.UTF8;
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;

                    using (Process p = new Process { StartInfo = psi })
                    {
                        lock(_processLock) _currentProcess = p;

                        p.OutputDataReceived += (s,e) => { if (e.Data!=null) { var outH = OnOutput; if (outH != null) outH(e.Data); } };
                        p.ErrorDataReceived += (s,e) => { if (e.Data!=null) { var errH = OnError; if (errH != null) errH("ERR: " + e.Data); } };

                        p.Start();
                        p.BeginOutputReadLine();
                        p.BeginErrorReadLine();

                        while (!p.HasExited) {
                            if (ct.IsCancellationRequested || _disposed) {
                                try { p.Kill(); } catch {}
                                var outH = OnOutput;
                                if (outH != null) outH("Process cancelled.");
                                break;
                            }
                            Thread.Sleep(100);
                        }

                        if (!ct.IsCancellationRequested && !_disposed) p.WaitForExit();

                        try { exitCode = p.ExitCode; } catch {}

                        lock(_processLock) _currentProcess = null;
                    }
                }
            } catch (Exception ex) {
                var err = OnError;
                if (err != null) err("Error launching process: " + ex.Message);
            } finally {
                try
                {
                    TimeSpan dur = DateTime.UtcNow - start;
                    var complete = OnCompleted;
                    if (complete != null) complete(exitCode, dur);
                }
                catch
                {
                }
            }
        }

        public void Cancel()
        {
            lock(_processLock) {
                if (_currentProcess != null && !_currentProcess.HasExited) {
                    try { _currentProcess.Kill(); } catch {}
                }
            }
        }

        private string FindScriptPath(string fileName)
        {
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;

            // Normalize path separator just in case
            fileName = fileName.TrimStart('\\', '/');

            // Search paths: prioritized order
            string[] potentialPaths = new string[] {
                // 1. Direct 'scripts' folder next to exe (Release/Production)
                Path.Combine(baseDir, "scripts", fileName),

                // 2. 'MaintenanceToolkit/scripts' next to exe (Unzipped structure sometimes)
                Path.Combine(baseDir, "MaintenanceToolkit", "scripts", fileName),

                // 3. Parent dir (Running from inside bin/Debug?)
                Path.Combine(baseDir, "..", "scripts", fileName),

                // 4. Grandparent dir (Dev environment)
                Path.Combine(baseDir, "..", "..", "scripts", fileName),

                // 5. Explicit check for dev root (e.g. if running from nested bin folder)
                Path.Combine(baseDir, "..", "..", "..", "scripts", fileName)
            };

            foreach (string p in potentialPaths)
            {
                if (File.Exists(p)) return Path.GetFullPath(p);
            }

            // Embedded fallback
            EnsureEmbeddedScriptsExtracted();
            if (_tempScriptDir != null)
            {
                string tempPath = Path.Combine(_tempScriptDir, fileName);
                if (File.Exists(tempPath)) return tempPath;
            }

            return null;
        }

        private void EnsureEmbeddedScriptsExtracted()
        {
            if (_tempScriptDir != null) return;

            try {
                _tempScriptDir = Path.Combine(Path.GetTempPath(), "SysMaintToolkit_" + Guid.NewGuid().ToString("N").Substring(0, 8));
                Directory.CreateDirectory(_tempScriptDir);

                var assembly = System.Reflection.Assembly.GetExecutingAssembly();
                string[] resources = assembly.GetManifestResourceNames();

                foreach (string resourceName in resources)
                {
                    string validPath = null;

                    // Case 1: BuildTool (Slashes) e.g. "scripts/lib/Common.ps1"
                    if (resourceName.StartsWith("scripts/") && resourceName.EndsWith(".ps1"))
                    {
                         validPath = resourceName.Substring("scripts/".Length);
                         if (Path.DirectorySeparatorChar != '/') validPath = validPath.Replace('/', Path.DirectorySeparatorChar);
                    }
                    // Case 2: VS Embedded (Dots) e.g. "SystemMaintenance.scripts.lib.Common.ps1"
                    else if (resourceName.Contains(".scripts.") && resourceName.EndsWith(".ps1"))
                    {
                         string afterScripts = resourceName.Substring(resourceName.IndexOf(".scripts.") + 9);

                         // Heuristic for subfolders
                         if (afterScripts.StartsWith("lib."))
                         {
                             validPath = Path.Combine("lib", afterScripts.Substring(4));
                         }
                         else
                         {
                             validPath = afterScripts;
                         }
                    }

                    if (validPath != null)
                    {
                        string fullPath = Path.Combine(_tempScriptDir, validPath);
                        string dir = Path.GetDirectoryName(fullPath);
                        if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

                        using (Stream stream = assembly.GetManifestResourceStream(resourceName))
                        using (FileStream fileStream = new FileStream(fullPath, FileMode.Create))
                        {
                            stream.CopyTo(fileStream);
                        }
                    }
                }
            } catch (Exception ex) {
                var err = OnError;
                if (err != null) err("Failed to extract embedded scripts: " + ex.Message);
            }
        }

        public void Dispose()
        {
            if (_disposed) return;

            Cancel(); // Kill any running process
            _disposed = true;

            if (_tempScriptDir != null && Directory.Exists(_tempScriptDir))
            {
                try { Directory.Delete(_tempScriptDir, true); } catch {}
            }
        }
    }
}
