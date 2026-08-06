# Triage Summary – Company App Fails to Install from Company Portal (Error 0x87D1041C)

**Date logged:** 2026-08-04
**Ticket:** T-1004

---

## Summary
User reports a company application fails to install via Company Portal, returning error 0x87D1041C.

---

## Impact
- **Who affected:** 1 end user reporting (USER_A) – to-verify whether other users/devices attempting the same app install are affected
- **How many:** Individual report; broader scope across estate/device group unknown at this stage – to-verify
- **Business urgency:** Depends on whether the app is required for the user's immediate work tasks – to-verify against role/business criticality; treat as standard priority unless user indicates they are blocked from performing required duties

---

## Known Facts
- Application install is being attempted through Company Portal
- Install fails with error code 0x87D1041C
- No further detail provided on device type, app name, OS version, or when the issue started – to-verify

---

## Missing Information to Gather
- Exact application name and version being installed – to-verify
- Device name/asset tag (DEVICE_01) and Windows OS build/version – to-verify
- Whether this is a first-time install attempt or a reinstall/update of an existing app
- Whether the install fails consistently or intermittently, and how many attempts have been made
- Whether other apps install successfully via Company Portal on the same device – to-verify
- Whether other users/devices in the same group or location report the same error – to-verify
- Time and date the failure was first observed
- Whether the device is on the corporate network, VPN, or external/home internet at time of install
- Device compliance/enrollment status in Intune (internal reference only, via approved tooling – not to be shared with public AI)
- Whether the user has sufficient free disk space and is signed in with the expected account
- Any recent changes to the device (updates, policy changes, reimage) prior to the failure – to-verify

---

## Likely Category
**Endpoint Management / Software Deployment – Company Portal (Intune) Application Install Failure**
Sub-category: To be confirmed once device compliance, network path, and app-specific details are gathered – to-verify

---

## Suggested First Diagnostic Step
Using approved internal Intune/Company Portal management tooling (not public AI), check the device's enrollment and compliance status and review the application deployment status/logs for this specific device to determine whether the failure originates from device compliance, content delivery, or an app-specific install condition; do not ask the user to share device identifiers, logs, or screenshots containing personal or environment-specific data through any public or unapproved channel.
