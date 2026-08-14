# Ranked Fixes – Floor 6 Login/Performance Issue

## Ranked Fixes (Most to Least Probable)

### 1. **New document-management app is blocking/deferring login or consuming resources during profile load**
**Why likely:**
- Deployment timing: Friday afternoon rollout → Monday morning failures (classic change-correlation pattern)
- Multi-user impact suggests scope-wide configuration, not individual machine issues
- Slow login + app rollout typically means the app startup/sync is on the login path

**Check to confirm:**
- On affected machine, capture process list during login with timestamps (Task Manager or `tasklist /v`)
- Check app event logs for errors during login window
- Compare login speed on a Floor 6 machine *before* uninstalling vs *after* uninstalling the app
- Check if app is set to run at startup/user login in registry: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`

**Action if confirmed:**
- Remove app from login path (delete from Run registry entries, disable in Task Scheduler)
- Defer app startup until after profile loads (edit app config if available)
- If app must run at login, escalate to vendor for login-blocking bug fix

---

### 2. **Group Policy conflict or corruption introduced by the rollout**
**Why likely:**
- App deployments often include new GPOs that conflict with existing policies
- GPO corruption affects ALL users in affected OU/security group uniformly
- Affects authentication, profile loading, and resource access (explains Copilot/shortcut issues too)

**Check to confirm:**
- Run `gpresult /h report.html` on affected machine, compare to unaffected Floor 6 user
- Check Group Policy Object Editor (`gpedit.msc`) for recently added/modified policies related to new app
- Review event logs on affected machine: `Computer Configuration > Windows Logs > System` for Group Policy errors
- (To confirm) Compare `gpupdate /force` before/after on test user—does forcing policy refresh resolve login speed?

**Action if confirmed:**
- Identify conflicting/corrupted GPO (likely named after new app or deployment package)
- Remove or rollback that GPO
- Force `gpupdate /force` on affected users
- If app requires GPO, work with Security/vendor to create non-conflicting version

---

### 3. **New app created a network share or authentication dependency that is timing out**
**Why likely:**
- Multi-user login slowness often indicates a shared backend/network dependency
- App rollout frequently adds network authentication checks that fail/delay if backend is down or misconfigured
- One user's Copilot anomaly could be related to new app's data indexing or access-control changes

**Check to confirm:**
- On affected machine during login, run `net use` to list mapped drives and check for timeout errors
- Check network connectivity: `ping [app-backend-server]` or check if app's backend service is running
- Review app logs (usually in `Program Files\[App]\logs\` or `%AppData%\[App]\logs\`) for network/auth failures
- Check Event Viewer > Application for errors from new app during login window
- (To confirm) Disable network adapters during login on test machine—does login complete quickly without network?

**Action if confirmed:**
- Verify app's backend server/service is running and reachable
- If backend is down, restart it; if misconfigured, fix configuration
- If app expects specific network path/share, ensure it exists and permissions are correct
- If network check is non-critical, disable it or make it asynchronous (escalate to vendor)

---

### 4. **Disk space exhausted by new app, blocking profile load or temp file operations**
**Why likely:**
- App rollout can consume significant space; insufficient space breaks login (especially if profile is trying to cache/expand)
- Affects multiple users if rollout went to same set of machines

**Check to confirm:**
- On affected machine: `dir C:\ /s` or Properties on C: drive—check free space (look for <1 GB free)
- Compare disk usage before/after rollout (to confirm via recent IT ticket or pre-rollout baseline)
- Check `%temp%` folder size: `dir %temp% /s` (especially if temp was used during rollout)

**Action if confirmed:**
- Free up space: delete old Windows.old folder, clear temp, uninstall non-essential software
- Move app cache/data to larger drive if possible
- Re-run Windows Disk Cleanup
- If still insufficient, add disk space to affected machines

---

### 5. **User profile is corrupted (registry hive locked or local profile cache corrupt)**
**Why likely:**
- Multi-user impact *and* missing shortcuts suggests a profile-level issue introduced by the rollout
- If rollout ran with admin privileges and modified HKCU hives, corruption is possible
- Missing shortcuts specifically point to corrupted profile data

**Check to confirm:**
- On affected machine, check Registry Editor for locked hives or corruption:
  - `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList` - look for missing or duplicate SIDs
  - Try to open affected user's HKCU hive in Regedit; if it locks/fails to load, it's corrupt
- Check `C:\Users\[affected-user]\` for missing folders (Desktop, Documents, etc.)
- Review System event log for "The system cannot find the path specified" or "Userenv" errors (to confirm)

**Action if confirmed:**
- Delete corrupted local profile and force re-creation on next login (delete `C:\Users\[SID]` registry key and folder)
- If OneDrive-backed desktop: sync will recover shortcuts after profile rebuild
- If managed via Group Policy/folder redirection: ensure central store is accessible

---

### 6. **Certificate or encryption issue affecting login or data access (Copilot anomaly root cause)**
**Why likely:**
- One user's Copilot access anomaly *could* be a symptom of the same root cause (if app changed encryption/ACLs)
- App rollout sometimes includes SSL certificate or credential changes that break authentication

**Check to confirm (to confirm):**
- For Copilot anomaly: preserve exact prompt and output; check Copilot data source permissions in admin console
- Check certificate store on affected machine: `certmgr.msc` - look for missing or expired certs related to new app
- Check Windows Auth logs for Kerberos failures: Event Viewer > Security > look for error codes 0x1f or 0x25
- (To confirm) Does login succeed if user skips the app's auth step, or does it still fail?

**Action if confirmed:**
- Reimport/reinstall required certificates
- Reset user credentials/cached tickets: `klist purge` (PowerShell)
- Sync time across machines/domain (Kerberos is time-sensitive)
- Escalate Copilot anomaly to Security + Data Governance team in parallel

---

## Diagnostic Priority Order
1. **Check #1 immediately** – app in login path (easiest to test, highest confidence correlation)
2. **Check #2 in parallel** – GPO conflict (broad impact, easy to compare across users)
3. **Check #3 next** – network/backend dependency (explains multi-user consistent delay)
4. **Check #4 if above don't resolve** – disk space (quick win if applicable)
5. **Check #5 if profile-specific** – profile corruption (only if one or few users, not whole floor)
6. **Check #6 escalate separately** – security/Copilot issue requires parallel security triage, not endpoint fix
