# FinBridge Service Desk - Incident Communications Pack

Incident: Login failure for FINBRIDGE\\cthompson (2024-03-15)
Prepared: 2026-08-06

## Audience 1 - Non-technical Executive

Access is restored and data is safe. One user (cthompson) could not sign in from about 08:40. We found repeated incorrect sign-in attempts, including from a second source, which caused a temporary account lock. The team removed the stale saved sign-in details, re-enabled the account at 09:08, and confirmed successful sign-in at 09:09 with no further issues reported. No action is needed.

## Audience 2 - Affected End-User Team (10 people, non-technical)

Quick update: this was a single-user issue, and access is now restored with no data impact. From about 08:40, cthompson could not sign in because old saved sign-in details on another source kept sending the wrong password and triggered a temporary account lock. Support cleared the stale saved details, re-enabled the account at 09:08, and confirmed successful sign-in at 09:09, with no further issues reported. If you see the same problem, stop retrying and contact the Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note

Summary:
- Scope: single user only (FINBRIDGE\\cthompson), login failure from ~08:40.
- Impact: user access interruption only; no further issues reported after fix.

Root cause:
- Stale persisted credentials in a secondary auth source replayed bad credentials for FINBRIDGE\\cthompson, causing repeated bad-password events and lockout.

Supporting evidence and config detail:
- DESKTOP-FB022 interactive failures:
  - 08:44:01 Event 4776, 0xC000006A (wrong password), source workstation DESKTOP-FB022.
  - 08:44:03/08:44:28/08:44:55 Event 4625, logon type 2, unknown username/bad password, source DESKTOP-FB022.
  - 08:44:56 Event 4740, account locked out, caller DESKTOP-FB022.
  - 08:45:10 Event 4625, logon type 7 unlock attempt, failure reason account locked out.
- Secondary source replay:
  - 08:45:44/08:46:01/08:46:33 Event 4771, Kerberos pre-auth failure code 0x18 (wrong password), source IP 10.10.8.112.
  - Known primary endpoint IP for DESKTOP-FB022: 10.10.1.88, confirming distinct secondary source path.

Exact action taken:
- Contained retries and remediated stale credential replay path.
- Cleared/corrected persisted credential state in affected auth paths.
- Re-enabled account:
  - 09:08:14 Event 4722 Audit Success, account FINBRIDGE\\cthompson enabled by FINBRIDGE\\helpdesk-admin.

Verification step:
- 09:09:01 Event 4624 Audit Success, logon type 2 interactive, source DESKTOP-FB022.
- User verified login to host; no further issues reported.
- Incident resolved at 09:09.

Preventive action required:
- Add lockout triage control: when Event 4740 occurs, immediately check for repeat Event 4771 from alternate source IP and isolate that source.
- Update runbook to enforce sequence: stop retries, identify secondary source, clear saved creds across device/app/service, controlled unlock/login, 15-30 minute DC event watch.
- Publish known-error guidance for stale secondary credentials causing recurring lockouts.
