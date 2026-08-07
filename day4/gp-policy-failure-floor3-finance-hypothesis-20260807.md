# Group Policy Incident Analysis and Hypotheses

Logged: 2026-08-07
Analyst role: DWP Engineer

## Scope Facts Used

- Symptom: no Group Policy.
- Who: three Windows 11 machines on Floor 3.
- Scope: 3 of 4 machines in OU=Finance affected.
- Since: between 07:40 and 07:55 this morning.
- Change: nil.

## Ranked Top 5 Causes

Most probable first. These are hypotheses only; no final cause is being committed yet.

1. Floor 3 network path to domain controllers or SYSVOL is degraded
	- Why this fits the scope facts: The impact clusters on a physical location, which is the strongest hint of a shared network path problem rather than a random client-only defect. If Floor 3 machines cannot consistently reach a DC, DFS, or SYSVOL share, Group Policy processing will fail or stall for those endpoints together.
	- Fastest single check: From one affected Floor 3 machine, verify DC discovery and SYSVOL access in one shot by testing `nltest /dsgetdc:<domain>` and opening `\\<dc>\SYSVOL`.

2. OU=Finance policy scope problem, such as a blocked link, security filter, or WMI filter
	- Why this fits the scope facts: Three of four machines in the same OU are affected, which strongly suggests something at OU scope rather than a purely random endpoint issue. A single machine escaping the symptom can happen if it is nested differently, has a different filter result, or inherits a different policy path.
	- Fastest single check: Compare the Resultant Set of Policy on one affected and the unaffected Finance machine, focusing on linked GPOs, security filtering, and WMI filter evaluation.

3. SYSVOL or DFSR inconsistency on one domain controller
	- Why this fits the scope facts: If one DC has stale or missing policy content, machines that hit that DC may lose Group Policy while others remain healthy. The timing window and partial scope fit a DC/content divergence better than a broad change event.
	- Fastest single check: Compare the affected GPO version and file presence on two different DCs, then force the affected machine to use an alternate DC and retest Group Policy.

4. Windows 11 Group Policy client-side processing failure on the affected build cohort
	- Why this fits the scope facts: The symptom is limited to Windows 11 machines, so a client-side processing regression or broken CSE path remains plausible. The fact that not all Finance machines are affected keeps this lower than a shared network or scope issue, but still viable if the common denominator is a specific Win11 build or configuration.
	- Fastest single check: Run `gpupdate /force` on one affected and one unaffected Windows 11 machine, then inspect the GroupPolicy operational log for a client-side extension or processing error.

5. Local DNS, time, or secure channel drift on the affected machines
	- Why this fits the scope facts: A small cluster of machines failing to process Group Policy can come from bad name resolution, time skew, or a broken secure channel. This would fit a subset of Windows 11 devices without requiring a broader change, but it is less explanatory than the shared location or OU clues.
	- Fastest single check: On one affected machine, test DNS/DC lookup and secure channel health with `ipconfig /all`, `w32tm /query /status`, and `Test-ComputerSecureChannel`.

## Working Hypothesis

The leading hypothesis is a shared dependency problem affecting the Floor 3 Windows 11 machines, with OU-level scope or DC/SYSVOL reachability as the next most likely alternatives. The current facts are not enough to commit to a single root cause.

## Next Best Triage Order

1. Confirm whether the affected machines share the same DC, subnet, or switch path.
2. Compare resultant policy on the affected and unaffected Finance machine.
3. Check SYSVOL access and Group Policy operational events on one affected endpoint.

## Addendum - Event Details Reviewed

### Confirmed Event Pattern

- 07:40:08 - Netlogon Event 5719: secure channel could not be set up because no domain controller was available.
- 07:40:09 - GroupPolicy Event 1058: Group Policy processing failed because `\\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini` could not be accessed.
- 07:40:10 - GroupPolicy Event 1030: cannot query list of Group Policy objects.
- 07:40:12 - GroupPolicy Event 1129: Group Policy failed due to no network connectivity to a domain controller.
- 07:41:05 - DNS Client Event 1014: name resolution for `FINBRIDGE-DC01.finbridge.local` timed out because none of the configured DNS servers responded.
- 07:42:18 - DHCP Client Event 50036: affected machine received DNS server `10.10.3.250`, which was the old decommissioned DNS server.
- 07:40:11 - GroupPolicy Event 1500 on DESKTOP-FB029: Group Policy settings processed successfully on the unaffected Finance control machine.

### Surviving Hypothesis

- Floor 3 DHCP scope still advertised the old DNS server, causing the affected Windows 11 machines to lose DC discovery, secure channel setup, and SYSVOL access.

### Resolution

1. Update the Floor 3 DHCP scope to remove the decommissioned DNS server and advertise `10.10.0.10` only.
2. Renew DHCP leases on the affected machines so they receive the corrected DNS configuration.
3. Clear stale DNS state on the affected endpoints and retest `FINBRIDGE-DC01.finbridge.local` resolution.
4. Verify secure channel restoration to the domain.
5. Run Group Policy refresh again and confirm success.
6. Validate the unaffected Finance machine remains healthy as a control after the DNS correction.
