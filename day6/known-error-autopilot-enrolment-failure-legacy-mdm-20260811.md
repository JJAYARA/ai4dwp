# Known Error Record - Autopilot Enrolment Failure (Legacy MDM Conflict)

Symptom : User/device provisioning through Windows Autopilot fails and the device does not complete enrolment. The device remains unmanaged for expected policy delivery, with profiles not applying (0 of 4).

Cause : Verified root cause is a conflicting existing legacy manual MDM enrolment record from 2023-11-04. This stale enrolment state blocks a clean Autopilot enrolment channel.

Scope : Affects Windows devices being enrolled through Autopilot where a prior legacy/manual MDM enrolment relationship still exists. Impact is on affected endpoint provisioning and the assigned enrolling user for that device.

Workaround : Perform immediate cleanup by retiring/deleting stale legacy managed device record(s) in Intune, removing obsolete duplicate device object(s) where confirmed stale, and disconnecting old work/school connection on the device. Then rerun Autopilot enrolment from a clean device state.

Permanent fix: Enforce a mandatory pre-Autopilot hygiene gate in operations: detect and remove legacy MDM enrolment artifacts and duplicate Intune/Entra records before redeployment. Require completion evidence in the ticket before Autopilot handoff.

How to spot it: Primary signals are `0x80180014` with message "The device is already enrolled in MDM," plus `MDMEnrolled: Yes` showing prior enrolment (2023-11-04, legacy manual source). Corroborating signals are `ProfilesApplied: 0 of 4`, `LastError: 0x80070005 (Access denied)`, with `AzureADJoined: Yes`, valid Intune/Autopilot licensing, and healthy network reachability. No specific event IDs were captured in the verified RCA dataset.