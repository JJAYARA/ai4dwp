# PowerShell 5.1 - Read-Only Diagnostic Script for Floor 6 Login/Performance Issue
# Purpose: Test all 6 ranked fixes without making any changes to system state
# Version: 1.0
# Date: 2026-08-14

# IMPORTANT: This script is READ-ONLY. No changes are made to the system.
# Review all sections marked with [VERIFY] before running on production machines.

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Floor 6 Login Issue - Diagnostic Script" -ForegroundColor Cyan
Write-Host "Read-Only Mode - No System Changes" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# CHECK #1: New Document-Management App in Login Path
# ==============================================================================

Write-Host "[CHECK 1] Scanning for app in login startup path..." -ForegroundColor Yellow

# Collect running processes during current session (cannot capture login without reboot scenario)
Write-Host "  • Current process list (for reference):"
$processes = Get-Process | Select-Object -Property Name, ID, WorkingSet -First 20
$processes | Format-Table -AutoSize

Write-Host ""
Write-Host "  • Checking HKCU Run registry for startup apps..."
$runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$runApps = Get-ItemProperty -Path $runPath -ErrorAction SilentlyContinue

if ($runApps) {
    Write-Host "    Found startup registry entries:" -ForegroundColor Green
    $runApps | Select-Object -Property * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSDrive, PSProvider | Format-Table -AutoSize
} else {
    Write-Host "    No startup entries found in HKCU\Run" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  • Checking HKLM Run registry (machine-wide startups)..."
$hklmRunPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$hklmRunApps = Get-ItemProperty -Path $hklmRunPath -ErrorAction SilentlyContinue

if ($hklmRunApps) {
    Write-Host "    Found machine-wide startup entries:" -ForegroundColor Green
    $hklmRunApps | Select-Object -Property * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSDrive, PSProvider | Format-Table -AutoSize
} else {
    Write-Host "    No startup entries found in HKLM\Run" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  • Checking Task Scheduler for login-triggered tasks..."
$tasks = Get-ScheduledTask | Where-Object { $_.Triggers.Enabled -eq $true } | Select-Object -Property TaskName, State, Author -First 15
if ($tasks) {
    Write-Host "    Active scheduled tasks (sample):" -ForegroundColor Green
    $tasks | Format-Table -AutoSize
} else {
    Write-Host "    No active scheduled tasks found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  [ACTION] If document-management app appears: uninstall or remove from login path" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# CHECK #2: Group Policy Issues
# ==============================================================================

Write-Host "[CHECK 2] Scanning Group Policy configuration..." -ForegroundColor Yellow

Write-Host "  • Generating Group Policy Report (may take 30 seconds)..."
# [VERIFY] This command requires gpresult.exe; ensure user has permission to run it
try {
    $gpReportPath = "$env:TEMP\gp-report-$((Get-Date).ToString('yyyyMMdd-HHmmss')).html"
    gpresult /h $gpReportPath | Out-Null
    Write-Host "    ✓ Group Policy report saved to: $gpReportPath" -ForegroundColor Green
    Write-Host "    📋 Review this report for conflicting/recently added policies related to document-management app" -ForegroundColor Cyan
} catch {
    Write-Host "    ✗ Could not generate GP report: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "  • Checking for Group Policy errors in event logs..."
# [VERIFY] This searches System event log for Group Policy errors
$gpErrors = Get-EventLog -LogName System -Source "GroupPolicy" -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue | Select-Object -Property TimeGenerated, EventID, Message -First 10
if ($gpErrors) {
    Write-Host "    Found recent GP errors:" -ForegroundColor Yellow
    $gpErrors | Format-Table -AutoSize
} else {
    Write-Host "    No Group Policy errors in System log (last 24 hours)" -ForegroundColor Green
}

Write-Host ""
Write-Host "  • Checking applied Group Policy objects..."
# [VERIFY] gpresult /scope:user shows user-applied policies; gpresult /scope:computer shows machine policies
Write-Host "    User-applied Group Policies:" -ForegroundColor Gray
gpresult /scope:user /v | Select-String "Applied Group Policy Objects" -A 50 | Select-Object -First 30

Write-Host ""
Write-Host "  [ACTION] If conflicts found: identify and rollback conflicting GPO" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# CHECK #3: Network Share and Backend Connectivity Issues
# ==============================================================================

Write-Host "[CHECK 3] Testing network connectivity and backend dependencies..." -ForegroundColor Yellow

Write-Host "  • Listing mapped network drives..."
$netUse = net use
Write-Host $netUse

Write-Host ""
Write-Host "  • Testing network availability (DNS resolution)..."
$testDnsServers = @(
    "8.8.8.8",           # Google DNS (fallback)
    "1.1.1.1"            # Cloudflare DNS (fallback)
    # [VERIFY] Add your actual backend server hostname/IP here
)

foreach ($server in $testDnsServers) {
    $testConn = Test-Connection -ComputerName $server -Count 1 -ErrorAction SilentlyContinue
    if ($testConn) {
        Write-Host "    ✓ Reachable: $server (Response time: $($testConn.ResponseTime)ms)" -ForegroundColor Green
    } else {
        Write-Host "    ✗ NOT reachable: $server" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  • Checking for app-related network shares (if document-management app uses SMB)..."
# [VERIFY] Modify this path to match actual document-management app backend
$appSharePath = "\\server-name\app-share"  # [VERIFY] Replace with actual share path
Write-Host "    Attempting to access: $appSharePath"
try {
    $pathExists = Test-Path -Path $appSharePath -ErrorAction Stop
    if ($pathExists) {
        Write-Host "    ✓ Share is accessible" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Share path does not exist or is not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "    ✗ Cannot access share: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "  • Checking Application event log for connection errors (last 24 hours)..."
$appErrors = Get-EventLog -LogName Application -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue | Where-Object { $_.Message -match "network|connection|timeout" } | Select-Object -Property TimeGenerated, Source, EventID, Message -First 10
if ($appErrors) {
    Write-Host "    Found network-related application errors:" -ForegroundColor Yellow
    $appErrors | Format-Table -AutoSize
} else {
    Write-Host "    No network connection errors in Application log (last 24 hours)" -ForegroundColor Green
}

Write-Host ""
Write-Host "  [ACTION] If backend unreachable: restart backend service or fix network configuration" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# CHECK #4: Disk Space
# ==============================================================================

Write-Host "[CHECK 4] Checking disk space on system drive..." -ForegroundColor Yellow

$systemDrive = $env:SystemDrive
$diskInfo = Get-Volume -DriveLetter $systemDrive.TrimEnd(':') -ErrorAction SilentlyContinue

if ($diskInfo) {
    $totalSize = $diskInfo.Size / 1GB
    $freeSpace = $diskInfo.SizeRemaining / 1GB
    $usedSpace = $totalSize - $freeSpace
    $percentUsed = [math]::Round(($usedSpace / $totalSize) * 100, 2)
    
    Write-Host "  Drive: $systemDrive" -ForegroundColor Green
    Write-Host "    Total: $([math]::Round($totalSize, 2)) GB" -ForegroundColor Gray
    Write-Host "    Used:  $([math]::Round($usedSpace, 2)) GB ($percentUsed%)" -ForegroundColor Gray
    Write-Host "    Free:  $([math]::Round($freeSpace, 2)) GB" -ForegroundColor Gray
    
    if ($freeSpace -lt 1) {
        Write-Host "    ⚠️  WARNING: Less than 1 GB free space detected!" -ForegroundColor Red
    } elseif ($freeSpace -lt 5) {
        Write-Host "    ⚠️  CAUTION: Less than 5 GB free space" -ForegroundColor Yellow
    } else {
        Write-Host "    ✓ Adequate free space" -ForegroundColor Green
    }
} else {
    Write-Host "  Could not retrieve disk information" -ForegroundColor Red
}

Write-Host ""
Write-Host "  • Checking temp folder size..."
$tempPath = $env:TEMP
$tempSize = (Get-ChildItem -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "    Temp folder size: $([math]::Round($tempSize, 2)) MB" -ForegroundColor Gray

Write-Host ""
Write-Host "  • Checking for old Windows.old folder..."
$windowsOldPath = "$systemDrive\Windows.old"
if (Test-Path -Path $windowsOldPath) {
    $windowsOldSize = (Get-ChildItem -Path $windowsOldPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "    Found Windows.old folder: $([math]::Round($windowsOldSize, 2)) GB" -ForegroundColor Yellow
    Write-Host "    This folder can be safely deleted if space is needed" -ForegroundColor Cyan
} else {
    Write-Host "    No Windows.old folder found" -ForegroundColor Green
}

Write-Host ""
Write-Host "  [ACTION] If <1 GB free: delete temp files, Windows.old, or uninstall non-essential apps" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# CHECK #5: User Profile Integrity
# ==============================================================================

Write-Host "[CHECK 5] Checking user profile integrity..." -ForegroundColor Yellow

Write-Host "  • Scanning user profile registry (HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList)..."
$profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$profiles = Get-ChildItem -Path $profileListPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "S-1-5-21" }

Write-Host "    Checking for corrupt/missing profile entries..." -ForegroundColor Gray
foreach ($profile in $profiles) {
    $sid = Split-Path -Leaf $profile.Name
    $profilePath = $profile.GetValue("ProfilePath")
    $profileExists = Test-Path -Path $profilePath -ErrorAction SilentlyContinue
    
    if (-not $profileExists) {
        Write-Host "    ⚠️  Missing profile folder: $profilePath (SID: $sid)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  • Checking current user's profile folders..."
$userProfile = $env:USERPROFILE
$requiredFolders = @("Desktop", "Documents", "AppData", "Downloads")

foreach ($folder in $requiredFolders) {
    $folderPath = Join-Path -Path $userProfile -ChildPath $folder
    if (Test-Path -Path $folderPath) {
        Write-Host "    ✓ $folder exists" -ForegroundColor Green
    } else {
        Write-Host "    ✗ $folder MISSING" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  • Checking for System event log errors related to user profiles (last 24 hours)..."
# [VERIFY] Searches for Userenv errors indicating profile load failures
$userenvErrors = Get-EventLog -LogName System -Source "Userenv" -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue | Select-Object -Property TimeGenerated, EventID, Message -First 10

if ($userenvErrors) {
    Write-Host "    Found profile-related errors:" -ForegroundColor Yellow
    $userenvErrors | Format-Table -AutoSize
} else {
    Write-Host "    No profile errors in System log (last 24 hours)" -ForegroundColor Green
}

Write-Host ""
Write-Host "  [ACTION] If profile missing/corrupt: delete profile and let system recreate on next login" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# CHECK #6: Certificate and Encryption Issues
# ==============================================================================

Write-Host "[CHECK 6] Checking certificates and Kerberos authentication..." -ForegroundColor Yellow

Write-Host "  • Listing certificates in Current User store..."
# [VERIFY] This accesses personal certificate store; ensure user has permission
$certs = Get-ChildItem -Path Cert:\CurrentUser\My -ErrorAction SilentlyContinue | Select-Object -Property Subject, Thumbprint, NotAfter -First 10

if ($certs) {
    Write-Host "    Certificates found:" -ForegroundColor Green
    $certs | Format-Table -AutoSize
} else {
    Write-Host "    No certificates in Current User store" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  • Checking for expired certificates..."
$expiredCerts = Get-ChildItem -Path Cert:\CurrentUser\My -ErrorAction SilentlyContinue | Where-Object { $_.NotAfter -lt (Get-Date) }

if ($expiredCerts) {
    Write-Host "    ⚠️  Expired certificates found:" -ForegroundColor Yellow
    $expiredCerts | Select-Object -Property Subject, Thumbprint, NotAfter | Format-Table -AutoSize
} else {
    Write-Host "    ✓ No expired certificates" -ForegroundColor Green
}

Write-Host ""
Write-Host "  • Checking Kerberos ticket cache..."
# [VERIFY] klist.exe is part of Windows; may require admin privileges on some systems
try {
    $klist = klist.exe
    Write-Host "    Current Kerberos tickets:" -ForegroundColor Green
    Write-Host $klist
} catch {
    Write-Host "    Could not retrieve Kerberos tickets: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "  • Checking Security event log for Kerberos errors (last 24 hours)..."
# [VERIFY] Looks for Kerberos error codes 0x1f and 0x25
$kerberosErrors = Get-EventLog -LogName Security -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue | Where-Object { $_.EventID -eq 4768 -or $_.EventID -eq 4771 } | Select-Object -Property TimeGenerated, EventID, Message -First 10

if ($kerberosErrors) {
    Write-Host "    Found Kerberos authentication errors:" -ForegroundColor Yellow
    $kerberosErrors | Format-Table -AutoSize
} else {
    Write-Host "    No Kerberos errors in Security log (last 24 hours)" -ForegroundColor Green
}

Write-Host ""
Write-Host "  [ACTION] If cert/Kerberos issues found: reset credentials or reimport certificates" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# Summary and Next Steps
# ==============================================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Diagnostic Complete" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review all findings above marked with ⚠️  or ✗" -ForegroundColor Gray
Write-Host "  2. Compare findings with unaffected Floor 6 users (run script on unaffected machine)" -ForegroundColor Gray
Write-Host "  3. Start with CHECK #1 (app in login path) - highest probability fix" -ForegroundColor Gray
Write-Host "  4. Run CHECK #2 (GPO) in parallel while investigating #1" -ForegroundColor Gray
Write-Host "  5. Escalate Copilot access anomaly to Security + Data Governance team" -ForegroundColor Gray
Write-Host ""
Write-Host "Remember: This script is READ-ONLY. No changes have been made to your system." -ForegroundColor Green
Write-Host ""
