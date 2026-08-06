# Triage Summary – AVD Session Disconnects After ~10 Minutes, Then Reconnects

**Date logged:** 2026-08-04
**Ticket:** T-1003

---

## Summary
User's Azure Virtual Desktop (AVD) session disconnects after roughly 10 minutes of use, then automatically reconnects.

---

## Impact
- **Who affected:** 1 end user reporting (USER_A) – to-verify whether other AVD users on the same host pool/session host are also affected
- **How many:** Individual report; wider scope across host pool unknown at this stage – to-verify
- **Business urgency:** Potentially high – repeated disconnects during a session can interrupt active work and cause unsaved data loss depending on the application in use; actual urgency depends on user's role and what work is disrupted – to-verify against business criticality

---

## Known Facts
- Session is on Azure Virtual Desktop (AVD)
- Disconnect occurs consistently at approximately 10 minutes into the session – to-verify exact/consistent timing
- Session reconnects automatically after the disconnect
- No error code or on-screen message has been reported – to-verify
- Ticket does not state the client device type (thin client, laptop, home PC) used to connect – to-verify
- Ticket does not state network type (corporate LAN, VPN, home broadband) – to-verify

---

## Missing Information to Gather
- Client device type and OS used to connect to AVD (DEVICE_01) – to-verify
- Connection method: AVD client app, web client, or RemoteApp – to-verify
- Network path: on DWP network, VPN, or external/home internet – to-verify
- Exact wording of any disconnect/reconnect message shown, if any (do not assume specific error text)
- Whether the ~10 minute timing is exact and repeatable every time, or approximate/variable
- Whether this happens on every session or intermittently
- Whether other users on the same host pool or session host are experiencing the same pattern
- Whether the issue started recently or has always occurred (e.g. after a recent update, policy change, or network change) – to-verify
- Whether the user is idle or actively working when the disconnect occurs
- Session host pool name/region (internal reference only, via approved tooling – not to be shared with public AI)
- Whether multi-factor authentication (MFA) re-prompts occur at reconnect – to-verify

---

## Likely Category
**Virtual Desktop Infrastructure (VDI) / Azure Virtual Desktop – Session Connectivity**
Sub-category: Possible session timeout, network/gateway interruption, or idle/token-related reconnect (to confirm root cause) – to-verify

---

## Suggested First Diagnostic Step
Using approved internal monitoring/tooling (not public AI), check the AVD diagnostics/connection logs for this user's session to identify whether the disconnect originates from the client network path, the gateway, or the session host; do not ask the user to share session logs, IP addresses, or device identifiers through any public or unapproved channel.
