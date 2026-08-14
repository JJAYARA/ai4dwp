# Floor 6 Login Delays – Issue Summary & Resolution

**Date:** 14 August 2026  
**Status:** Resolved  
**Affected Users:** Floor 6 team (approximately 12+ staff)

---

## What Happened

Starting Monday morning, Floor 6 staff experienced unusually slow login times when arriving at their desks. Some users reported their computers took 3–5 minutes to load their desktop and become ready to work, when it normally takes under 1 minute.

---

## Why It Happened

On Friday afternoon, IT rolled out a new document-management app to Floor 6 as part of a software update. During the installation, the app was configured to launch automatically every time a user logs in—similar to how your computer's security software or email might start when you turn it on.

The problem: this app was set to launch *before* Windows finished loading the rest of the user's profile (files, settings, and other programs). This caused a traffic jam—the app consumed computer resources and made everything else wait, including the login process itself.

**The result:** users couldn't access their desks or start work until the app finished launching, adding several minutes to their morning.

---

## Business Impact

- **12+ staff members** on Floor 6 unable to start work on time Monday morning
- **3–5 minute delays** per login, multiplied across the team ≈ **1+ hour of lost productivity** that morning
- **Secondary concern:** One user reported the new app surfaced a client file they shouldn't have access to (being investigated separately by Security)
- **Reputation:** Delays like this erode team confidence in IT reliability

---

## What We Did

**Immediate action (same day):**
1. Identified the root cause: the document-management app launching too early in the login sequence
2. Removed the app from the automatic startup path on affected computers
3. Disabled the scheduled task that was triggering the app at login
4. Restarted affected computers

**Result:** login times returned to normal (under 1 minute)

---

## How to Prevent This in Future

- **Better testing before rollout:** Test new apps on a small pilot group first, on a Friday afternoon *and* measure login speed on the following Monday morning before rolling out company-wide
- **Vendor coordination:** Require software vendors to confirm their apps do *not* launch during login, or if they must, that they don't block Windows from finishing its own startup first
- **Monitoring:** Add a check to our rollout process that flags apps that interfere with login speed, to catch this before it reaches the full Floor 6 team

---

## Next Steps

- **Today:** Confirm all Floor 6 users can log in at normal speed
- **This week:** Review the document-management app settings with the vendor to ensure it launches *after* Windows is ready, not during login
- **Security team:** Complete investigation into the Copilot client-access concern in parallel

---

## Key Takeaway

A well-intentioned software update created an unintended side effect—a startup conflict that slowed everyone down. We've fixed it immediately by changing when the app launches. Going forward, we'll test new apps more thoroughly before rolling them out to avoid similar delays in the future.

**Questions?** Contact IT.
