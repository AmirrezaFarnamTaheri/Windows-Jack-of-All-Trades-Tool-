import os
import re

scripts_dir = "MaintenanceToolkit/scripts"
common_import_line = '. "$PSScriptRoot/lib/Common.ps1"\n'

# Regex for the standard Admin Block
admin_pattern = re.compile(r'# Check for Administrator privileges.*?Exit\s+}', re.DOTALL)

def refactor_script(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If the file was touched by sed, it has the import line at the top.
    # We want to keep that (or ensure it's there) but still apply replacements.

    # 1. Replace Admin Block
    if "Assert-Admin" not in content:
        new_content = admin_pattern.sub('Assert-Admin', content)
    else:
        new_content = content

    # 2. Ensure Import is present exactly once
    if common_import_line.strip() not in new_content:
        new_content = common_import_line + new_content

    # 3. Replace Headers
    header_pattern = re.compile(r'Write-Host "--- (.*?) ---" -ForegroundColor Cyan')
    def header_replace(match):
        return f'Write-Header "{match.group(1)}"'
    new_content = header_pattern.sub(header_replace, new_content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Refactored: {filepath}")

for filename in os.listdir(scripts_dir):
    if filename.endswith(".ps1") and filename not in ["_MasterMenu.ps1", "_SetupAutoSchedule.ps1", "_WeeklyMaintenance.ps1"]:
        refactor_script(os.path.join(scripts_dir, filename))
