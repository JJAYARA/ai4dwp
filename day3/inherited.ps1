<#
Purpose:
- Collect quick local endpoint health signals.
- Show top memory-consuming processes.
- Show recent System log errors.
- Report count of stale-looking user profiles.

Author:
- Inherited script, refactored for readability by GitHub Copilot.

How to run:
- Open PowerShell.
- Run: .\inherited.ps1

Notes:
- This script is read-only; it queries system information and writes output to the console.
#>

# Read basic computer system information into an object for possible later use.
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Read free space (bytes) from the C: drive.
$cDriveFreeBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Read running processes, sort by Working Set memory usage (highest first), and keep top 5.
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Read the latest 10 System log entries and keep only error-level events (Level 2).
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Read local user profiles, excluding special profiles, and keep profiles that have a last use timestamp.
$candidateStaleProfiles = Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special -and $_.LastUseTime }

# Print each top process object to the console.
$topMemoryProcesses | ForEach-Object { Write-Host $_ }

# Print each event timestamp and message to the console.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated "`n$($_.Message)" }

# If at least one candidate stale profile exists, print the count.
if ($candidateStaleProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $candidateStaleProfiles.Count }
