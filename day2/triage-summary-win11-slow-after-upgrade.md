# Triage Summary — T-1006: Everything Is Slow After Win11 Upgrade

## Summary
User reports general system slowness following a Win11 upgrade performed two days ago.

---

## Impact
- **Who:** Single user (one device confirmed)
- **How many:** 1 user affected
- **Business urgency:** Medium — user productivity is degraded but the device is functional; urgency increases if the role is time-critical or the issue is appearing across multiple upgraded devices

---

## Known Facts
- Slowness began after a Windows 11 upgrade approximately two days ago
- Issue is general ("everything") rather than app-specific
- Timing strongly correlates the fault with the OS upgrade

---

## Missing Information to Gather
1. What is the device model, RAM, and storage type (SSD or HDD)? — to-verify (Win11 hardware demands may expose marginal specs)
2. Is Task Manager showing consistently high CPU, RAM, or disk usage at idle? If so, which processes?
3. Is Windows still completing post-upgrade background tasks (indexing, optimisation, update installation)? — to-verify
4. Were any DWP-managed applications, drivers, or security agents re-pushed after the upgrade? — to-verify
5. Is the user profile new or migrated from Win10? Profile rebuild can cause prolonged background activity — to-verify
6. Has a full reboot been performed since the upgrade completed?
7. Are other users who upgraded at the same time reporting the same symptoms? — to-verify

---

## Likely Category
**Endpoint — OS Upgrade / Performance**
Secondary possibility: driver compatibility issue or security agent conflict post-upgrade (to-verify)

---

## First Diagnostic Step
Ask the user to open **Task Manager** (`Ctrl+Shift+Esc`) > **Performance** tab and report CPU, Memory, and Disk utilisation at idle.

- If Disk is at or near 100%: likely Windows Search indexing or SysMain (Superfetch) completing post-upgrade tasks; monitor for 24–48 hours before further intervention
- If CPU or Memory is consistently high: go to **Processes** tab, sort by resource usage, and identify the top consumer — check whether it is a DWP-managed agent or a Windows service
- If all metrics are normal: investigate display driver compatibility or power plan settings which can regress to default after an upgrade — to-verify

---

*Triage produced: 2026-08-04 | Analyst review required before action*
