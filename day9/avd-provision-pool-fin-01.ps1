<#
.SYNOPSIS
    End-to-end Azure Virtual Desktop provisioning script for DWP Win11 migration.
    Creates POOL-FIN-01, FinBridge-Workspace, one Win11 multi-session session host,
    Entra-ID-only join, and assigns the required AVD and VM roles.

.PARAMETER SubscriptionId
    Target Azure subscription.

.PARAMETER ResourceGroup
    Pre-existing resource group.

.PARAMETER AssigneeUpn
    UPN of the user to assign Desktop Virtualization User + VM User Login roles.

.PARAMETER AdminPassword
    Local admin password for the session host VM (min 12 chars, complexity required).

.NOTES
    Requirements:
    - Azure CLI >= 2.60 with desktopvirtualization extension
    - Signed in as Owner (or Contributor + User Access Administrator) on the subscription
    - MSIs already downloaded locally to $LocalMsiPath (see STEP 6 comments)

    Tested: 2026-08-13 | az desktopvirtualization 1.0.0 | Win11 24H2 (26100.9168)
#>

param(
    [string]$SubscriptionId = 'e9d6a1e0-74ba-4519-8a8c-2cd97b40a046',
    [string]$ResourceGroup  = 'dwp-lab-rg',
    [string]$Region         = 'centralus',
    [string]$AssigneeUpn    = 'traininguser10@zippyops.in',
    [string]$AdminPassword  = 'DwpAvd#Lab2026!',
    [string]$LocalMsiPath   = 'C:\AVDInstall'
)

$ErrorActionPreference = 'Stop'
$az = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd'

function Az { & $az @args }
function Assert-Ok {
    param([string]$Step)
    if ($LASTEXITCODE -ne 0) { throw "FAILED at step: $Step (exit $LASTEXITCODE)" }
    Write-Host "  [OK] $Step"
}

# ── Set subscription context ─────────────────────────────────────────────────
Az account set --subscription $SubscriptionId
Assert-Ok "Set subscription"

# ── STEP 0: Confirm identity and role ────────────────────────────────────────
Write-Host "`n[STEP 0] Confirming signed-in identity..."
$me = Az account show -o json 2>&1 | ConvertFrom-Json
Write-Host "  Signed in as : $($me.user.name)"
$roles = Az role assignment list --scope /subscriptions/$SubscriptionId --include-inherited -o json 2>&1 | ConvertFrom-Json
$myRole = $roles | Where-Object { $_.principalName -eq $me.user.name } | Select-Object -First 1
if (-not $myRole) { throw "No RBAC role found for $($me.user.name) — cannot proceed" }
Write-Host "  Role on subscription : $($myRole.roleDefinitionName)"

# ── STEP 1: Install CLI extension ────────────────────────────────────────────
Write-Host "`n[STEP 1] Installing desktopvirtualization CLI extension..."
$extVer = Az extension list --query "[?name=='desktopvirtualization'].version" -o tsv 2>&1
if (-not $extVer) {
    Az extension add --name desktopvirtualization --yes
    Assert-Ok "Install desktopvirtualization extension"
} else {
    Write-Host "  Already installed: v$extVer"
}

# ── STEP 2: Create Host Pool ─────────────────────────────────────────────────
Write-Host "`n[STEP 2] Creating host pool POOL-FIN-01..."
$expiry = ([datetime]::UtcNow.AddHours(48)).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$hp = Az desktopvirtualization hostpool create `
    --resource-group $ResourceGroup --name POOL-FIN-01 --location $Region `
    --host-pool-type Pooled --load-balancer-type BreadthFirst `
    --max-session-limit 5 --preferred-app-group-type Desktop `
    --registration-info expiration-time="$expiry" registration-token-operation=Update `
    -o json 2>&1 | ConvertFrom-Json
Assert-Ok "Create host pool"
Write-Host "  Host pool ID : $($hp.id)"
$regToken = $hp.registrationInfo.token

# ── STEP 3: Create Desktop Application Group ──────────────────────────────────
Write-Host "`n[STEP 3] Creating Desktop application group..."
$hpId = "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostpools/POOL-FIN-01"
Az desktopvirtualization applicationgroup create `
    --resource-group $ResourceGroup --name POOL-FIN-01-DAG --location $Region `
    --application-group-type Desktop --host-pool-arm-path $hpId `
    -o json 2>&1 | Out-Null
Assert-Ok "Create Desktop app group"
$dagId = "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationgroups/POOL-FIN-01-DAG"

# ── STEP 4: Create Workspace and register App Group ───────────────────────────
Write-Host "`n[STEP 4] Creating workspace FinBridge-Workspace..."
Az desktopvirtualization workspace create `
    --resource-group $ResourceGroup --name FinBridge-Workspace --location $Region `
    --application-group-references $dagId `
    -o json 2>&1 | Out-Null
Assert-Ok "Create workspace"

# ── STEP 5: Create VNet, Subnet, and NAT Gateway ─────────────────────────────
Write-Host "`n[STEP 5] Creating network infrastructure..."
Az network vnet create `
    --resource-group $ResourceGroup --name dwp-avd-vnet --location $Region `
    --address-prefix 10.10.0.0/16 --subnet-name avd-subnet --subnet-prefix 10.10.1.0/24 `
    -o json 2>&1 | Out-Null
Assert-Ok "Create VNet + subnet"

# NAT Gateway for outbound internet (subnet is created with defaultOutboundAccess=false)
Az network public-ip create `
    --resource-group $ResourceGroup --name dwp-avd-natgw-pip --location $Region `
    --sku Standard --allocation-method Static -o json 2>&1 | Out-Null
Assert-Ok "Create NAT gateway public IP"

Az network nat gateway create `
    --resource-group $ResourceGroup --name dwp-avd-natgw --location $Region `
    --public-ip-addresses dwp-avd-natgw-pip --idle-timeout 10 -o json 2>&1 | Out-Null
Assert-Ok "Create NAT gateway"

Az network vnet subnet update `
    --resource-group $ResourceGroup --vnet-name dwp-avd-vnet --name avd-subnet `
    --nat-gateway dwp-avd-natgw -o json 2>&1 | Out-Null
Assert-Ok "Attach NAT gateway to subnet"

# ── STEP 6: Create Session Host VM ───────────────────────────────────────────
Write-Host "`n[STEP 6] Creating session host VM (Win11 24H2 multi-session, Standard_B2ms)..."
Write-Host "  Image : MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest"
Write-Host "  Security : TrustedLaunch | SecureBoot=true | vTPM=true"
Az vm create `
    --resource-group $ResourceGroup --name avd-sh-fin-01 --location $Region `
    --image "MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest" `
    --size Standard_B2ms `
    --admin-username dwpadmin --admin-password $AdminPassword `
    --vnet-name dwp-avd-vnet --subnet avd-subnet `
    --security-type TrustedLaunch --enable-secure-boot true --enable-vtpm true `
    --assign-identity "[system]" `
    --license-type Windows_Client `
    --public-ip-address '""' --nsg '""' `
    -o json 2>&1 | Out-Null
Assert-Ok "Create VM"
$vmId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/avd-sh-fin-01"

# ── STEP 7: Entra ID Join (AADLoginForWindows extension) ──────────────────────
Write-Host "`n[STEP 7] Installing AADLoginForWindows extension (Entra ID join)..."
Az vm extension set `
    --resource-group $ResourceGroup --vm-name avd-sh-fin-01 `
    --name AADLoginForWindows --publisher Microsoft.Azure.ActiveDirectory --version 2.0 `
    -o json 2>&1 | Out-Null
Assert-Ok "Install AADLoginForWindows"

# ── STEP 8: Stage MSIs in Azure Blob Storage ─────────────────────────────────
Write-Host "`n[STEP 8] Uploading AVD agent MSIs to staging storage..."
Write-Host "  NOTE: Download MSIs locally first if not present:"
Write-Host "    Invoke-WebRequest 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv' -OutFile $LocalMsiPath\RDAgent.msi"
Write-Host "    Invoke-WebRequest 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH' -OutFile $LocalMsiPath\RDAgentBootloader.msi"

$stgAccount = 'dwpavdstg001'
Az storage account create `
    --resource-group $ResourceGroup --name $stgAccount --location $Region `
    --sku Standard_LRS --kind StorageV2 --allow-blob-public-access false `
    -o json 2>&1 | Out-Null
Assert-Ok "Create staging storage account"

$stgKey = (Az storage account keys list --account-name $stgAccount --resource-group $ResourceGroup --query "[0].value" -o tsv 2>&1).Trim()

Az storage container create --account-name $stgAccount --account-key $stgKey --name avd-agents -o json 2>&1 | Out-Null
Assert-Ok "Create blob container"

Az storage blob upload --account-name $stgAccount --account-key $stgKey `
    --container-name avd-agents --name RDAgent.msi --file "$LocalMsiPath\RDAgent.msi" --overwrite -o json 2>&1 | Out-Null
Assert-Ok "Upload RDAgent.msi"

Az storage blob upload --account-name $stgAccount --account-key $stgKey `
    --container-name avd-agents --name RDAgentBootloader.msi --file "$LocalMsiPath\RDAgentBootloader.msi" --overwrite -o json 2>&1 | Out-Null
Assert-Ok "Upload RDAgentBootloader.msi"

$expirySas = (Get-Date).ToUniversalTime().AddHours(4).ToString("yyyy-MM-ddTHH:mmZ")
$agentSas  = (Az storage blob generate-sas --account-name $stgAccount --account-key $stgKey --container-name avd-agents --name RDAgent.msi --permissions r --expiry $expirySas --https-only -o tsv 2>&1).Trim()
$bootSas   = (Az storage blob generate-sas --account-name $stgAccount --account-key $stgKey --container-name avd-agents --name RDAgentBootloader.msi --permissions r --expiry $expirySas --https-only -o tsv 2>&1).Trim()
$agentUrl  = "https://$stgAccount.blob.core.windows.net/avd-agents/RDAgent.msi?$agentSas"
$bootUrl   = "https://$stgAccount.blob.core.windows.net/avd-agents/RDAgentBootloader.msi?$bootSas"

# ── STEP 9: Install AVD Agents on the VM via CustomScriptExtension ─────────────
Write-Host "`n[STEP 9] Installing AVD agents on session host via CustomScriptExtension..."
$regToken = (Az desktopvirtualization hostpool retrieve-registration-token --resource-group $ResourceGroup --name POOL-FIN-01 -o json 2>&1 | ConvertFrom-Json).token

$installScript = '$ProgressPreference="SilentlyContinue"; $ErrorActionPreference="Stop"; New-Item -Path C:\AVDInstall -ItemType Directory -Force | Out-Null; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile("' + $agentUrl + '","C:\AVDInstall\RDAgent.msi"); (New-Object Net.WebClient).DownloadFile("' + $bootUrl + '","C:\AVDInstall\RDAgentBootloader.msi"); Start-Process msiexec.exe -ArgumentList "/i C:\AVDInstall\RDAgent.msi REGISTRATIONTOKEN=' + $regToken + ' /quiet /l*v C:\AVDInstall\RDAgent.log" -Wait; Start-Process msiexec.exe -ArgumentList "/i C:\AVDInstall\RDAgentBootloader.msi /quiet /l*v C:\AVDInstall\Bootloader.log" -Wait; Set-Content C:\AVDInstall\done.txt "done $(Get-Date)"'
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($installScript))

# Submit via REST API to avoid CLI long-poll timeouts
$bearerToken = (Az account get-access-token --query accessToken -o tsv 2>&1).Trim()
$putUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/avd-sh-fin-01/extensions/InstallAVDAgents?api-version=2024-03-01"
$body = @{
    location   = $Region
    properties = @{
        publisher               = "Microsoft.Compute"
        type                    = "CustomScriptExtension"
        typeHandlerVersion      = "1.10"
        autoUpgradeMinorVersion = $true
        protectedSettings       = @{ commandToExecute = "powershell.exe -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $b64" }
    }
} | ConvertTo-Json -Depth 5
$hdrs = @{ Authorization = "Bearer $bearerToken"; "Content-Type" = "application/json" }
$resp = Invoke-WebRequest -Uri $putUri -Method PUT -Headers $hdrs -Body $body -UseBasicParsing
Write-Host "  Extension submitted: HTTP $($resp.StatusCode)"

# Poll until done (up to 10 minutes)
$extUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/avd-sh-fin-01/extensions/InstallAVDAgents?`$expand=instanceView&api-version=2024-03-01"
for ($i = 1; $i -le 12; $i++) {
    Start-Sleep -Seconds 60
    $ext = Invoke-RestMethod -Uri $extUri -Headers @{Authorization="Bearer $bearerToken"} -UseBasicParsing
    $ps  = $ext.properties.provisioningState
    Write-Host "  [$(Get-Date -Format 'HH:mm:ss')] Extension state: $ps"
    if ($ps -eq 'Succeeded') { break }
    if ($ps -eq 'Failed')    { throw "Extension failed: $($ext.properties.instanceView.statuses[0].message)" }
}
Assert-Ok "AVD agent install extension"

# ── STEP 10: Assign roles to end user ────────────────────────────────────────
Write-Host "`n[STEP 10] Assigning roles to $AssigneeUpn..."
Az role assignment create --assignee $AssigneeUpn --role "Desktop Virtualization User" --scope $dagId -o json 2>&1 | Out-Null
Assert-Ok "Assign Desktop Virtualization User on app group"

Az role assignment create --assignee $AssigneeUpn --role "Virtual Machine User Login" --scope $vmId -o json 2>&1 | Out-Null
Assert-Ok "Assign Virtual Machine User Login on VM"

# ── STEP 11: Verify session host status ──────────────────────────────────────
Write-Host "`n[STEP 11] Verifying session host status..."
$shUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostpools/POOL-FIN-01/sessionHosts/avd-sh-fin-01?api-version=2024-04-03"
$sh = Invoke-RestMethod -Uri $shUri -Headers @{Authorization="Bearer $bearerToken"} -UseBasicParsing
Write-Host "  Status        : $($sh.properties.status)"
Write-Host "  Agent version : $($sh.properties.agentVersion)"
Write-Host "  OS version    : $($sh.properties.osVersion)"
if ($sh.properties.status -ne 'Available') {
    Write-Warning "Session host status is '$($sh.properties.status)' — check health check results below"
    $sh.properties.sessionHostHealthCheckResults | ForEach-Object {
        Write-Host "  $($_.healthCheckName): $($_.healthCheckResult)"
    }
}

Write-Host "`n======================================================"
Write-Host " AVD PROVISIONING COMPLETE"
Write-Host "======================================================"
Write-Host " Host pool    : POOL-FIN-01"
Write-Host " Workspace    : FinBridge-Workspace"
Write-Host " Session host : avd-sh-fin-01  [$($sh.properties.status)]"
Write-Host " User         : $AssigneeUpn"
Write-Host " Connect via  : https://client.wvd.microsoft.com/arm/webclient/"
Write-Host "======================================================"
