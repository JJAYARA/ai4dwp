# Root Cause Analysis (RCA): User Account Lockout - jsmith

## Incident Summary
- **User:** jsmith
- **Host involved:** DESKTOP-FB001
- **Observation window:** 08:02:14 to 08:23:44 (approximately 22 minutes within the provided 30-minute period)
- **Impact:** User could not access workstation due to account lockout until helpdesk intervention.

## Event ID Explanations

### Event ID 4625 - Failed logon
- Records a failed authentication attempt.
- In this incident, 4625 appears with:
  - Failure reason: **Unknown username or bad password** (bad credential input)
  - Later failure reason: **Account locked out** (authentication blocked after lockout)
- Logon types seen:
  - **Type 2 (Interactive):** direct local/console sign-in attempt.
  - **Type 7 (Unlock):** attempt to unlock an already logged-in workstation session.

### Event ID 4740 - Account locked out
- Records that an account has been locked due to lockout policy threshold being reached.
- Includes the calling/source machine that triggered lockout.
- Here, lockout was called from **DESKTOP-FB001**.

### Event ID 4722 - Account enabled
- Records that an account was enabled by an administrator.
- In this case, action was performed by **FINBRIDGE\\helpdesk-admin**.
- In many environments, this event can appear during administrative recovery workflows that accompany unlocking/restoring access.

### Event ID 4624 - Successful logon
- Records a successful authentication.
- Here it indicates the user successfully logged on interactively (Type 2) after remediation.

## Reconstructed Sequence (Plain English)
1. At 08:02:14, jsmith entered credentials at the machine console, but authentication failed due to bad credentials.
2. At 08:04:22, a second interactive sign-in attempt failed with the same bad credential reason.
3. At 08:06:01, the account hit the lockout threshold and was locked; the lockout-triggering source is DESKTOP-FB001.
4. At 08:07:45, jsmith tried to unlock the workstation (Logon Type 7), but this failed because the account was already locked.
5. At 08:22:10, helpdesk-admin performed an administrative action (account enabled) to restore access state.
6. At 08:23:44, jsmith successfully signed in interactively.

## Most Likely Cause of Lockout
The most likely cause is **repeated incorrect password entry by the user at the local workstation**, which triggered account lockout policy.

### Evidence Supporting This Cause
- Two consecutive **4625** failures with reason **Unknown username or bad password** at 08:02:14 and 08:04:22.
- **4740** lockout shortly after (08:06:01), sourced from the same endpoint (**DESKTOP-FB001**) where failures occurred.
- Post-lockout **4625** at 08:07:45 shows failure reason **Account locked out**, confirming policy enforcement after prior failures.
- No evidence in the provided window of another source host or service repeatedly attempting credentials.

## 5 Whys Analysis

### Problem Statement
User jsmith was locked out and unable to access their workstation.

1. **Why was jsmith locked out?**
   - Because the account exceeded the allowed failed authentication attempts.
2. **Why were there multiple failed authentication attempts?**
   - Incorrect credentials were entered during interactive sign-in attempts.
3. **Why were incorrect credentials entered repeatedly?**
   - The user likely used an outdated/incorrect password or made repeated entry mistakes without successful reset/verification first.
4. **Why did repeated attempts immediately result in access disruption?**
   - The account lockout policy correctly enforced security controls after threshold breach.
5. **Why did restoration require helpdesk intervention?**
   - The user lacked self-service recovery path (or did not use one), so administrative action was needed to re-enable access.

## Root Cause
**Primary root cause:** repeated bad password entry for account jsmith on DESKTOP-FB001.

**Contributing factors:**
- Account lockout policy threshold reached quickly after repeated failed attempts.
- Dependence on helpdesk for recovery extended user downtime.

## Corrective Actions Taken
- Helpdesk administrative remediation performed at 08:22:10 (Event 4722 by FINBRIDGE\\helpdesk-admin).
- User successfully logged on at 08:23:44 (Event 4624).

## Preventive Actions (Recommended)
1. Enable or reinforce user self-service password reset and account unlock workflow.
2. Provide user guidance: after 1-2 failed attempts, verify credential state before retrying repeatedly.
3. Add lockout alerting to service desk with source host context from Event 4740 for faster triage.
4. Review lockout threshold and observation window balance to reduce avoidable lockouts while maintaining security.
5. If recurring for this user, investigate cached credentials on endpoint apps/services (though not evidenced in this specific window).

## Timeline Table
| Time | Event ID | Outcome | Key Detail |
|---|---:|---|---|
| 08:02:14 | 4625 | Failed logon | Bad credentials; Source DESKTOP-FB001; Type 2 |
| 08:04:22 | 4625 | Failed logon | Bad credentials; Source DESKTOP-FB001; Type 2 |
| 08:06:01 | 4740 | Account lockout | Lockout called from DESKTOP-FB001 |
| 08:07:45 | 4625 | Failed unlock | Reason: Account locked out; Type 7 |
| 08:22:10 | 4722 | Admin remediation | Account enabled by FINBRIDGE\\helpdesk-admin |
| 08:23:44 | 4624 | Successful logon | Interactive sign-in succeeded; Type 2 |

## RCA Confidence
- **Confidence level:** High (based on direct chronological consistency across 4625 -> 4740 -> post-lockout 4625 -> admin action -> 4624 success).
- **Data limitations:** Only provided events within the 30-minute slice were analyzed; no domain controller-side correlation logs were provided in this prompt.
