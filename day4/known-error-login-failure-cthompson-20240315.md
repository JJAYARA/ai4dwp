Symptom : User FINBRIDGE\cthompson was unable to log in from about 08:40. The user experienced sign-in failure until recovery actions were completed and access was restored.

Cause : The verified root cause was stale persisted credentials in a secondary authentication source replaying wrong passwords for FINBRIDGE\cthompson. This caused repeated bad-password authentication attempts and account lockout behavior.

Scope : This incident affected one user only: FINBRIDGE\cthompson. The observed primary endpoint was DESKTOP-FB022, with additional bad-password traffic from source IP 10.10.8.112.

Workaround : Stop repeated login attempts and contain retry activity while stale credential replay is remediated. Re-enable the account and perform one controlled interactive sign-in test; in this incident, account enable at 09:08:14 was followed by successful logon at 09:09:01.

Permanent fix: Remediate the stale credential replay path and clear/correct persisted credential state in affected authentication paths. Confirm service restoration with successful interactive logon and no further reported issues.

How to spot it: Look for this event sequence: Event 4776 with 0xC000006A (wrong password), repeated Event 4625 (unknown user name or bad password, logon type 2), Event 4740 (account locked out), and repeated Event 4771 with failure code 0x18 from an alternate source IP. In this incident, lockout came from DESKTOP-FB022 activity and continuing 4771 failures came from 10.10.8.112.
