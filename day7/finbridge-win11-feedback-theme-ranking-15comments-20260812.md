# FinBridge Win11 Migration — Feedback Theme Ranking (15-Comment Sample)
Date: 2026-08-12
Analyst: DWP Endpoint Engineering
Source: 15 post-migration comments, FinBridge staff

---

## Ranking Methodology

Themes were weighted by **impact first, volume second**.
A single Blocker outranks any number of Minor or Positive issues.
Where multiple themes share the same severity (all Blockers here), volume and persistence broke the tie.

---

## Top 3 Themes to Act on Today

---

### Rank 1 — Credentials Vault Inaccessible
**Count:** 3 comments | **Severity:** Blocker

**Why it ranks first:**
Highest volume among the Blocker themes. The issue has persisted for at least three days, affects the whole team (not a single user), and has already been escalated to management — all signals of an unresolved, widening outage rather than a one-off fault.

**Manager summary:**
Three staff members report the shared credentials vault has been completely inaccessible for multiple days, the entire team is blocked, and the issue has been escalated — this needs P1 treatment and an owner assigned today.

---

### Rank 2 — Admin Console Lockouts
**Count:** 2 comments | **Severity:** Blocker

**Why it ranks second:**
Tied on volume with Rank 3, but the language in comments shifts from individual ("second engineer") to collective ("whole team now"), indicating the blast radius is growing. A widening admin lockout is an escalation risk.

**Manager summary:**
Admin console lockouts have spread from a single engineer to the whole team this week, and if left unresolved will prevent any privileged operations across the FinBridge estate.

---

### Rank 3 — Test VM Access Failure
**Count:** 2 comments | **Severity:** Blocker

**Why it ranks third:**
Equal volume to Rank 2 but scoped to individual engineers rather than a team-wide lockout. Both affected users are completely unable to perform their role, making this a Blocker — it is ranked below Admin Console Lockouts only because the scope appears more contained.

**Manager summary:**
Two engineers have been unable to remote into their test VMs since the Win11 update and cannot work, so we need to determine whether this is a policy change, network ACL issue, or Hyper-V compatibility problem before the end of today.

---

## Themes Not in Top 3

| Theme | Count | Severity | Reason not ranked |
|---|---|---|---|
| Minor UI and UX Annoyances | 4 | Minor | No work stoppage; cosmetic/low impact |
| Positive Experience / No Issues | 4 | Positive | No action required |
