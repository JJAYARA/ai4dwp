# FinBridge Service Desk - Root Cause Analysis (RCA)

Incident: Floor 3 Finance Windows 11 machines unable to process Group Policy
Date of incident: 2026-08-07
RCA prepared: 2026-08-07
Analyst role: DWP Engineer

## 1) Executive Summary

Between approximately 07:40 and 07:55 on 2026-08-07, three Windows 11 machines on Floor 3 in OU=Finance were unable to process Group Policy. The symptom presented as no Group Policy update/processing on the affected endpoints.

Event evidence on the affected machine shows a consistent failure chain: Netlogon Event 5719 reported that the secure channel could not be established because no domain controller was available; GroupPolicy Event 1058 then failed because the policy path on `FINBRIDGE-DC01` could not be accessed; GroupPolicy Event 1030 could not query the list of GPOs; and GroupPolicy Event 1129 confirmed no network connectivity to a domain controller. DNS Client Event 1014 later showed name resolution for `FINBRIDGE-DC01.finbridge.local` timed out.

DHCP comparison evidence showed the affected Floor 3 machine received DNS server `10.10.3.250`, which was the old decommissioned Floor 3 local DNS server. The unaffected control machine in the same OU, DESKTOP-FB029, received the correct DNS server `10.10.0.10` and processed Group Policy successfully. DHCP server logs also showed Floor 3 subnets FB055-057 still pointed to `172.16.5.5` (old decommissioned local DNS), while FB058 had already been manually set to `10.10.0.10` and remained unaffected.

The corrective resolution was to update the Floor 3 DHCP scope to remove the decommissioned DNS server and advertise the correct central DNS server only. After the change, DHCP leases were renewed and Group Policy updates were verified as working. Incident is resolved.

## 2) Scope and Business Impact

- Affected scope: three Windows 11 machines on Floor 3 in OU=Finance.
- Unaffected scope: one Finance machine, DESKTOP-FB029, processed Group Policy successfully.
- User impact: the affected machines were unable to receive or update Group Policy during the incident window.
- Business impact: policy refreshes, logon policy application, and domain-dependent configuration were interrupted for the impacted endpoints.

## 3) Supporting Evidence

### 3.1 Affected Machine Evidence - DESKTOP-FB031

- 07:40:02 - Service Control Manager Event 7036
  - The Network Location Awareness service entered running state.

- 07:40:08 - Netlogon Event 5719, Level: Error
  - This computer was unable to set up a secure channel to domain FINBRIDGE.
  - No domain controller available.
  - DNS query for `FINBRIDGE-DC01.finbridge.local` returned no response.

- 07:40:09 - GroupPolicy Event 1058, Level: Error
  - Group Policy processing failed.
  - Cannot access `\\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini`.
  - Error code: 0x3 (The system cannot find the path specified).

- 07:40:10 - GroupPolicy Event 1030, Level: Warning
  - Cannot query list of Group Policy objects.
  - Error code: 0x546.

- 07:40:11 - GroupPolicy Event 1058, Level: Error
  - Group Policy processing failed again for the same policy path.

- 07:40:12 - GroupPolicy Event 1129, Level: Error
  - Group Policy failed - no network connectivity to a domain controller.
  - A success message would be generated once connectivity was restored.

- 07:41:05 - DNS Client Event 1014, Level: Warning
  - Name resolution for `FINBRIDGE-DC01.finbridge.local` timed out.
  - None of the configured DNS servers responded.

- 07:42:18 - DHCP Client Event 50036, Level: Information
  - IP address `10.10.3.144` leased from server `10.10.0.1`.
  - DNS servers assigned by DHCP: `10.10.3.250`.
  - Note: `10.10.3.250` was the old DNS server and had been decommissioned overnight.

- 07:44:01 - GroupPolicy Event 1129, Level: Error
  - Group Policy processing failed again - no DC connectivity.

### 3.2 Comparison Machine Evidence - DESKTOP-FB029

- 07:40:05 - DHCP Client Event 50036
  - DNS servers assigned: `10.10.0.10`.
  - Note: this was the correct new DNS server and the machine had been manually reconfigured before the migration wave.

- 07:40:11 - GroupPolicy Event 1500, Level: Information
  - Group Policy settings processed successfully.

### 3.3 DHCP Server Log Evidence

- FB055-057 DNS assigned: `172.16.5.5`.
  - Note: Floor 3 local DNS, decommissioned overnight on 2024-03-14.

- FB058 DNS: `10.10.0.10`.
  - Note: Central DNS, correct, and manually set before migration.

### 3.4 Evidence Summary

- Affected machine evidence shows failure at the DC discovery and SYSVOL access layers.
- DHCP evidence shows the affected Floor 3 subnet still referenced decommissioned DNS infrastructure.
- The control machine in the same OU succeeded when using the correct DNS server.

## 4) Timeline (All times local)

- 07:40:02 - Network Location Awareness service enters running state on DESKTOP-FB031.
- 07:40:08 - Netlogon Event 5719 reports no domain controller available and secure channel setup failure.
- 07:40:09 - GroupPolicy Event 1058 reports SYSVOL/GPT.INI path access failure.
- 07:40:10 - GroupPolicy Event 1030 reports it cannot query GPO list.
- 07:40:11 - GroupPolicy Event 1058 repeats for the same policy path.
- 07:40:12 - GroupPolicy Event 1129 reports no DC connectivity.
- 07:41:05 - DNS Client Event 1014 times out resolving `FINBRIDGE-DC01.finbridge.local`.
- 07:42:18 - DHCP Client Event 50036 assigns old DNS server `10.10.3.250` to the affected machine.
- 07:44:01 - GroupPolicy Event 1129 repeats on the affected machine.
- 07:40:05 - DESKTOP-FB029 receives correct DNS server `10.10.0.10`.
- 07:40:11 - DESKTOP-FB029 processes Group Policy successfully.
- During triage - DHCP comparison confirms Floor 3 scope still points to the old DNS server.
- Resolution window - Floor 3 DHCP scope corrected and affected leases renewed.
- Verification - Group Policy updates confirmed working after remediation.

## 5) Hypothesis Elimination Outcome

The following hypotheses were evaluated against the evidence:

1. Floor 3 network path to domain controllers or SYSVOL is degraded: supported.
2. OU=Finance policy scope problem, such as blocked link/security filter/WMI filter: contradicted.
3. SYSVOL or DFSR inconsistency on one domain controller: contradicted.
4. Windows 11 Group Policy client-side processing failure on the affected build cohort: contradicted.
5. Local DNS, time, or secure channel drift on the affected machines: supported.

Surviving technical hypothesis and final root cause direction:

- Floor 3 DHCP scope still advertised the old DNS server, causing the affected Windows 11 machines to lose DC discovery, secure channel setup, and SYSVOL access.

## 6) 5-Why Analysis

Problem statement: Three Windows 11 machines on Floor 3 could not process Group Policy.

Why 1: Why could the affected machines not process Group Policy?
- Because they could not reliably reach a domain controller or access SYSVOL/GPT.INI.

Why 2: Why could they not reach the domain controller or SYSVOL?
- Because DNS name resolution for `FINBRIDGE-DC01.finbridge.local` timed out and no configured DNS servers responded.

Why 3: Why did DNS resolution fail on the affected Floor 3 machines?
- Because DHCP assigned the old decommissioned DNS server `10.10.3.250` instead of the correct central DNS server `10.10.0.10`.

Why 4: Why was the old DNS server still being assigned?
- Because the Floor 3 DHCP scope had not been updated after the DNS migration/decommissioning change.

Why 5: Why did the problem affect only part of the Finance estate?
- Because one Finance machine, DESKTOP-FB029, had already been manually reconfigured to the correct DNS server `10.10.0.10`, while the affected Floor 3 machines continued using the outdated DHCP-provided DNS settings.

Root cause:
- Floor 3 DHCP scope still referenced the old DNS server, causing affected Windows 11 machines to fail DC discovery, secure channel establishment, and SYSVOL access, which prevented Group Policy processing.

## 7) Resolution Actions Executed

1. Incident containment
- Identified that the issue was tied to the Floor 3 DHCP/DNS path rather than an OU-wide GPO configuration problem.
- Used the unaffected Finance machine as a control to verify that Group Policy could still process normally with correct DNS settings.

2. Corrective remediation
- Updated the Floor 3 DHCP scope to remove the old DNS server `172.16.5.5` / `10.10.3.250`.
- Configured the scope to advertise the correct central DNS server `10.10.0.10` only.
- Renewed DHCP leases on affected machines so they received the corrected DNS configuration.

3. Validation
- Verified that Group Policy updates were getting applied after the DNS/DHCP correction.
- Confirmed the issue was resolved and no additional Group Policy failures were reported after remediation.

## 8) Preventive and Corrective Action Plan (CAPA)

### 8.1 Immediate Corrective Controls

- Audit all Floor 3 DHCP scopes to ensure only current DNS servers are advertised.
- Remove any remaining references to decommissioned DNS infrastructure from DHCP options.
- Confirm that all Finance endpoints point to the approved DNS server list.

### 8.2 Preventive Engineering Controls

- Add a DHCP migration validation step to every DNS cutover or decommissioning change.
- Require post-change verification that all subnet scopes have the correct DNS options before sign-off.
- Maintain a control machine in each critical OU/subnet to validate Group Policy and DNS behavior after network service changes.

### 8.3 Monitoring and Alerting

- Add monitoring for GroupPolicy Event 1058, 1030, and 1129 bursts tied to DNS failures.
- Alert when Netlogon Event 5719 appears with DNS resolution failure to a known DC.
- Track DHCP scope configuration drift against approved DNS server inventory.

### 8.4 Process Improvements

- Update the DNS/DHCP change checklist to include verification of all downstream scopes after DNS server decommissioning.
- Require a comparison test between one affected endpoint and one known-good endpoint during validation.
- Document the dependency between DHCP DNS settings, DC discovery, secure channel health, and Group Policy processing.

## 9) Closure Statement

The incident was resolved after the Floor 3 DHCP scope was corrected to advertise the proper DNS server and affected clients renewed their leases. Verification confirmed that Group Policy was updating successfully again. The evidence supports DHCP-supplied stale DNS settings as the root cause of the Group Policy failure on the affected Floor 3 Windows 11 machines.

## 10) Evidence References

- Affected machine event log extract: DESKTOP-FB031, 07:40-07:55, System, DNS Client, DHCP Client, and GroupPolicy logs.
- Comparison machine event log extract: DESKTOP-FB029, same window, same OU, correct DNS configuration.
- DHCP server log comparison for Floor 3 subnet and Finance control host.
- Initial hypothesis and elimination note: day4/gp-policy-failure-floor3-finance-hypothesis-20260807.md.