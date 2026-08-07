# FinBridge Service Desk - Root Cause Analysis (RCA)

Incident: Finance team cannot access shared drives
Date of incident: 2026-08-07
RCA prepared: 2026-08-07
Analyst role: DWP Engineer

## 1) Executive Summary

At 08:00 on 2026-08-07, Finance users on `DESKTOP-FB*` devices in `OU=Finance` were unable to access their shared drives. The impact affected 45 users and aligned to the Finance-managed endpoint population rather than an isolated user, server, or Group Policy failure.

The evidence shows the mapped drive deployment path had been changed the previous evening from a user-context GPO logon script to an Intune PowerShell script running as `SYSTEM`. At sign-in, the script executed at `08:00:01`, ran in `SYSTEM` context at `08:00:02`, then failed at `08:00:03` because the UNC path `\\finbridge-fs01\Finance` was not accessible from `SYSTEM` context at that execution point. The Workstation service only entered running state at `08:00:05`, after the mapping attempt had already failed. Group Policy processed successfully at `08:00:06`, which rules out a GPO processing failure.

The root cause was an implementation defect introduced by the change at `2024-03-14 23:30`: the drive mapping script was migrated from a user-context delivery model to Intune `SYSTEM` context without being redesigned for machine-context execution timing, UNC accessibility, or retry behavior. The issue was resolved by applying the proposed correction, restoring a valid execution model, and verifying that shared drives were accessible again.

## 2) Scope and Business Impact

- Affected scope: 45 Finance users.
- Affected devices: `DESKTOP-FB*` devices in `OU=Finance`.
- Start time: 08:00 this morning.
- Reported change at intake: nil.
- Actual relevant change identified in evidence: `2024-03-14 23:30` drive mapping migration from GPO user-context script to Intune `SYSTEM`-context script.
- User impact: Finance users could not access mapped shared drives.
- Business impact: Finance users were blocked from reaching shared department file locations required for normal work.

## 3) Supporting Evidence

### 3.1 Intune Management Extension Evidence

- `08:00:01` - ScriptRunner Info
  - Executing `Map-FinBridgeDrives.ps1`.

- `08:00:02` - ScriptRunner Info
  - Script context: `SYSTEM` account.

- `08:00:03` - ScriptRunner Warning
  - Network path `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time.

- `08:00:03` - ScriptRunner Error
  - Script `Map-FinBridgeDrives.ps1` failed.
  - Exit code: `1`.
  - Error: `Network name cannot be found`.

- `08:00:04` - ScriptRunner Info
  - No retry configured.

### 3.2 System Log Evidence - DESKTOP-FB041

- `08:00:05` - Service Control Manager Event `7036`
  - Workstation service entered running state.
  - This indicates the SMB client dependency came online after the mapping script had already failed.

- `08:00:06` - GroupPolicy Event `1500`
  - Group Policy settings processed successfully.
  - This is key contradictory evidence against any theory that the incident was caused by failed Group Policy processing.

- `08:00:07` - Ntfs Event `98` Warning
  - File system could not map drive letter `S:`.
  - Drive letter had not been assigned.
  - This is consistent with the mapping script failing before the drive could be created.

### 3.3 Prior Change Evidence

- `2024-03-14 23:30` - Migration change note
  - Drive mapping script migrated from GPO logon script running as `USER` to Intune PowerShell script running as `SYSTEM`.
  - Script not updated to handle `SYSTEM` context.
  - UNC access path depended on conditions not reliably available to `SYSTEM` at login time.

### 3.4 Evidence Interpretation Summary

- The script failed before the Workstation service was running.
- The script failed in `SYSTEM` context, not user context.
- Group Policy succeeded, so the original GPO-failure theory does not match the facts.
- The error pattern is execution-model and startup-timing specific, not a server-side availability or share-permission pattern.
- No retry behavior existed, so a transient early boot/sign-in timing miss became a user-visible service failure.

## 4) Timeline (All times local)

- `2024-03-14 23:30` - Change implemented: drive mapping moved from GPO logon script in user context to Intune PowerShell execution in `SYSTEM` context.
- `08:00:01` - Intune ScriptRunner starts `Map-FinBridgeDrives.ps1`.
- `08:00:02` - ScriptRunner records execution in `SYSTEM` context.
- `08:00:03` - ScriptRunner warning: `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context.
- `08:00:03` - ScriptRunner error: script fails with exit code `1` and `Network name cannot be found`.
- `08:00:04` - ScriptRunner records that no retry is configured.
- `08:00:05` - Service Control Manager Event `7036`: Workstation service enters running state.
- `08:00:06` - GroupPolicy Event `1500`: Group Policy processes successfully.
- `08:00:07` - Ntfs Event `98`: drive letter `S:` is not assigned.
- During triage - prior migration change identified as the relevant environmental change.
- During remediation - suggested resolution applied to correct the delivery and execution model.
- Post-remediation verification - shared drives confirmed accessible and issue resolved.

## 5) Root Cause Statement

Primary root cause:
- The Finance shared-drive mapping failed because `Map-FinBridgeDrives.ps1` was moved from a user-context GPO logon model to an Intune deployment running as `SYSTEM`, but the script and its delivery method were not redesigned for machine-context startup timing and UNC access behavior.

Contributing factors:
- The script executed before the Workstation service was fully available.
- UNC access to `\\finbridge-fs01\Finance` was attempted from `SYSTEM` context at sign-in time.
- No retry logic existed to recover from a transient early-start timing failure.
- The migration change introduced an execution-context dependency that was not validated under real user sign-in conditions before rollout.

## 6) Hypothesis Elimination Summary

The initial scope-only hypotheses were reassessed against the evidence as follows:

1. OU=Finance Group Policy or drive mapping policy failed, was unlinked, or stopped applying: contradicted.
- Determining evidence: GroupPolicy Event `1500` at `08:00:06` confirms Group Policy settings processed successfully.

2. Finance file server share or NTFS permissions were changed or no longer include the Finance group: contradicted.
- Determining evidence: ScriptRunner error at `08:00:03` reports `Network name cannot be found`, not an authorization failure such as `Access is denied`.

3. Authentication path to the file server is failing for Finance users because of Kerberos or domain controller reachability issues: contradicted.
- Determining evidence: GroupPolicy Event `1500` at `08:00:06` confirms successful domain policy processing during the same window.

4. Finance devices received a bad DNS or network configuration that blocks resolution or routing to the file server namespace: partially compatible at first, but not the final explanation.
- Determining evidence: `Network name cannot be found` at `08:00:03` could superficially fit, but the stronger evidence is that the script ran as `SYSTEM` at `08:00:02` and the Workstation service only became available at `08:00:05`.

5. The shared drive target itself, such as the file server service, DFS namespace, or storage backing it, is unavailable: contradicted.
- Determining evidence: The failure is explicitly tied to `SYSTEM` context at execution time, which is not how a general backend outage would normally present.

Surviving technical hypothesis:
- The mapping failed because the script was executed in the wrong context and at the wrong point in the startup/sign-in sequence after the Intune migration.

## 7) 5-Why Analysis

Problem statement: Finance users could not access shared drives.

Why 1: Why could Finance users not access shared drives?
- Because the Finance drive mapping script failed and the expected drive letter was not assigned.

Why 2: Why did the drive mapping script fail?
- Because it attempted to access `\\finbridge-fs01\Finance` from `SYSTEM` context and failed with `Network name cannot be found`.

Why 3: Why was it attempting the mapping from `SYSTEM` context?
- Because the delivery method had been changed from a user-context GPO logon script to an Intune PowerShell script running as `SYSTEM`.

Why 4: Why did the Intune `SYSTEM`-context model fail at runtime?
- Because it executed before the Workstation service and UNC access path were reliably ready, and the script was not adapted to wait, retry, or shift to user context.

Why 5: Why was that design flaw released into production?
- Because the change was migrated without validating execution-context assumptions and startup dependencies under real sign-in conditions for Finance endpoints.

Root cause conclusion:
- A change-introduced execution-context and timing defect in the Intune deployment of `Map-FinBridgeDrives.ps1` caused the shared-drive mapping failure across Finance devices.

## 8) Resolution Actions Executed

1. Incident containment
- Confirmed that the issue was not caused by Group Policy failure, share permissions, or a general file server outage.
- Narrowed the fault domain to the mapping script execution path.

2. Corrective remediation
- Applied the recommended correction to stop using the failing `SYSTEM`-context mapping model for the Finance scope.
- Restored a valid mapping approach that runs in the correct user-aware execution context or after the required network service dependency is available.
- Ensured the mapping process no longer attempts UNC drive creation before the platform is ready.

3. Validation
- Verified shared drives are accessible after the change.
- Confirmed the issue is resolved.
- Confirmed the mapping outcome no longer fails at sign-in for the corrected deployment path.

## 9) Preventive and Corrective Actions (CAPA)

### 9.1 Preventive Engineering Actions

1. Execution context design standard
- Require a formal design check whenever a script is moved from user context to `SYSTEM` context, especially for mapped drives, printers, profile data, or other user-scoped resources.

2. Dependency-aware script pattern
- Standardize script wrappers that explicitly wait for required services such as Workstation and verify UNC reachability before attempting mappings.

3. Retry and backoff requirement
- Require retry logic for sign-in and startup tasks that depend on network readiness, so transient early-start failures do not become full service outages.

4. Pilot-first rollout control
- Require pilot validation on a small endpoint subset before broad Intune rollout of login-critical scripts.

### 9.2 Change Management Improvements

1. Pre-production validation checklist
- Add a mandatory check that confirms whether the target workload is user-scoped or machine-scoped and whether the chosen delivery model matches that requirement.

2. Sign-in timing test case
- Add a test case for first logon or early sign-in timing, including service readiness and network path validation.

3. Backout plan requirement
- Require a documented rollback option whenever a login-critical GPO function is migrated to Intune.

### 9.3 Monitoring and Alerting

1. Intune script failure monitoring
- Alert on repeated ScriptRunner failures for the same Finance deployment package.

2. Pattern detection
- Flag the event sequence: script execution in `SYSTEM` context, UNC access warning, no retry configured, followed by missing drive mapping.

3. Control verification
- Add periodic endpoint compliance checks to confirm required Finance drives are actually mapped after sign-in.

### 9.4 Knowledge and Runbook Updates

1. Known error article
- Publish a known error for user-scoped resource mappings deployed through machine-context Intune scripts.

2. Service desk triage update
- Add a quick discriminator: if Group Policy Event `1500` succeeds but the drive-mapping script fails in `SYSTEM` context, route to endpoint packaging/change analysis instead of AD/GPO investigation.

3. Engineering standard note
- Document that mapped drives should generally be delivered in user context unless there is a tested and supported machine-context design.

## 10) Closure Statement

The incident was resolved after the corrected drive-mapping approach was applied and Finance shared drives were verified as accessible. The evidence supports a change-induced execution-context and startup-timing defect in the Intune deployment of `Map-FinBridgeDrives.ps1` as the root cause.

## 11) Evidence References

- Intune Management Extension log extract for `Map-FinBridgeDrives.ps1`, incident window around `08:00:01` to `08:00:04`.
- System log extract from affected endpoint `DESKTOP-FB041`, including Service Control Manager Event `7036`, GroupPolicy Event `1500`, and Ntfs Event `98`.
- Migration change note dated `2024-03-14 23:30` for the drive mapping deployment change.
- Hypothesis analysis note: `day4/shared-drive-access-failure-finance-hypothesis-20260807.md`.