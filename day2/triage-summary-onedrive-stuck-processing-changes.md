# Triage Summary — T-1007: OneDrive Stuck 'Processing Changes' After Migration; Files Missing Locally

## Summary
OneDrive has been stuck on 'processing changes' since a migration event and locally expected files are not visible on the device.

---

## Impact
- **Who:** Single user (scope of migration not yet confirmed — to-verify)
- **How many:** 1 user confirmed; if this is a batch migration, other users may be silently affected — to-verify
- **Business urgency:** High — files are not accessible locally, which may block work if the user cannot reach them via the web client either

---

## Known Facts
- OneDrive status has been 'processing changes' since the migration
- Files are missing locally (not just unsynced — reported as missing)
- Issue is directly correlated with a migration event
- OneDrive appears to be running (status visible) rather than crashed

---

## Missing Information to Gather
1. Are the files visible when the user logs into OneDrive via a web browser? — to-verify (critical: determines if data is present but unsync'd, or potentially lost)
2. What type of migration was this? (e.g., SharePoint tenant move, personal OneDrive to business, storage restructure) — to-verify
3. How long ago did the migration complete, and was the user notified it finished successfully?
4. Is OneDrive signed in with the correct account post-migration? Check the account shown in the OneDrive system tray icon
5. Is Files On-Demand enabled? If so, files may exist in the cloud but not downloaded locally — to-verify
6. Are there any sync errors shown in the OneDrive activity centre (right-click tray icon > View sync activity)?
7. Was the local OneDrive folder path changed or re-pointed during the migration? — to-verify

---

## Likely Category
**Endpoint / Cloud Storage — OneDrive Sync / Post-Migration**
Secondary possibility: account re-authentication required after tenant change (to-verify)

---

## First Diagnostic Step
Confirm file existence before any other action — ask the user to open **OneDrive on the web** (browser, sign in with work account) and check whether the files are present there.

- If files are present in the web client: data is safe; the issue is a sync/local cache problem — proceed to check OneDrive sync errors and account sign-in state on the device
- If files are not present in the web client: this is a potential data loss situation — stop, do not attempt local fixes, and escalate immediately to the migration team or storage owner with the ticket reference
- Do not share file names, user identifiers, or folder paths containing PII when escalating externally

---

*Triage produced: 2026-08-04 | Analyst review required before action*
