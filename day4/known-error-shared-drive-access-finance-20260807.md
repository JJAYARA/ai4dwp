Symptom : Finance users on `DESKTOP-FB*` devices in `OU=Finance` could not access their mapped shared drives from 08:00 during the incident. On the affected endpoint, drive letter `S:` was not assigned.

Cause : The verified root cause was that `Map-FinBridgeDrives.ps1` had been migrated from a user-context GPO logon script to an Intune PowerShell script running as `SYSTEM`, but it was not redesigned for machine-context startup timing or UNC access behavior. The script ran in `SYSTEM` context at `08:00:02` and failed at `08:00:03` before the Workstation service was running.

Scope : The impact affected 45 Finance users on `DESKTOP-FB*` devices in `OU=Finance`. The RCA evidence references affected endpoint `DESKTOP-FB041` during validation of the fault pattern.

Workaround : Stop using the failing `SYSTEM`-context mapping model for the Finance scope and restore a valid mapping approach that runs in the correct user-aware execution context or after the required network service dependency is available. This was the corrective action used to restore service in the incident.

Permanent fix: Redesign the drive-mapping deployment so user-scoped mappings are not executed through an unvalidated `SYSTEM`-context Intune startup path. Add dependency-aware execution and retry behavior, and validate the design under real sign-in conditions before rollout.

How to spot it: Look for Intune ScriptRunner entries showing `Map-FinBridgeDrives.ps1` executing at `08:00:01`, running as `SYSTEM` at `08:00:02`, then failing at `08:00:03` with `Network name cannot be found` and `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context. Correlate that with Service Control Manager Event `7036` at `08:00:05`, GroupPolicy Event `1500` at `08:00:06`, and Ntfs Event `98` at `08:00:07`.