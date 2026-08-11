# L2/L3 KB: Autopilot Enrolment Failure - Legacy MDM Conflict

Version: v 1.0  
Date: 11/08/2026  
Status : Draft

---

## Background

Windows Autopilot is used to provision a device into DWP management so the endpoint receives policy, security controls, and application baseline from Intune. This matters because failed enrolment blocks managed-state onboarding, delays user readiness, and prevents expected compliance posture.

---

## Symptom

Engineer observes Autopilot enrolment failure with no policy application progress. User reports setup does not complete.

Verified incident signals:
- `EnrollmentState : Failed`
- `ErrorCode : 0x80180014`
- `ErrorDescription : The device is already enrolled in MDM.`
- `ProfilesApplied : 0 of 4`
- `LastError : 0x80070005 (Access denied)`
- `AzureADJoined : Yes`
- `IntuneP1License : Yes`, `AutopilotLicense : Yes`
- `Network : All endpoints reachable, no proxy`

---

## Root Cause

Specific technical cause: a pre-existing legacy manual MDM enrolment record (from 2023-11-04) conflicted with Autopilot enrolment, preventing a clean management channel from being created.

Evidence that confirms it:
- `MDMEnrolled : Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource : Legacy manual MDM enrolment`
- `ErrorCode : 0x80180014` with explicit description that device is already enrolled in MDM
- Join/licensing/network checks were healthy, removing those as primary cause candidates

---

## Detection

Use this sequence and confirm all fields before remediation.

### Step 1 - Confirm export-level failure signature
Log location:
- MDM diagnostic export used in ticket evidence (incident dataset)

Fields to inspect:
- `EnrollmentState`
- `ErrorCode`
- `ErrorDescription`
- `MDMEnrolled`
- `EnrolmentSource`
- `ProfilesApplied`
- `LastError`
- `AzureADJoined`
- `IntuneP1License`
- `AutopilotLicense`
- `Network`

What to look for:
- `EnrollmentState : Failed`
- `ErrorCode : 0x80180014`
- Existing enrolment indicators (`MDMEnrolled : Yes`, legacy source)

### Step 2 - Windows event corroboration on endpoint
Log location:
- Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> DeviceManagement-Enterprise-Diagnostics-Provider -> Admin

Fields to inspect per event:
- `Event ID`
- `Level`
- `TimeCreated`
- `Message`

What to look for:
- Events at failure timestamp containing enrolment failure text and/or code references matching `0x80180014` or `0x80070005`

Specific event IDs:
- Incident evidence pack did not include captured Event IDs. If present in local log, record exact IDs in ticket and preserve with timestamp correlation.

### Step 3 - Intune device record conflict check
Portal path:
- Intune Admin Center -> Devices -> All devices

Fields to inspect:
- Device name
- Enrolment date/time
- Management state
- Duplicate records for same serial/hardware identity

What to look for:
- Historical/stale managed record plus current failed attempt context for same endpoint

### Step 4 - Entra object duplication check
Portal path:
- Microsoft Entra admin center -> Devices -> All devices

Fields to inspect:
- Device display name
- Join type/state
- Last activity
- Duplicate objects for same physical endpoint

What to look for:
- Obsolete duplicate object(s) that can maintain conflicting enrolment identity path

### Step 5 - Comparison check (control vs affected)
Comparison pair:
- Affected device (failed)
- Control device (known-good Autopilot completion in same tenant/policy ring)

Compare these exact fields:
- Export: `MDMEnrolled`, `EnrolmentSource`, `ProfilesApplied`, `ErrorCode`
- Intune: count of active managed records for same hardware identity
- Entra: count of active objects mapped to same endpoint identity

Expected difference in this incident pattern:
- Failed device shows legacy enrolment history and conflict signature; control device does not.

---

## Resolution

Perform in this order.

### 1. Capture evidence snapshot before change
Portal path:
- Intune Admin Center -> Devices -> All devices -> select device -> Overview

Action:
- Record current object IDs, enrolment status, timestamps, and duplicate count in ticket.

Expected result:
- Baseline evidence stored for audit/rollback traceability.

### 2. Retire/delete stale Intune managed record(s)
Portal path:
- Intune Admin Center -> Devices -> All devices -> select stale legacy record -> Retire -> Delete

Action:
- Retire stale record first, then delete after status update.

Expected result:
- Conflicting stale managed record removed from Intune active set.

### 3. Remove obsolete duplicate Entra object(s) where confirmed stale
Portal path:
- Microsoft Entra admin center -> Devices -> All devices -> select obsolete duplicate -> Delete

Action:
- Delete only objects validated as stale/obsolete; keep intended active identity path.

Expected result:
- Single clean identity path remains for reenrolment.

### 4. Validate Autopilot registration/profile targeting
Portal path:
- Intune Admin Center -> Devices -> Windows -> Windows enrolment -> Devices

Action:
- Confirm device registration present and profile assignment correct.

Expected result:
- Device has valid Autopilot assignment ready for rerun.

### 5. Device-side cleanup and rerun
Console path on device:
- Settings -> Accounts -> Access work or school -> select old work connection -> Disconnect -> Reboot

Action:
- Remove old work connection, reboot, rerun Autopilot flow.

Expected result:
- Device proceeds through enrolment without legacy-channel collision.

---

## Verification

Confirm all checks pass:
1. Intune enrolment succeeds with no new `0x80180014` state.
2. `ProfilesApplied` progresses from `0 of 4` to applied state for assigned profiles.
3. No persistent `0x80070005` during enrolment/policy stage.
4. Intune shows one active current managed record for the endpoint.
5. Entra shows one valid current device object path for that endpoint.

---

## Rollback

If changes worsen state (for example, wrong active object removed):

1. Stop further deletion actions immediately.
2. Use ticket evidence snapshot from Resolution Step 1 to identify removed object(s) and mismatch.
3. Re-establish clean target by re-validating Autopilot registration assignment in Intune:
   - Intune Admin Center -> Devices -> Windows -> Windows enrolment -> Devices
4. Re-run device enrolment from clean rebooted state after correcting assignment/object posture.
5. Escalate to endpoint engineering lead with captured before/after object identifiers and timestamps.

Rollback intent:
- Return to a single valid management identity path and retry controlled enrolment.

---

## Preventive

Implement these specific controls:

1. Mandatory pre-Autopilot hygiene gate in SOP (existing control, strengthened):
- Owner: `DWP engineer`; Timing: before deployment; Mode: manual (can be automated via Graph query for duplicate serial/hardware identity).
- Pass = Intune active managed record count = 1, Entra active device object count = 1, and no legacy/manual enrolment conflict flag for target device; Fail = any count > 1 or legacy conflict present.
- Signal: checklist fields recorded in ticket (`IntuneRecordCount`, `EntraObjectCount`, `LegacyConflictFlag`); If fail: block assignment/redeployment and open cleanup task.

2. Deployment ticket quality gate (existing control, strengthened):
- Owner: `service desk lead`; Timing: before deployment handoff; Mode: manual [REQUIRES: ticket template with mandatory fields].
- Pass = ticket contains timestamped evidence of clean state (Intune/Entra screenshots or export showing single active path); Fail = missing or stale evidence (>24h old).
- Signal: ticket validator returns pass/fail on required attachments; If fail: ticket cannot move to "Ready for Autopilot".

3. Weekly detection report and engineering queue (existing control, strengthened):
- Owner: `release engineer`; Timing: after deployment (weekly) and before next deployment wave; Mode: automated [REQUIRES: Log Analytics/Workbook or scheduled Graph report].
- Pass = report generated weekly and reviewed; Fail = report missing or unreviewed.
- Signal: count of new failures with `0x80180014` and count of devices flagged with legacy enrolment source; If fail: auto-create engineering queue items for each flagged device.

4. Ownership and KPI control (existing control, strengthened):
- Owner: `change manager`; Timing: after deployment (monthly governance review); Mode: manual.
- Pass = first-pass Autopilot success rate meets agreed threshold and `0x80180014` recurrence trend is non-increasing month-on-month; Fail = threshold miss or rising recurrence.
- Signal: monthly KPI pack with `FirstPassSuccess%` and `0x80180014 IncidentCount`; If fail: trigger corrective action plan and change advisory review.

5. Pre-deployment smoke-test gate (missing layer added):
- Owner: `release engineer`; Timing: before deployment; Mode: manual (can be automated with preflight script in release pipeline) [REQUIRES: preflight script/process].
- Pass = one control device in target ring completes enrolment with no `0x80180014` and profile application progresses beyond `0 of 4`; Fail = any control device fails.
- Signal: smoke-test record with device ID, result, and error code; If fail: stop rollout and remediate before user deployment.

6. In-flight rollout monitoring alert (missing layer added):
- Owner: `DWP engineer`; Timing: during deployment window; Mode: automated [REQUIRES: enrolment failure alert rule].
- Pass = failure rate with `0x80180014` stays below 2 devices or below 5% of rollout batch (whichever is lower); Fail = threshold breached.
- Signal: live count of enrolment failures by error code (`0x80180014`, `0x80070005`) per rollout batch; If fail: pause rollout and start incident bridge.

7. Post-deployment validation gate (missing layer added):
- Owner: `change manager`; Timing: after deployment, before change closure; Mode: manual.
- Pass = sampled deployed devices show one active Intune record, one active Entra object, and no unresolved `0x80180014` failures; Fail = any sampled exception.
- Signal: closure checklist with sample size and pass/fail counts; If fail: keep change open and assign remediation actions.

8. Rollback trigger threshold (missing layer added):
- Owner: `release engineer`; Timing: during deployment; Mode: manual decision using automated metrics [REQUIRES: batch-level failure dashboard].
- Pass = thresholds not breached; Fail trigger = `0x80180014` in >=3 devices in first 20 deployments or >=10% of current wave.
- Signal: batch dashboard counters by error code and device count; If fail: execute rollback path (pause rollout, cleanup stale records, rerun only after smoke-test pass).

9. Knowledge update control (missing layer added):
- Owner: `service desk lead`; Timing: after deployment/incident closure; Mode: manual.
- Pass = related KB, runbook, and service-desk checklist updated within 5 business days of RCA finalization; Fail = overdue update.
- Signal: document revision log includes new version/date and reviewer sign-off; If fail: escalate to `change manager` and block similar change approvals until updated.

---

## Related

Connected incident/KB records in this workspace:
- `day6/autopilot-enrolment-failure-analysis-legacy-mdm-20260811.md`
- `day6/rca-autopilot-enrolment-failure-legacy-mdm-20260811.md`
- `day6/known-error-autopilot-enrolment-failure-legacy-mdm-20260811.md`
- `day6/closure-note-autopilot-enrolment-failure-legacy-mdm-20260811.md`
- `day6/enduser-communication-autopilot-enrolment-failure-legacy-mdm-20260811.md`