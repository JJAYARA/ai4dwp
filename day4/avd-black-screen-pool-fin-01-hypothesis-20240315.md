# FinBridge Service Desk - AVD Incident Analysis and Hypotheses

Logged: 2024-03-15 07:18  
Reported by: Maria Lopez, Finance (ext 4421)

## Scope Facts Used

- Symptom: Black screen post-login. Clears after ~30 seconds for some users; persists for others.
- Who: ~40% of users on POOL-FIN-01.
- Unaffected: POOL-FIN-02 completely unaffected.
- Since: ~07:00 this morning.
- Change: Overnight image update to POOL-FIN-01 at 02:00; POOL-FIN-02 not updated.

## Primary Hypothesis

Most consistent with the scope split and timing clue:

- POOL-FIN-01 image regression introduced by the 02:00 update wave.

Why this is strongest:

- Fault boundary matches exactly (updated pool affected, non-updated pool clean).
- Onset matches first business logons after overnight change.
- Variable user experience can occur from host/user-state differences on the same new image.

## Re-Ranked Top 5 Causes (Most Probable First)

1. POOL-FIN-01 image regression (core logon/shell components)
	- Why it fits scope facts: Best fit to both timing and clean pool A/B split.
	- Fastest single check: Roll one affected host to prior image version and retest user logon.

2. Uneven bad subset of updated hosts in POOL-FIN-01
	- Why it fits scope facts: ~40% impact suggests incidents may cluster on specific hosts in the updated ring.
	- Fastest single check: Correlate failed sessions by session host; isolate any clustered hosts.

3. FSLogix/profile attach regression triggered by new image
	- Why it fits scope facts: Black screen after auth aligns with delayed/failed profile attach; image-only pool impact is plausible.
	- Fastest single check: Test affected user with temporary local profile path (bypass profile container).

4. Display/GPU stack regression from the updated image
	- Why it fits scope facts: Black screen with delayed recovery matches display initialization timeout/recovery behavior.
	- Fastest single check: Compare display driver stack on affected vs unaffected hosts and test one no-GPU-accel login.

5. Logon policy/script/app-init delay introduced via updated baseline
	- Why it fits scope facts: Could be image-linked, but less directly indicated than image/host/profile/display paths.
	- Fastest single check: Temporarily bypass synchronous logon processing on a test host and retest.

## Weighting Note

Ranking is intentionally weighted toward causes directly coupled to the 02:00 POOL-FIN-01-only image change, because POOL-FIN-02 remained unchanged and fully unaffected.

---

## Addendum - Event Evidence Review and Resolution (2024-03-15)

### Evidence Window and Hosts

- Affected host analyzed: `SHFIN-01-A` (POOL-FIN-01)
- Comparison host: `SHFIN-02-A` (POOL-FIN-02, unaffected)
- Time window: 07:00-07:30

### Key Event Details Observed

- 07:02:10 - `TerminalServices-LocalSessionManager` Event 21: Session logon succeeded (`FINBRIDGE\mlopez`, Session 3).
- 07:02:14 - `Kernel-General` Event 1: Boot time 02:03:11 (post-overnight image update restart).
- 07:02:16 - `Application Error` Event 1000: `dwm.exe` faulting in `igdumd64.dll` (Exception `0xc0000005`).
- 07:02:17 - `TerminalServices-LocalSessionManager` Event 40: Session disconnected.
- 07:02:18 - `Desktop Window Manager` Event 9009: DWM exited (`0x40010004`).
- 07:02:44 - `TerminalServices-LocalSessionManager` Event 21: Reconnect logon succeeded (`mlopez`, Session 3).
- 07:02:46 - `Application Error` Event 1000: Repeat `dwm.exe` fault in `igdumd64.dll`.
- 07:02:47 - `TerminalServices-LocalSessionManager` Event 40: Session disconnected again.
- 07:03:01 - `Desktop Window Manager` Event 9009: DWM exited again.
- 07:03:10 - `TerminalServices-LocalSessionManager` Event 21: Second reconnect succeeded (`mlopez`, Session 4).
- 07:08:22 - `TerminalServices-LocalSessionManager` Event 21: Logon succeeded (`FINBRIDGE\akapoor`, Session 5).
- 07:08:24 - `Application Error` Event 1000: `dwm.exe` fault in `igdumd64.dll` on another user session.

Comparison host (`SHFIN-02-A`, pre-update image `10.0.22621.2861-build-20240313`):

- 07:01:44 - Event 21 logon succeeded.
- 07:01:46 - `Desktop Window Manager` Event 9011: DWM started successfully.
- No `Application Error` Event 1000 entries in the same window.

### Hypothesis-by-Hypothesis Elimination Results

1. POOL-FIN-01 image regression (core logon/shell components)
	- Judgement: Support
	- Determining evidence: 07:02:14 (Event 1 post-update boot), plus 07:02:16 and 07:02:46 (Event 1000 on updated host), contrasted with 07:01:46 Event 9011 and no Event 1000 on unaffected pre-update host.

2. Uneven bad subset of updated hosts in POOL-FIN-01
	- Judgement: Support (limited)
	- Determining evidence: repeat failures on the same host and across users at 07:02:16, 07:02:46, and 07:08:24 (Event 1000). This suggests host-level concentration, but does not alone prove pool-wide distribution.

3. FSLogix/profile attach regression triggered by new image
	- Judgement: Contradicts
	- Determining evidence: Event 21 success at 07:02:10 and 07:02:44, followed by immediate DWM/graphics module crash (Event 1000 at 07:02:16 and 07:02:46), which is more consistent with display stack failure than profile attach failure.

4. Display/GPU stack regression from the updated image
	- Judgement: Support
	- Determining evidence: Event 1000 at 07:02:16, 07:02:46, and 07:08:24 all show `dwm.exe` faulting in `igdumd64.dll`; Event 9009 at 07:02:18 and 07:03:01 confirms DWM termination sequence.

5. Logon policy/script/app-init delay introduced via updated baseline
	- Judgement: Contradicts
	- Determining evidence: repeated pattern is successful logon (Event 21) followed by immediate crash/disconnect (Event 1000 -> Event 40), not a pure slow synchronous processing delay.

### Surviving Hypothesis

- Display/GPU stack regression introduced by the updated POOL-FIN-01 image, with `dwm.exe` crashing in Intel graphics module `igdumd64.dll`.

### Detailed Resolution Steps

1. Immediate containment
	- Put affected POOL-FIN-01 session hosts in drain mode.
	- Route new finance sessions to POOL-FIN-02.
	- Publish service desk advisory with temporary routing/workaround.

2. Service restoration
	- Roll POOL-FIN-01 back to the last known good image baseline.
	- Prioritize rollback/reimage of the highest-failure hosts (start with `SHFIN-01-A`).
	- Reopen with pilot users first before full release.

3. Technical validation in isolation
	- Clone one failed host for controlled testing.
	- Replace/downgrade Intel graphics driver version `31.0.101.4146` to known-good baseline from pre-update image.
	- Reboot and execute repeated logon/reconnect test cycles.
	- Validation criteria:
		- No `Application Error` Event 1000 for `dwm.exe`.
		- No `Desktop Window Manager` Event 9009 exits.
		- Normal DWM startup events (Event 9011 behavior).
		- No immediate Event 40 disconnect after Event 21 logon.

4. Temporary mitigations (if rollback alone does not fully stabilize)
	- Disable hardware GPU acceleration for affected AVD hosts/users in pilot scope.
	- Apply conservative RDP graphics policy settings.
	- Remove mitigations after corrected image is proven stable.

5. Corrected image rollout
	- Build a corrected POOL-FIN-01 image from known-good baseline.
	- Reapply only validated updates and approved graphics driver package.
	- Run pre-prod smoke tests (concurrent logons, reconnect loops, Office/Teams rendering).
	- Deploy in rings: 10% -> 50% -> 100% with hold points.

6. Exit and monitoring criteria
	- Monitor at least one full business cycle.
	- Require sustained normalization of:
		- `Application Error` Event 1000 (dwm.exe) rates.
		- DWM error events (9009).
		- Session disconnect rates (Event 40) post-logon.
	- Close incident after stability and ticket volume return to baseline.

7. Recurrence prevention
	- Add image promotion gate checks for DWM/graphics crash signals.
	- Enforce canary validation across A/B pools before broad rollout.
	- Pin approved graphics driver versions in image pipeline.
	- Add alerting threshold for `dwm.exe` + `igdumd64.dll` crash bursts.
