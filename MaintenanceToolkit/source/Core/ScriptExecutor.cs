using System;
using System.Diagnostics;
using System.IO;
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

        public bool IsScriptRunning => _scriptRunning == 1;

        public event Action<string> OnOutput;
        public event Action<string> OnError;

        public ScriptExecutor()
        {
        }

        public async Task RunScriptAsync(ScriptInfo script, bool verbose, CancellationToken ct)
        {
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
                OnError?.Invoke("Script file not found: " + script.FileName);
                return;
            }

            try {
                string args = string.Format("-NoProfile -ExecutionPolicy Bypass {0} -File \"{1}\"", script.IsInteractive ? "-NoExit" : "-NonInteractive", path);
                ProcessStartInfo psi = new ProcessStartInfo("powershell.exe", args);

                psi.UseShellExecute = false;
                psi.CreateNoWindow = !script.IsInteractive;

                if (verbose) psi.EnvironmentVariables["MAINTENANCE_DIAG"] = "1";
                else if (psi.EnvironmentVariables.ContainsKey("MAINTENANCE_DIAG")) psi.EnvironmentVariables.Remove("MAINTENANCE_DIAG");

                if (ConfigManager.IsSafeMode) psi.EnvironmentVariables["MAINTENANCE_SAFE_MODE"] = "1";
                else if (psi.EnvironmentVariables.ContainsKey("MAINTENANCE_SAFE_MODE")) psi.EnvironmentVariables.Remove("MAINTENANCE_SAFE_MODE");

                if (!script.IsInteractive) {
                    psi.StandardOutputEncoding = Encoding.UTF8;
                    psi.StandardErrorEncoding = Encoding.UTF8;
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                }

                using (Process p = new Process { StartInfo = psi }) {
                    if (!script.IsInteractive) {
                        lock(_processLock) _currentProcess = p;

                        p.OutputDataReceived += (s,e) => { if (e.Data!=null) OnOutput?.Invoke(e.Data); };
                        p.ErrorDataReceived += (s,e) => { if (e.Data!=null) OnError?.Invoke("ERR: "+e.Data); };

                        p.Start();
                        p.BeginOutputReadLine();
                        p.BeginErrorReadLine();

                        while (!p.HasExited) {
                            if (ct.IsCancellationRequested) {
                                p.Kill();
                                OnOutput?.Invoke("Process cancelled.");
                                break;
                            }
                            Thread.Sleep(100);
                        }

                        if (!ct.IsCancellationRequested) p.WaitForExit();

                        lock(_processLock) _currentProcess = null;
                    } else {
                        Process.Start(psi);
                    }
                }
            } catch (Exception ex) {
                OnError?.Invoke("Error launching process: " + ex.Message);
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

            // Priority 1: Local
            string[] localPaths = new string[] {
                Path.Combine(baseDir, "scripts", fileName),
                Path.Combine(baseDir, "MaintenanceToolkit", "scripts", fileName),
                Path.Combine(baseDir, "..", "scripts", fileName)
            };

            foreach (string p in localPaths)
            {
                if (File.Exists(p)) return p;
            }

            // Priority 2: Embedded
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
                foreach (string resourceName in assembly.GetManifestResourceNames())
                {
                    if (resourceName.StartsWith("scripts/"))
                    {
                        string relPath = resourceName.Substring("scripts/".Length);
                        string fullPath = Path.Combine(_tempScriptDir, relPath.Replace("/", Path.DirectorySeparatorChar.ToString()));

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
                OnError?.Invoke("Failed to extract embedded scripts: " + ex.Message);
            }
        }

        public void Dispose()
        {
            if (_tempScriptDir != null && Directory.Exists(_tempScriptDir))
            {
                try { Directory.Delete(_tempScriptDir, true); } catch {}
            }
        }
    }
}
