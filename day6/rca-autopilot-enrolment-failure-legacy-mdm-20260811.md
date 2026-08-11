# Root Cause Analysis (RCA) - Autopilot Enrolment Failure (Legacy MDM Conflict)

**Author:** DWP Analyst  
**Date:** 2026-08-11  
**RCA ID:** RCA-AP-LEGACYMDM-20260811-01  
**Environment:** Windows Autopilot + Microsoft Intune + Microsoft Entra ID  
**Status:** Final

---

## 1. Incident Summary

An Autopilot enrolment attempt failed on a Windows endpoint. The device was Azure AD joined, licensing was valid, and network connectivity was healthy, but enrolment did not progress to policy application. The primary failure signal was `0x80180014` with description that the device was already enrolled in MDM. A previous legacy manual MDM enrolment from 2023-11-04 existed for the same endpoint.

### Business impact
- Device provisioning did not complete through Autopilot.
- Expected configuration profiles were not applied (`0 of 4`).
- Device could not reach expected managed/ready state for user handover.

### Technical impact
- Enrolment transaction terminated before successful management channel establishment.
- Policy stage blocked with `0x80070005` access denied symptom.

---

## 2. Scope and Constraints

This RCA is based on the diagnostic export and confirmed findings collected during triage.

In scope:
- Enrolment outcome and error signals
- Device join state
- Existing MDM enrolment state
- Policy application state
- Licensing and network prerequisites

Out of scope:
- Unrelated tenant-wide service incidents
- Hardware defects not indicated by evidence

---

## 3. Supporting Evidence

## 3.1 Raw Evidence Extract

- EnrollmentState: Failed
- ErrorCode: `0x80180014`
- ErrorDescription: The device is already enrolled in MDM.
- MDMEnrolled: Yes (previous enrolment from 2023-11-04)
- EnrolmentSource: Legacy manual MDM enrolment
- ProfilesApplied: 0 of 4
- LastError: `0x80070005` (Access denied)
- AzureADJoined: Yes
- IntuneP1License: Yes
- AutopilotLicense: Yes
- Network: All endpoints reachable, no proxy

## 3.2 Evidence Interpretation Matrix

| Evidence item | Observation | RCA relevance |
|---|---|---|
| EnrollmentState | Failed | Confirms incident outcome |
| `0x80180014` + description | Already enrolled in MDM | Direct indicator of enrolment conflict |
| MDMEnrolled = Yes (2023-11-04) | Prior management relationship exists | Confirms stale/legacy state likely predated Autopilot run |
| EnrolmentSource = legacy manual | Non-Autopilot management channel existed | Strongly supports conflict scenario |
| ProfilesApplied = 0 of 4 | No policy delivery progression | Indicates failure happened before or at management channel establishment |
| `0x80070005` access denied | Permission/state denial symptom | Secondary error consistent with blocked policy stage |
| AzureADJoined = Yes | Identity join succeeded | Rules out join failure as primary cause |
| Intune/Autopilot license = Yes | Licensing prerequisite met | Rules out license absence as primary cause |
| Network reachable, no proxy | Connectivity prerequisite met | Rules out transport/proxy as primary cause |

---

## 4. Timeline (UTC)

Note: Exact telemetry timestamps were not provided in the export. Timeline below uses incident-sequence reconstruction from available evidence.

| Time (UTC) | Event | Evidence basis |
|---|---|---|
| 2023-11-04 (historical) | Device enrolled through legacy manual MDM path | `MDMEnrolled: Yes` and enrolment date |
| T0 | Autopilot enrolment initiated | Incident context |
| T0 + short interval | Azure AD join shows successful state | `AzureADJoined: Yes` |
| T0 + short interval | Enrolment conflict detected | `0x80180014` + already enrolled description |
| T0 + short interval | Policy stage does not progress | `ProfilesApplied: 0 of 4` |
| T0 + short interval | Access denied symptom recorded | `LastError: 0x80070005` |
| T0 + short interval | Incident triage confirms network and licensing healthy | `IntuneP1License: Yes`, `AutopilotLicense: Yes`, endpoints reachable |
| 2026-08-11 | Root cause confirmed and remediation finalized | Analyst determination from evidence set |

---

## 5. Root Cause Statement

The Autopilot enrolment failed because the endpoint already had an existing legacy manual MDM enrolment record (from 2023-11-04). This stale/conflicting management relationship prevented Autopilot from establishing a clean enrolment channel in Intune, resulting in enrolment failure (`0x80180014`) and no policy application (`0 of 4`, with access denied symptom `0x80070005`).

---

## 6. 5 Whys Analysis

### Problem
Autopilot enrolment failed and the device did not receive required policies.

1. Why did Autopilot enrolment fail?  
Because the enrolment engine returned `0x80180014` indicating the device was already enrolled in MDM.

2. Why was the device considered already enrolled?  
Because a previous enrolment record and relationship existed from 2023-11-04.

3. Why did that prior enrolment conflict with current Autopilot?  
Because the legacy manual MDM enrolment path remained active/stale and conflicted with the new Autopilot-driven enrolment channel.

4. Why was stale legacy enrolment not removed before redeployment?  
Because pre-Autopilot cleanup/validation did not enforce a mandatory check for historical enrolment artifacts and duplicate management records.

5. Why was that mandatory check missing?  
Because operational SOPs did not consistently require an enrolment hygiene gate (retire/delete stale records and device-side disconnect/reset verification) before Autopilot reuse/reprovisioning.

### 5 Whys conclusion
The technical trigger was an existing legacy MDM enrolment conflict; the process root cause was an insufficient pre-redeployment hygiene control in operational workflow.

---

## 7. Corrective Actions Implemented / Required

## 7.1 Immediate corrective actions (incident device)

1. Admin center cleanup:
- Locate stale managed device record(s) in Intune.
- Retire then delete stale legacy record(s).
- Validate Entra device object state and remove obsolete duplicates where appropriate.

2. Device-side cleanup:
- Remove legacy work/school account connection.
- Reboot and confirm no old management relationship remains.

3. Re-enrolment:
- Re-run Autopilot from clean state.
- Confirm profile assignment and completion.

## 7.2 Validation after corrective action

Success criteria:
- Enrolment completes without `0x80180014`.
- Required profiles apply (not `0 of 4`).
- No persistent access denied (`0x80070005`) in enrolment path.
- Only one active, current management record exists for the endpoint.

---

## 8. Preventive Actions (Recurrence Control)

## 8.1 Process controls

1. Add mandatory pre-Autopilot hygiene gate to SOP:
- Check for historical/legacy MDM enrolment records.
- Check for duplicate Intune or Entra device objects by serial/hardware identity.
- Retire/delete stale records before assigning Autopilot profile.

2. Add service desk checklist control:
- Do not start Autopilot reprovisioning until admin cleanup sign-off is complete.

3. Add quality gate evidence requirement:
- Attach screenshot/export proof of clean object state to ticket before handover.

## 8.2 Monitoring and detection controls

1. Weekly report:
- Devices with duplicate records by serial number.
- Devices with legacy enrolment source.
- Failed Autopilot events containing `0x80180014`.

2. Alert routing:
- Auto-route flagged devices to endpoint engineering queue for preemptive cleanup.

## 8.3 Governance controls

1. Define ownership:
- Endpoint engineering owns cleanup standard and report review.
- Service desk owns execution checklist before deployment handoff.

2. KPI tracking:
- Track Autopilot first-pass success rate.
- Track incident count tied to existing-enrolment conflicts.
- Set reduction target over rolling 90 days.

---

## 9. Residual Risk

- If legacy records are not cleaned consistently, repeated enrolment collisions remain likely.
- If device-side disconnect/reset steps are skipped, hidden local enrolment artifacts may continue to cause failures even after portal cleanup.

Risk rating after preventive controls: **Low to Medium**, dependent on SOP compliance.

---

## 10. Final Resolution

RCA confirms a single primary root cause: conflicting legacy MDM enrolment state. Corrective path is clear and repeatable: remove stale admin-side records, clear device-side legacy connection, then rerun Autopilot with verification gates. Preventive controls have been defined to reduce recurrence across devices with legacy enrolment history.