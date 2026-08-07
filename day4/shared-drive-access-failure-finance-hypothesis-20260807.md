# Shared Drive Access Incident Analysis and Hypotheses

Logged: 2026-08-07
Analyst role: DWP Engineer

## Scope Facts Used

- Symptom: Finance team cannot access shared drives.
- Who: all Finance users on `DESKTOP-FB*` devices in `OU=Finance`.
- Scope: 45 users affected.
- Since: 08:00 this morning.
- Change: nil.

## Ranked Top 5 Causes

Most probable first. These are hypotheses only; no final cause is being committed yet.

1. OU=Finance Group Policy or drive mapping policy failed, was unlinked, or stopped applying
   - Why this fits the scope facts: The impact cleanly aligns to an organisational boundary, not a random subset of users or one physical area. All affected users are in the same OU and on similarly named managed devices, which is exactly the pattern expected when a drive-mapping GPO, security filter, loopback interaction, or item-level targeting issue breaks at OU scope.
   - Fastest single check: On one affected Finance device, run `gpresult /r` and confirm whether the expected drive-mapping GPO is missing, denied, or filtering out.

2. Finance file server share or NTFS permissions were changed or no longer include the Finance group
   - Why this fits the scope facts: If all Finance users lost access at the same time but other teams were not mentioned, a permissions regression on the target shares is a strong fit. This can happen without an announced change if an admin group membership, share ACL, or NTFS ACL was altered indirectly or by automation.
   - Fastest single check: From the file server, verify whether the Finance AD group still has the expected share and NTFS permissions on the affected drive path.

3. Authentication path to the file server is failing for Finance users because of Kerberos or domain controller reachability issues
   - Why this fits the scope facts: A broad access failure starting at a precise morning time can come from authentication failure rather than the share itself being down. If Finance clients cannot obtain or present valid tickets to the file server, the symptom to users is simply that shared drives cannot be accessed.
   - Fastest single check: On one affected device, access the UNC path directly and immediately check Security, System, and Kerberos-related events for logon or ticket failures against the file server.

4. Finance devices received a bad DNS or network configuration that blocks resolution or routing to the file server namespace
   - Why this fits the scope facts: The affected population is device-based as well as user-based, which keeps a client network issue in scope. If `DESKTOP-FB*` endpoints share subnet, DHCP scope, or DNS settings, they could all fail to resolve or reach the same file server or DFS namespace from 08:00 onward without any deliberate service-side change.
   - Fastest single check: On one affected device, test name resolution and connectivity to the mapped drive target with `nslookup <fileserver>` and `Test-NetConnection <fileserver> -Port 445`.

5. The shared drive target itself, such as the file server service, DFS namespace, or storage backing it, is unavailable
   - Why this fits the scope facts: A single backend outage would explain why every Finance user lost access at once. This ranks below OU and permission causes because the scope facts do not yet say whether other departments using the same storage are affected, but it remains a plausible common-point failure.
   - Fastest single check: From an admin host, open the target UNC path or DFS namespace directly and confirm whether the server and `LanmanServer`/SMB service are responding.

## Working Position

The current facts point first to an OU-scoped policy or access control issue, with authentication and client network path problems close behind. The scope alone is not enough to distinguish between policy failure, permission regression, and backend availability, so no single root cause should be selected yet.

## Next Best Triage Order

1. Confirm whether the expected Finance drive mapping policy is still applying on one affected device.
2. Validate share and NTFS permissions for the Finance access group on the target file path.
3. Test direct name resolution and SMB connectivity from an affected `DESKTOP-FB*` endpoint to the file server.

## Evidence Review Against Each Hypothesis

Using the incident evidence provided, each original hypothesis is assessed below without selecting a final winner.

1. OU=Finance Group Policy or drive mapping policy failed, was unlinked, or stopped applying
   - Judgement: contradicts.
   - Determining evidence: GroupPolicy Event 1500 at `08:00:06` states that Group Policy settings processed successfully, which directly argues against a GPO processing or link failure as the reason the Finance drive access broke.
   - Additional note: The Intune Management Extension entries at `08:00:01` through `08:00:04` show a separate script execution path, which further weakens the idea that this was a Group Policy delivery issue.

2. Finance file server share or NTFS permissions were changed or no longer include the Finance group
   - Judgement: contradicts.
   - Determining evidence: ScriptRunner Warning at `08:00:03` says `\\finbridge-fs01\Finance` was not accessible from `SYSTEM` context at execution time, and ScriptRunner Error at `08:00:03` reports `Network name cannot be found` rather than `Access is denied` or another authorization failure.
   - Additional note: The prior change note explicitly says the mapping script was migrated to run as `SYSTEM` and was not updated for that context, which points away from share ACL or NTFS ACL regression.

3. Authentication path to the file server is failing for Finance users because of Kerberos or domain controller reachability issues
   - Judgement: contradicts.
   - Determining evidence: GroupPolicy Event 1500 at `08:00:06` shows Group Policy processed successfully, which is strong evidence that domain communication was working on the endpoint during the incident window. The ScriptRunner Error at `08:00:03` is `Network name cannot be found`, not a Kerberos, logon, or trust failure.
   - Additional note: No Security, Kerberos, Netlogon, or GroupPolicy failure events were presented to support an authentication-path outage.

4. Finance devices received a bad DNS or network configuration that blocks resolution or routing to the file server namespace
   - Judgement: neutral.
   - Determining evidence: ScriptRunner Error at `08:00:03` reporting `Network name cannot be found` is superficially compatible with a name-resolution or path-reachability problem, so the evidence does not fully eliminate this hypothesis.
   - Additional note: The same evidence is also explained by the prior change note and the execution timing: the script ran in `SYSTEM` context at `08:00:02`, then the Workstation service only entered the running state at `08:00:05` in Service Control Manager Event 7036. That makes the evidence non-discriminating rather than supportive.

5. The shared drive target itself, such as the file server service, DFS namespace, or storage backing it, is unavailable
   - Judgement: contradicts.
   - Determining evidence: ScriptRunner Warning at `08:00:03` states the path was not accessible from `SYSTEM` context at execution time, which makes the execution context part of the failure condition. The prior change note also says the script was moved from user context to `SYSTEM` and not updated to handle that model.
   - Additional note: If the backend share had simply been down, the evidence would not need to mention `SYSTEM` context as the deciding factor.

## Interim Position After Evidence Review

The supplied evidence weakens four of the five original scope-only hypotheses and leaves the DNS or network-path hypothesis as neutral rather than supported. The event sequence points to an execution-context or startup-timing failure pattern, but that conclusion is still being held as an observation rather than a final root-cause declaration here.

## Addendum - Event Details Reviewed

### Confirmed Event Pattern

- `08:00:01` - ScriptRunner Info: Executing `Map-FinBridgeDrives.ps1`.
- `08:00:02` - ScriptRunner Info: Script context was `SYSTEM` account.
- `08:00:03` - ScriptRunner Warning: Network path `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time.
- `08:00:03` - ScriptRunner Error: `Map-FinBridgeDrives.ps1` failed with exit code `1` and `Network name cannot be found`.
- `08:00:04` - ScriptRunner Info: No retry configured.
- `08:00:05` - Service Control Manager Event `7036`: Workstation service entered running state.
- `08:00:06` - GroupPolicy Event `1500`: Group Policy settings processed successfully.
- `08:00:07` - Ntfs Event `98` Warning: File system could not map drive letter `S:` because the drive letter had not been assigned.
- `2024-03-14 23:30` - Prior change note: drive mapping moved from GPO logon script running as `USER` to Intune PowerShell script running as `SYSTEM`, and the script was not updated to handle `SYSTEM` context at login time.

### Surviving Hypothesis

- The drive mapping failure was caused by the migration of `Map-FinBridgeDrives.ps1` from a user-context GPO logon script to an Intune PowerShell script running in `SYSTEM` context before the Workstation service and UNC access path were fully available.
- This hypothesis fits the evidence because the script explicitly ran as `SYSTEM` at `08:00:02`, failed at `08:00:03` because the UNC path was not accessible from that context, and the Workstation service only reached running state at `08:00:05`.
- Group Policy itself is excluded by GroupPolicy Event `1500` at `08:00:06`, so the surviving explanation is a script execution model and startup timing defect introduced by the documented migration change.

### Resolution

1. Remove or disable the Intune `SYSTEM`-context deployment of `Map-FinBridgeDrives.ps1` for the Finance device group.
2. Restore drive mapping in user context, either by returning to the previous GPO logon script model or by redeploying the script through a user-context method that runs after user sign-in.
3. If Intune must remain the delivery mechanism, repackage the mapping logic so it runs in the signed-in user context rather than `SYSTEM`.
4. Add a startup guard so the script only runs after the Workstation service is running and the UNC path `\\finbridge-fs01\Finance` is reachable.
5. Add retry logic so a transient early-start failure does not become a hard failure for the whole sign-in session.
6. Validate the mapping logic by testing on one Finance endpoint and confirming the `S:` drive maps successfully in user context.
7. Redeploy the corrected mapping method to the Finance scope and confirm successful mapping across a sample of affected `DESKTOP-FB*` devices.
8. Monitor Intune Management Extension and System logs after rollout to confirm the ScriptRunner failure at `08:00:03` pattern no longer recurs.