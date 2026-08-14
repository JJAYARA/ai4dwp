# Triage Summary – Floor 6 Login/Performance and Access Anomaly

## Summary (one line)
Floor 6 has a reported multi-user disruption with login failures or very slow logins, plus one reported potential unauthorized data access concern and one report of missing desktop shortcuts.

## Impact (who/how many/ business urgency)
- Who affected: Floor 6 users (exact teams/roles to confirm)
- How many: At least a dozen people reported affected (to confirm exact count)
- Business urgency: High (to confirm) due to broad login/access disruption and a potential information access concern

## Known facts
- Report states Floor 6 is experiencing issues this morning.
- At least a dozen people reportedly cannot log in or are experiencing very slow login.
- One paralegal reported Copilot surfaced a client matter they say they have never had access to (to confirm).
- Another user reported desktop shortcuts vanished.
- A new document management app was rolled out to Floor 6 on Friday afternoon.

## Missing information to gather
- Exact affected user list, teams, and business-critical roles
- Exact count split by symptom: cannot log in vs slow login
- Timestamp window for first occurrence and whether issue is ongoing
- Whether affected users share same device model, image, OU, or policy set
- Whether failures occur on network sign-in, Windows profile load, or app sign-in
- Any common error messages/codes/screenshots
- Whether unaffected users exist on Floor 6 and what differs
- Change details for Friday rollout: deployment scope, version, install success/failure rates, and post-install reboots
- For the Copilot/client-matter concern: exact prompt/output evidence, data source surfaced, and reproducibility (all to confirm)
- For missing shortcuts: whether shortcuts were local profile, Start menu, OneDrive-backed desktop, or managed via policy (to confirm)

## Likely category
Major incident candidate (to confirm):
- Primary: Endpoint authentication/profile/performance issue after recent change (to confirm)
- Secondary: Potential data access/governance incident requiring security triage (to confirm)

## Suggest first diagnostic step
Immediately open and prioritize this as a potential major incident, then run a rapid scope check with Floor 6 leads to confirm exact affected count by symptom and whether all affected users received the Friday document-management rollout, while simultaneously escalating the Copilot/client-matter report to security for parallel triage (to confirm evidence).