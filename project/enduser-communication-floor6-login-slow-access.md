# End-User Communication - Floor 6 Login/Performance Issue

## Audience 1 - Non-technical Executive

Floor 6 users reported slow logins after a Friday rollout of a new document-management app. The likely cause is that the app is blocking or delaying login or using resources during profile load; other ranked causes to confirm are Group Policy, network or authentication timing, disk space, profile corruption, and certificate issues. If the issue returns, contact the Service Desk.

## Audience 2 - Affected End-User Team (10 people, non-technical)

Floor 6 users had slow logins after a Friday rollout of a new document-management app. The likely cause is that the app is blocking or delaying login or using resources during profile load; other ranked causes to confirm are Group Policy, network or authentication timing, disk space, profile corruption, and certificate issues. If you see the same issue again, contact the Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note

Summary:
- Floor 6 users reported slow login and performance issues after the Friday afternoon rollout of a new document-management app.
- The leading hypothesis is that the app is blocking or deferring login, or consuming resources during profile load.
- Other ranked causes to confirm are Group Policy conflict or corruption, a network share or authentication dependency timing out, disk space exhaustion, user profile corruption, or a certificate/encryption issue.

Root cause:
- To confirm.
- The current ranked-fix analysis points first to the new document-management app on the login path, but no single verified root cause is recorded in the source material.

Exact action taken:
- Remove the app from the login path by deleting Run registry entries and disabling Task Scheduler entries.
- Defer app startup until after profile load.
- If Group Policy is suspected, run gpupdate /force on affected users to confirm whether policy refresh changes the login behavior.

Config detail:
- Check whether the app is set to run at startup or user login in HKCU\Software\Microsoft\Windows\CurrentVersion\Run.
- For the GPO path, compare gpresult /h report.html on an affected machine with an unaffected Floor 6 user and review recent policy changes in gpedit.msc.
- For the network/backend path, check app logs under Program Files\[App]\logs\ or %AppData%\[App]\logs\ for network or authentication failures.

Verification step:
- Compare login speed on a Floor 6 machine before uninstalling the app versus after uninstalling it.
- Check app event logs for errors during the login window.
- If the app path does not explain the issue, compare gpupdate /force results and confirm whether policy refresh changes login speed.

Preventive action needed:
- Permanently remove or defer the app from login startup if it is confirmed as the cause.
- If another ranked cause is confirmed, rollback the conflicting GPO, repair the backend dependency, free disk space, rebuild the corrupted profile, or reimport certificates and purge cached tickets as applicable.