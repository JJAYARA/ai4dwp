# FinBridge Service Desk - Root Cause Analysis (RCA)

Incident: AVD black screen post-login on POOL-FIN-01  
Date of incident: 2024-03-15  
RCA prepared: 2026-08-06  
Primary reporter: Maria Lopez, Finance (ext 4421)

## 1) Executive Summary

Between approximately 07:00 and 10:00 on 2024-03-15, users logging into AVD hosts in POOL-FIN-01 experienced black screen behavior after authentication, with repeated session disconnect/reconnect for some users. POOL-FIN-02 remained unaffected.

Log evidence from affected host SHFIN-01-A shows repeated Desktop Window Manager (dwm.exe) crashes in Intel graphics module igdumd64.dll (Event 1000), followed by DWM exit events (Event 9009) and session disconnect events (Event 40). The unaffected comparison host SHFIN-02-A showed normal DWM startup (Event 9011) and no Event 1000 during the same window.

The implemented recovery action (rollback/correction of the updated image and display stack path) restored service. Incident was resolved at 10:00 AM, with verified successful user logins to POOL-FIN-01 and no further issues reported.

## 2) Scope and Business Impact

- Affected scope: POOL-FIN-01 only.
- Unaffected scope: POOL-FIN-02.
- User impact: approximately 40 percent of users on POOL-FIN-01 encountered black screen and/or disconnect loops after logon.
- Business impact: delayed access for Finance users during morning startup period.

## 3) Supporting Evidence

### 3.1 Change Correlation Evidence

- Overnight image update applied to POOL-FIN-01 at approximately 02:00.
- Affected host SHFIN-01-A reports post-update boot timestamp:
  - 07:02:14 Kernel-General Event 1 states boot time 02:03:11.
- POOL-FIN-02 remained on pre-update image version 10.0.22621.2861-build-20240313 and was unaffected.

### 3.2 Affected Host Evidence (SHFIN-01-A)

- 07:02:10 - TerminalServices-LocalSessionManager Event 21: logon succeeded (FINBRIDGE\\mlopez, Session 3).
- 07:02:16 - Application Error Event 1000: faulting application dwm.exe, faulting module igdumd64.dll, exception 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40: session disconnected.
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:02:44 - Event 21: reconnect logon succeeded.
- 07:02:46 - Event 1000: repeat dwm.exe crash in igdumd64.dll.
- 07:02:47 - Event 40: disconnected again.
- 07:03:01 - Event 9009: DWM exited again.
- 07:08:22 - Event 21: another user (FINBRIDGE\\akapoor) logon succeeded.
- 07:08:24 - Event 1000: same dwm.exe + igdumd64.dll crash signature.

### 3.3 Unaffected Host Evidence (SHFIN-02-A)

- 07:01:44 - TerminalServices-LocalSessionManager Event 21: logon succeeded.
- 07:01:46 - Desktop Window Manager Event 9011: DWM started successfully.
- No Application Error Event 1000 observed in the incident window.

## 4) Timeline (All times local)

- 02:00 - Planned overnight image update starts for POOL-FIN-01.
- 02:03:11 - SHFIN-01-A rebooted after update (confirmed later by Event 1 at 07:02:14).
- ~07:00 - First business-hour user reports begin (black screen post-login).
- 07:02:10 - User mlopez logon succeeds on SHFIN-01-A (Event 21).
- 07:02:16 - First captured dwm.exe crash in igdumd64.dll (Event 1000).
- 07:02:17 - Session disconnect (Event 40).
- 07:02:18 - DWM exit event (9009).
- 07:02:44 - Reconnect logon succeeds (Event 21).
- 07:02:46 - Repeat dwm.exe crash (Event 1000).
- 07:02:47 - Repeat disconnect (Event 40).
- 07:03:01 - Repeat DWM exit (9009).
- 07:08:24 - Same crash signature reproduced on second user session (Event 1000).
- During triage - Affected hosts contained, sessions redirected, rollback/corrective image-driver path executed.
- 10:00 - Service restored and incident resolved.
- Post-10:00 verification - Users successfully logging into POOL-FIN-01; no new issues reported.

## 5) Hypothesis Elimination Outcome

The following five hypotheses were evaluated against evidence:

1. POOL-FIN-01 image regression (core logon/shell components): supported.
2. Uneven bad subset of updated hosts in POOL-FIN-01: supported (limited).
3. FSLogix/profile attach regression: contradicted by direct DWM/graphics crash sequence.
4. Display/GPU stack regression from updated image: strongly supported.
5. Logon policy/script/app-init delay: contradicted by immediate crash/disconnect pattern.

Surviving technical hypothesis and final root cause direction:

- Display/GPU stack regression introduced by updated POOL-FIN-01 image, causing dwm.exe crashes in igdumd64.dll during/after session initialization.

## 6) 5-Why Analysis

Problem statement: Users on POOL-FIN-01 saw black screens and disconnect loops after logon.

Why 1: Why did users get black screens after logon?
- Because Desktop Window Manager failed during session initialization, preventing stable desktop rendering.

Why 2: Why did Desktop Window Manager fail?
- Because dwm.exe repeatedly crashed with Application Error Event 1000 in igdumd64.dll (Intel graphics user-mode driver), exception 0xc0000005.

Why 3: Why was this crash signature recurring on affected hosts?
- Because POOL-FIN-01 hosts had a newly updated image path correlated with the crash onset and host reboot after update.

Why 4: Why did this affect POOL-FIN-01 but not POOL-FIN-02?
- Because POOL-FIN-02 remained on pre-update image baseline and did not exhibit Event 1000 crashes in the same interval.

Why 5: Why was the regression introduced to production impact scope?
- Because image promotion controls did not sufficiently gate display/GPU driver regressions under real multi-user AVD logon/reconnect patterns before rollout.

Root cause:
- Image-linked display driver stack regression in POOL-FIN-01 update path (dwm.exe crashing in igdumd64.dll), combined with insufficient pre-promotion validation for AVD graphics/session behavior.

## 7) Resolution Actions Executed

1. Incident containment
- Affected POOL-FIN-01 hosts were placed in drain mode.
- New sessions were routed to unaffected POOL-FIN-02.

2. Corrective remediation
- POOL-FIN-01 image path was rolled back/corrected to known-good state.
- Graphics stack alignment was restored to stable baseline.

3. Validation
- User login checks on POOL-FIN-01 hosts succeeded after remediation.
- No additional user-reported black screen issues after 10:00 resolution point.

## 8) Preventive and Corrective Action Plan (CAPA)

### 8.1 Immediate Corrective Controls

- Pin approved graphics driver versions for AVD image builds.
- Block image promotion if DWM crash signatures (Event 1000 with dwm.exe and igdumd64.dll) appear in pilot validation.

### 8.2 Preventive Engineering Controls

- Implement ringed release policy for AVD pools: canary, pilot, broad.
- Require A/B pool comparison gate before broad rollout.
- Add automated validation tests:
  - Repeated logon/reconnect loops.
  - Multi-user concurrency with office app rendering checks.
  - Session stability and disconnect-rate thresholds.

### 8.3 Monitoring and Alerting

- Create alert for burst pattern:
  - Application Error Event 1000 where faulting app is dwm.exe and module is igdumd64.dll.
  - Correlated Event 40 disconnect spikes within 15-minute windows.
- Dashboard key indicators:
  - DWM crash count per host.
  - Post-logon disconnect rate.
  - Pool-by-pool incident deltas.

### 8.4 Process Improvements

- Update change advisory checklist to include AVD graphics stack risk sign-off.
- Add mandatory rollback readiness evidence before image deployment.
- Document known-good driver matrix by pool and image version.

## 9) Closure Statement

The incident was resolved at 10:00 AM on 2024-03-15 after applying the recommended corrective path. Verification confirmed users could log in to hosts in POOL-FIN-01 successfully, and no further issues were reported after restoration.

## 10) Evidence References

- Affected host event export: SHFIN-01-A, 07:00-07:30, Application and System logs.
- Comparison host event extract: SHFIN-02-A, same window, pre-update image baseline.
- Initial analysis and hypothesis document: day4/avd-black-screen-pool-fin-01-hypothesis-20240315.md.
