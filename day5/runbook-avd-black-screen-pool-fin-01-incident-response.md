Title: Runbook: AVD Black Screen Post-Login on POOL-FIN-01
Version: 1.0
Date: 07/08/2026
Author: Jayaprakash Jayaraman
Reviewed: self
Status: draft
Change: initial version from RCA

# Runbook: AVD Black Screen Post-Login on POOL-FIN-01

Incident pattern covered: users authenticate to AVD host pool POOL-FIN-01, then see a black screen and may disconnect/reconnect repeatedly.

## prerequisites

Complete this checklist before you start:

1. Confirm you are assigned one active incident owner.
Expected result: exactly one engineer is responsible for decisions and timeline updates.

2. Confirm you have Azure role permissions for host pool management in the target subscription. [ELEVATED]
Expected result: you can open and edit host pool properties and session host settings.

3. Confirm you have Azure role permissions for image version rollback or reassignment in the image pipeline. [ELEVATED]
Expected result: you can select and apply a known-good image version for POOL-FIN-01.

4. Confirm you have permission to read Windows Event Logs on affected session hosts. [ELEVATED]
Expected result: you can query Application and System logs on SHFIN-01-A or equivalent affected hosts.

5. Open Azure portal in a browser session dedicated to this incident.
Expected result: the portal is signed in and responsive.

6. Open a PowerShell 7 terminal with Az module available.
Expected result: running Get-Module -ListAvailable Az returns one or more results.

7. Retrieve and paste these incident constants from CMDB or operations notes into your scratch pad:
   - Subscription ID
   - Resource group for AVD host pools
   - Host pool names: POOL-FIN-01 and POOL-FIN-02
   - Known-good image version ID used by POOL-FIN-02
   - Primary affected host name (for example SHFIN-01-A)
Expected result: all five values are present and confirmed.

8. Notify Service Desk that user impact triage is in progress and ask them to route new reports to this incident ID.
Expected result: ticket queue updates reference one incident ID.

## Procedure

1. Open the POOL-FIN-01 host pool page in Azure portal.
Expected result: host pool overview for POOL-FIN-01 is visible.

2. Set all POOL-FIN-01 session hosts to drain mode. [ELEVATED]
Expected result: no new user sessions are placed on POOL-FIN-01 hosts.

3. Increase allowed session intake on POOL-FIN-02 to absorb redirected sessions. [ELEVATED]
Expected result: POOL-FIN-02 accepts new sessions without capacity rejection.

4. Force a user sign-in test to POOL-FIN-01 using a test account.
Expected result: the test reproduces black screen or disconnect behavior.

5. On one affected host, query Application log for Event ID 1000 entries where faulting application is dwm.exe.
Expected result: one or more recent Event 1000 entries for dwm.exe are returned.

6. On the same host, query Event 1000 details for faulting module name.
Expected result: module name is igdumd64.dll in the failing events.

7. On the same host, query TerminalServices-LocalSessionManager Event ID 40 in the same time window.
Expected result: disconnect events are present and time-correlated with DWM crashes.

8. Record one timestamped evidence set (Event 21, 40, 1000, and 9009 or 9011 comparison) in the incident notes.
Expected result: incident timeline contains concrete event correlation evidence.

9. Select the known-good image version currently used by POOL-FIN-02 in the image pipeline for POOL-FIN-01. [ELEVATED]
Expected result: POOL-FIN-01 deployment target is set to the known-good image.

10. Apply the image rollback or correction deployment to POOL-FIN-01 session hosts. [ELEVATED]
Expected result: deployment job starts successfully and reports in-progress state.

11. Wait for deployment completion state to report success for all targeted POOL-FIN-01 hosts.
Expected result: deployment status is success with no failed hosts.

12. Restart each updated POOL-FIN-01 session host once after image correction. [ELEVATED]
Expected result: each host returns to available state after reboot.

13. Disable drain mode on one pilot host in POOL-FIN-01. [ELEVATED]
Expected result: one host is available for controlled user logins.

14. Execute one test login on the pilot host.
Expected result: desktop renders normally with no black screen.

15. Monitor that pilot session for five minutes.
Expected result: no disconnect loop and no desktop compositor crash behavior.

16. Query Application log again on the pilot host for new Event 1000 dwm.exe crashes after pilot release.
Expected result: no new matching Event 1000 entries appear in the verification window.

17. Disable drain mode on remaining POOL-FIN-01 hosts. [ELEVATED]
Expected result: full pool is available for normal intake.

18. Inform Service Desk to resume normal routing to POOL-FIN-01.
Expected result: new user sessions are no longer intentionally diverted.

## Verification

1. Run three separate user login tests to POOL-FIN-01 from different user accounts.
Expected result: all three sessions reach usable desktop without black screen.

2. Check POOL-FIN-01 disconnect metrics for the last 30 minutes.
Expected result: disconnect rate returns to baseline and shows no spike pattern.

3. Query affected hosts for Application Event 1000 where app is dwm.exe and module is igdumd64.dll during the last 30 minutes.
Expected result: zero new matching events.

4. Confirm no new Service Desk tickets tagged with black screen and POOL-FIN-01 in the last 30 minutes.
Expected result: ticket trend is flat or decreasing.

5. Update incident record with remediation details, verification evidence, and closure timestamp.
Expected result: incident documentation is complete and auditable.

## Rollback

Use this section immediately if black screens increase, disconnect loops worsen, or deployment fails partway.

Execute Steps 1-6 within 3 minutes for emergency containment.

1. In Azure portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts. [ELEVATED]
Expected result: session host list for POOL-FIN-01 is visible.

2. Click Select all on the session host grid. [ELEVATED]
Expected result: every host row in POOL-FIN-01 is selected.

3. Click Drain mode > On. [ELEVATED]
Expected result: drain mode shows On for all selected hosts.

4. In Azure portal, open Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts. [ELEVATED]
Expected result: session host list for POOL-FIN-02 is visible.

5. Verify at least one POOL-FIN-02 host shows Available.
Expected result: redirected logins have a healthy destination pool.

6. Post "Rollback containment active: POOL-FIN-01 in drain mode" in the incident bridge chat.
Expected result: all responders are notified that containment is in effect.

7. In the image deployment console, open Releases > AVD > POOL-FIN-01.
Expected result: POOL-FIN-01 release page is visible.

8. Select image version field for POOL-FIN-01. [ELEVATED]
Expected result: image selector is active.

9. Choose the Last Known Good image version recorded in the incident notes. [ELEVATED]
Expected result: rollback target shows the prior stable image version.

10. Click Deploy to start rollback for POOL-FIN-01. [ELEVATED]
Expected result: deployment status changes to Running.

11. In Azure portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: host list is visible for post-deploy actions.

12. Restart one completed host marked Succeeded by the deployment job. [ELEVATED]
Expected result: selected host returns to Available after reboot.

13. Set Drain mode Off on that one restarted host. [ELEVATED]
Expected result: only one pilot host can take new sessions.

14. Run one test login to the pilot host.
Expected result: desktop loads without black screen or disconnect loop.

15. Create a Sev-2 escalation ticket if the pilot login fails.
Expected result: platform engineering engagement starts with rollback already contained.

16. Set Drain mode Off on remaining POOL-FIN-01 hosts only after 15 minutes with no new Event 1000 dwm.exe crashes. [ELEVATED]
Expected result: full POOL-FIN-01 service is safely restored.

## Notes

- This incident pattern is tightly associated with Desktop Window Manager crashes in igdumd64.dll after image change.
- POOL-FIN-02 acting as unaffected comparator is a key diagnostic control; always preserve at least one known-good comparison pool.
- If Event 1000 is absent but users still see black screen, check for FSLogix attach delays and policy script stalls as secondary paths.
- If only one host reproduces the issue, isolate that host first and compare image/driver fingerprint against a healthy host.
- If rollback deployment reports partial failure, do not release pool-wide intake; operate in pilot mode until all failed hosts are remediated.
- Related analysis: day4/rca-avd-black-screen-pool-fin-01-20240315.md
- Related known error: day4/known-error-avd-black-screen-pool-fin-01-20240315.md
- Related closure note: day4/closure-note-avd-black-screen-pool-fin-01-20240315.md
