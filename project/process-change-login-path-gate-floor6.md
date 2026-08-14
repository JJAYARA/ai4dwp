# Process Change: Login Path Gate (LPG) for Endpoint Rollouts

## One specific control
Implement a mandatory **Login Path Gate (LPG)** for any endpoint app rollout scheduled after 12:00 on Friday: **the rollout cannot be promoted beyond pilot unless measured post-install sign-in time stays within threshold on pilot devices and startup entries are verified not to block profile load**.

## Why this would have caught the Floor 6 issue
The incident documents point to the Friday document-management deployment placing the app on the sign-in startup path, which caused Monday login delays. This control checks exactly that failure mode before broad release.

## Control definition (operational)
- Trigger: Any endpoint software rollout to 25 or more users, or any rollout after 12:00 Friday.
- Owner: Endpoint Engineering (executor) and Incident Duty Manager (approver).
- Test window: Complete within 2 hours after pilot deployment, before change closure.
- Pilot sample: 5 users minimum from target floor/OU.
- Required checks:
  - Baseline sign-in duration captured pre-install for each pilot user.
  - Post-install sign-in duration captured after reboot for each pilot user.
  - Startup-path check completed (`HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run` and Task Scheduler logon tasks) to confirm no blocking app launch on sign-in.
- Pass criteria:
  - Median sign-in delta <= +15 seconds versus baseline.
  - No single pilot user sign-in delta > +30 seconds.
  - No new critical errors in Application/System/Group Policy logs during login window.
- Fail criteria (automatic hold):
  - Any pass criterion missed.
  - Any newly introduced logon-startup task for the app without deferred start.
- Enforcement:
  - Change ticket cannot move from Pilot to Broad Deploy until LPG evidence is attached and approved.

## Evidence required in the change ticket
- Baseline vs post-install timing table for all pilot users.
- Screenshot/export of Run key and relevant Task Scheduler logon tasks.
- Event log export for pilot login window.
- Approver sign-off from Incident Duty Manager.

## Immediate implementation in current runbook/change process
Add LPG as a hard gate in the pre-production checklist for `runbook-floor6-login-slow-access.md` workflows and Friday change templates.
