# JAMF Translation - macOS Security Baseline (Design Team, 25 Devices)

Date: 2026-08-13
Scope: 25 macOS devices in the Design team fleet

## Important verification discipline

Some JAMF Pro UI labels and payload names can vary by version and by whether you use legacy Configuration Profiles, Application & Custom Settings, or Compliance tooling. Treat the labels below as implementation guidance, and verify exact names and locations in your own JAMF instance before rollout.

## Baseline to JAMF mapping

| Baseline requirement | Payload type | Value | Effect | False-positive risk | Verify JAMF label in your instance? |
|---|---|---|---|---|---|
| FileVault disk encryption must be enabled | Security & Privacy payload (FileVault tab/pane in many JAMF versions) | Enable FileVault. Escrow personal recovery key to JAMF. Enforce at next login/logout. | Forces full-disk encryption and ensures recovery key is centrally recoverable. | Device can appear non-compliant during the encryption-in-progress window; key escrow delay if device has not checked in yet. | Yes - naming/layout often differs by JAMF Pro version. |
| Gatekeeper must be enabled (identified developers only) | Restrictions payload (system policy control for app execution) or Security & Privacy controls depending on JAMF version | Allow apps from App Store and identified developers only. Disallow Anywhere. | Blocks unsigned or untrusted apps unless explicitly allowed by admin action/workflow. | Developer or creative tooling may be legitimately unsigned/notarization-delayed and trigger compliance alerts on otherwise healthy devices. | Yes - this control has moved between UI areas across versions. |
| Minimum macOS version: current stable minus one point release | Not a pure Configuration Profile payload. Use Smart Group/Compliance Policy criteria and remediation workflow. | Set minimum allowed OS version to (current stable minus one point release), then update each Apple release cycle. Example: if stable is 16.2, minimum is 16.1. | Keeps fleet close to current supported patch level and reduces exposure window to known vulnerabilities. | False alerts during staged rollout windows, deferred update deadlines, Apple CDN delay, or devices with temporarily blocked major update paths. | Yes - enforcement path varies (Smart Groups, Compliance, patch policy tooling). |
| Firewall must be enabled | Security & Privacy payload (Firewall tab/pane in many JAMF versions) | Enable firewall. Optionally enable stealth mode for stricter posture if approved by support teams. | Host-based firewall is always on, reducing inbound attack surface. | Endpoint security/network tools can briefly report state mismatch during agent startup or after reboot; transient check-in lag. | Yes - payload naming and sub-options can differ by version. |
| Login password required after sleep/screen saver | Security & Privacy payload (General/password timing) or Login Window/Restrictions controls depending on JAMF version | Require password immediately after sleep or screen saver begins. | Prevents unattended unlocked access when a user walks away from device. | User session timing drift (screen saver grace period or MDM status lag) may show temporary non-compliance right after policy apply. | Yes - exact location can vary by macOS and JAMF version. |
| Automatic security updates enabled | Software Update payload (managed update settings) or Restrictions/Application & Custom Settings depending on JAMF version | Enable automatic checking/downloading/installing for security updates and system data files. Keep users from disabling if policy requires. | Ensures security patches install automatically without waiting for user action. | Devices on battery saver, low disk, VPN constraints, or Apple update service throttling can be healthy but appear behind briefly. | Yes - Apple update keys and JAMF UI wording change over time. |

## Notes for operations

1. Use a pilot ring first (for example, 3-5 devices) before deploying to all 25 design endpoints.
2. Pair configuration with a compliance dashboard that allows a short grace period for check-in and encryption/update completion.
3. Document explicit exceptions for developer tools that need notarization or temporary Gatekeeper allowances.
4. Re-validate payload names and option wording after each JAMF Pro upgrade.
