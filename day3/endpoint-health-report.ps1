<#
.SYNOPSIS
    Endpoint health report for DWP engineers (PowerShell 5.1).

.DESCRIPTION
    Produces a read-only health report with these sections:
      1) System uptime
      2) Free disk space
      3) Pending reboot status (registry-based checks)
      4) Top 5 processes by memory (Working Set)
      5) Top 5 processes by CPU
      6) Last 5 System log errors

.NOTES
    This script is strictly read-only: it does not modify files, registry, services, or system settings.
#>

[CmdletBinding()]
param()

# Common timestamp for report generation.
$reportTime = Get-Date
Write-Host "=================================================="
Write-Host "Endpoint Health Report"
Write-Host "Generated: $($reportTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "Computer : $env:COMPUTERNAME"
Write-Host "=================================================="

# --------------------------------------------------
# SECTION 1: System Uptime
# What this section does:
#   Reads the last OS boot time and calculates total uptime.
#   This is read-only and uses WMI/CIM system information.
# --------------------------------------------------
Write-Host "`n[1] System Uptime" -ForegroundColor Cyan
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    Write-Host ("Last Boot Time : {0}" -f $lastBoot)
    Write-Host ("Uptime         : {0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
}
catch {
    Write-Warning "Unable to read uptime information: $($_.Exception.Message)"
}

# --------------------------------------------------
# SECTION 2: Free Disk Space
# What this section does:
#   Reads logical disk usage for local fixed disks and shows total,
#   free space, and free percentage.
#   This is read-only and does not alter any storage configuration.
# --------------------------------------------------
Write-Host "`n[2] Free Disk Space" -ForegroundColor Cyan
try {
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object @{Name='Drive';Expression={$_.DeviceID}},
                      @{Name='Label';Expression={$_.VolumeName}},
                      @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
                      @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                      @{Name='FreePercent';Expression={
                          if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 }
                      }} |
        Format-Table -AutoSize
}
catch {
    Write-Warning "Unable to read disk information: $($_.Exception.Message)"
}

# --------------------------------------------------
# SECTION 3: Pending Reboot (Registry Checks)
# What this section does:
#   Reads known registry locations used by Windows/components to
#   indicate whether a reboot is pending.
#   This is read-only: it only checks for key existence/values.
#
# VERIFY BEFORE RUNNING:
#   Verify these registry paths are approved in your environment policy.
# --------------------------------------------------
Write-Host "`n[3] Pending Reboot Status (Registry)" -ForegroundColor Cyan
try {
    # VERIFY BEFORE RUNNING: Confirm this CBS key is valid for your target Windows build.
    $cbsRebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"

    # VERIFY BEFORE RUNNING: Confirm this Windows Update key is valid in your environment.
    $wuRebootRequired = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

    # VERIFY BEFORE RUNNING: Confirm this Session Manager value is used by your endpoint baseline.
    $pendingFileRename = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) -ne $null

    $reasons = @()
    if ($cbsRebootPending) { $reasons += "Component Based Servicing: RebootPending" }
    if ($wuRebootRequired) { $reasons += "Windows Update: RebootRequired" }
    if ($pendingFileRename) { $reasons += "Session Manager: PendingFileRenameOperations" }

    $isPending = $reasons.Count -gt 0

    Write-Host ("Pending Reboot : {0}" -f $(if ($isPending) { 'YES' } else { 'NO' }))
    if ($isPending) {
        Write-Host "Reasons:"
        $reasons | ForEach-Object { Write-Host (" - {0}" -f $_) }
    }
}
catch {
    Write-Warning "Unable to read reboot-pending registry data: $($_.Exception.Message)"
}

# --------------------------------------------------
# SECTION 4: Top 5 Processes by Memory (Working Set)
# What this section does:
#   Reads running process data and displays the top 5 by Working Set
#   memory usage.
#   This is read-only and does not stop or alter processes.
# --------------------------------------------------
Write-Host "`n[4] Top 5 Processes by Memory (Working Set)" -ForegroundColor Cyan
try {
    Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 -Property Name, Id,
                      @{Name='ExecutablePath';Expression={
                          try {
                              if ([string]::IsNullOrWhiteSpace($_.Path)) { '<Unavailable>' } else { $_.Path }
                          }
                          catch { '<AccessDeniedOrUnavailable>' }
                      }},
                      @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
                      @{Name='CPUSeconds';Expression={
                          if ($null -ne $_.CPU) { [math]::Round($_.CPU, 2) } else { $null }
                      }} |
        Format-Table -AutoSize
}
catch {
    Write-Warning "Unable to read process memory data: $($_.Exception.Message)"
}

# --------------------------------------------------
# SECTION 5: Top 5 Processes by CPU
# What this section does:
#   Reads running process data and displays the top 5 by cumulative
#   CPU time consumed (seconds since process start).
#   This is read-only and does not terminate or modify processes.
# --------------------------------------------------
Write-Host "`n[5] Top 5 Processes by CPU" -ForegroundColor Cyan
try {
    Get-Process |
        Where-Object { $null -ne $_.CPU } |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 -Property Name, Id,
                      @{Name='ExecutablePath';Expression={
                          try {
                              if ([string]::IsNullOrWhiteSpace($_.Path)) { '<Unavailable>' } else { $_.Path }
                          }
                          catch { '<AccessDeniedOrUnavailable>' }
                      }},
                      @{Name='CPUSeconds';Expression={[math]::Round($_.CPU, 2)}},
                      @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} |
        Format-Table -AutoSize
}
catch {
    Write-Warning "Unable to read process CPU data: $($_.Exception.Message)"
}

# --------------------------------------------------
# SECTION 6: Last 5 System Log Errors
# What this section does:
#   Reads the Windows System event log and returns the 5 most recent
#   entries with level = Error.
#   This is read-only and does not clear or edit logs.
#
# VERIFY BEFORE RUNNING:
#   Access to System log may require elevated permissions depending
#   on endpoint policy.
# --------------------------------------------------
Write-Host "`n[6] Last 5 System Log Errors" -ForegroundColor Cyan
try {
    # VERIFY BEFORE RUNNING: Confirm reading 'System' log is permitted by local policy.
    Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
        Select-Object TimeCreated, Id, ProviderName,
                      @{Name='Message';Expression={
                          if ($_.Message.Length -gt 180) { $_.Message.Substring(0, 180) + '...' } else { $_.Message }
                      }} |
        Format-Table -Wrap -AutoSize
}
catch {
    Write-Warning "Unable to read System event log errors: $($_.Exception.Message)"
}

Write-Host "`nReport complete."
