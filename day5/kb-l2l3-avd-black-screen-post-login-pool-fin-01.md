Title: AVD Black Screen Post-Login on POOL-FIN-01 - L2/L3 Diagnostic Article
Version: v 1.0
Date: 07/08/2026
Status: Draft

## Background
POOL-FIN-01 is the Finance AVD pool used for daily logon and app access. It matters because Finance users rely on it at the start of the workday, and a failed desktop after sign-in blocks access to email, files, and business apps.

## Symptom
Users report that sign-in completes, then the screen goes black. Some users also report repeated sign-in and disconnect loops. On the engineer side, one pool shows failures while the comparison pool stays healthy.

## Root Cause
The specific cause was a display stack regression introduced in the updated POOL-FIN-01 build. On affected hosts, Desktop Window Manager crashed repeatedly in igdumd64.dll. The confirmed evidence was:
- Event ID 1000 in the Application log
- Faulting application: dwm.exe
- Faulting module: igdumd64.dll
- Exception code: 0xc0000005

The comparison pool, POOL-FIN-02, remained on the prior known-good build and did not show the same crash pattern. On SHFIN-02-A, DWM started normally and no Event ID 1000 appeared in the same time window.

## Detection
Confirm this issue before acting by checking the Application log on the affected host and comparing it to POOL-FIN-02.

1. Open the Application log on SHFIN-01-A in Event Viewer > Windows Logs > Application.
Expected result: the Application log is open and filtered to the incident window.

2. Search for Event ID 1000 in the Application log on SHFIN-01-A.
Expected result: at least one Event 1000 entry is present.

3. Open the Event 1000 entry and read the Faulting application name and Faulting module name fields.
Expected result: Faulting application name is dwm.exe and Faulting module name is igdumd64.dll.

4. Search for Event ID 9009 in the Application log on SHFIN-01-A.
Expected result: Event 9009 is present and shows Desktop Window Manager exited after the crash.

5. Run this PowerShell command against SHFIN-01-A to extract the same evidence quickly:
```powershell
Get-WinEvent -ComputerName SHFIN-01-A -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-3)} | Select-Object TimeCreated, Id, ProviderName, Message
```
Expected result: the output shows both Event 1000 and Event 9009 from the Application log.

6. Open the Application log on SHFIN-02-A in Event Viewer > Windows Logs > Application.
Expected result: the comparison host Application log is open for the same time window.

7. Search for Event ID 9011 on SHFIN-02-A.
Expected result: Event 9011 is present and shows DWM started successfully on the unaffected control host.

8. Run this PowerShell command against SHFIN-02-A to confirm the healthy baseline quickly:
```powershell
Get-WinEvent -ComputerName SHFIN-02-A -FilterHashtable @{LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-3)} | Select-Object TimeCreated, Id, ProviderName, Message
```
Expected result: the output shows Event 9011 on POOL-FIN-02 and no matching Event 1000 crash pattern.

## Resolution
1. Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: the POOL-FIN-01 host list is visible.

2. On Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, select every host and set Settings > Allow new sessions = Off.
Expected result: no new user sessions are sent to the affected pool.

3. Run this Azure CLI command to drain POOL-FIN-01 without clicking through the portal:
```powershell
az desktopvirtualization sessionhost list -g <resource-group> -n POOL-FIN-01 --query "[].name" -o tsv | ForEach-Object { az desktopvirtualization sessionhost update -g <resource-group> -n POOL-FIN-01 --name $_ --allow-new-session false }
```
Expected result: all POOL-FIN-01 session hosts have Allow new sessions set to false.

4. Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts.
Expected result: the POOL-FIN-02 host list is visible.

5. On Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts, confirm at least one host shows Settings > Allow new sessions = On.
Expected result: redirected users have a healthy target pool.

6. Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Properties > Image version.
Expected result: the image version picker is visible.

7. Select the known-good build used by POOL-FIN-02 in Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Properties > Image version.
Expected result: POOL-FIN-01 is aligned to the stable build.

8. Start the rollback deployment from Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: deployment status changes to Running.

9. Wait for the deployment to complete on Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: the deployment reports Succeeded for all targeted hosts.

10. Restart one pilot host from Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: the pilot host returns to Available.

11. Set Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > pilot host > Settings > Allow new sessions = On.
Expected result: only the pilot host can take a test session.

12. Run one test sign-in to the pilot host.
Expected result: the desktop opens normally with no black screen.

13. Set Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > remaining hosts > Settings > Allow new sessions = On after the pilot is stable.
Expected result: normal service is restored for the pool.

## Verification
1. Run this Azure CLI command to confirm no new Event 1000 crashes on the affected host:
```powershell
az vm run-command invoke -g <resource-group> -n SHFIN-01-A --command-id RunPowerShellScript --scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-3)} | Select-Object TimeCreated, Id, ProviderName, Message"
```
Expected result: no new dwm.exe Event 1000 crashes appear after the fix.

2. Run this Azure CLI command to confirm Event 9009 on the affected host:
```powershell
az vm run-command invoke -g <resource-group> -n SHFIN-01-A --command-id RunPowerShellScript --scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9009; StartTime=(Get-Date).AddHours(-3)} | Select-Object TimeCreated, Id, ProviderName, Message"
```
Expected result: Event 9009 stops recurring or appears only before the rollback point.

3. Open Event Viewer > Windows Logs > Application on SHFIN-01-A and confirm the same window is clean after remediation.
Expected result: the Application log shows no new Event 1000 entries after the fix.

4. Run this Azure CLI command to confirm the healthy baseline on SHFIN-02-A:
```powershell
az vm run-command invoke -g <resource-group> -n SHFIN-02-A --command-id RunPowerShellScript --scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-3)} | Select-Object TimeCreated, Id, ProviderName, Message"
```
Expected result: Event 9011 appears on POOL-FIN-02 as the unaffected control.

5. Run three sign-in tests to POOL-FIN-01 from different accounts.
Expected result: all three sessions reach a usable desktop.

## Rollback
If the fix makes things worse, act immediately.

1. Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: the affected host list is visible.

2. On Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, set Settings > Allow new sessions = Off for all POOL-FIN-01 hosts.
Expected result: no new sessions enter the unstable pool.

3. Run this Azure CLI command to keep POOL-FIN-01 drained during rollback:
```powershell
az desktopvirtualization sessionhost list -g <resource-group> -n POOL-FIN-01 --query "[].name" -o tsv | ForEach-Object { az desktopvirtualization sessionhost update -g <resource-group> -n POOL-FIN-01 --name $_ --allow-new-session false }
```
Expected result: all POOL-FIN-01 hosts remain unavailable for new sign-ins.

4. Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts.
Expected result: the comparison pool is visible.

5. On Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts, confirm at least one host shows Settings > Allow new sessions = On.
Expected result: user traffic can continue on the healthy pool.

6. Open Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Properties > Image version.
Expected result: the image version picker is visible.

7. Revert Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Properties > Image version to the last known-good build.
Expected result: the pool points back to the prior stable build.

8. Restart one pilot host from Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: the host returns to Available on the old stable build.

9. Run this Azure CLI command to verify the pilot host logs after rollback:
```powershell
az vm run-command invoke -g <resource-group> -n SHFIN-01-A --command-id RunPowerShellScript --scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-3)} | Select-Object TimeCreated, Id, ProviderName, Message"
```
Expected result: no new crash pattern appears after the rollback.

10. Test one sign-in on the pilot host.
Expected result: the desktop opens without black screen.

11. Keep Azure portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts in Drain mode if the pilot still fails and escalate to platform engineering.
Expected result: impact stays contained while deeper troubleshooting continues.

## Preventive
The recurring fix is to strengthen image promotion and validation for AVD graphics behavior.

1. Comparison gate for candidate vs control (existing control, strengthened)
Owner: image owner. Timing: before deployment. Type: manual.
Signal and pass/fail: in a 30-minute pilot window, POOL-FIN-01 candidate must show Event 1000 count = 0 and Event 9009 count = 0, while POOL-FIN-02 control shows Event 9011 >= 1 and Event 1000 = 0.
If fail: release engineer blocks promotion and returns candidate to image owner; automate with scheduled cross-pool query [REQUIRES: cross-pool validation script].

2. Promotion block on crash signature (existing control, strengthened)
Owner: release engineer. Timing: before deployment. Type: automated [REQUIRES: release gate integration].
Signal and pass/fail: any Event 1000 containing Faulting application name=dwm.exe and Faulting module name=igdumd64.dll in pilot logs is an automatic fail.
If fail: change manager marks release failed, promotion is stopped, and rollback-ready build is set as active target.

3. Automated crash and disconnect delta check (existing control, strengthened)
Owner: DWP engineer. Timing: before deployment. Type: automated [REQUIRES: telemetry job].
Signal and pass/fail: candidate pool must keep Event 1000 and Event 40 rates within +10 percent of POOL-FIN-02 baseline over 30 minutes.
If fail: deployment does not start; image owner receives defect with exported event counts and timestamps.

4. Rollback-ready build ID in change record (existing control, strengthened)
Owner: change manager. Timing: before deployment. Type: manual.
Signal and pass/fail: change ticket must contain one valid known-good build resource ID and a tested rollback command set; missing either is fail.
If fail: CAB approval is denied; manual step can be automated by mandatory ticket fields [REQUIRES: ITSM form rule].

5. Pilot sign-in and event validation before broad rollout (existing control, strengthened)
Owner: DWP engineer. Timing: during deployment. Type: manual.
Signal and pass/fail: one pilot login succeeds and 15-minute check shows Event 1000=0, Event 9009=0, and no repeated Event 40 on pilot host.
If fail: keep Allow new sessions Off for remaining POOL-FIN-01 hosts and execute rollback.

6. In-flight monitoring during rollout window (added missing layer)
Owner: service desk lead. Timing: during deployment. Type: automated [REQUIRES: alert rule].
Signal and pass/fail: trigger alert if Event 1000 >= 2 on any POOL-FIN-01 host or Event 40 count >= 5 per host in 15 minutes.
If fail: page DWP engineer immediately, pause rollout, and set all non-pilot hosts to Allow new sessions Off.

7. Post-deployment health validation before change closure (added missing layer)
Owner: DWP engineer. Timing: after deployment. Type: manual.
Signal and pass/fail: for 30 minutes after full release, POOL-FIN-01 shows Event 1000=0 and Event 9009=0, and POOL-FIN-02 remains stable with Event 9011 present.
If fail: change cannot be closed; switch to rollback path and reopen incident bridge.

8. Explicit rollback trigger threshold (added missing layer)
Owner: change manager. Timing: during deployment and after deployment. Type: automated threshold + manual execution.
Signal and pass/fail: rollback is mandatory if Event 1000 >= 3 across POOL-FIN-01 within 15 minutes or if pilot sign-in fails twice.
If fail threshold is hit: release engineer starts rollback within 5 minutes and records trigger evidence in the change record.

9. Knowledge and checklist update after incident (added missing layer)
Owner: image owner. Timing: after deployment. Type: manual.
Signal and pass/fail: runbook, release checklist, and known-error entry are updated within 2 business days and peer-reviewed by a DWP engineer.
If fail: service desk lead escalates overdue action in weekly ops review; automate reminders via ticket workflow [REQUIRES: ITSM reminder rule].

## Related
- day4/rca-avd-black-screen-pool-fin-01-20240315.md
- day4/avd-black-screen-pool-fin-01-hypothesis-20240315.md
- day4/known-error-avd-black-screen-pool-fin-01-20240315.md
- day4/closure-note-avd-black-screen-pool-fin-01-20240315.md
- day5/runbook-avd-black-screen-pool-fin-01-incident-response.md
