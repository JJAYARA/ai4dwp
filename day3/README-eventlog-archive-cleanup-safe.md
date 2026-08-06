# Event Log Archive and Cleanup Script (Safe, PowerShell 5.1)

Script path:
- day3/eventlog-archive-cleanup-safe.ps1

## What the script does

- Archives and clears selected Windows event logs with safety guards.
- Supports dry run mode to report how many records would be deleted.
- Uses age targeting with a configurable day threshold.
- Uses try/catch handling for all operations and per-log processing.
- Logs every action to a timestamped log file.
- Prints a summary at the end.
- Creates rollback manifests.
- Supports idempotency by skipping archive/cleanup when a same-day archive file already exists.

## Important implementation note

Windows event logs do not provide a safe native method to delete only old records from a live log.
To meet the age requirement safely, the script clears a log only when the newest event in that log is older than the cutoff.
That means all deleted records are older than the configured threshold.

## Parameters

- DryRun (switch)
  - Preview mode.
  - Prints count of records older than cutoff that would be deleted.

- OlderThanDays (int, default: 3)
  - Age threshold for cleanup targeting.
  - Cutoff is current time minus this number of days.

- LogNames (string[])
  - Logs to process.
  - Default: Application and System.

- ArchiveDirectory (string)
  - Folder where EVTX archives and manifests are stored.
  - Default: day3/eventlog-archive under script location.

- LogDirectory (string)
  - Folder for script execution logs.
  - Default: day3/logs under script location.

- Rollback (switch)
  - Runs rollback mode from a manifest.

- RollbackManifestPath (string)
  - Required in rollback mode.
  - Path to rollback-manifest-*.json created by cleanup mode.

- RollbackRestoreDirectory (string)
  - Base folder where rollback mode restores archived EVTX copies.
  - Default: day3/rollback-restores under script location.

## Usage examples

Dry run with defaults:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup-safe.ps1 -DryRun
```

Cleanup logs older than 7 days:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup-safe.ps1 -OlderThanDays 7
```

Process custom log set:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup-safe.ps1 -LogNames @('Application','System','Windows PowerShell') -OlderThanDays 5
```

Rollback from manifest:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup-safe.ps1 -Rollback -RollbackManifestPath .\day3\eventlog-archive\manifests\rollback-manifest-20260805-120000.json
```

Dry run rollback preview:

```powershell
powershell -ExecutionPolicy Bypass -File .\day3\eventlog-archive-cleanup-safe.ps1 -Rollback -RollbackManifestPath .\day3\eventlog-archive\manifests\rollback-manifest-20260805-120000.json -DryRun
```

## Safety notes

- Running archive/cleanup on some logs (for example Security) may require elevated rights.
- The script logs and continues when a specific log operation fails.
- Review summary and log file after each run.
