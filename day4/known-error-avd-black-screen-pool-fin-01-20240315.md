Symptom : Users logging into AVD hosts in POOL-FIN-01 experienced a black screen after authentication. Some sessions entered disconnect/reconnect loops.

Cause : A display/GPU stack regression was introduced by the 02:00 POOL-FIN-01 image update. The verified root cause was dwm.exe crashing in igdumd64.dll during/after session initialization.

Scope : Impact was limited to POOL-FIN-01; POOL-FIN-02 was unaffected. Approximately 40% of users on POOL-FIN-01 were affected during the incident window.

Workaround : Put affected POOL-FIN-01 hosts in drain mode and route new sessions to POOL-FIN-02. This restores user access while remediation is applied.

Permanent fix: Roll back/correct POOL-FIN-01 to a known-good image state and restore graphics stack alignment to stable baseline. Service was restored and verified at 10:00 AM with successful POOL-FIN-01 logins and no further reported issues.

How to spot it: Look for Application Error Event 1000 showing faulting application dwm.exe and faulting module igdumd64.dll with exception 0xc0000005. Correlate with Desktop Window Manager Event 9009 exits and TerminalServices-LocalSessionManager Event 40 disconnects following Event 21 successful logons.
