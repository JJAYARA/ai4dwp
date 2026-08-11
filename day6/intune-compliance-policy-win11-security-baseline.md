# Intune Compliance Policy – Windows 11 Security Baseline
**Author:** DWP Endpoint Engineer  
**Date:** 2026-08-11  
**Scope:** Windows 11 managed devices enrolled in Microsoft Intune  
**Grace Period:** 7 days applied to all settings  

---

## Overview

This document translates the DWP Windows 11 security baseline requirements into Intune Compliance Policy settings. Each entry provides the exact setting name as it appears in the Intune portal, the required value, the enforcement effect, known false-positive risks, and recommendations to reduce noise without weakening security posture.

> **Policy creation path (Intune portal):**  
> Home → Devices → Compliance → Policies → Create Policy  
> - Platform: **Windows 10 and later**  
> - Profile type: **Windows 10/11 compliance policy**  
>
> **Wizard tabs:** ① Basics → ② Compliance settings → ③ Actions for noncompliance → ④ Assignments → ⑤ Review + create  
> All security settings below are configured on **Tab ② – Compliance settings**.

---

## Requirement 1 – BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Setting name** | Require BitLocker |
| **Intune UI path** | Tab ② Compliance settings → **Device Health** → Require BitLocker |
| **Value** | Require |
| **Grace period** | 7 days |

**Effect:**  
Intune queries the Windows Health Attestation Service (HAS) to confirm that BitLocker Drive Encryption is active on the OS volume. Devices without BitLocker protection are marked non-compliant and can be blocked from conditional access-protected resources (e.g. Exchange Online, SharePoint).

**False-positive risk:**  
- Devices that have BitLocker enabled but the **TPM attestation report has not yet synced** to Intune will temporarily report as non-compliant. This is common on newly enrolled or recently reimaged devices.  
- Devices with a **software-only BitLocker implementation** (no TPM) may not pass HAS attestation even though encryption is present.  
- Virtual machines (e.g. AVD session hosts assessed as physical endpoints) may lack a TPM and fail attestation.

**Recommendation:**  
Apply the 7-day grace period to absorb attestation sync delays post-enrolment. Exclude known VM or AVD host collections via a dynamic AAD group if this policy targets physical endpoints only. Ensure TPM 2.0 is present and enabled in BIOS/UEFI as part of the build standard.

---

## Requirement 2 – Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Setting name** | Require Secure Boot to be enabled on the device |
| **Intune UI path** | Tab ② Compliance settings → **Device Health** → Require Secure Boot to be enabled on the device |
| **Value** | Require |
| **Grace period** | 7 days |

**Effect:**  
Intune uses HAS to confirm the device's firmware is running with Secure Boot active. This prevents bootkits and rootkits from loading before the OS, ensuring only Microsoft-trusted or OEM-signed boot components execute.

**False-positive risk:**  
- **Legacy BIOS / MBR partition scheme** devices cannot support Secure Boot. Older hardware refreshed onto Windows 11 without a full UEFI migration will always fail.  
- Some **custom or developer BIOS configurations** (e.g. test-signed drivers or dual-boot setups) require Secure Boot to be disabled.  
- HAS report latency can cause a transient non-compliant state on first enrolment.

**Recommendation:**  
Confirm all estate hardware was provisioned with UEFI + GPT as part of the Windows 11 rollout. Exclude any legitimate dual-boot or developer devices via a named exclusion group with documented justification. Do not lower this setting — Secure Boot is a Windows 11 hardware prerequisite; its absence indicates a non-standard device.

---

## Requirement 3 – Minimum OS Build (N-1 Policy)

| Field | Detail |
|---|---|
| **Setting name** | Minimum OS version |
| **Intune UI path** | Tab ② Compliance settings → **Device Properties** → Operating System Version → Minimum OS version |
| **Value** | `10.0.22621.2861` |
| **Grace period** | 7 days |

**Effect:**  
Devices running an OS build older than Windows 11 22H2 (build 22621.2861) — the defined N-1 floor — are marked non-compliant. This ensures devices are no more than one cumulative update behind the current known-good release (22621.3155), maintaining a minimum security patch level across the estate.

**False-positive risk:**  
- Devices that have **downloaded but not yet applied** a pending Windows Update (e.g. awaiting reboot) will report the old build and appear non-compliant until restart.  
- **Windows Update for Business deferral rings** with a deferral longer than the patch cycle gap between N and N-1 may cause legitimate managed devices to sit below the threshold temporarily.  
- Devices with a **failed Windows Update** (e.g. due to disk space or driver conflict) will remain non-compliant until the issue is resolved.

**Recommendation:**  
Align WUfB deferral ring settings so that the maximum deferral period does not cause devices to fall below the N-1 floor. Set the **Maximum OS version** field to blank (unrestricted) to avoid flagging devices that have moved ahead to a newer build. Review and update this value each Patch Tuesday when Microsoft publishes a new cumulative update.

> ⚠️ **UI change notice:** The Intune setting format expects the full 5-part build string (e.g. `10.0.22621.2861`). Verify the exact field label in your tenant — Microsoft has periodically renamed OS version fields in the compliance blade. As of mid-2024 the path above was current, but confirm in your live portal.

---

## Requirement 4 – Windows Defender Real-Time Protection Must Be On

| Field | Detail |
|---|---|
| **Setting name** | Require real-time protection |
| **Intune UI path** | Tab ② Compliance settings → **Microsoft Defender Antivirus** → Require real-time protection |
| **Value** | Require |
| **Grace period** | 7 days |

**Effect:**  
Confirms that Microsoft Defender Antivirus real-time protection (RTP) is actively scanning files on access. Devices with RTP disabled — whether by user action, policy conflict, or third-party AV — are marked non-compliant.

**False-positive risk:**  
- Devices running an **approved third-party AV product** (e.g. Sophos, CrowdStrike) may cause Defender to enter passive mode. In passive mode, Defender RTP reports as off, triggering non-compliance even though another AV is actively protecting the device.  
- **Temporary Defender exclusion scripts** run by support staff can briefly disable RTP and leave the device non-compliant until the next compliance check cycle.  
- The compliance check may run between an RTP engine update and its activation, creating a short window of apparent non-compliance.

**Recommendation:**  
If the DWP estate uses a third-party AV alongside Defender, evaluate whether to replace this check with a **Microsoft Defender for Endpoint risk score** compliance setting instead (see Requirement 7 note). If Defender is the primary AV, enforce this setting as-is. Ensure support runbooks do not permanently disable RTP.

---

## Requirement 5 – Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Setting name** | Microsoft Defender Firewall |
| **Intune UI path** | Tab ② Compliance settings → **Microsoft Defender Firewall** → Microsoft Defender Firewall |
| **Value** | Require |
| **Grace period** | 7 days |

**Effect:**  
Enforces that Windows Defender Firewall is enabled across all three network profiles: Domain, Private, and Public. Devices with firewall disabled on any profile are flagged non-compliant.

**False-positive risk:**  
- Devices where a **third-party firewall product is installed and active** may cause the Windows Firewall service to be reported as off, even though network traffic is being filtered.  
- **GPO or legacy SCCM settings** that explicitly disable the Windows Firewall for the Domain profile (a legacy network administration practice) will conflict with this compliance check.  
- The Intune compliance report checks the Windows Security Centre registration, not packet-level filtering — a misconfigured AV/firewall suite that does not register correctly with WSC will appear non-compliant.

**Recommendation:**  
Audit and remove any GPO settings that disable Windows Firewall on the Domain profile. If a third-party firewall is deployed, ensure it registers correctly with the Windows Security Centre API. Do not exempt devices from this requirement — an open firewall profile is a significant lateral movement risk, particularly for Public profile on mobile workers.

---

## Requirement 6 – A PIN or Password Must Be Configured

| Field | Detail |
|---|---|
| **Setting name** | Require a password to unlock mobile devices |
| **Intune UI path** | Tab ② Compliance settings → **System Security** → Require a password to unlock mobile devices |
| **Value** | Require |
| **Grace period** | 7 days |

**Additional supporting settings (recommended to configure alongside):**

| Setting name | Value |
|---|---|
| Simple passwords | Block |
| Minimum password length | 8 |
| Required password type | Alphanumeric (or at minimum Numeric) |
| Password expiration (days) | Per DWP password policy |

> ⚠️ **UI change notice:** On Windows 10/11 desktop compliance policies, the password section may appear under **System Security** rather than a dedicated "Password" section. The label "Require a password to unlock mobile devices" is the legacy label retained from the MDM shared schema — it applies to Windows desktops enrolled in Intune. Confirm the exact label in your tenant as Microsoft has updated naming in recent portal refreshes.

**Effect:**  
Ensures the device requires authentication (PIN, password, or Windows Hello) before granting access to the desktop. Devices with no screen lock configured are marked non-compliant.

**False-positive risk:**  
- **Shared kiosk or public-facing devices** intentionally configured without a password (e.g. reception terminals, print kiosks) will be flagged non-compliant. These should be excluded or placed in a separate kiosk compliance policy.  
- Devices enrolled via **Windows Autopilot in kiosk/single-app mode** may not expose a traditional lock screen.  
- Users who have configured **Windows Hello for Business biometrics only** (no PIN fallback) may show as non-compliant on some Intune versions if the PIN is not formally set — verify this against your tenant's Hello for Business policy.

**Recommendation:**  
Create a separate compliance policy for kiosk/shared devices with appropriate exclusions. For standard user devices, enforce this setting without exception — unprotected endpoints are the primary vector for physical access attacks.

---

## Requirement 7 – Device Must Not Be Jailbroken or Rooted

| Field | Detail |
|---|---|
| **Setting name** | Device Threat Level |
| **Intune UI path** | Tab ② Compliance settings → **Microsoft Defender for Endpoint** → Require the device to be at or under the machine risk score |
| **Value** | Clear (or Low, if Clear generates excessive noise) |
| **Grace period** | 7 days |

> **Note:** On Windows, "jailbroken or rooted" does not apply in the Android/iOS sense. The Windows equivalent — checking for tampered or compromised system integrity — is enforced via the **Microsoft Defender for Endpoint (MDE) machine risk score** integration, and optionally via **HAS code integrity** checks.

**Alternative / supplementary setting:**

| Setting name | Intune UI path | Value |
|---|---|---|
| Code integrity | Tab ② Compliance settings → **Device Health** → Require code integrity | Require |

**Effect (Device Threat Level):**  
Intune queries the MDE risk score for the device. A score above "Clear" indicates Defender has detected active threats, suspicious behaviour, or system integrity issues — the functional equivalent of a compromised/rooted state on Windows. Devices above the threshold are blocked from compliant-device conditional access policies.

**Effect (Code Integrity):**  
HAS confirms that kernel code integrity is enforced — drivers and OS components have not been tampered with. This is the closest Windows analogue to detecting a rooted/jailbroken state.

**False-positive risk:**  
- **MDE onboarding latency** — newly enrolled devices not yet fully onboarded to MDE will show no risk score, which some tenants interpret as non-compliant depending on configuration.  
- Devices with **unsigned or test-signed drivers** (e.g. specialist peripherals with legacy drivers) may fail code integrity checks.  
- Legitimate **security research tooling or pen-test software** on analyst devices may trigger an elevated MDE risk score.

**Recommendation:**  
Start with `Low` rather than `Clear` for the MDE risk score if initial rollout generates high non-compliance volume. Escalate to `Clear` once the estate is stable and MDE onboarding is confirmed complete. Use named exclusion groups (with SIRO/security team sign-off) for pen-test or SOC analyst devices. Ensure the MDE–Intune connector is active in your tenant before enabling this setting.

> ⚠️ **UI change notice:** The MDE integration setting path has moved in some portal versions. If you do not see "Microsoft Defender for Endpoint" as a compliance section, verify the MDE connector is enabled under: Endpoint security → Microsoft Defender for Endpoint → Compliance policy evaluation. The connector must be active for the risk score setting to appear.

---

## Grace Period Summary

| Requirement | Setting | Grace Period |
|---|---|---|
| 1 – BitLocker | Require BitLocker | 7 days |
| 2 – Secure Boot | Require Secure Boot | 7 days |
| 3 – OS Build (N-1) | Minimum OS version: 10.0.22621.2861 | 7 days |
| 4 – Defender RTP | Require real-time protection | 7 days |
| 5 – Firewall | Microsoft Defender Firewall | 7 days |
| 6 – PIN/Password | Require a password to unlock mobile devices | 7 days |
| 7 – Not compromised | Device Threat Level / Code Integrity | 7 days |

> Configure the grace period in Intune at: **Tab ③ – Actions for noncompliance** → Mark device noncompliant → Schedule (days after noncompliance): **7**

---

## Actions for Non-Compliance (Recommended)

> Configure on **Tab ③ – Actions for noncompliance**

| Day | Action | Intune action type |
|---|---|---|
| 0 | Mark device as non-compliant (recorded, no user impact) | Mark device noncompliant |
| 1 | Send email notification to user | Send email to end user |
| 7 | Enforce non-compliance (block conditional access) | Mark device noncompliant (grace period expires) |
| 30 | Retire device (optional — requires change approval) | Retire the noncompliant device |

---

## Known Intune UI Changes – Flags for Review

| # | Setting | Risk | Recommended action |
|---|---|---|---|
| 3 | Minimum OS version field label | Microsoft has periodically renamed/restructured OS version fields | Verify the 5-part build string format (`10.0.xxxxx.xxxx`) is accepted in your tenant before publishing |
| 6 | Password section label | "Require a password to unlock mobile devices" is a legacy MDM label; may be relabelled in newer portal versions | Check under System Security in the Windows compliance blade |
| 7 | MDE risk score path | MDE connector section may not appear if the connector is inactive | Enable the Intune–MDE connector before configuring; path may differ in GovCloud/DWP tenants |

---

## Post-Assignment Validation

### Where to Check Compliance Status in the Intune Admin Center

**Per-device view (single device check):**
> Home → Devices → All devices → [search device name] → **Compliance**

This lists every compliance policy assigned to the device. Click the policy name to open the per-setting breakdown — this shows exactly which setting is failing, not just overall status.

**Per-policy view (all devices against this policy):**
> Home → Devices → Compliance → Policies → [policy name] → **Device status**

Filter by Compliant / Not compliant / In grace period. Use **Export** (CSV) for fleet-wide analysis or to share with the project team.

---

### Compliance States and Conditional Access Impact

| Status | Meaning | Conditional Access impact |
|---|---|---|
| **Compliant** | All settings pass; HAS attestation reports are current | Full access to CA-protected resources (Exchange Online, SharePoint, Teams) |
| **In grace period** | One or more settings failing but the 7-day grace clock has not expired | **Access continues.** Device is flagged in reporting but CA does not block yet — this is the intended buffer for reboot-pending or attestation-lagging devices |
| **Not compliant** | One or more settings fail AND grace period has expired | **Access blocked** to all CA policies scoped to "Require compliant device". User sees an access denied page with a remediation link |

> "In grace period" and "Not compliant" both register as failures in Intune compliance reports — the distinction is only whether CA enforcement has activated.

---

### BitLocker False Positive — Three Most Common Causes and Fastest Checks

Use these when a device reports non-compliant on **Require BitLocker** despite BitLocker visibly being enabled.

#### Cause 1 — TPM Attestation Report Has Not Yet Synced to HAS

The device has BitLocker active but the Windows Health Attestation Service has not returned a fresh report to Intune since enrolment or reimage. Common in the first 30–60 minutes after a device syncs.

**Fastest check:**
1. On the device, run in an elevated prompt: `dsregcmd /status`
2. In the Intune admin center go to: Device → **Hardware** → scroll to **TPM version** — blank or unknown means attestation is incomplete.
3. Force a sync on the device: Settings → Accounts → Access work or school → Info → **Sync**
4. Wait 15 minutes and re-check compliance status.

#### Cause 2 — BitLocker Is Suspended (Protectors Off), Not Disabled

Suspend is used automatically during BIOS/firmware updates or can be triggered manually by support staff. The drive remains encrypted but protection is paused — HAS reports this state as non-compliant.

**Fastest check:**
```powershell
manage-bde -status C:
```
Look for **Protection Status**. If it shows `Protection Off` or `Suspended`, resume with:
```powershell
manage-bde -resume C:
```
Then trigger an Intune sync and re-check after 15 minutes.

#### Cause 3 — TPM Present But Not Initialised by Windows

The TPM chip exists in firmware but Windows has not taken ownership — common on devices reimaged without clearing the TPM first, or where a legacy GPO blocked TPM auto-provisioning.

**Fastest check:**
1. Run `tpm.msc` on the device.
2. Status must read **"The TPM is ready for use"**.
3. If it shows "The TPM is not ready for use" or "Compatible TPM cannot be found":
   - In `tpm.msc`: Actions → **Clear TPM** (requires reboot)
   - Or in elevated PowerShell: `Initialize-Tpm`
4. After reboot, BitLocker will re-key, HAS will re-attest, and Intune will update compliance status on the next sync cycle.

---

## References

- [Microsoft – Windows 11 compliance settings in Intune](https://learn.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-windows)  
- [Microsoft – Microsoft Defender for Endpoint integration with Intune](https://learn.microsoft.com/en-us/mem/intune/protect/advanced-threat-protection)  
- [Microsoft – Windows Health Attestation](https://learn.microsoft.com/en-us/windows/security/threat-protection/protect-high-value-assets-by-controlling-the-health-of-windows-10-based-devices)  
- [DWP Personal AI Usage Charter](../personal-ai-usage-charter-dwp-endpoint.md)
