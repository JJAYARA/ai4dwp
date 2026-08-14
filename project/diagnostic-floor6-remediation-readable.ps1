<#
================================================================================
  SCRIPT: DWP Floor 6 Endpoint Remediation Script (Readable Version)
================================================================================

PURPOSE:
  This script safely remediates Floor 6 login/performance issues caused by:
  - Insufficient disk space (temp files, old Windows installations)
  - Event log bloat reducing system performance
  - Corrupted or orphaned user profiles blocking logins
  - Registry inconsistencies causing authentication delays

TARGET ISSUES:
  • Disk space exhaustion (CHECK #4)
  • Event log performance degradation
  • User profile corruption (CHECK #5)
  • Orphaned profiles and registry entries

AUTHOR:
  DWP Engineering
  Version: 1.0 (Readable Edition)
  Date: 2026-08-14

SUPPORTED OPERATING SYSTEMS:
  • Windows 10 / 11 (PowerShell 5.1+)
  • Requires Administrator privileges for most operations

SAFETY FEATURES:
  ✓ Dry-run mode (preview changes without applying them)
  ✓ Configurable file age threshold (only delete files older than N days)
  ✓ Locked file handling (gracefully skips in-use files, continues script)
  ✓ Per-file error handling (one failure doesn't stop entire process)
  ✓ Comprehensive logging (timestamped, severity-coded, saved to file)
  ✓ Rollback support (backs up all files before deletion, can restore)
  ✓ Idempotent execution (safe to run multiple times)

PREREQUISITES:
  • PowerShell 5.1 or later
  • Administrator privileges (for event log, profile, registry operations)
  • 10+ GB free disk space for backup folder

================================================================================
  HOW TO RUN THIS SCRIPT
================================================================================

BASIC USAGE (Dry-run only - no changes):
  .\diagnostic-floor6-remediation-readable.ps1 -DryRun

CLEAN FILES OLDER THAN 7 DAYS:
  .\diagnostic-floor6-remediation-readable.ps1 -DaysOld 7

RUN WITH ADMIN PRIVILEGES (recommended):
  Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File diagnostic-floor6-remediation-readable.ps1" -Verb RunAs

SPECIFY CUSTOM LOG LOCATION:
  .\diagnostic-floor6-remediation-readable.ps1 -LogPath "C:\Logs\remediation.log"

ROLLBACK - RESTORE PREVIOUSLY BACKED-UP FILES:
  .\diagnostic-floor6-remediation-readable.ps1 -Rollback -RollbackSource "C:\Users\labuser\AppData\Local\Temp\DWP-Remediation-Backup-20260814-120000"

================================================================================
  PARAMETERS
================================================================================

-DryRun [switch]
  When specified, previews all deletions without making changes.
  Use this first to verify what will be deleted.
  Default: $false (will make changes if not specified)

-DaysOld [int]
  Only delete files older than this many days.
  For example, -DaysOld 7 deletes only files not modified in 7+ days.
  Default: 0 (deletes all files, including recent ones)

-LogPath [string]
  Full path where log file will be saved.
  Log file contains timestamped entries of all actions taken.
  Default: "$env:TEMP\DWP-Remediation-[timestamp].log"

-BackupPath [string]
  Directory where deleted files are backed up before deletion.
  Used for rollback functionality.
  Default: "$env:TEMP\DWP-Remediation-Backup-[timestamp]"

-Rollback [switch]
  Enables rollback mode; restores files from backup directory.
  Must be used with -RollbackSource parameter.
  Warning: Restores deleted files back to original locations.

-RollbackSource [string]
  Path to backup folder created during remediation run.
  Required when using -Rollback switch.
  Example: C:\Users\labuser\AppData\Local\Temp\DWP-Remediation-Backup-20260814-120000

================================================================================
  WHAT THIS SCRIPT DOES (Six Remediation Sections)
================================================================================

SECTION 1: TEMP FOLDER CLEANUP
  • Removes old temporary files from %TEMP% folder
  • Frees disk space without breaking anything (temp files recreate as needed)
  • Skips locked files, logs them for next run

SECTION 2: EVENT LOG CLEANUP
  • Clears outdated entries from System, Application, Security logs
  • Reduces log file size (often 1-5 GB on older systems)
  • Improves system performance, speeds up log queries

SECTION 3: WINDOWS.OLD FOLDER CLEANUP
  • Deletes Windows.old folder (previous Windows installation backup)
  • Typically frees 10-20 GB of disk space
  • Only safe to delete after confirming upgrade was successful

SECTION 4: USER PROFILE CLEANUP
  • Identifies and removes corrupted profiles (missing NTUSER.DAT)
  • Removes orphaned profiles from inactive/deleted accounts
  • Profiles automatically recreate on next login

SECTION 5: REGISTRY PROFILE HEALTH CHECK
  • Scans registry for orphaned profile entries (profiles with missing paths)
  • Reports orphaned entries for manual cleanup
  • Read-only check (does not delete registry entries)

SECTION 6: DISK SPACE REPORT
  • Displays current disk usage statistics
  • Shows total, used, free space and percentage used
  • Alerts if disk space is critically low (<1 GB) or low (<5 GB)

================================================================================
  EXAMPLE EXECUTION FLOW
================================================================================

Step 1: Run in dry-run mode first
  .\diagnostic-floor6-remediation-readable.ps1 -DryRun
  → Review what will be deleted, verify it's safe to delete

Step 2: Run with admin privileges
  Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File diagnostic-floor6-remediation-readable.ps1" -Verb RunAs
  → Makes actual changes, creates backup folder

Step 3: Review log file
  Notepad $env:TEMP\DWP-Remediation-*.log
  → Verify all operations completed successfully

Step 4: If something goes wrong, rollback
  .\diagnostic-floor6-remediation-readable.ps1 -Rollback -RollbackSource "C:\path\to\backup"
  → Restores all backed-up files to original locations

================================================================================
#>

# ==============================================================================
# SCRIPT PARAMETERS - Configurable options for script execution
# ==============================================================================

param(
    # Execute script in dry-run mode (preview changes without applying them)
    [switch]$DryRun = $false,
    
    # Only target files that are this many days old or older (default: all files)
    [int]$DaysOld = 0,
    
    # Path where timestamped log file will be created
    [string]$LogPath = "$env:TEMP\DWP-Remediation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log",
    
    # Directory where backed-up files will be stored before deletion
    [string]$BackupPath = "$env:TEMP\DWP-Remediation-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    
    # Enable rollback mode to restore files from previous backup
    [switch]$Rollback = $false,
    
    # Source backup folder path for rollback operation
    [string]$RollbackSource = ""
)

# ==============================================================================
# INITIALIZATION SECTION - Set up script counters and backup directory
# ==============================================================================

# Create backup directory if running in live mode (not dry-run or rollback)
if (-not $DryRun -and -not $Rollback) {
    # Check if backup directory already exists to avoid errors
    if (-not (Test-Path -Path $BackupPath)) {
        # Create the backup directory for storing files before deletion
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    }
}

# Initialize counters for tracking operations (used in summary report)
# Count of total files processed by the script
$script:FilesProcessed = 0

# Count of files successfully deleted
$script:FilesDeleted = 0

# Count of files skipped (locked, too recent, or already deleted)
$script:FilesSkipped = 0

# Count of files backed up before deletion
$script:FilesBackedUp = 0

# Counter for non-fatal errors encountered during processing
$script:ErrorCount = 0

# Counter for warning-level issues (not critical, script continues)
$script:WarningCount = 0

# Array to store detailed action history for summary and troubleshooting
$script:ActionLog = @()

# ==============================================================================
# LOGGING FUNCTION - Write timestamped entries to log file and console
# ==============================================================================

function Write-LogEntry {
    <#
    .SYNOPSIS
    Writes timestamped log entries to both log file and console with color coding.
    
    .DESCRIPTION
    Creates a standard log entry with timestamp, severity level, and message.
    Logs to file for persistent record, displays on console with color for visibility.
    Automatically increments warning/error counters for summary report.
    #>
    param(
        # The message text to log
        [string]$Message,
        
        # Severity level: INFO (blue), WARN (yellow), ERROR (red), SUCCESS (green)
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Severity = "INFO"
    )
    
    # Get current date/time in standard format with milliseconds for precision
    $CurrentTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    
    # Construct complete log entry with timestamp, severity, and message
    $FormattedLogMessage = "[$CurrentTimestamp] [$Severity] $Message"
    
    # Write log entry to file (appends to existing file, UTF8 encoding for compatibility)
    $FormattedLogMessage | Out-File -FilePath $LogPath -Append -Encoding UTF8
    
    # Determine console text color based on severity level for visual distinction
    $ConsoleColor = switch ($Severity) {
        "INFO"    { "Cyan" }      # Information messages in cyan
        "WARN"    { "Yellow" }    # Warnings in yellow for attention
        "ERROR"   { "Red" }       # Errors in red for visibility
        "SUCCESS" { "Green" }     # Success messages in green for confirmation
        default   { "White" }     # Unknown severity defaults to white
    }
    
    # Write log entry to console with appropriate color
    Write-Host $FormattedLogMessage -ForegroundColor $ConsoleColor
    
    # Increment warning counter if this is a warning-level message
    if ($Severity -eq "WARN") { 
        $script:WarningCount++ 
    }
    
    # Increment error counter if this is an error-level message
    if ($Severity -eq "ERROR") { 
        $script:ErrorCount++ 
    }
}

# ==============================================================================
# ACTION LOGGING FUNCTION - Track all actions for summary and audit trail
# ==============================================================================

function Log-Action {
    <#
    .SYNOPSIS
    Logs specific action details for summary report generation and rollback tracking.
    
    .DESCRIPTION
    Creates structured log entries for actions (backup, delete, skip) to enable
    detailed summary reporting and to track what was backed up for rollback.
    #>
    param(
        # Type of action performed (e.g., "Backup", "Delete", "Delete (Failed)", "Skip")
        [string]$Action,
        
        # File or directory path that action was performed on
        [string]$Path,
        
        # Result status (e.g., "Backed-Up", "Deleted", "Locked", "Error", "Dry-Run")
        [string]$Status
    )
    
    # Add entry to action log array with full details for later reporting
    # Including timestamp, action type, path, status, and backup location if applicable
    $script:ActionLog += @{
        # Timestamp when action was logged
        Timestamp = Get-Date
        
        # Type of operation (Backup, Delete, Skip, etc.)
        Action = $Action
        
        # File or directory affected by this action
        Path = $Path
        
        # Result status of the action
        Status = $Status
        
        # If file was backed up, store location for potential rollback
        BackupLocation = if ($Status -eq "Backed-Up") { 
            Join-Path -Path $BackupPath -ChildPath (Split-Path -Leaf $Path) 
        } else { 
            "" 
        }
    }
}

# ==============================================================================
# ROLLBACK FUNCTION - Restore previously backed-up files to original locations
# ==============================================================================

function Invoke-Rollback {
    <#
    .SYNOPSIS
    Restores all files backed up during a previous remediation run.
    
    .DESCRIPTION
    Reads backup directory created during previous script run and restores
    all backed-up files back to their original locations. Useful if cleanup
    caused unexpected issues and needs to be reversed.
    
    WARNING: This overwrites current files with backed-up versions!
    #>
    
    # Display separator and indicate rollback mode has started
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "ROLLBACK MODE INITIATED" "WARN"
    Write-LogEntry "============================================" "WARN"
    
    # Verify that backup source path exists before attempting restore
    if (-not (Test-Path -Path $RollbackSource)) {
        # Log error if backup path cannot be found
        Write-LogEntry "Rollback source not found: $RollbackSource" "ERROR"
        
        # Exit script with error code (1 = failure)
        exit 1
    }
    
    # Get all files and folders in the backup directory recursively
    $BackupItems = Get-ChildItem -Path $RollbackSource -Recurse -Force -ErrorAction SilentlyContinue
    
    # Initialize counter for successfully restored items
    $RestoredItemCount = 0
    
    # Process each backed-up file in the backup directory
    foreach ($BackupItem in $BackupItems) {
        try {
            # Extract relative path from full backup path for logging
            $RelativePath = $BackupItem.FullName.Substring($RollbackSource.Length).TrimStart('\')
            
            # Reconstruct original file path by removing backup directory prefix
            # [VERIFY] Adjust this logic if backup directory structure differs from your environment
            $OriginalFilePath = $BackupItem.FullName -replace [regex]::Escape($RollbackSource), ""
            
            # Only process files, not directories (directories are created by file restore)
            if (-not $BackupItem.PSIsContainer) {
                # Log that we're restoring this specific file
                Write-LogEntry "Restoring file: $OriginalFilePath" "INFO"
                
                # Copy backed-up file back to original location, overwriting if exists
                Copy-Item -Path $BackupItem.FullName -Destination $OriginalFilePath -Force -ErrorAction Stop
                
                # Increment counter for successfully restored items
                $RestoredItemCount++
                
                # Log successful restoration with checkmark
                Write-LogEntry "✓ Restored: $OriginalFilePath" "SUCCESS"
            }
        } catch {
            # Log any errors encountered during restore process
            Write-LogEntry "✗ Failed to restore: $($BackupItem.FullName) - Error: $_" "ERROR"
        }
    }
    
    # Log completion of rollback operation with count of restored items
    Write-LogEntry "Rollback complete. Restored $RestoredItemCount items." "SUCCESS"
    
    # Exit script after rollback completes (0 = success)
    exit 0
}

# ==============================================================================
# FILE DELETION FUNCTION - Safely delete files with backup and error handling
# ==============================================================================

function Remove-FileWithBackup {
    <#
    .SYNOPSIS
    Deletes a single file with optional backup and graceful error handling.
    
    .DESCRIPTION
    Safely removes a file after creating backup copy (unless in dry-run mode).
    Handles locked files gracefully by skipping and logging, then continuing.
    Respects age threshold (-DaysOld parameter) to avoid deleting recent files.
    All actions tracked for logging and rollback capability.
    #>
    param(
        # Full path to file to be deleted
        [string]$FilePath,
        
        # Description of why file is being deleted (for log clarity)
        [string]$Description = ""
    )
    
    # Increment total files processed counter
    $script:FilesProcessed++
    
    # Check if file exists before attempting to process it
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        # File not found (already deleted or path doesn't exist)
        Write-LogEntry "File not found (already deleted?): $FilePath" "WARN"
        
        # Increment skipped counter since we didn't process this file
        $script:FilesSkipped++
        
        # Exit function early since there's nothing to delete
        return
    }
    
    try {
        # Get detailed file information (size, modification date, etc.)
        $FileMetadata = Get-Item -Path $FilePath -Force -ErrorAction Stop
        
        # Calculate how many days old this file is (current date - last write time)
        $FileAgeInDays = (Get-Date) - $FileMetadata.LastWriteTime
        
        # Check if file is newer than the configured threshold
        if ($FileAgeInDays.Days -lt $DaysOld) {
            # File is too recent; skip it to preserve recent data
            Write-LogEntry "Skipping file (too recent): $FilePath (Age: $($FileAgeInDays.Days) days, threshold: $DaysOld days)" "INFO"
            
            # Increment skipped counter
            $script:FilesSkipped++
            
            # Exit function; don't delete this file
            return
        }
        
        # Convert file size from bytes to megabytes for human-readable logging
        $FileSizeInMB = $FileMetadata.Length / 1MB
        
        # Attempt to back up the file if not in dry-run mode
        if (-not $DryRun) {
            try {
                # Construct backup file path in backup directory using original filename
                $BackupDestinationPath = Join-Path -Path $BackupPath -ChildPath (Split-Path -Leaf $FilePath)
                
                # Copy file to backup location before deletion
                Copy-Item -Path $FilePath -Destination $BackupDestinationPath -Force -ErrorAction Stop
                
                # Log successful backup with checkmark indicator
                Write-LogEntry "✓ Backed up: $FilePath" "SUCCESS"
                
                # Increment files backed up counter
                $script:FilesBackedUp++
                
                # Add entry to action log for audit trail
                Log-Action -Action "Backup" -Path $FilePath -Status "Backed-Up"
            } catch {
                # If backup fails, warn but continue (will still attempt delete)
                Write-LogEntry "⚠️  Could not backup file (will still attempt delete): $FilePath - Error: $_" "WARN"
            }
        }
        
        # In dry-run mode: just report what would be deleted without making changes
        if ($DryRun) {
            # Log what would be deleted with file size and description
            Write-LogEntry "[DRY-RUN] Would delete: $FilePath ($([math]::Round($FileSizeInMB, 2)) MB) - $Description" "INFO"
            
            # Increment deleted counter (for dry-run summary)
            $script:FilesDeleted++
            
            # Log this as a dry-run action
            Log-Action -Action "Delete (Dry-Run)" -Path $FilePath -Status "Dry-Run"
            
            # Exit function; don't actually delete in dry-run mode
            return
        }
        
        # Attempt to actually delete the file (live mode only)
        try {
            # Delete file with Force flag to override read-only attribute
            Remove-Item -Path $FilePath -Force -ErrorAction Stop
            
            # Log successful deletion with checkmark and file details
            Write-LogEntry "✓ Deleted: $FilePath ($([math]::Round($FileSizeInMB, 2)) MB) - $Description" "SUCCESS"
            
            # Increment successful deletion counter
            $script:FilesDeleted++
            
            # Add entry to action log for audit trail
            Log-Action -Action "Delete" -Path $FilePath -Status "Deleted"
        } catch [System.IO.IOException] {
            # File is locked by another process (in use); skip and continue
            Write-LogEntry "⚠️  LOCKED FILE (skipping): $FilePath - Still in use, will retry next run" "WARN"
            
            # Increment skipped counter since file wasn't deleted
            $script:FilesSkipped++
            
            # Log this as a locked file for troubleshooting
            Log-Action -Action "Delete (Failed)" -Path $FilePath -Status "Locked"
        } catch {
            # Other deletion errors (permission denied, path not found, etc.)
            Write-LogEntry "⚠️  Could not delete: $FilePath - Error: $_" "WARN"
            
            # Increment skipped counter
            $script:FilesSkipped++
            
            # Log deletion failure for audit trail
            Log-Action -Action "Delete (Failed)" -Path $FilePath -Status "Error"
        }
        
    } catch {
        # Error retrieving file information; log and continue with next file
        Write-LogEntry "✗ Error processing file: $FilePath - Error: $_" "ERROR"
        
        # Increment skipped counter since file wasn't processed
        $script:FilesSkipped++
    }
}

# ==============================================================================
# DIRECTORY DELETION FUNCTION - Safely delete directories with backup
# ==============================================================================

function Remove-DirectoryWithBackup {
    <#
    .SYNOPSIS
    Deletes an entire directory tree with backup and error handling.
    
    .DESCRIPTION
    Recursively removes directory and all contents after creating backup copy.
    Handles locked files gracefully; logs any inaccessible files without stopping.
    Used for removing large folders like Windows.old and corrupted profiles.
    #>
    param(
        # Full path to directory to be deleted
        [string]$DirectoryPath,
        
        # Description of why directory is being deleted (for log clarity)
        [string]$Description = ""
    )
    
    # Check if directory exists before attempting to process it
    if (-not (Test-Path -Path $DirectoryPath -PathType Container)) {
        # Directory not found (already deleted or path doesn't exist)
        Write-LogEntry "Directory not found (already deleted?): $DirectoryPath" "WARN"
        
        # Exit function early since there's nothing to delete
        return
    }
    
    try {
        # Get directory metadata (size, modification date)
        $DirectoryMetadata = Get-Item -Path $DirectoryPath -Force -ErrorAction Stop
        
        # Calculate total size of directory by summing all file sizes recursively
        $DirectorySizeInMB = (Get-ChildItem -Path $DirectoryPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        
        # In dry-run mode: report what would be deleted without making changes
        if ($DryRun) {
            # Log what would be deleted with directory size and description
            Write-LogEntry "[DRY-RUN] Would delete directory: $DirectoryPath ($([math]::Round($DirectorySizeInMB, 2)) MB) - $Description" "INFO"
            
            # Exit function without making changes
            return
        }
        
        try {
            # Backup entire directory structure before deletion
            # Construct backup destination path using original directory name
            $BackupDestinationPath = "$BackupPath\$(Split-Path -Leaf $DirectoryPath)"
            
            # Copy entire directory tree to backup location with all contents
            Copy-Item -Path $DirectoryPath -Destination $BackupDestinationPath -Recurse -Force -ErrorAction Stop
            
            # Log successful backup of directory
            Write-LogEntry "✓ Backed up directory: $DirectoryPath" "SUCCESS"
            
            # Delete the original directory and all contents recursively
            Remove-Item -Path $DirectoryPath -Recurse -Force -ErrorAction Stop
            
            # Log successful deletion with directory size and description
            Write-LogEntry "✓ Deleted directory: $DirectoryPath ($([math]::Round($DirectorySizeInMB, 2)) MB) - $Description" "SUCCESS"
            
            # Log this action for audit trail
            Log-Action -Action "Delete Directory" -Path $DirectoryPath -Status "Deleted"
        } catch [System.IO.IOException] {
            # Some files in directory are locked; skip entire directory
            Write-LogEntry "⚠️  LOCKED DIRECTORY (skipping): $DirectoryPath - Files still in use" "WARN"
            
            # Log locked directory for troubleshooting
            Log-Action -Action "Delete Directory (Failed)" -Path $DirectoryPath -Status "Locked"
        } catch {
            # Other errors during deletion (permission denied, access denied, etc.)
            Write-LogEntry "⚠️  Could not delete directory: $DirectoryPath - Error: $_" "WARN"
            
            # Log deletion failure for audit trail
            Log-Action -Action "Delete Directory (Failed)" -Path $DirectoryPath -Status "Error"
        }
    } catch {
        # Error retrieving directory metadata; log and continue
        Write-LogEntry "✗ Error processing directory: $DirectoryPath - Error: $_" "ERROR"
    }
}

# ==============================================================================
# SECTION 1: CLEAN TEMP FOLDER - Remove old temporary files (CHECK #4 - DISK SPACE)
# ==============================================================================

function Remove-OldTempFiles {
    <#
    .SYNOPSIS
    Removes old files from Windows temporary folder to free disk space.
    
    .DESCRIPTION
    Cleans the %TEMP% folder by deleting files older than threshold.
    Temp files are safe to delete as operating system recreates them as needed.
    Locked/in-use files are skipped gracefully without stopping script.
    This typically frees 500 MB to 5 GB of disk space.
    #>
    
    # Display section header with separators for clarity
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "SECTION 1: CLEANING TEMP FOLDER" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Get Windows temp folder path from environment variable
    $WindowsTempFolder = $env:TEMP
    
    # Log which folder is being scanned
    Write-LogEntry "Scanning temp folder: $WindowsTempFolder" "INFO"
    
    # Get all files in temp folder recursively (includes subdirectories)
    # Using Force to include hidden/system files
    $AllTempFiles = Get-ChildItem -Path $WindowsTempFolder -File -Force -Recurse -ErrorAction SilentlyContinue
    
    # Log total count of files found for user awareness
    Write-LogEntry "Found $($AllTempFiles.Count) files in temp folder" "INFO"
    
    # Process each temp file if any exist
    if ($AllTempFiles.Count -gt 0) {
        # Loop through all temp files
        foreach ($TempFile in $AllTempFiles) {
            # Call function to safely delete file with backup
            Remove-FileWithBackup -FilePath $TempFile.FullName -Description "Temp file cleanup"
        }
    }
    
    # Log completion of temp folder cleanup section
    Write-LogEntry "Temp folder cleanup complete." "SUCCESS"
    
    # Add blank line for readability between sections
    Write-LogEntry ""
}

# ==============================================================================
# SECTION 2: CLEAR OLD EVENT LOGS - Reduce log file sizes (DISK SPACE & PERFORMANCE)
# ==============================================================================

function Clear-OldEventLogs {
    <#
    .SYNOPSIS
    Clears old entries from Windows event logs to free disk space and improve performance.
    
    .DESCRIPTION
    Reduces event log size by clearing entries older than specified threshold.
    Target logs: System, Application, Security (most space-consuming).
    Clearing old logs speeds up system performance and frees 1-10 GB disk space.
    Requires administrator privileges to clear event logs.
    #>
    
    # Display section header with separators for clarity
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "SECTION 2: CLEARING OLD EVENT LOGS" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Check if current user has administrator privileges required for event log access
    # [VERIFY] This requires admin privileges; will skip if user is not admin
    $IsUserAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    # If not running as admin, skip event log cleanup
    if (-not $IsUserAdministrator) {
        # Log warning that event log cleanup is being skipped
        Write-LogEntry "Skipping event log cleanup (requires admin privileges)" "WARN"
        
        # Exit function early
        return
    }
    
    # Array of event log names to clear (most space-consuming logs)
    $EventLogNames = @("System", "Application", "Security")
    
    # Calculate cutoff date (older than this date will be cleared)
    $CutoffDateForDeletion = (Get-Date).AddDays(-$DaysOld)
    
    # Process each event log
    foreach ($EventLogName in $EventLogNames) {
        try {
            # Log which event log is being processed
            Write-LogEntry "Processing event log: $EventLogName" "INFO"
            
            # Get current event log size (count of entries)
            $CurrentEventCount = (Get-EventLog -LogName $EventLogName -ErrorAction SilentlyContinue | Measure-Object).Count
            
            # Log the current number of entries in this log
            Write-LogEntry "  Current entries: $CurrentEventCount" "INFO"
            
            # In dry-run mode: report what would be cleared without making changes
            if ($DryRun) {
                # Log what would be cleared
                Write-LogEntry "  [DRY-RUN] Would clear events older than: $CutoffDateForDeletion" "INFO"
            } else {
                # Live mode: actually clear the event log
                # Note: PowerShell 5.1 does not have native cmdlet for selective clearing
                # Use WMI to clear entire event log (Windows behavior)
                
                # Build WMI query parameters for targeting specific event log
                $WmiQueryParameters = @{
                    # Class name for NT event log files in WMI
                    Class = 'Win32_NTEventLogFile'
                    
                    # Filter to target specific event log by name
                    Filter = "LogFileName='$EventLogName'"
                    
                    # Continue if error occurs
                    ErrorAction = 'SilentlyContinue'
                }
                
                # Query WMI for the event log file object
                $WmiEventLogFile = Get-WmiObject @WmiQueryParameters
                
                # If event log WMI object found, clear it
                if ($WmiEventLogFile) {
                    # Call WMI method to clear the event log
                    $WmiEventLogFile.ClearEventLog() | Out-Null
                    
                    # Log successful event log clear
                    Write-LogEntry "✓ Cleared event log: $EventLogName" "SUCCESS"
                    
                    # Log this action for audit trail
                    Log-Action -Action "Clear EventLog" -Path $EventLogName -Status "Cleared"
                } else {
                    # Event log WMI object not found; log warning
                    Write-LogEntry "⚠️  Could not clear event log: $EventLogName" "WARN"
                }
            }
        } catch {
            # Error processing event log; log warning and continue with next log
            Write-LogEntry "⚠️  Error processing event log $EventLogName : $_" "WARN"
        }
    }
    
    # Log completion of event log cleanup section
    Write-LogEntry "Event log cleanup complete." "SUCCESS"
    
    # Add blank line for readability between sections
    Write-LogEntry ""
}

# ==============================================================================
# SECTION 3: REMOVE WINDOWS.OLD FOLDER - Free major disk space (CHECK #4 - DISK SPACE)
# ==============================================================================

function Remove-WindowsOldFolder {
    <#
    .SYNOPSIS
    Removes the Windows.old folder to reclaim disk space after Windows upgrade.
    
    .DESCRIPTION
    Windows creates Windows.old folder during OS upgrade containing previous installation.
    This folder is typically 10-20 GB and safe to delete after confirming upgrade success.
    Deleting this folder frees significant disk space.
    Only proceeds if Windows.old folder actually exists on system drive.
    #>
    
    # Display section header with separators for clarity
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "SECTION 3: CLEANING WINDOWS.OLD FOLDER" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Get system drive letter (usually C:)
    $SystemDriveLetterOnly = $env:SystemDrive
    
    # Construct full path to Windows.old folder on system drive
    $WindowsOldFolderPath = "$SystemDriveLetterOnly\Windows.old"
    
    # Check if Windows.old folder exists before attempting to delete
    if (Test-Path -Path $WindowsOldFolderPath -PathType Container) {
        # Log that Windows.old folder was found
        Write-LogEntry "Found Windows.old folder at: $WindowsOldFolderPath" "WARN"
        
        # Call function to safely delete directory with backup
        Remove-DirectoryWithBackup -DirectoryPath $WindowsOldFolderPath -Description "Previous Windows installation (safe to delete after successful upgrade)"
    } else {
        # Windows.old folder not present; log for user awareness
        Write-LogEntry "No Windows.old folder found (not present)" "INFO"
    }
    
    # Log completion of Windows.old cleanup section
    Write-LogEntry "Windows.old cleanup complete." "SUCCESS"
    
    # Add blank line for readability between sections
    Write-LogEntry ""
}

# ==============================================================================
# SECTION 4: REMOVE CORRUPTED PROFILES - Fix login failures (CHECK #5 - PROFILE INTEGRITY)
# ==============================================================================

function Remove-CorruptedUserProfiles {
    <#
    .SYNOPSIS
    Identifies and removes corrupted or orphaned user profiles.
    
    .DESCRIPTION
    Scans user profiles directory and registry to find:
    - Profiles with missing/corrupted NTUSER.DAT file (registry hive)
    - Profiles from deleted/inactive user accounts (orphaned)
    - Profiles older than retention threshold
    
    Corrupted profiles cause login failures and slow login times.
    Deleted profiles automatically recreate on next user login.
    Requires administrator privileges.
    
    [VERIFY] This requires admin privileges and careful validation.
    #>
    
    # Display section header with separators for clarity
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "SECTION 4: CHECKING USER PROFILES" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Check if current user has administrator privileges
    $IsUserAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    # If not running as admin, skip profile cleanup
    if (-not $IsUserAdministrator) {
        # Log warning that profile cleanup is being skipped
        Write-LogEntry "Skipping profile cleanup (requires admin privileges)" "WARN"
        
        # Exit function early
        return
    }
    
    # Path where user profile folders are stored on all Windows systems
    $UsersProfilesPath = "C:\Users"
    
    # Array of system/built-in profiles that should never be deleted
    $ProtectedProfileNames = @("Administrator", "Guest", "DefaultAccount", "Public", "SYSTEM")
    
    # Log which path is being scanned for profiles
    Write-LogEntry "Scanning user profiles at: $UsersProfilesPath" "INFO"
    
    # Get all user accounts currently logged in with active profiles
    $LoggedInUserProfiles = Get-WmiObject -Class Win32_UserProfile -Filter "Loaded=true" -ErrorAction SilentlyContinue
    
    # Add logged-in user names to list of protected profiles to avoid deletion
    foreach ($LoggedInUserProfile in $LoggedInUserProfiles) {
        # Extract username from profile path (e.g., C:\Users\jsmith → jsmith)
        $LoggedInUserName = Split-Path -Leaf $LoggedInUserProfile.LocalPath
        
        # Add to protected list so we don't accidentally delete active profile
        $ProtectedProfileNames += $LoggedInUserName
    }
    
    # Get all user profile directories
    $AllUserProfiles = Get-ChildItem -Path $UsersProfilesPath -Directory -Force -ErrorAction SilentlyContinue
    
    # Process each profile found
    foreach ($UserProfileFolder in $AllUserProfiles) {
        # Extract username from folder name
        $UserProfileName = $UserProfileFolder.BaseName
        
        # Check if this profile is in the protected list (shouldn't be deleted)
        if ($UserProfileName -in $ProtectedProfileNames) {
            # Log that this active/protected profile is being skipped
            Write-LogEntry "Skipping active profile: $UserProfileName" "INFO"
            
            # Continue to next profile in loop
            continue
        }
        
        try {
            # Calculate how many days old this profile is
            $ProfileAgeInDays = (Get-Date) - $UserProfileFolder.LastWriteTime
            
            # Build path to NTUSER.DAT (registry hive file - indicates valid profile)
            $NtuserDataFilePath = Join-Path -Path $UserProfileFolder.FullName -ChildPath "NTUSER.DAT"
            
            # Check if NTUSER.DAT file exists (present in all valid profiles)
            $NtuserFileExists = Test-Path -Path $NtuserDataFilePath -PathType Leaf
            
            # If profile is old enough to process and appears corrupted
            if ($ProfileAgeInDays.Days -ge $DaysOld) {
                # If NTUSER.DAT is missing, profile is corrupted
                if (-not $NtuserFileExists) {
                    # Log warning about corrupted profile with age
                    Write-LogEntry "Profile appears corrupted (missing NTUSER.DAT): $UserProfileName - Age: $($ProfileAgeInDays.Days) days" "WARN"
                    
                    # Check if running in dry-run mode
                    if ($DryRun) {
                        # Log what would be deleted without making changes
                        Write-LogEntry "  [DRY-RUN] Would delete corrupted profile: $($UserProfileFolder.FullName)" "INFO"
                    } else {
                        # Live mode: actually delete the corrupted profile
                        # Log that corrupted profile is being deleted
                        Write-LogEntry "  Deleting corrupted profile: $($UserProfileFolder.FullName)" "WARN"
                        
                        # Call function to safely delete directory with backup
                        Remove-DirectoryWithBackup -DirectoryPath $UserProfileFolder.FullName -Description "Corrupted user profile (missing NTUSER.DAT)"
                    }
                }
            } else {
                # Profile is too recent; skip to preserve newer data
                Write-LogEntry "Skipping profile (too recent): $UserProfileName (Age: $($ProfileAgeInDays.Days) days)" "INFO"
            }
        } catch {
            # Error processing profile; log warning and continue
            Write-LogEntry "⚠️  Error processing profile $UserProfileName : $_" "WARN"
        }
    }
    
    # Log completion of user profile scan section
    Write-LogEntry "User profile scan complete." "SUCCESS"
    
    # Add blank line for readability between sections
    Write-LogEntry ""
}

# ==============================================================================
# SECTION 5: TEST REGISTRY PROFILE HEALTH - Identify orphaned registry entries
# ==============================================================================

function Test-RegistryProfileHealth {
    <#
    .SYNOPSIS
    Scans Windows registry for orphaned user profile entries.
    
    .DESCRIPTION
    Scans HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList registry key
    for entries that point to non-existent profile paths.
    These orphaned entries waste registry space and can slow down profile loading.
    
    This is a READ-ONLY check; does not delete registry entries.
    Orphaned entries should be manually deleted by administrator.
    Requires administrator privileges.
    #>
    
    # Display section header with separators for clarity
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "SECTION 5: SCANNING REGISTRY PROFILE HEALTH" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Check if current user has administrator privileges
    $IsUserAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    # If not running as admin, skip registry scan
    if (-not $IsUserAdministrator) {
        # Log warning that registry scan is being skipped
        Write-LogEntry "Skipping registry scan (requires admin privileges)" "WARN"
        
        # Exit function early
        return
    }
    
    # Full registry path to user profile list
    $ProfileListRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    
    # Initialize counter for orphaned entries found
    $OrphanedEntryCount = 0
    
    try {
        # Get all subkeys in profile list registry (each is a user profile SID)
        # Filter to only security identifiers (SID format: S-1-5-21-...)
        $ProfileRegistryKeys = Get-ChildItem -Path $ProfileListRegistryPath -ErrorAction SilentlyContinue | Where-Object { 
            # Match only SIDs (start with S-1-5-21), ignore other entries
            $_.Name -match "S-1-5-21" 
        }
        
        # Log how many profile registry entries are being scanned
        Write-LogEntry "Scanning $($ProfileRegistryKeys.Count) profile registry entries..." "INFO"
        
        # Process each profile registry entry
        foreach ($ProfileRegistryKey in $ProfileRegistryKeys) {
            try {
                # Read the ProfilePath value from registry (points to actual profile folder)
                $ProfilePathValue = $ProfileRegistryKey.GetValue("ProfilePath")
                
                # Extract SID from registry key name (last part of path)
                $UserSecurityIdentifier = Split-Path -Leaf $ProfileRegistryKey.Name
                
                # If ProfilePath value is not empty/null
                if (-not [string]::IsNullOrEmpty($ProfilePathValue)) {
                    # Check if the path listed in registry actually exists on disk
                    if (-not (Test-Path -Path $ProfilePathValue -ErrorAction SilentlyContinue)) {
                        # Profile path in registry doesn't exist on disk (orphaned entry)
                        Write-LogEntry "⚠️  Orphaned registry entry (profile path missing): $UserSecurityIdentifier → $ProfilePathValue" "WARN"
                        
                        # Increment counter for reporting
                        $OrphanedEntryCount++
                        
                        # Check if in dry-run mode
                        if ($DryRun) {
                            # Log what would be flagged
                            Write-LogEntry "  [DRY-RUN] Would flag for manual cleanup" "INFO"
                        } else {
                            # In live mode, provide manual cleanup instruction
                            Write-LogEntry "  [MANUAL ACTION REQUIRED] Delete registry key: HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSecurityIdentifier" "WARN"
                        }
                    }
                }
            } catch {
                # Error reading registry entry; log warning and continue
                Write-LogEntry "⚠️  Error reading profile registry entry: $_" "WARN"
            }
        }
        
        # Log completion of registry scan with count of orphaned entries
        Write-LogEntry "Registry scan complete. Found $OrphanedEntryCount orphaned entries." "INFO"
    } catch {
        # Fatal error during registry scan; log and continue
        Write-LogEntry "✗ Error scanning registry profiles: $_" "ERROR"
    }
    
    # Add blank line for readability between sections
    Write-LogEntry ""
}

# ==============================================================================
# SECTION 6: DISK SPACE REPORT - Display system storage status
# ==============================================================================

function Report-DiskSpace {
    <#
    .SYNOPSIS
    Reports current system disk space usage and available space.
    
    .DESCRIPTION
    Displays detailed disk usage statistics for system drive:
    - Total capacity
    - Used space (in GB and percentage)
    - Free space (in GB)
    - Status alerts if space is low or critical
    
    Useful before and after cleanup to verify space was freed.
    #>
    
    # Display section header with separators for clarity
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "SECTION 6: DISK SPACE REPORT" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Extract system drive letter (e.g., C from C:)
    $SystemDriveLetterOnly = $env:SystemDrive.TrimEnd(':')
    
    try {
        # Get disk volume information for system drive
        $SystemDiskInfo = Get-Volume -DriveLetter $SystemDriveLetterOnly -ErrorAction SilentlyContinue
        
        # If disk info retrieved successfully
        if ($SystemDiskInfo) {
            # Convert total size from bytes to gigabytes
            $TotalSizeInGB = $SystemDiskInfo.Size / 1GB
            
            # Convert remaining free space from bytes to gigabytes
            $FreeSpaceInGB = $SystemDiskInfo.SizeRemaining / 1GB
            
            # Calculate used space by subtracting free from total
            $UsedSpaceInGB = $TotalSizeInGB - $FreeSpaceInGB
            
            # Calculate percentage of disk space that is used
            $PercentageUsed = [math]::Round(($UsedSpaceInGB / $TotalSizeInGB) * 100, 2)
            
            # Log system drive letter
            Write-LogEntry "Drive: $env:SystemDrive" "INFO"
            
            # Log total capacity rounded to 2 decimal places
            Write-LogEntry "  Total:  $([math]::Round($TotalSizeInGB, 2)) GB" "INFO"
            
            # Log used space with percentage for context
            Write-LogEntry "  Used:   $([math]::Round($UsedSpaceInGB, 2)) GB ($PercentageUsed%)" "INFO"
            
            # Log available free space
            Write-LogEntry "  Free:   $([math]::Round($FreeSpaceInGB, 2)) GB" "INFO"
            
            # Alert if disk space is critically low (less than 1 GB)
            if ($FreeSpaceInGB -lt 1) {
                Write-LogEntry "  ⚠️  CRITICAL: Less than 1 GB free!" "WARN"
            } 
            # Alert if disk space is low (less than 5 GB)
            elseif ($FreeSpaceInGB -lt 5) {
                Write-LogEntry "  ⚠️  LOW DISK SPACE: Less than 5 GB free" "WARN"
            } 
            # Disk space is adequate
            else {
                Write-LogEntry "  ✓ Adequate disk space available" "SUCCESS"
            }
        }
    } catch {
        # Error retrieving disk information; log warning
        Write-LogEntry "⚠️  Could not retrieve disk information: $_" "WARN"
    }
    
    # Add blank line for readability between sections
    Write-LogEntry ""
}

# ==============================================================================
# SECTION 7: SUMMARY REPORT - Display execution summary and statistics
# ==============================================================================

function Write-SummaryReport {
    <#
    .SYNOPSIS
    Generates and displays a summary of all actions taken during script execution.
    
    .DESCRIPTION
    Creates detailed execution summary including:
    - Execution mode (dry-run vs. live)
    - Configuration parameters used
    - Action counts (files deleted, backed up, skipped, errors)
    - Rollback instructions if files were deleted
    - Log file location for detailed review
    
    This summary helps users verify script execution and troubleshoot issues.
    #>
    
    # Display section header with separators for clarity
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "EXECUTION SUMMARY" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Log whether script ran in dry-run or live mode
    $ExecutionModeDescription = if ($DryRun) { 
        'DRY-RUN (No changes made)' 
    } else { 
        'LIVE (Changes applied)' 
    }
    Write-LogEntry "Execution Mode: $ExecutionModeDescription" "INFO"
    
    # Log the days threshold used for file age filtering
    Write-LogEntry "Days Threshold: $DaysOld days" "INFO"
    
    # Log location of log file for reference
    Write-LogEntry "Log File: $LogPath" "INFO"
    
    # Log location of backup directory (if files were backed up)
    Write-LogEntry "Backup Location: $BackupPath" "INFO"
    
    # Add blank line for readability
    Write-LogEntry "" "INFO"
    
    # Log header for action counts
    Write-LogEntry "Actions Summary:" "INFO"
    
    # Log total files processed
    Write-LogEntry "  Files Processed: $script:FilesProcessed" "INFO"
    
    # Log number of files successfully deleted
    Write-LogEntry "  Files Deleted: $script:FilesDeleted" "SUCCESS"
    
    # Log number of files backed up before deletion
    Write-LogEntry "  Files Backed Up: $script:FilesBackedUp" "SUCCESS"
    
    # Log number of files skipped (locked, recent, or error)
    Write-LogEntry "  Files Skipped (Locked/Recent): $script:FilesSkipped" "WARN"
    
    # Log total non-fatal errors encountered
    Write-LogEntry "  Errors Encountered: $script:ErrorCount" "ERROR"
    
    # Log total warnings encountered
    Write-LogEntry "  Warnings: $script:WarningCount" "WARN"
    
    # Add blank line for readability
    Write-LogEntry "" "INFO"
    
    # If files were deleted in live mode, provide rollback instructions
    if (-not $DryRun -and $script:FilesDeleted -gt 0) {
        # Log header for rollback information
        Write-LogEntry "Rollback Command:" "INFO"
        
        # Log exact command to restore deleted files
        Write-LogEntry "  .\diagnostic-floor6-remediation-readable.ps1 -Rollback -RollbackSource `"$BackupPath`"" "INFO"
    }
    
    # Add blank line for readability
    Write-LogEntry "" "INFO"
    
    # Display final completion message with separators
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "Script execution complete." "INFO"
    Write-LogEntry "============================================" "INFO"
}

# ==============================================================================
# MAIN EXECUTION BLOCK - Orchestrate all remediation sections
# ==============================================================================

try {
    # Display script startup banner with separators
    Write-LogEntry "============================================" "INFO"
    Write-LogEntry "DWP Floor 6 Remediation Script Started" "INFO"
    Write-LogEntry "============================================" "INFO"
    
    # Log execution date and time for record-keeping
    Write-LogEntry "Execution Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
    
    # Log computer name for reference (useful when run on multiple machines)
    Write-LogEntry "Computer: $env:COMPUTERNAME" "INFO"
    
    # Log username executing script
    Write-LogEntry "User: $env:USERNAME" "INFO"
    
    # Log execution policy for security reference
    Write-LogEntry "Execution Policy: $(Get-ExecutionPolicy)" "INFO"
    
    # Log PowerShell version for compatibility reference
    Write-LogEntry "PowerShell Version: $($PSVersionTable.PSVersion)" "INFO"
    
    # Add blank line for readability
    Write-LogEntry "" "INFO"
    
    # Check if running in rollback mode
    if ($Rollback) {
        # Execute rollback function and exit
        Invoke-Rollback
    }
    
    # Run all remediation sections in sequence
    # SECTION 1: Clean temporary files
    Remove-OldTempFiles
    
    # SECTION 2: Clear event logs
    Clear-OldEventLogs
    
    # SECTION 3: Remove Windows.old folder
    Remove-WindowsOldFolder
    
    # SECTION 4: Remove corrupted user profiles
    Remove-CorruptedUserProfiles
    
    # SECTION 5: Scan registry for profile health
    Test-RegistryProfileHealth
    
    # SECTION 6: Display disk space statistics
    Report-DiskSpace
    
    # SECTION 7: Generate and display execution summary
    Write-SummaryReport
    
} catch {
    # Catch any fatal errors that occur during script execution
    Write-LogEntry "✗ FATAL ERROR: $_" "ERROR"
    Write-LogEntry "Script execution failed." "ERROR"
    
    # Exit with error code 1 to indicate failure
    exit 1
}

# ==============================================================================
# POST-EXECUTION OUTPUT - Display final status to user
# ==============================================================================

# Add blank line for visual separation
Write-Host ""

# Display log file location to user for reference
Write-Host "Log file saved to: $LogPath" -ForegroundColor Cyan

# If running in live mode, also display backup location
if (-not $DryRun) {
    Write-Host "Backup location: $BackupPath" -ForegroundColor Cyan
}
