# Runbook - Floor 6 Login Slowness After Document-Management App Rollout

## Prerequisites
- Access to one affected Floor 6 workstation and one affected user account.
- Access to a second, unaffected Floor 6 workstation for comparison if available.
- The exact name or package ID of the new document-management app from the Friday rollout.
- Local administrator rights, or an endpoint management account that can change startup items and restart the device.
- Permission to open Registry Editor, Task Scheduler, Event Viewer, and an elevated Command Prompt.
- The change window or rollback approval for the Friday app rollout.

## Procedure
1. Sign in to one affected Floor 6 workstation with an affected user account. Expected result: you can reproduce the slow sign-in on the same device.
2. Open Registry Editor and export HKCU\Software\Microsoft\Windows\CurrentVersion\Run to a .reg file. Expected result: you have a rollback copy of the current Run values.
3. Delete the Run value that starts the new document-management app. Expected result: the app no longer starts from user logon.
4. Open Task Scheduler and disable the task that starts the new document-management app at sign-in. Expected result: the app task shows Disabled. [Requires elevated permissions]
5. Restart the workstation. Expected result: the machine reboots cleanly.
6. Sign in again with the same affected user account. Expected result: the desktop loads faster than before and the login delay is reduced or gone.
7. Run gpupdate /force from an elevated Command Prompt if the login delay is still present after step 6. Expected result: Group Policy refresh completes and tells you whether policy is part of the slowdown. [Requires elevated permissions]
8. Run gpresult /h %TEMP%\floor6-gpo.html from an elevated Command Prompt if gpupdate /force does not change the login delay. Expected result: you have a policy report for comparison with an unaffected Floor 6 user. [Requires elevated permissions]

## Verification
- Confirm the affected user reaches the desktop without the original login delay.
- Confirm the document-management app does not start automatically during sign-in.
- Open Event Viewer and confirm there are no new Application, System, or Group Policy errors in the same login window.
- Compare the sign-in time on the affected workstation with an unaffected Floor 6 workstation if one is available.

## Rollback
1. Sign out of the affected user account immediately if the workstation becomes slower or unstable after the change.
2. Sign in with a local administrator or endpoint management account.
3. Import the saved .reg backup to restore HKCU\Software\Microsoft\Windows\CurrentVersion\Run.
4. Re-enable the disabled document-management app task in Task Scheduler. [Requires elevated permissions]
5. Restart the workstation and confirm the original startup behavior is restored.
6. If you changed the Friday rollout GPO during troubleshooting, unlink that GPO from the Floor 6 OU and run gpupdate /force on the affected workstation. [Requires elevated permissions]

## Notes
- If the app startup entry does not exist, stop removing other startup items and move to the Group Policy or backend dependency path.
- If only one user is affected, user profile corruption is more likely than the floor-wide app rollout.
- If multiple users on Floor 6 are affected, treat the issue as scope-wide and check the rollout, Group Policy, and shared network dependencies first.
- If login improves after removing the startup path but the app still needs to run, defer the app until after profile load instead of starting it at sign-in.
- The reported Copilot or client-matter access concern is a separate security issue and should be triaged in parallel.