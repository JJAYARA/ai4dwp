<#
.SYNOPSIS
    Safe archive and cleanup script for Windows Event Logs (PowerShell 5.1).

.DESCRIPTION
    Archives and clears event logs with safety guards:
      - Dry run mode (shows record counts that would be deleted)
      - Age filter via -OlderThanDays (default 3)
      - Per-operation and per-log try/catch error handling
      - Timestamped action logging
      - End-of-run summary
      - Rollback support via manifest (safe archive recovery)
      - Idempotent daily archive behavior

.NOTES
    Important behavior for age targeting:
      Windows does not support selective deletion of only older records from live logs.
      To enforce the age requirement safely, this script clears a log only when the
      newest record in that log is older than the cutoff. That guarantees all deleted
      records are older than -OlderThanDays.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 3,

    [Parameter()]
    [string[]]$LogNames = @('Application', 'System'),

    [Parameter()]
    [string]$ArchiveDirectory = (Join-Path $PSScriptRoot 'eventlog-archive'),

    [Parameter()]
    [string]$LogDirectory = (Join-Path $PSScriptRoot 'logs'),

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [string]$RollbackManifestPath,

    [Parameter()]
    [string]$RollbackRestoreDirectory = (Join-Path $PSScriptRoot 'rollback-restores')
)

# --------------------------------------------------
# SECTION: Utility Functions
# What this section does:
#   Provides common helper functions for logging, safe file naming,
#   and consistent summary output.
# --------------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $script:LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

function Get-SafeFileName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $safe = $Name
    foreach ($char in $invalid) {
        $safe = $safe.Replace($char, '_')
    }

    return $safe.Replace('/', '_').Replace('\\', '_')
}

function Write-Summary {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Summary,

        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "===== $Title ====="
    $Summary.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, $_.Value) }
    Write-Host "==========================="
}

# --------------------------------------------------
# SECTION: Initialization
# What this section does:
#   Initializes timestamp identifiers, creates directories, and
#   starts the timestamped log file for this script run.
# --------------------------------------------------
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$todayStamp = Get-Date -Format 'yyyyMMdd'
$cutoff = (Get-Date).AddDays(-1 * $OlderThanDays)

try {
    if (-not (Test-Path -LiteralPath $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
}
catch {
    throw "Failed to create/check LogDirectory '$LogDirectory'. Error: $($_.Exception.Message)"
}

$script:LogFile = Join-Path $LogDirectory ("eventlog-cleanup-{0}.log" -f $runId)
try {
    New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
}
catch {
    throw "Failed to create log file '$script:LogFile'. Error: $($_.Exception.Message)"
}

Write-Log -Message "Starting event log archive/cleanup script."
Write-Log -Message "Computer: $env:COMPUTERNAME"
Write-Log -Message ("Mode: DryRun={0}; Rollback={1}; OlderThanDays={2}; Cutoff={3}" -f $DryRun, $Rollback, $OlderThanDays, $cutoff)

# --------------------------------------------------
# SECTION: Rollback Mode
# What this section does:
#   Processes a previously created rollback manifest and safely copies
#   archived EVTX files into a restore folder for recovery.
#   This avoids unsafe in-place manipulation of live system log files.
# --------------------------------------------------
if ($Rollback) {
    $rollbackSummary = @{
        TotalEntries        = 0
        RestoredArchives    = 0
        WouldRestore        = 0
        MissingArchive      = 0
        SkippedAlreadyExist = 0
        Errors              = 0
    }

    if ([string]::IsNullOrWhiteSpace($RollbackManifestPath)) {
        Write-Log -Level ERROR -Message 'Rollback mode requires -RollbackManifestPath.'
        Write-Summary -Summary $rollbackSummary -Title 'Rollback Summary'
        Write-Host "Log file: $script:LogFile"
        return
    }

    if (-not (Test-Path -LiteralPath $RollbackManifestPath)) {
        Write-Log -Level ERROR -Message "Rollback manifest not found: $RollbackManifestPath"
        Write-Summary -Summary $rollbackSummary -Title 'Rollback Summary'
        Write-Host "Log file: $script:LogFile"
        return
    }

    try {
        $manifest = Get-Content -LiteralPath $RollbackManifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Log -Level ERROR -Message "Unable to parse rollback manifest '$RollbackManifestPath'. Error: $($_.Exception.Message)"
        Write-Summary -Summary $rollbackSummary -Title 'Rollback Summary'
        Write-Host "Log file: $script:LogFile"
        return
    }

    $restoreRoot = Join-Path $RollbackRestoreDirectory ("restore-{0}" -f $runId)
    try {
        if (-not (Test-Path -LiteralPath $restoreRoot)) {
            New-Item -ItemType Directory -Path $restoreRoot -Force | Out-Null
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Unable to create rollback restore directory '$restoreRoot'. Error: $($_.Exception.Message)"
        Write-Summary -Summary $rollbackSummary -Title 'Rollback Summary'
        Write-Host "Log file: $script:LogFile"
        return
    }

    foreach ($operation in $manifest.Operations) {
        $rollbackSummary.TotalEntries++

        try {
            $archivePath = $operation.ArchivePath
            if (-not (Test-Path -LiteralPath $archivePath)) {
                Write-Log -Level WARN -Message "Archive file missing, cannot restore: $archivePath"
                $rollbackSummary.MissingArchive++
                continue
            }

            $destFileName = [System.IO.Path]::GetFileName($archivePath)
            $destPath = Join-Path $restoreRoot $destFileName

            if (Test-Path -LiteralPath $destPath) {
                Write-Log -Level WARN -Message "Restore target already exists, skipping: $destPath"
                $rollbackSummary.SkippedAlreadyExist++
                continue
            }

            if ($DryRun) {
                Write-Log -Message ("[DryRun] Would restore archive copy '{0}' to '{1}'" -f $archivePath, $destPath)
                $rollbackSummary.WouldRestore++
                continue
            }

            Copy-Item -LiteralPath $archivePath -Destination $destPath -ErrorAction Stop
            Write-Log -Message ("Restored archive copy: '{0}'" -f $destPath)
            $rollbackSummary.RestoredArchives++
        }
        catch {
            Write-Log -Level ERROR -Message ("Rollback operation failed for archive '{0}'. Error: {1}" -f $operation.ArchivePath, $_.Exception.Message)
            $rollbackSummary.Errors++
        }
    }

    Write-Log -Message 'Rollback mode complete.'
    Write-Summary -Summary $rollbackSummary -Title 'Rollback Summary'
    Write-Host "Log file: $script:LogFile"
    Write-Host "Restore folder: $restoreRoot"
    return
}

# --------------------------------------------------
# SECTION: Cleanup Preparation
# What this section does:
#   Prepares archive/manifests directories and initializes summary and
#   manifest data structures used by the cleanup workflow.
# --------------------------------------------------
$summary = @{
    LogsProcessed             = 0
    LogsArchivedAndCleared    = 0
    LogsSkippedIdempotent     = 0
    LogsSkippedAgeGuard       = 0
    LogsSkippedNoOldRecords   = 0
    RecordsWouldDelete        = 0
    RecordsDeletedEstimate    = 0
    Errors                    = 0
}

$manifestOperations = New-Object System.Collections.Generic.List[object]
$manifestDirectory = Join-Path $ArchiveDirectory 'manifests'

try {
    if (-not (Test-Path -LiteralPath $ArchiveDirectory)) {
        New-Item -ItemType Directory -Path $ArchiveDirectory -Force | Out-Null
    }
}
catch {
    Write-Log -Level ERROR -Message "Unable to create/check archive directory '$ArchiveDirectory'. Error: $($_.Exception.Message)"
    Write-Summary -Summary $summary -Title 'Cleanup Summary'
    Write-Host "Log file: $script:LogFile"
    return
}

try {
    if (-not (Test-Path -LiteralPath $manifestDirectory)) {
        New-Item -ItemType Directory -Path $manifestDirectory -Force | Out-Null
    }
}
catch {
    Write-Log -Level ERROR -Message "Unable to create/check manifest directory '$manifestDirectory'. Error: $($_.Exception.Message)"
    Write-Summary -Summary $summary -Title 'Cleanup Summary'
    Write-Host "Log file: $script:LogFile"
    return
}

# --------------------------------------------------
# SECTION: Archive and Cleanup Processing
# What this section does:
#   For each target log, calculates eligible record counts, enforces
#   age guard logic, performs archive+clear operations, and logs every
#   action with per-log try/catch protection.
# --------------------------------------------------
foreach ($logName in $LogNames) {
    $summary.LogsProcessed++

    try {
        $safeLogName = Get-SafeFileName -Name $logName
        $logArchiveFolder = Join-Path $ArchiveDirectory $safeLogName

        if (-not (Test-Path -LiteralPath $logArchiveFolder)) {
            New-Item -ItemType Directory -Path $logArchiveFolder -Force | Out-Null
        }

        $archivePath = Join-Path $logArchiveFolder ("{0}-{1}.evtx" -f $safeLogName, $todayStamp)

        # Idempotency check: if today's archive exists, skip this log.
        if (Test-Path -LiteralPath $archivePath) {
            Write-Log -Level WARN -Message "Skipping '$logName' because today's archive already exists: $archivePath"
            $summary.LogsSkippedIdempotent++
            continue
        }

        # Count records older than cutoff for dry-run and summary reporting.
        $oldCount = 0
        try {
            $oldCount = (Get-WinEvent -FilterHashtable @{ LogName = $logName; EndTime = $cutoff } -ErrorAction Stop | Measure-Object).Count
        }
        catch {
            throw "Failed counting old records for '$logName'. Error: $($_.Exception.Message)"
        }

        if ($DryRun) {
            Write-Log -Message ("[DryRun] Log '{0}' would delete {1} records older than {2}." -f $logName, $oldCount, $cutoff)
            $summary.RecordsWouldDelete += $oldCount
            continue
        }

        if ($oldCount -eq 0) {
            Write-Log -Message "No records older than cutoff in '$logName'; nothing to clean."
            $summary.LogsSkippedNoOldRecords++
            continue
        }

        # Age guard: clear only when newest record is also older than cutoff.
        # This guarantees all deleted records satisfy the age threshold.
        $newestEvent = $null
        try {
            $newestEvent = Get-WinEvent -FilterHashtable @{ LogName = $logName } -MaxEvents 1 -ErrorAction Stop
        }
        catch {
            throw "Failed to read newest record from '$logName'. Error: $($_.Exception.Message)"
        }

        if ($null -eq $newestEvent) {
            Write-Log -Message "Log '$logName' has no readable events; skipping clear."
            $summary.LogsSkippedNoOldRecords++
            continue
        }

        if ($newestEvent.TimeCreated -gt $cutoff) {
            Write-Log -Level WARN -Message ("Skipping '$logName': it contains newer records ({0}), so selective old-record deletion is not supported safely." -f $newestEvent.TimeCreated)
            $summary.LogsSkippedAgeGuard++
            continue
        }

        # Archive the full log to EVTX before clearing.
        try {
            & wevtutil epl "$logName" "$archivePath"
            if ($LASTEXITCODE -ne 0) {
                throw "wevtutil epl returned exit code $LASTEXITCODE"
            }
            Write-Log -Message "Archived '$logName' to '$archivePath'."
        }
        catch {
            throw "Archive failed for '$logName'. Error: $($_.Exception.Message)"
        }

        # Clear the source log after a successful archive.
        try {
            & wevtutil cl "$logName"
            if ($LASTEXITCODE -ne 0) {
                throw "wevtutil cl returned exit code $LASTEXITCODE"
            }
            Write-Log -Message "Cleared log '$logName'."
        }
        catch {
            throw "Clear failed for '$logName'. Error: $($_.Exception.Message)"
        }

        $manifestOperations.Add([pscustomobject]@{
            LogName          = $logName
            ArchivePath      = $archivePath
            CutoffTime       = $cutoff.ToString('yyyy-MM-dd HH:mm:ss')
            ClearedAt        = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            DeletedEstimate  = $oldCount
        }) | Out-Null

        $summary.RecordsDeletedEstimate += $oldCount
        $summary.LogsArchivedAndCleared++
    }
    catch {
        Write-Log -Level ERROR -Message ("Processing failed for log '{0}'. Error: {1}" -f $logName, $_.Exception.Message)
        $summary.Errors++
        continue
    }
}

# --------------------------------------------------
# SECTION: Manifest and Completion
# What this section does:
#   Writes rollback metadata to a timestamped manifest and prints final
#   summary/log locations for operational follow-up.
# --------------------------------------------------
if (-not $DryRun -and $manifestOperations.Count -gt 0) {
    $manifestPath = Join-Path $manifestDirectory ("rollback-manifest-{0}.json" -f $runId)

    $manifest = [pscustomobject]@{
        RunId         = $runId
        CreatedAt     = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Computer      = $env:COMPUTERNAME
        OlderThanDays = $OlderThanDays
        ArchiveRoot   = $ArchiveDirectory
        Operations    = $manifestOperations
        RollbackNote  = 'Rollback mode restores archived EVTX copies to a restore folder safely.'
    }

    try {
        $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
        Write-Log -Message "Rollback manifest created: $manifestPath"
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to write rollback manifest. Error: $($_.Exception.Message)"
        $summary.Errors++
    }

    Write-Host "Rollback manifest: $manifestPath"
}

Write-Log -Message 'Cleanup mode complete.'
Write-Summary -Summary $summary -Title 'Cleanup Summary'
Write-Host "Log file: $script:LogFile"
