# DWP Runbook: Add a Windows App to Intune Catalog Before Phased Rollout

Date: 2026-08-11  
Audience: DWP engineers (including engineers with no prior Intune app deployment experience)  
Worked example: FinBridge Connect v3.1

## Purpose
Use this guide to add a Windows application to the Intune app catalog correctly before any phased rollout begins.

Important UI note: Microsoft Endpoint Manager/Intune labels and menu order can vary by tenant version, preview features, and portal updates. At each step marked "UI may vary", verify against your live tenant and do not rely only on this document label.

## 1. Add an App in Intune (Where and Which App Type)

1. Sign in to the Intune admin center.
2. Go to: `Apps` -> `Windows` -> `Add`.
3. UI may vary: In some tenants, the path may appear as `Apps` -> `All apps` -> `Add`, then platform/type is selected in the add flow. Verify the live path and labels.
4. In "Select app type", choose the correct type for your package/source:
   1. For a `.intunewin` package: select `Windows app (Win32)`.
   2. For Microsoft Store content: select `Microsoft Store app (new)` (or tenant-equivalent Store option).
   3. For a URL shortcut: select `Web link`.
5. For this runbook example, select: `Windows app (Win32)`.

## 2. Create the LOB Windows App (Required Fields)

### 2.1 App package file
1. In the Win32 app creation flow, upload the `.intunewin` package for FinBridge Connect v3.1.
2. UI may vary: Some portals show a dedicated "App package file" page first, others include upload within the initial pane. Verify live labels.

### 2.2 App information
1. Open the `App information` section.
2. Populate required/expected metadata:
   1. Name: `FinBridge Connect`
   2. Description: `FinBridge Connect desktop client version 3.1`
   3. Publisher: `FinBridge`
   4. App version: `3.1`
3. Add optional fields (recommended): owner/contact URL, information URL, privacy URL, notes.
4. Save and continue.

### 2.3 Program settings
1. Open the `Program` section.
2. Enter install command exactly:
   `FinBridgeConnect_Setup.exe /silent`
3. Enter uninstall command exactly:
   `FinBridgeConnect_Setup.exe /uninstall /silent`
4. Set install behavior:
   1. `System` context for machine-wide installs and HKLM detection (recommended for this example).
   2. `User` context only if the app is user-scoped and does not require elevation.
5. UI may vary: Install behavior can be labeled as `Install behavior`, `Run this script using the logged on credentials`, or similar wording depending on app type wizard revision. Verify actual option semantics.
6. Save and continue.

### 2.4 Requirements
1. Open the `Requirements` section.
2. Configure architecture:
   1. Select supported architecture(s): `x64` (and add others only if vendor supports them).
3. Configure minimum OS version:
   1. For Windows 10/11 managed estates, select your approved baseline (for example `Windows 10 20H2` or tenant baseline equivalent).
4. UI may vary: OS selectors can be split by edition/build in some tenants. Validate your production baseline with endpoint standards.
5. Save and continue.

### 2.5 Detection rules
1. Open the `Detection rules` section.
2. Choose detection rule format: `Manually configure detection rules` (if prompted).
3. Add registry-based detection for this example:
   1. Rule type: `Registry`
   2. Key path: `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect`
   3. Value name: `Version`
   4. Detection method/operator: `String comparison` or equivalent
   5. Operator: `Equals`
   6. Expected value: `3.1`
4. Confirm 64-bit registry handling option if shown. Use vendor guidance for 32-bit redirection scenarios.
5. Alternatives (use only when appropriate):
   1. MSI product code detection for MSI-based packages.
   2. File/folder path detection with version checks for EXE-based installers.
6. Save and continue.

### 2.6 Return codes
1. Open the `Return codes` section.
2. Ensure standard meanings are configured:
   1. `0` = Success
   2. `3010` = Soft reboot required (success with restart)
   3. `1641` = Hard reboot initiated (success)
3. Ensure non-success codes remain mapped to failure/retry per policy.
4. UI may vary: Default return code table can differ by app type and tenant. Validate mappings before create.
5. Save and continue.

### 2.7 Review and create
1. Open `Review + create`.
2. Re-check all required fields from sections above.
3. Select `Create`.
4. Wait for package processing to complete.

## 3. Assignment Basics (Pilot-First)

1. Open the created app: `Apps` -> `Windows` (or `All apps`) -> `FinBridge Connect`.
2. Go to `Assignments`.
3. UI may vary: Assignment UX may show as tabs (`Required`, `Available for enrolled devices`, `Uninstall`) or as grouped rows. Verify labels in your tenant.
4. Understand assignment types:
   1. `Required`: Intune enforces installation automatically on targeted devices/users.
   2. `Available`: App is offered in Company Portal; user can choose to install.
   3. `Uninstall`: Intune removes app from targeted devices/users.
5. Pilot-first rule:
   1. Assign first to a small, controlled pilot group (for example 20-50 representative devices/users).
   2. Do not assign immediately to the full 10,000-device estate.
6. Why pilot first:
   1. Limits blast radius if install, detection, dependency, or reboot behavior is wrong.
   2. Validates device model, network, and policy interactions before scale.
   3. Allows rapid rollback/assignment change with minimal user impact.
7. Create initial assignment for this runbook:
   1. Add one `Required` assignment to your FinBridge pilot device group.
   2. Optionally add one `Available` assignment for a support validation user group.
8. Save assignments.

## 4. Verification Steps

### 4.1 Confirm app appears correctly in catalog
1. Navigate to app list: `Apps` -> `Windows` or `Apps` -> `All apps`.
2. Search for `FinBridge Connect`.
3. Open app properties and confirm:
   1. Version shows `3.1`.
   2. Install/uninstall commands match expected values.
   3. Detection rule shows registry key/value for FinBridge version.
   4. Assignments show only pilot scope at this stage.

### 4.2 Check install status on an assigned test device
1. In Intune app blade, open device status views (`Device install status`, `User install status`, or tenant equivalent).
2. Filter to your pilot group/test device.
3. Confirm status progression after sync:
   1. Pending/In progress -> Installed (expected successful path).
4. On the test device, validate locally:
   1. Trigger Company Portal/Intune sync if required.
   2. Confirm application launches.
   3. Confirm registry value exists: `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`.

### 4.3 Interpret status values
1. `Installed`:
   1. Intune reports successful installation and detection rule matched.
2. `Failed`:
   1. Install command failed, timed out, or detection rule did not match expected state.
   2. Action: review return code, installer logs, and detection rule logic.
3. `Not applicable`:
   1. Target does not meet requirement filters (OS, architecture, assignment filters, or context).
   2. Action: verify requirements and assignment targeting.

## 5. Pre-Rollout Exit Criteria (Before Any Wider Phase)

1. App metadata is complete and accurate.
2. Program commands execute silently and consistently.
3. Detection rule is stable across pilot devices.
4. Return code mapping is validated.
5. Pilot success rate meets team threshold (example: >= 95% installed, 0 critical regressions).
6. Any failures have documented remediation steps.
7. Only after meeting criteria, expand assignment in controlled phases.

## 6. Quick Troubleshooting Pointers

1. If installs fail quickly, verify command-line switches and content packaging.
2. If app installs but still shows failed, detection rule is usually incorrect.
3. If status is not applicable unexpectedly, verify architecture/minimum OS filters.
4. If rollout appears stalled, force device sync and review Intune Management Extension logs on endpoint.

## 7. Worked Example Snapshot (FinBridge Connect v3.1)

1. App type: `Windows app (Win32)` for `.intunewin`
2. Install command: `FinBridgeConnect_Setup.exe /silent`
3. Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
4. Detection: `HKLM\SOFTWARE\FinBridge\Connect\Version` equals `3.1`
5. First assignment: pilot group only (`Required`), not full fleet

---

Document control: Version 1.0 (draft), owner DWP Endpoint Engineering.
