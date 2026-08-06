# FinBridge Service Desk - Root Cause Analysis (RCA)

Incident: User login failure - FINBRIDGE\\cthompson  
Date of incident: 2024-03-15  
RCA prepared: 2026-08-06  
Analyst role: DWP Engineer

## 1) Executive Summary

At approximately 08:40, user FINBRIDGE\\cthompson was unable to log in. The impact was isolated to one user. Security log evidence shows repeated wrong-password authentication attempts from DESKTOP-FB022, followed by account lockout, then continued Kerberos pre-authentication failures from a second source IP (10.10.8.112), indicating persisted stale credentials from an additional device/app/service.

The remediation sequence focused on stopping credential replay, removing stale stored credentials, and controlled account recovery. Recovery was confirmed at 09:09 with successful interactive logon and no further user issues reported.

## 2) Scope and Impact

- Affected user: FINBRIDGE\\cthompson only.
- Start time: approximately 08:40.
- Reported change: none.
- Business impact: single-user access interruption to workstation logon.
- Resolution time: 09:09 AM.

## 3) Supporting Evidence

### 3.1 Failure and Lockout Evidence

- 08:44:01 - Security Event 4776 Audit Failure
  - Domain credential validation failed.
  - Account: FINBRIDGE\\cthompson.
  - Error code: 0xC000006A (wrong password).
  - Source workstation: DESKTOP-FB022.

- 08:44:03 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\\cthompson.
  - Failure reason: Unknown user name or bad password.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

- 08:44:28 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\\cthompson.
  - Failure reason: Unknown user name or bad password.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

- 08:44:55 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\\cthompson.
  - Failure reason: Unknown user name or bad password.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

- 08:44:56 - Security Event 4740 Audit Failure
  - A user account was locked out.
  - Account: FINBRIDGE\\cthompson.
  - Caller computer: DESKTOP-FB022.

- 08:45:10 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\\cthompson.
  - Failure reason: Account locked out.
  - Logon type: 7 (Unlock attempt).
  - Source: DESKTOP-FB022.

### 3.2 Secondary Source Evidence (Credential Replay)

- 08:45:44 - Security Event 4771 Audit Failure
  - Kerberos pre-authentication failed.
  - Account: FINBRIDGE\\cthompson.
  - Failure code: 0x18 (wrong password).
  - Source IP: 10.10.8.112.

- 08:46:01 - Security Event 4771 Audit Failure
  - Kerberos pre-authentication failed.
  - Account: FINBRIDGE\\cthompson.
  - Failure code: 0x18 (wrong password).
  - Source IP: 10.10.8.112.

- 08:46:33 - Security Event 4771 Audit Failure
  - Kerberos pre-authentication failed.
  - Account: FINBRIDGE\\cthompson.
  - Failure code: 0x18 (wrong password).
  - Source IP: 10.10.8.112.

### 3.3 Recovery Verification Evidence

- 09:08:14 - Security Event 4722 Audit Success
  - A user account was enabled.
  - Account: FINBRIDGE\\cthompson.
  - Done by: FINBRIDGE\\helpdesk-admin.

- 09:09:01 - Security Event 4624 Audit Success
  - An account was successfully logged on.
  - Account: FINBRIDGE\\cthompson.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

Operational confirmation:
- Issue resolved at 09:09 AM.
- User verified logging in to host successfully.
- No further issues reported after restoration.

## 4) Timeline (All times local)

- ~08:40 - User reports inability to login.
- 08:44:01 - First confirmed wrong-password validation failure (Event 4776, 0xC000006A).
- 08:44:03 - Interactive logon failure (Event 4625, bad password).
- 08:44:28 - Repeat interactive logon failure (Event 4625, bad password).
- 08:44:55 - Repeat interactive logon failure (Event 4625, bad password).
- 08:44:56 - Account lockout recorded (Event 4740).
- 08:45:10 - Unlock attempt blocked due to lockout (Event 4625, logon type 7).
- 08:45:44 - Kerberos wrong-password failure from secondary source IP 10.10.8.112 (Event 4771).
- 08:46:01 - Repeat Kerberos wrong-password failure from 10.10.8.112 (Event 4771).
- 08:46:33 - Repeat Kerberos wrong-password failure from 10.10.8.112 (Event 4771).
- 09:08:14 - Account enabled by helpdesk admin (Event 4722).
- 09:09:01 - Successful interactive logon on DESKTOP-FB022 (Event 4624).
- 09:09 - Incident confirmed resolved.

## 5) Root Cause Statement

Primary root cause:
- Persisted stale credentials associated with FINBRIDGE\\cthompson were repeatedly submitted from a secondary source (10.10.8.112), causing ongoing wrong-password authentication attempts and lockout behavior.

Contributing factors:
- Multiple interactive bad-password attempts from DESKTOP-FB022 increased lockout risk.
- Absence of immediate source isolation allowed continued Kerberos pre-authentication failures post-lockout.

## 6) Hypothesis Elimination Summary

Evaluated hypotheses and outcome:

1. Incorrect credential entry on primary endpoint: supported but insufficient alone.
- Supported by Event 4776 (08:44:01) and Event 4625 sequence (08:44:03/08:44:28/08:44:55).
- Does not fully explain continued wrong-password attempts from a different source IP.

2. Account lockout due to repeated bad attempts: supported as a symptom state.
- Supported by Event 4740 (08:44:56) and Event 4625 lockout reason (08:45:10).
- Explains inability to login, but not underlying continued credential replay source.

3. Persisted old credential from secondary source: strongly supported and survives.
- Supported by repeated Event 4771 wrong-password failures from source IP 10.10.8.112 (08:45:44/08:46:01/08:46:33), distinct from DESKTOP-FB022.

4. AD account state issue (disabled/expired/restriction): contradicted.
- Failure codes observed are wrong-password patterns (4776/0xC000006A and 4771/0x18), not disabled/expired/restricted logon conditions.

5. Endpoint-only local issue on DESKTOP-FB022: partially supported but not sufficient.
- DESKTOP-FB022 generated failures, but distinct secondary source evidence rules out endpoint-only explanation.

## 7) Resolution Actions Executed

1. Incident containment
- Halted repeated login attempts while investigation proceeded.

2. Credential replay path remediation
- Identified and addressed stale credential replay behavior from a secondary source path.
- Cleared or corrected persisted credential state in affected authentication paths.

3. Account recovery
- Account was re-enabled (Event 4722 at 09:08:14).

4. Functional validation
- Verified successful interactive login (Event 4624 at 09:09:01 from DESKTOP-FB022).
- Confirmed user can access host with no immediate recurrence.

## 8) 5-Why Analysis

Problem statement: FINBRIDGE\\cthompson could not log in.

Why 1: Why could the user not log in?
- Because authentication attempts failed repeatedly with wrong-password outcomes and then account lockout.

Why 2: Why were authentication attempts failing as wrong password?
- Because submitted credentials did not match current valid credentials (4776 0xC000006A and 4771 0x18).

Why 3: Why did failures continue after lockout conditions appeared?
- Because a secondary source (10.10.8.112) continued to send stale credentials via Kerberos pre-authentication.

Why 4: Why was a secondary source still sending stale credentials?
- Because stored/saved credentials persisted in a device, app, or service context outside the primary interactive login flow.

Why 5: Why was this not prevented before user impact?
- Because there was no immediate control to detect and suppress multi-source stale-credential replay for this user at incident onset.

Root cause conclusion:
- Multi-source stale credential persistence and replay led to repeated bad-password authentication and lockout, preventing successful login until credential paths were remediated and the account was re-enabled.

## 9) Preventive and Corrective Actions (CAPA)

### 9.1 Preventive Actions

1. Stale credential hygiene standard
- Mandate credential refresh guidance across all enrolled user devices and apps after password changes.

2. Lockout triage checklist enhancement
- Add mandatory step to identify non-primary source IP/host when Event 4771 repeats after lockout.

3. Monitoring improvement
- Create alert logic for pattern: Event 4740 followed by repeated Event 4771 from alternate source within 15 minutes.

4. User communications template
- Provide quick user script: stop retries, sign out secondary devices, then perform controlled single-endpoint test.

### 9.2 Corrective Actions

1. Knowledge base update
- Publish known-error article for "single-user lockout with secondary source IP credential replay" including required evidence markers.

2. Service desk runbook update
- Add ordered recovery sequence: contain retries, isolate source, clear credentials, controlled reset/unlock, verify with Event 4624.

3. Post-incident verification standard
- Require 15-30 minute DC log watch for recurrence after resolution before closure.

## 10) Closure Criteria and Status

Closure criteria met:
- Successful interactive user logon recorded (Event 4624 at 09:09:01).
- User confirmed access to host.
- No further issues reported.

Final status:
- Resolved at 09:09 AM on 2024-03-15.
