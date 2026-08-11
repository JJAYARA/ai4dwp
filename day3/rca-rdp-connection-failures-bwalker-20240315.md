# Root Cause Analysis (RCA): RDP Connection Failures and Account Lockout

## Incident Summary
- **Incident type:** Repeated Remote Desktop (RDP) login failures leading to account lockout
- **Date:** 2024-03-15
- **Source client IP:** 10.10.5.44
- **User account affected:** FINBRIDGE\bwalker
- **Primary impact:** User could not establish an RDP session until lockout state cleared/remediated.

## Event ID Explanations

### Event ID 56 (System, Source: TermDD)
- Records that the Terminal Services security layer detected a protocol/security stream problem and disconnected the client.
- In failed-auth scenarios, this can appear when the server terminates the session during or just after security-layer negotiation.

### Event ID 140 (System, Source: RemoteDesktopServices-RdpCoreTS)
- Records an RDP authentication failure at the RDP core service layer.
- Here it explicitly states the connection failed because the username or password was not correct.

### Event ID 4625 (Security)
- Records a failed logon attempt.
- In this incident, all listed 4625 events are:
  - **Logon Type 10:** RemoteInteractive (RDP)
  - **Failure reason:** Unknown username or bad password
  - **Source IP:** 10.10.5.44

### Event ID 4740 (Security)
- Records that a user account was locked out by account lockout policy.
- Includes caller/source computer context; here the caller is 10.10.5.44.

### Event ID 131 (System, Source: RemoteDesktopServices-RdpCoreTS)
- Records that the server accepted a new inbound TCP connection for RDP.
- This confirms network-level reachability and TCP session establishment from the client.

### Event ID 4624 (Security)
- Records a successful logon.
- Here, Logon Type 10 confirms a successful RDP authentication for FINBRIDGE\bwalker from 10.10.5.44.

## Reconstructed Sequence of Events (Plain English)
1. At 14:01:02, the client at 10.10.5.44 attempted RDP access. The server logged both a security/protocol disconnect (Event 56) and an explicit bad-credential failure (Event 140).
2. At 14:01:04, Security Event 4625 recorded a failed RemoteInteractive logon for FINBRIDGE\bwalker from 10.10.5.44.
3. Additional failed RDP logons for the same account/source occurred at 14:03:18 and 14:05:33 (both Event 4625, bad password/username).
4. At 14:05:34, the account was locked out (Event 4740), with caller computer 10.10.5.44.
5. At 14:22:07, the server accepted a fresh TCP RDP connection from 10.10.5.44 (Event 131).
6. At 14:22:09, authentication succeeded for FINBRIDGE\bwalker over RDP (Event 4624).

## Most Likely Cause of Connection Failures
The most likely cause was repeated use of incorrect credentials for FINBRIDGE\bwalker from client 10.10.5.44, which triggered account lockout policy and temporarily prevented successful RDP authentication.

### Evidence Supporting This Cause
- Event 140 explicitly says username or password was not correct at the first failure timestamp.
- Three Security Event 4625 failures show Logon Type 10 (RDP) and failure reason "Unknown username or bad password" for the same account and source IP.
- Event 4740 immediately follows the third failure, confirming account lockout due to threshold breach.
- Later Event 131 + Event 4624 shows connection/authentication succeeds from the same source IP once lockout state was no longer in effect (unlock by admin or lockout duration expiry).

## Root Cause Statement
**Primary root cause:** Incorrect credentials were repeatedly submitted for FINBRIDGE\bwalker over RDP from 10.10.5.44.

**Contributing factors:**
- Account lockout threshold was reached quickly after repeated failed attempts.
- No successful corrective action occurred before threshold was exceeded.

## 5 Whys Analysis

### Problem
User could not connect through RDP and the account became locked.

1. **Why did the RDP connection fail initially?**
	- Authentication failed because the supplied username/password was incorrect (Event 140 and 4625).
2. **Why did authentication keep failing?**
	- The same invalid credential set was retried multiple times from 10.10.5.44 (three 4625 events).
3. **Why did this become a broader access issue?**
	- Repeated failures triggered account lockout policy (Event 4740).
4. **Why was access not immediately restored?**
	- While locked out, valid authentication could not proceed until lockout cleared (time delay until 14:22 success).
5. **Why was the user eventually able to log in?**
	- Lockout state was removed (likely timed unlock or administrative unlock), allowing a successful RDP logon (Event 4624).

## Timeline Table
| Time (2024-03-15) | Log | Event ID | Outcome | Key detail |
|---|---|---:|---|---|
| 14:01:02 | System | 56 | Session disconnected | TermDD security layer/protocol stream error; client 10.10.5.44 |
| 14:01:02 | System | 140 | Authentication failed | Username or password not correct; client 10.10.5.44 |
| 14:01:04 | Security | 4625 | Failed logon | FINBRIDGE\\bwalker, Type 10, bad password/username |
| 14:03:18 | Security | 4625 | Failed logon | FINBRIDGE\\bwalker, Type 10, bad password/username |
| 14:05:33 | Security | 4625 | Failed logon | FINBRIDGE\\bwalker, Type 10, bad password/username |
| 14:05:34 | Security | 4740 | Account locked | Caller computer 10.10.5.44 |
| 14:22:07 | System | 131 | TCP accepted | New RDP TCP connection accepted from 10.10.5.44 |
| 14:22:09 | Security | 4624 | Successful logon | FINBRIDGE\\bwalker, Type 10, source 10.10.5.44 |

## Corrective and Preventive Actions
1. Confirm password reset/credential validation with user before repeated retries.
2. Instruct users to stop after 1-2 failed attempts and contact service desk to avoid lockout.
3. Enable lockout alerting that includes source IP and username for faster triage.
4. Validate whether saved/cached credentials on the source endpoint are replaying stale passwords.
5. Review lockout policy settings to balance security with operational usability.

## Confidence and Limitations
- **Confidence level:** High.
- **Reason:** Chronological consistency across RDP-core authentication failure (140), repeated security failures (4625), lockout event (4740), and later successful RDP logon (4624).
- **Limitations:** No explicit unlock event was provided in the supplied dataset, so unlock mechanism (manual vs policy timeout) is inferred.
