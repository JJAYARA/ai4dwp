# Temp Cleanup Script (Safe, PowerShell 5.1)

This document explains how to use the endpoint-safe temp cleanup script:
- Script: day3/temp-cleanup-safe.ps1

## What the script does

- Cleans temp files by moving eligible files into a rollback store.
- Supports dry run mode to preview files before any action.
- Filters by file age using LastWriteTime and a configurable day value.
- Skips locked files and continues processing.
- Uses try/catch per file so one failure does not stop the run.
- Logs all actions to a date-timestamped log file.
- Prints a summary at the end.
- Supports rollback from a manifest file.
- Is idempotent:
  - Re-running cleanup does not re-process already moved files.
  - Re-running rollback safely skips already restored or missing items.

## Parameters

- DryRun (switch)
  - Preview mode. Prints every file that would be removed from target folders.
  - No files are moved.

- OlderThanDays (int, default: 0)
  - Only files with LastWriteTime less than or equal to now minus this value are eligible.
  - Example: 7 means older than 7 days.

- TargetPaths (string[])
  - Target folders to scan.
  - Default is current user TEMP folder.

- IncludeWindowsTemp (switch)
  - Adds Windows Temp folder to target paths.
  - Use when running with appropriate permissions.

- LogDirectory (string)
  - Directory where timestamped log files are written.
  - Default: day3/logs under script location.

- RollbackRoot (string)
  - Directory where moved files and manifest are stored.
  - Default: day3/rollback-store under script location.

- Rollback (switch)
  - Enables rollback mode (restore files from manifest entries).

- RollbackManifestPath (string)
  - Required when Rollback is used.
  - Path to a manifest produced by an earlier cleanup run.

## Usage examples

Preview only (dry run):

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-cleanup-safe.ps1 -DryRun
```

Clean user TEMP files older than 7 days:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-cleanup-safe.ps1 -OlderThanDays 7
```

Include Windows Temp too:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-cleanup-safe.ps1 -OlderThanDays 3 -IncludeWindowsTemp
```

Custom target folders:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-cleanup-safe.ps1 -TargetPaths @("C:\Users\Public\Temp","C:\Temp") -OlderThanDays 14
```

Rollback from manifest:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-cleanup-safe.ps1 -Rollback -RollbackManifestPath .\day3\rollback-store\20260805-120000\rollback-manifest-20260805-120000.json
```

Dry-run rollback preview:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\temp-cleanup-safe.ps1 -Rollback -RollbackManifestPath .\day3\rollback-store\20260805-120000\rollback-manifest-20260805-120000.json -DryRun
```

## Safety notes

- The cleanup flow moves files into rollback storage first, instead of hard delete.
- Locked or inaccessible files are logged and skipped.
- Review logs and manifest after each run.
