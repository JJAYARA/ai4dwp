Symptom : Floor 6 users experienced slow login and performance issues after the Friday afternoon rollout of a new document-management app. The incident also aligns with reported login-path impact and related access anomalies, to confirm.

Cause : To confirm. The leading hypothesis is that the new document-management app is blocking or deferring login, or consuming resources during profile load. Other ranked causes to confirm include Group Policy conflict or corruption, a network share or authentication dependency timing out, disk space exhaustion, user profile corruption, or a certificate/encryption issue.

Scope : Multiple users on Floor 6 were affected, which suggests a scope-wide configuration or rollout issue rather than a single-machine problem, to confirm.

Workaround : Remove the app from the login path by deleting Run registry entries and disabling Task Scheduler entries, or defer app startup until after profile load. If Group Policy is suspected, run gpupdate /force on affected users to confirm whether policy refresh changes the login behavior.

Permanent fix: Permanently remove or defer the app from login startup. If a different ranked cause is confirmed, rollback the conflicting GPO, repair the network/backend dependency, free disk space, rebuild the corrupted profile, or reimport certificates and purge cached tickets as applicable.
