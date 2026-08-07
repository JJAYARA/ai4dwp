# FinBridge Service Desk - Incident Communication

Incident: Floor 3 Finance Windows 11 Group Policy failure
Prepared: 2026-08-07

## Audience 1 - Non-technical Executive

Access and data are safe. Three Floor 3 Finance computers could not get their settings updated because they were given an old network address. We corrected the Floor 3 network settings, refreshed the affected computers, and confirmed the settings are updating again. No action is needed.

## Audience 2 - Affected End-User Team (10 people, non-technical)

Quick update: access and data are safe. Three Floor 3 Finance computers could not get their settings updated because the network was giving them an old address for the service they use to reach the company server. We fixed the Floor 3 network settings, refreshed the affected computers, and confirmed the settings are updating again. If you see the same issue, contact the Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note

Summary:
- Scope: 3 of 4 Windows 11 Finance machines on Floor 3 were unable to process Group Policy.
- Impact window: 07:40-07:55 on 2026-08-07.

Root cause:
- Floor 3 DHCP scope still referenced the old decommissioned DNS server, so affected clients received stale DNS and could not reliably reach the domain controller or SYSVOL.

Supporting evidence and config detail:
- DESKTOP-FB031:
  - 07:40:08 Netlogon Event 5719: secure channel setup failed; no domain controller available.
  - 07:40:09 GroupPolicy Event 1058: cannot access `\\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini`, error 0x3.
  - 07:40:10 GroupPolicy Event 1030: cannot query GPO list.
  - 07:40:12 GroupPolicy Event 1129: no network connectivity to a domain controller.
  - 07:41:05 DNS Client Event 1014: name resolution for `FINBRIDGE-DC01.finbridge.local` timed out.
  - 07:42:18 DHCP Client Event 50036: DNS server `10.10.3.250` assigned; this was the old decommissioned DNS server.
- Comparison host DESKTOP-FB029:
  - 07:40:05 DHCP Client Event 50036: DNS server `10.10.0.10` assigned.
  - 07:40:11 GroupPolicy Event 1500: Group Policy settings processed successfully.
- DHCP server log comparison:
  - FB055-057 DNS assigned: `172.16.5.5` (Floor 3 local DNS, decommissioned 2024-03-14 overnight).
  - FB058 DNS: `10.10.0.10` (central DNS, manually set before migration).

Exact action taken:
- Corrected the Floor 3 DHCP scope to remove the decommissioned DNS server and advertise `10.10.0.10` only.
- Renewed DHCP leases on the affected machines.

Verification step:
- Group Policy updates were confirmed to be applying after remediation.
- The unaffected Finance control machine remained healthy with correct DNS settings.

Preventive action required:
- Add a mandatory DNS/DHCP validation step to every DNS migration or decommissioning change.
- Verify every subnet scope before sign-off and compare one affected endpoint with one known-good endpoint after the change.
- Track DHCP scope drift against approved DNS server inventory and alert on reintroduction of deprecated DNS values.