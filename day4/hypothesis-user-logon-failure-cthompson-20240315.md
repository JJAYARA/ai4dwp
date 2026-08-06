# FinBridge Service Desk - Login Failure Hypothesis Analysis

Incident: User login failure (FINBRIDGE\\cthompson)
Date of incident: 2024-03-15
Analysis prepared: 2026-08-06
Analyst role: DWP Engineer

## 1) Scope Facts (Input Constraints)

- Symptom: user cthompson not able to login.
- Who: cthompson only (single user impact).
- Since: approximately 08:40 this morning.
- Change: nil reported.

Note: The ranked list below is generated from scope facts only (before event evidence weighting).

## 2) Ranked Hypotheses From Scope Facts Only

### 1. Incorrect credential being entered (user typo, stale remembered password, or keyboard/layout issue)

Why this fits scope facts:
- Single-user-only impact is most consistent with a user-specific credential entry issue.
- Sudden start time with no declared environment change commonly matches password entry problems rather than platform-wide failure.

Single fastest check:
- Attempt AD password verification using known-good process (for example, reset to temporary password and test one controlled sign-in once).

### 2. Account lockout caused by repeated bad password attempts

Why this fits scope facts:
- A single user can move quickly from bad-password attempts into lockout.
- "Cannot login" after a specific morning time often maps to lockout threshold being hit shortly before first ticket/report.

Single fastest check:
- Check AD account lockout status and lockout timestamp for FINBRIDGE\\cthompson.

### 3. Persisted old credential from a secondary device/app/service repeatedly authenticating

Why this fits scope facts:
- User-specific impact with no change can be explained by one user having stale saved credentials in phone mail app, Outlook profile, VPN client, mapped drive, or scheduled task.
- This can continuously re-trigger lockout even after unlock.

Single fastest check:
- Query lockout source/caller and recent bad-password sources in DC security logs to identify non-primary device/IP repeatedly submitting bad credentials.

### 4. User account state issue in AD (disabled/expired/restricted logon conditions)

Why this fits scope facts:
- Single-user-only login failure can be caused by account-level policy or state specific to that identity.
- No broad change required for this to occur.

Single fastest check:
- Inspect AD attributes and status for cthompson (enabled/disabled, password expired, logon hours/workstation restrictions).

### 5. Endpoint-specific local issue on user workstation (credential provider cache, trust/session corruption, Winlogon path issue)

Why this fits scope facts:
- Single affected user with no wider blast radius can still be due to one endpoint state issue.
- Morning onset may align with startup/resume state corruption on one device.

Single fastest check:
- Test same account login on a second known-good domain-joined endpoint to separate account-path vs workstation-path fault quickly.

## 3) Evidence Review Against Each Ranked Hypothesis

Evidence window: Security log, DESKTOP-FB022, 08:44-09:12.

### Hypothesis 1: Incorrect credential being entered

Judgement: supports.

Why:
- Event 4776 at 08:44:01 shows DC credential validation failure with error 0xC000006A (wrong password) for FINBRIDGE\\cthompson.
- Events 4625 at 08:44:03, 08:44:28, and 08:44:55 show interactive logon failures with "Unknown user name or bad password" from DESKTOP-FB022.

Determining event(s):
- Event 4776 at 08:44:01 (0xC000006A wrong password).
- Event 4625 at 08:44:03, 08:44:28, 08:44:55 (bad password failure reason).

### Hypothesis 2: Account lockout after repeated bad attempts

Judgement: supports.

Why:
- Event 4740 at 08:44:56 explicitly records account lockout for FINBRIDGE\\cthompson.
- Event 4625 at 08:45:10 explicitly states "Failure reason: Account locked out" (logon type 7 unlock attempt).

Determining event(s):
- Event 4740 at 08:44:56 (account locked out).
- Event 4625 at 08:45:10 (account locked out on unlock attempt).

### Hypothesis 3: Persisted old credential from secondary source

Judgement: supports.

Why:
- Kerberos pre-auth failures (Event 4771) continue at 08:45:44, 08:46:01, and 08:46:33 with failure code 0x18 (wrong password).
- Source IP is 10.10.8.112, which differs from DESKTOP-FB022 (10.10.1.88), indicating at least one additional credential submission source.

Determining event(s):
- Event 4771 at 08:45:44 from 10.10.8.112 (wrong password).
- Event 4771 at 08:46:01 from 10.10.8.112 (wrong password).
- Event 4771 at 08:46:33 from 10.10.8.112 (wrong password).

### Hypothesis 4: AD account state issue (disabled/expired/restriction)

Judgement: contradicts.

Why:
- Observed failures are specifically wrong-password and lockout patterns, not disabled/expired/restriction codes.
- Event 4776 reports 0xC000006A (wrong password), and Event 4771 reports 0x18 (wrong password), which does not indicate disabled or expired account state.

Determining event(s):
- Event 4776 at 08:44:01 (0xC000006A wrong password).
- Event 4771 at 08:45:44 (0x18 wrong password).

### Hypothesis 5: Endpoint-specific local issue on DESKTOP-FB022

Judgement: neutral.

Why:
- Supportive element: multiple interactive failures originate from DESKTOP-FB022 (Event 4625 at 08:44:03, 08:44:28, 08:44:55), so local endpoint path could be involved.
- Offsetting element: separate bad-password source appears from IP 10.10.8.112 (Event 4771 series), so issue is not isolated to DESKTOP-FB022 alone.

Determining event(s):
- Event 4625 at 08:44:03, 08:44:28, 08:44:55 from DESKTOP-FB022.
- Event 4771 at 08:45:44 from 10.10.8.112.

## 4) Current Position

- No single winner selected yet, by request.
- Evidence has been mapped to all ranked hypotheses without final root-cause commitment.

## 5) Addendum Update - Event Detail, Surviving Hypothesis, and Resolution

### 5.1 Event Detail Consolidation (Incident Window)

- 08:44:01 - Security Event 4776 Audit Failure on DESKTOP-FB022.
	- Account: FINBRIDGE\\cthompson.
	- Error code: 0xC000006A (wrong password).
- 08:44:03 - Security Event 4625 Audit Failure.
	- Failure reason: Unknown user name or bad password.
	- Logon type: 2 (Interactive), source DESKTOP-FB022.
- 08:44:28 - Security Event 4625 Audit Failure.
	- Failure reason: Unknown user name or bad password.
	- Logon type: 2 (Interactive), source DESKTOP-FB022.
- 08:44:55 - Security Event 4625 Audit Failure.
	- Failure reason: Unknown user name or bad password.
	- Logon type: 2 (Interactive), source DESKTOP-FB022.
- 08:44:56 - Security Event 4740 Audit Failure.
	- Account FINBRIDGE\\cthompson was locked out.
	- Caller computer: DESKTOP-FB022.
- 08:45:10 - Security Event 4625 Audit Failure.
	- Failure reason: Account locked out.
	- Logon type: 7 (Unlock attempt), source DESKTOP-FB022.
- 08:45:44 - Security Event 4771 Audit Failure.
	- Kerberos pre-authentication failed.
	- Failure code: 0x18 (wrong password).
	- Source IP: 10.10.8.112.
- 08:46:01 - Security Event 4771 Audit Failure.
	- Kerberos pre-authentication failed.
	- Failure code: 0x18 (wrong password).
	- Source IP: 10.10.8.112.
- 08:46:33 - Security Event 4771 Audit Failure.
	- Kerberos pre-authentication failed.
	- Failure code: 0x18 (wrong password).
	- Source IP: 10.10.8.112.

Observation summary:
- The sequence shows initial bad-password attempts, account lockout, then continued wrong-password submissions from a second source IP not matching DESKTOP-FB022.

### 5.2 Surviving Hypothesis

Surviving hypothesis:
- Persisted old credential from a secondary device/app/service repeatedly authenticating as FINBRIDGE\\cthompson.

Why this survives elimination:
- It explains the full chain: wrong-password failures (4776/4625), lockout (4740), and continued pre-auth wrong-password failures (4771) from different source IP 10.10.8.112 after lockout conditions were already present on DESKTOP-FB022.

### 5.3 Detailed Resolution Steps

1. Contain the lockout loop.
- Stop all new login attempts by the user until source isolation is complete.
- Keep the account locked during investigation to prevent repeated threshold churn.

2. Identify source IP 10.10.8.112.
- Resolve hostname and owner via DNS/DHCP/endpoint inventory.
- Classify source type (workstation, VDI, mobile sync path, service host, VPN edge).

3. Isolate active credential replay.
- On identified source, terminate apps/services/tasks using FINBRIDGE\\cthompson credentials.
- Disable auto-connect/sync components temporarily (mail client, VPN profile, mapped drives, scheduled tasks).

4. Remove stale stored credentials.
- Clear Windows Credential Manager entries on DESKTOP-FB022 and identified secondary source.
- Remove saved credentials from Outlook/Teams/OneDrive/VPN/RDP and any script/task bindings.
- Purge Kerberos tickets for affected sessions and sign out completely.

5. Controlled password reset and unlock.
- Reset to temporary strong password.
- Unlock account once.
- Perform one controlled interactive login from a known-good endpoint.
- If successful, rotate to final user password and update all enrolled devices.

6. Validate stability.
- Monitor domain controller security events for 15-30 minutes.
- Pass criteria: no new Event 4771 (0x18), no Event 4776 bad-password for cthompson, and no Event 4740 lockout.

7. Prevent recurrence.
- Document offending source and corrective action.
- Publish known-error note: stale secondary credentials causing repeated lockout.
- Instruct user to update credentials on all devices immediately after any future password change.
