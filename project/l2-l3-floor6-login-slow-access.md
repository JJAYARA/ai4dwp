v 1.0, 14/08/2026, status : Draft

# Floor 6 slow logon after document-management app rollout

## Background
The affected computers use Windows and Microsoft 365 sign-in. During logon, Windows loads the user profile, applies policy, and starts any sign-in items. This matters because anything that runs too early can delay access to the desktop, block work, and affect many users at once.

## Symptom
The engineer sees long logon times, a slow desktop after logon, and the problem affecting multiple Floor 6 users after the Friday rollout of the document-management app. Users report that logon takes much longer than normal, then the computer feels slow for several minutes.

## Root cause
The document-management app was assigned to Floor 6 in a way that started it during logon. The app created a startup entry under HKCU\Software\Microsoft\Windows\CurrentVersion\Run and a sign-in task in Task Scheduler, so the app launched before the user session finished loading. The issue is confirmed when removing that startup path makes logon return to normal, and the affected device does not show User Profile Service or Group Policy failure events.

## Detection
1. Compare one affected Floor 6 computer with one unaffected Floor 6 computer.
   - Log location: not a log check.
   - Field to compare: time from entering credentials to a usable desktop.
   - Confirmed issue: the affected computer is slower by a clear margin.

2. Open Event Viewer > Applications and Services Logs > Microsoft > Windows > User Profile Service > Operational on the affected computer.
   - Filter event IDs: 1500, 1508, 1511, 1515, 1530.
   - Field to check: General tab message, plus Details > EventData for ProfilePath, UserName, and ErrorCode.
   - Confirmed issue: these events show profile loading problems, a temporary profile, or registry/profile access failures.

3. Open Event Viewer > Windows Logs > System on the affected computer.
   - Filter event IDs: 1030 and 1058.
   - Field to check: General tab message, plus Details > EventData for CSEExtensionName and ErrorCode.
   - Confirmed issue: Group Policy cannot finish processing or a policy extension fails.

4. Open Event Viewer > Applications and Services Logs > Microsoft > Windows > TaskScheduler > Operational on the affected computer.
   - Field to check: General tab task name and action details for the document-management app task.
   - Confirmed issue: the app task runs at logon on the affected computer but is not present, or is disabled, on the unaffected computer.

5. Check the startup entry on the affected computer.
   - Location: Registry Editor > HKCU\Software\Microsoft\Windows\CurrentVersion\Run.
   - Field to check: the value name and command line for the document-management app.
   - Confirmed issue: the app is listed and launches at logon.

## Resolution
1. Open Microsoft Intune admin center > Apps > Windows > document-management app > Properties > Assignments.
   - Remove the Floor 6 required assignment or move it to a non-production pilot group.
   - Expected result: the rollout no longer pushes the app to the affected group.

2. Open Microsoft Intune admin center > Devices > Windows > Scripts and remediations > logon-startup-remediation > Properties > Assignments.
   - Remove the Floor 6 assignment.
   - Expected result: the startup cleanup does not reapply the logon entry.

3. On the affected computer, remove the document-management app value from HKCU\Software\Microsoft\Windows\CurrentVersion\Run.
   - Expected result: the app no longer starts from user logon.

4. On the affected computer, disable the scheduled task that starts the document-management app.
   - Expected result: the task shows Disabled and no longer runs at sign-in.

5. Open Microsoft Intune admin center > Devices > Windows > select the affected device > Sync.
   - Expected result: the device checks in and receives the updated assignment state.

6. Restart the affected computer.
   - Expected result: the next sign-in is no longer delayed by the app startup path.

## Verification
- The affected user signs in at normal speed.
- The document-management app does not launch during sign-in.
- Event Viewer no longer shows new User Profile Service 1500/1508/1511/1515/1530 events for the same sign-in.
- Event Viewer no longer shows new Group Policy 1030 or 1058 errors for the same sign-in.
- The affected computer and an unaffected Floor 6 computer now have similar sign-in times.

## Rollback
1. Re-open Microsoft Intune admin center > Apps > Windows > document-management app > Properties > Assignments.
   - Reassign the app to the original Floor 6 group if the change caused a business problem.
   - Expected result: the app deployment is restored.

2. Re-open Microsoft Intune admin center > Devices > Windows > Scripts and remediations > logon-startup-remediation > Properties > Assignments.
   - Reassign the script to the original group if you need to restore the previous state.
   - Expected result: the previous remediation path is restored.

3. Restore the exported Run key backup on the affected computer.
   - Expected result: the original startup entry returns.

4. Re-enable the scheduled task for the document-management app.
   - Expected result: the app starts again at logon.

5. Open Microsoft Intune admin center > Devices > Windows > select the affected device > Sync.
   - Expected result: the device receives the restored policy and assignment state.

6. Restart the affected computer and confirm the original state is back.
   - Expected result: the computer behaves the same as before the change.

## Preventive
- Package the document-management app with a pre-deployment check that blocks any assignment if the app creates a Run entry or scheduled task that launches before the desktop is ready.
- Use a pilot ring for Floor 6 before moving the app to a required assignment.
- Add an Intune remediation rule that checks for the app in HKCU\Software\Microsoft\Windows\CurrentVersion\Run and in Task Scheduler, then reports the result before broad rollout.
- Require one unaffected comparison device and one affected pilot device in every future logon-performance change.