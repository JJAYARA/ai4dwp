# End-User Communication - Autopilot Enrolment Failure (Legacy MDM Record)

## Audience 1 - Non-technical executive

Your access and data are safe. One device setup failed because it still had an old management record from 2023-11-04, which blocked the new setup process. We removed the old record, cleared the old work account link on the device, and ran setup again. Network and licensing were confirmed healthy. If you are asked to set up a device again, follow the support steps provided; otherwise, no action is needed.

## Audience 2 - Affected end-user team (10 people, non-technical)

Your access and data are safe, and this was a setup issue only. One device setup failed because an old company management link from 2023-11-04 was still attached and blocked the new setup. We removed the old record in admin systems, cleared the old work account link on the device, and reran setup, and we confirmed network and licensing were healthy. If you see the same setup failure, stop and contact the DWP Endpoint Service Desk for the same cleanup-and-rerun fix.

## Audience 3 - Engineer-to-engineer internal note

Root cause: Autopilot enrolment collision with existing legacy manual MDM enrolment (dated 2023-11-04). Primary failure signal `0x80180014` (already enrolled in MDM), with secondary symptom `0x80070005` access denied and `ProfilesApplied: 0 of 4`; `AzureADJoined: Yes`, Intune P1 and Autopilot licensing both present, and network path healthy (all required endpoints reachable, no proxy).

Exact action taken:
1. Intune Admin Center: identified stale/legacy managed device record(s), retired and deleted stale record(s).
2. Entra device posture check: removed obsolete duplicate device object(s) where confirmed stale.
3. Device-side: disconnected old work/school account link, rebooted, and reran Autopilot from clean state.

Config detail: conflict came from historical legacy/manual enrolment state, not from join, license, or network prerequisites.

Verification step:
1. Enrolment completed without recurrence of `0x80180014`.
2. Policy/profile application progressed (no longer `0 of 4`) and no persistent enrolment-stage `0x80070005`.
3. Single active current management record remained for the endpoint.

Preventive action needed: enforce mandatory pre-Autopilot hygiene gate in SOP to detect and remove legacy/stale MDM enrolment artifacts and duplicate Intune/Entra records before redeployment; require evidence of clean state before Autopilot handoff.