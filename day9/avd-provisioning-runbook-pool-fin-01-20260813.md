# AVD Provisioning Runbook — POOL-FIN-01
**Project:** DWP Windows 11 Workplace Migration  
**Date:** 2026-08-13  
**Engineer:** traininguser10@zippyops.in  
**Subscription:** labs10 (`e9d6a1e0-74ba-4519-8a8c-2cd97b40a046`)  
**Resource group:** dwp-lab-rg (Central US)

---

## Overview

This document records the end-to-end provisioning of an Azure Virtual Desktop (AVD) pooled host pool for the Finance team. It covers every CLI command executed, the issues encountered, how each was diagnosed and resolved, and the final verified state.

---

## Pre-flight: Identity and permissions check

Before creating any resources, confirm the signed-in CLI identity has sufficient RBAC.

```powershell
# Confirm subscription context
& az account show -o json

# List role assignments — must return Owner or Contributor+UAA
& az role assignment list --scope /subscriptions/<subId> --include-inherited -o json
```

**Result:** `traininguser10@zippyops.in` holds **Owner** on subscription `e9d6a1e0-…` (assigned 2026-08-10). Sufficient to create resources and make role assignments.

> If no role is found, stop — do not proceed. The provisioning account needs at minimum **Contributor** to create resources and **User Access Administrator** to assign roles later.

---

## Step 1 — Install the desktopvirtualization CLI extension

```powershell
& az extension add --name desktopvirtualization --yes
& az extension list --query "[?name=='desktopvirtualization'].{name:name,version:version}" -o json
```

**Result:** Extension v1.0.0 installed.

---

## Step 2 — Create the host pool

**Specification:** Pooled, BreadthFirst load balancing, max 5 sessions per host, registration token valid 48 hours.

```powershell
$expiry = ([datetime]::UtcNow.AddHours(48)).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

& az desktopvirtualization hostpool create `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01 `
  --location centralus `
  --host-pool-type Pooled `
  --load-balancer-type BreadthFirst `
  --max-session-limit 5 `
  --preferred-app-group-type Desktop `
  --registration-info expiration-time="$expiry" registration-token-operation=Update `
  -o json
```

**Verified output (key fields):**
| Field | Value |
|---|---|
| `hostPoolType` | `Pooled` |
| `loadBalancerType` | `BreadthFirst` |
| `maxSessionLimit` | `5` |
| `registrationInfo.expirationTime` | `2026-08-15T05:44:43Z` |

---

## Step 3 — Create the Desktop application group

```powershell
$hpId = "/subscriptions/e9d6a1e0-.../resourcegroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostpools/POOL-FIN-01"

& az desktopvirtualization applicationgroup create `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01-DAG `
  --location centralus `
  --application-group-type Desktop `
  --host-pool-arm-path $hpId `
  -o json
```

**Result:** `POOL-FIN-01-DAG` created with `applicationGroupType: Desktop`.

---

## Step 4 — Create the workspace and register the app group

```powershell
$dagId = "/subscriptions/e9d6a1e0-.../resourcegroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationgroups/POOL-FIN-01-DAG"

& az desktopvirtualization workspace create `
  --resource-group dwp-lab-rg `
  --name FinBridge-Workspace `
  --location centralus `
  --application-group-references $dagId `
  -o json
```

**Result:** `FinBridge-Workspace` created. `applicationGroupReferences` array contains `POOL-FIN-01-DAG` — app group is registered.

---

## Step 5 — Create VNet, subnet, and NAT Gateway

### VNet and subnet

```powershell
& az network vnet create `
  --resource-group dwp-lab-rg `
  --name dwp-avd-vnet `
  --location centralus `
  --address-prefix 10.10.0.0/16 `
  --subnet-name avd-subnet `
  --subnet-prefix 10.10.1.0/24
```

> **Important:** The subnet is created with `defaultOutboundAccess: false` in newer API versions. Without outbound internet, the session host cannot download the AVD agents or reach the AVD broker. A NAT Gateway is required.

### NAT Gateway (outbound internet for session hosts)

```powershell
# Public IP for the NAT gateway
& az network public-ip create `
  --resource-group dwp-lab-rg --name dwp-avd-natgw-pip `
  --location centralus --sku Standard --allocation-method Static

# NAT gateway
& az network nat gateway create `
  --resource-group dwp-lab-rg --name dwp-avd-natgw `
  --location centralus --public-ip-addresses dwp-avd-natgw-pip --idle-timeout 10

# Associate with subnet
& az network vnet subnet update `
  --resource-group dwp-lab-rg --vnet-name dwp-avd-vnet --name avd-subnet `
  --nat-gateway dwp-avd-natgw
```

**Result:** `avd-subnet` — `natGateway` field populated, `provisioningState: Succeeded`.

---

## Step 6 — Create the session host VM

**Specification:** Windows 11 24H2 multi-session (AVD-optimised), Standard_B2ms, Trusted Launch with Secure Boot + vTPM, Entra ID joined (no public IP, no NSG attached at NIC level).

```powershell
& az vm create `
  --resource-group dwp-lab-rg `
  --name avd-sh-fin-01 `
  --location centralus `
  --image "MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest" `
  --size Standard_B2ms `
  --admin-username dwpadmin `
  --admin-password "<password>" `
  --vnet-name dwp-avd-vnet --subnet avd-subnet `
  --security-type TrustedLaunch `
  --enable-secure-boot true `
  --enable-vtpm true `
  --assign-identity "[system]" `
  --license-type Windows_Client `
  --public-ip-address '""' --nsg '""'
```

**Verified VM security profile:**
| Property | Value |
|---|---|
| `securityType` | `TrustedLaunch` |
| `secureBootEnabled` | `True` |
| `vTpmEnabled` | `True` |
| `identityType` | `SystemAssigned` |
| `principalId` | `aaec978b-4f40-4645-a2aa-a0170174b028` |
| OS image | `win11-24h2-avd` build `26100.9168` |

---

## Step 7 — Entra ID join (AADLoginForWindows extension)

The environment has **no on-premises Active Directory**. The `AADLoginForWindows` extension performs the Microsoft Entra ID join and enables Entra-based authentication for RDP sessions.

```powershell
& az vm extension set `
  --resource-group dwp-lab-rg `
  --vm-name avd-sh-fin-01 `
  --name AADLoginForWindows `
  --publisher Microsoft.Azure.ActiveDirectory `
  --version 2.0
```

**Result:** `provisioningState: Succeeded`  
**Confirmed by AVD health check:** `AADJoinedHealthCheck: HealthCheckSucceeded` — DeviceId `37584ddc-65cc-47c4-bf33-9ac4463c13b5`

---

## Step 8 — Stage MSI installers in Azure Blob Storage

### Issue encountered and root cause

The standard public CDN URLs for the AVD agents returned `BlobNotFound` from the VM in Central US, while the same URLs returned HTTP 200 from the local machine. This is a CDN geo-routing issue specific to this Azure region.

```
# URLs that returned BlobNotFound from the VM (still valid from other locations):
https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv   # RD Agent
https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH   # Bootloader
```

**Workaround:** Download the MSIs locally, upload to a private Azure Blob Storage account in the same region, and serve them to the VM via time-limited SAS URLs.

### Download MSIs locally

```powershell
$ProgressPreference = 'SilentlyContinue'
New-Item -Path C:\AVDInstall -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "C:\AVDInstall\RDAgent.msi" -UseBasicParsing
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "C:\AVDInstall\RDAgentBootloader.msi" -UseBasicParsing
```

| File | Size |
|---|---|
| `RDAgent.msi` | 96,571,392 bytes (~92 MB) |
| `RDAgentBootloader.msi` | 11,194,368 bytes (~11 MB) |

### Upload to Azure Blob Storage

```powershell
# Create storage account (private — no public blob access)
& az storage account create `
  --resource-group dwp-lab-rg --name dwpavdstg001 `
  --location centralus --sku Standard_LRS --allow-blob-public-access false

# Get storage key for upload
$stgKey = (& az storage account keys list --account-name dwpavdstg001 `
  --resource-group dwp-lab-rg --query "[0].value" -o tsv).Trim()

& az storage container create --account-name dwpavdstg001 --account-key $stgKey --name avd-agents

& az storage blob upload --account-name dwpavdstg001 --account-key $stgKey `
  --container-name avd-agents --name RDAgent.msi --file "C:\AVDInstall\RDAgent.msi" --overwrite

& az storage blob upload --account-name dwpavdstg001 --account-key $stgKey `
  --container-name avd-agents --name RDAgentBootloader.msi --file "C:\AVDInstall\RDAgentBootloader.msi" --overwrite
```

### Generate 4-hour read-only SAS tokens

```powershell
$expiry  = (Get-Date).ToUniversalTime().AddHours(4).ToString("yyyy-MM-ddTHH:mmZ")
$agentSas = (& az storage blob generate-sas --account-name dwpavdstg001 --account-key $stgKey `
  --container-name avd-agents --name RDAgent.msi --permissions r --expiry $expiry --https-only -o tsv).Trim()
$bootSas  = (& az storage blob generate-sas --account-name dwpavdstg001 --account-key $stgKey `
  --container-name avd-agents --name RDAgentBootloader.msi --permissions r --expiry $expiry --https-only -o tsv).Trim()
```

---

## Step 9 — Install AVD agents via CustomScriptExtension

### Why CustomScriptExtension via REST API (not `az vm run-command`)

`az vm run-command invoke` and `az vm run-command create` both block synchronously waiting for the Azure VM guest agent to respond. Because the agent install takes 5–10 minutes (downloads + MSI installs), the CLI long-poll times out in this environment. The CustomScriptExtension submitted via a direct ARM REST PUT returns **HTTP 201 immediately** and executes async on the VM; status is polled separately with a simple REST GET.

### Build and submit the extension

```powershell
# Refresh the registration token immediately before install
$regToken = (& az desktopvirtualization hostpool retrieve-registration-token `
  --resource-group dwp-lab-rg --name POOL-FIN-01 -o json | ConvertFrom-Json).token

# Build install script (single-line, embedded in base64 for -EncodedCommand)
$installScript = '<download-from-SAS-urls-and-install-with-token>'
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($installScript))

# Submit via REST PUT — returns 201 immediately
$bearerToken = (& az account get-access-token --query accessToken -o tsv).Trim()
$putUri = "https://management.azure.com/subscriptions/e9d6a1e0-.../resourceGroups/dwp-lab-rg/providers/Microsoft.Compute/virtualMachines/avd-sh-fin-01/extensions/InstallAVDAgents?api-version=2024-03-01"
$body = @{
  location   = "centralus"
  properties = @{
    publisher               = "Microsoft.Compute"
    type                    = "CustomScriptExtension"
    typeHandlerVersion      = "1.10"
    autoUpgradeMinorVersion = $true
    protectedSettings       = @{
      commandToExecute = "powershell.exe -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $b64"
    }
  }
} | ConvertTo-Json -Depth 5

Invoke-WebRequest -Uri $putUri -Method PUT `
  -Headers @{ Authorization = "Bearer $bearerToken"; "Content-Type" = "application/json" } `
  -Body $body -UseBasicParsing
# → HTTP 201 Created
```

The full parameterised agent install script is in [avd-session-host-agent-install.ps1](avd-session-host-agent-install.ps1).

### Poll for completion (REST GET — no blocking wait)

```powershell
$extUri = "https://management.azure.com/.../extensions/InstallAVDAgents?`$expand=instanceView&api-version=2024-03-01"
$ext = Invoke-RestMethod -Uri $extUri -Headers @{Authorization="Bearer $bearerToken"}
$ext.properties.provisioningState   # Creating → Succeeded
```

**Result:** `ProvisioningState: Succeeded` with empty error output — agents installed cleanly.

---

## Step 10 — Assign roles to end user

Two roles are required for `traininguser10@zippyops.in`:

| Role | Scope | Purpose |
|---|---|---|
| **Desktop Virtualization User** | `POOL-FIN-01-DAG` app group | Sees and connects to the published desktop in the AVD client |
| **Virtual Machine User Login** | `avd-sh-fin-01` VM | Authenticates via Entra ID credentials during RDP |

```powershell
$dagId = "/subscriptions/e9d6a1e0-.../applicationgroups/POOL-FIN-01-DAG"
$vmId  = "/subscriptions/e9d6a1e0-.../virtualMachines/avd-sh-fin-01"

& az role assignment create --assignee traininguser10@zippyops.in `
  --role "Desktop Virtualization User" --scope $dagId

& az role assignment create --assignee traininguser10@zippyops.in `
  --role "Virtual Machine User Login" --scope $vmId
```

---

## Final verification — Session host status

```powershell
$shUri = "https://management.azure.com/.../hostpools/POOL-FIN-01/sessionHosts/avd-sh-fin-01?api-version=2024-04-03"
$sh = Invoke-RestMethod -Uri $shUri -Headers @{Authorization="Bearer $bearerToken"}
$sh.properties | Select-Object status, agentVersion, osVersion, allowNewSession, lastHeartBeat
```

### Confirmed live output

| Property | Value |
|---|---|
| **status** | **Available** |
| `agentVersion` | `1.0.15008.300` |
| `osVersion` | `10.0.26100.9168` (Windows 11 24H2) |
| `sxSStackVersion` | `rdp-sxs260519600` |
| `allowNewSession` | `True` |
| `sessions` | `0` |
| `lastHeartBeat` | `2026-08-13T06:32:34.97Z` |

### Health check results

| Health check | Result |
|---|---|
| `AADJoinedHealthCheck` | ✅ HealthCheckSucceeded — DeviceId `37584ddc-65cc-47c4-bf33-9ac4463c13b5` |
| `DomainJoinedCheck` | ✅ HealthCheckSucceeded |
| `DomainTrustCheck` | ✅ HealthCheckSucceeded |
| `SxSStackListenerCheck` | ✅ HealthCheckSucceeded — SessionEnv Running |
| `MetaDataServiceCheck` | ✅ HealthCheckSucceeded |
| `AppAttachHealthCheck` | ✅ HealthCheckSucceeded |
| `TURNRelayAccessHealthCheck` | ✅ HealthCheckSucceeded |

---

## Issues encountered and resolutions

| # | Issue | Root cause | Resolution |
|---|---|---|---|
| 1 | `az vm run-command invoke` timed out | CLI long-polls the VM guest agent; agent install takes 5–10 min | Used CustomScriptExtension submitted via REST PUT (returns 201 immediately); polled status via REST GET |
| 2 | `avd-subnet` had no outbound internet | New API creates subnets with `defaultOutboundAccess: false` | Created Azure NAT Gateway (`dwp-avd-natgw`) and associated it with the subnet |
| 3 | MSI download returned `BlobNotFound` from VM | CDN geo-routing in Central US for `query.prod.cms.rt.microsoft.com` | Downloaded MSIs locally, uploaded to `dwpavdstg001` Azure Blob Storage, served via 4-hour SAS URLs |

---

## Infrastructure summary

| Resource type | Name | Key config |
|---|---|---|
| Host pool | `POOL-FIN-01` | Pooled · BreadthFirst · max 5 sessions |
| Application group | `POOL-FIN-01-DAG` | Desktop type |
| Workspace | `FinBridge-Workspace` | POOL-FIN-01-DAG registered |
| Virtual network | `dwp-avd-vnet` | `10.10.0.0/16` |
| Subnet | `avd-subnet` | `10.10.1.0/24` |
| NAT Gateway | `dwp-avd-natgw` | PIP `dwp-avd-natgw-pip` |
| Session host VM | `avd-sh-fin-01` | Win11 24H2 AVD · B2ms · TrustedLaunch |
| Entra join | `AADLoginForWindows` v2.0 | `Microsoft.Azure.ActiveDirectory` |
| Agent install | `InstallAVDAgents` CSE | `Microsoft.Compute.CustomScriptExtension` v1.10.22 |
| Staging storage | `dwpavdstg001` | Standard_LRS · private blobs |

---

## Connecting to the desktop

| Method | Steps |
|---|---|
| **AVD web client** | Browse to `https://client.wvd.microsoft.com/arm/webclient/` → sign in as `traininguser10@zippyops.in` → **FinBridge-Workspace** → **SessionDesktop** |
| **Remote Desktop app** | Subscribe to workspace URL `https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery` → sign in → launch SessionDesktop |
| **Direct RDP** | Connect to VM private IP; use Entra ID login (`Virtual Machine User Login` role grants access) |

---

## Scripts in this folder

| File | Purpose |
|---|---|
| [avd-provision-pool-fin-01.ps1](avd-provision-pool-fin-01.ps1) | Full end-to-end provisioning script (parameterised, idempotent-friendly) |
| [avd-session-host-agent-install.ps1](avd-session-host-agent-install.ps1) | Parameterised agent install script delivered to the session host VM |
