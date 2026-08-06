# FinBridge Service Desk - End-User Communications (AVD Incident 2024-03-15)

## Audience 1 - Non-technical executive

Your access and data are safe. On 15 Mar, 7:00-10:00 AM, about 40% of users in Finance desktop group POOL-FIN-01 saw a black screen after sign-in; POOL-FIN-02 was unaffected. The cause was a 2:00 AM update to POOL-FIN-01. We routed users to POOL-FIN-02 and restored POOL-FIN-01 to a known-good version, resolving by 10:00 with clean login checks. Future updates will use phased checks. No action is needed unless this recurs; then contact the Service Desk.

## Audience 2 - Affected end-user team (10 people, non-technical)

Your access and data are safe. On 15 Mar between 7:00 and 10:00 AM, a 2:00 AM update to Finance desktop group POOL-FIN-01 caused black screens after sign-in for about 40% of users, while POOL-FIN-02 was unaffected. We routed sessions to POOL-FIN-02 and restored POOL-FIN-01 to a known-good version, and by 10:00 login checks were clean with no further issues reported. Future updates will use phased checks. If this happens again, sign out and sign back in once, then contact the FinBridge Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Your access and data are safe. Incident window was 2024-03-15 07:00-10:00, with approximately 40% impact limited to POOL-FIN-01 (black screen post-sign-in); POOL-FIN-02 was unaffected. Root cause: 02:00 AM POOL-FIN-01 image update introduced a display stack regression. Exact action taken: drained affected POOL-FIN-01 hosts, redirected new sessions to POOL-FIN-02, and rolled POOL-FIN-01 back/corrected to known-good image plus graphics baseline. Config detail: impacted configuration was POOL-FIN-01 post-update; comparison configuration POOL-FIN-02 remained unaffected. Verification: issue resolved at 10:00 AM, user logins to POOL-FIN-01 validated, no further issues reported. Preventive action needed: phased update checks via canary/pilot gating before broad rollout.
