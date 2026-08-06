# Triage Summary – BitLocker Recovery Key Prompt on Every Boot

**Date logged:** 2026-08-04
**Ticket:** T-1001

---

## Summary
New Win11 laptop prompts for BitLocker recovery key on every boot.

---

## Impact
- **Who affected:** 1 end user (name to confirm – to-verify)
- **How many:** Individual report; wider impact across other new-build devices unknown at this stage – to-verify
- **Business urgency:** High – device is new and user cannot reliably start work if recovery key is unavailable or unknown; risk of user being locked out entirely if key is not recorded anywhere – to-verify against user's actual role/deadline criticality

---

## Known Facts
- Device is a new Windows 11 laptop
- BitLocker is prompting for the recovery key at every boot (not a one-off event)
- No error code has been reported – to-verify
- Ticket does not state when the laptop was issued or first used – to-verify
- Ticket does not state whether the user has successfully entered the recovery key before – to-verify

---

## Missing Information to Gather
- User's full name, staff ID, and department – to-verify
- Exact date/time the laptop was issued and when the prompting first started
- Whether this is the very first boot after provisioning, or started after a period of normal use
- Whether the user (or IT) has the recovery key already stored (e.g. in Azure AD/Intune, Active Directory, or a printed record) – to-verify
- Exact wording of the prompt/screen shown (screenshot if possible) – do not assume specific error text
- Whether any hardware changes were made recently (docking station, external drives, BIOS/UEFI settings, TPM changes) – to-verify
- Whether a firmware/BIOS update, Windows update, or Secure Boot/TPM setting change occurred before the prompting started – to-verify
- Whether other new-build Win11 laptops from the same batch/image are showing the same behaviour
- Device asset tag/serial number for tracking
- Whether the device is fully managed by Intune/Autopilot or was built another way – to-verify

---

## Likely Category
**Endpoint Security / Disk Encryption (BitLocker)**
Sub-category: Recovery key / TPM binding issue on new device build (to confirm root cause)

---

## Suggested First Diagnostic Step
Confirm whether the recovery key is already escrowed and retrievable via the approved internal tooling (e.g. Intune/Azure AD device record) before asking the user for any details, so the device can be unblocked safely; do not ask the user to share the recovery key or any device identifiers through any public or unapproved channel.
