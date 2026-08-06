# Triage Summary — T-1005: Teams Audio Dead on Three Meeting Room Machines

## Summary
Teams audio is non-functional on three devices located in the same meeting room, affecting the ability to hold or join audio calls.

---

## Impact
- **Who:** Users assigned to or using the affected meeting room
- **How many:** Three devices confirmed; number of affected users depends on room booking frequency (to-verify)
- **Business urgency:** Medium-High — meeting room audio loss blocks collaboration and remote calls; impact scales with how frequently the room is booked

---

## Known Facts
- Fault is isolated to three machines in the same physical meeting room
- Audio failure is specific to Teams (scope of other apps not yet confirmed — to-verify)
- All three devices are affected simultaneously, suggesting a shared cause (room-level hardware, policy, or update)
- No user-specific account fault as multiple devices are affected

---

## Missing Information to Gather
1. Is audio also broken outside of Teams (e.g., system sounds, other apps)? — to-verify
2. When did this start? Was there a recent Windows Update, Teams update, or any room hardware change?
3. Are the devices joined to the same physical audio hardware (e.g., shared speakerphone, HDMI audio device, USB hub)? — to-verify
4. Is the audio device showing in Teams Settings > Devices on each machine, or is it missing entirely? — to-verify
5. Are all three machines the same model/build? — to-verify
6. Is the Teams app desktop client or web browser version? — to-verify
7. Has a reboot been attempted on any of the three devices?

---

## Likely Category
**Endpoint / Collaboration — Teams Audio / Peripheral Device**
Secondary possibility: Windows audio driver or policy issue (to-verify)

---

## First Diagnostic Step
On one of the affected machines, open **Teams Settings > Devices** and check whether an audio output and microphone device are listed and selected.

- If no device is shown: the issue is at the OS/driver or hardware layer — check Device Manager for audio devices with errors
- If a device is shown but audio still fails: test audio outside Teams (e.g., play a system sound via Settings > Sound) to isolate whether this is Teams-specific or OS-level
- Do not share device hostnames, user details, or internal config data when escalating or using external tools — per DWP AI usage charter, sanitize all identifiers before any further analysis

---

*Triage produced: 2026-08-04 | Analyst review required before action*
