# Autopilot Enrolment Failure Analysis - Legacy MDM Conflict

**Author:** DWP Analyst  
**Date:** 2026-08-11  
**Incident Type:** Windows Autopilot enrolment failure  
**Status:** Root cause confirmed, remediation finalized

---

## 1. Executive Summary

Autopilot enrolment failed because the device already had an existing legacy MDM enrolment record (dated 2023-11-04). This conflict blocked modern Autopilot-driven Intune enrolment from completing.

Primary blocking error:
- `0x80180014` with description: **The device is already enrolled in MDM**

Secondary symptom:
- `0x80070005` (Access denied) during policy/application phase (`ProfilesApplied: 0 of 4`)

---

## 2. Scope Facts Used

- Enrolment state: Failed
- Error code: `0x80180014`
- Error description: Device already enrolled in MDM
- Existing MDM enrolment: Yes (previous enrolment from 2023-11-04)
- Enrolment source: Legacy manual MDM enrolment
- Azure AD joined: Yes
- Profiles applied: 0 of 4
- Last error: `0x80070005` (Access denied)
- Licensing: Intune P1 = Yes, Autopilot = Yes
- Network: All required endpoints reachable, no proxy issue

Conclusion from facts: identity, licensing, and connectivity prerequisites were present; the stale/legacy enrolment conflict was the blocker.

---

## 3. Confirmed Root Cause

The device had an existing legacy/manual MDM enrolment relationship that conflicted with Autopilot enrolment. Autopilot could not establish a clean management channel while the older enrolment state was still active.

---

## 4. Remediation Runbook (Exact Steps)

## 4.1 Order of Operations

Follow this sequence exactly:
1. Admin center cleanup (stale records and assignments)
2. Device-side unenrolment/reset actions
3. Re-run Autopilot from clean state
4. Post-remediation verification

---

## 4.2 Intune Admin Center Actions (Admin Center Only)

### Step A - Identify stale device objects
**Access type:** Admin center only

1. Go to **Intune Admin Center** -> **Devices** -> **All devices**.
2. Search by serial number, hardware hash identifier, or device name.
3. Identify duplicate or historical records tied to the same physical endpoint.

### Step B - Retire/delete stale managed device record
**Access type:** Admin center only

1. Open the stale/legacy managed device record.
2. Capture audit details first (device name, user, enrolment date, management state).
3. Select **Retire** (if still active) and then **Delete** once retired status is reflected.
4. Confirm no active conflicting managed device record remains for that endpoint.

### Step C - Validate Entra ID device object posture
**Access type:** Admin center only

1. In **Microsoft Entra admin center** -> **Devices** -> **All devices**, locate related object(s).
2. Remove obsolete/duplicate object only if confirmed stale and not the intended active identity for the next enrolment run.
3. Keep one clean target object path for re-enrolment.

### Step D - Confirm Autopilot registration assignment
**Access type:** Admin center only

1. Go to **Intune Admin Center** -> **Devices** -> **Windows** -> **Windows enrolment** -> **Devices**.
2. Locate the device by serial number.
3. Verify profile assignment is correct and profile status is ready.
4. Confirm target user/device group assignment is present for Autopilot profile and required configuration profiles.

---

## 4.3 Device-Side Actions (Requires Device Access: Physical or Remote)

### Step E - Disconnect old work/school MDM connection
**Access type:** Device access required (physical or remote)

1. On the endpoint, open **Settings** -> **Accounts** -> **Access work or school**.
2. Select old/legacy work account connection.
3. Choose **Disconnect**.
4. Reboot the device.

### Step F - Ensure clean enrolment state
**Access type:** Device access required (physical or remote)

1. Confirm old management artifacts are not reappearing after reboot.
2. If device remains contaminated with previous enrolment state, perform approved reset path for Autopilot rerun (per DWP endpoint runbook).

### Step G - Re-run Autopilot enrolment
**Access type:** Device access required (physical or remote)

1. Start OOBE/Autopilot flow on a clean state device.
2. Complete user sign-in with intended enrolment identity.
3. Allow ESP and policy stages to complete.

---

## 5. Verification Checks After Remediation

Use all checks below to confirm successful resolution.

### Verification 1 - Enrolment success state
**Where:** Intune Admin Center -> Devices -> All devices -> target device

Pass criteria:
- Device shows as enrolled and managed
- No new `0x80180014` failure event

### Verification 2 - Policy/application completion
**Where:** Device record -> Device configuration / Compliance / Managed apps status

Pass criteria:
- Previously expected profiles now apply (not `0 of 4`)
- No persistent `0x80070005` in enrolment stage outcomes

### Verification 3 - Single active management record
**Where:** Intune All devices + Entra device objects

Pass criteria:
- One active current record for the endpoint
- No stale legacy duplicate bound to same hardware identity

### Verification 4 - Device-side confirmation
**Where:** Endpoint Settings and Company Portal/Work account status

Pass criteria:
- Work account shows current tenant management only
- No legacy manual enrolment connection present

---

## 6. Preventive Action to Stop Recurrence

Implement a pre-Autopilot hygiene gate for reused/reprovisioned devices.

### Preventive control
Before assigning/redeploying any device to Autopilot:
1. Check for existing legacy/manual MDM enrolment records in Intune.
2. Retire/delete stale records before handoff.
3. Validate only one active Entra/Intune device identity path exists.
4. Add this as a mandatory checklist item in build/rebuild SOP and service desk intake.

### Recommended operational enhancement
- Create a periodic report for devices with:
  - historical legacy enrolment source
  - duplicate records for same serial number
  - failed Autopilot events containing `0x80180014`
- Route report to endpoint engineering queue for cleanup before user-impacting redeployments.

---

## 7. Final Resolution Statement

Root cause is confirmed as conflicting pre-existing legacy MDM enrolment. Resolution is to remove stale enrolment records in admin portals, clear old device-side work/school connection state, and rerun Autopilot from a clean posture. Success is confirmed when enrolment completes, expected profiles apply, and only one active management record remains.