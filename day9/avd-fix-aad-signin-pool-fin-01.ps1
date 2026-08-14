<#
.SYNOPSIS
    Fixes two post-deployment issues that prevented p08@zippyops.in from
    signing in to the POOL-FIN-01 AVD desktop.

.DESCRIPTION
    Fix 1 — Missing role assignments for p08@zippyops.in
        Symptom : Windows App showed "system administrator hasn't set up any
                  resources" for p08@zippyops.in.
        Cause   : Desktop Virtualization User and Virtual Machine User Login
                  roles were only assigned to traininguser10@zippyops.in.
        Fix     : Assign both roles to p08@zippyops.in.

    Fix 2 — Missing Entra ID RDP properties on the host pool
        Symptom : "Sign in Failed – please check your username and password"
                  inside the RDP session prompt.
        Cause   : customRdpProperty lacked targetisaadjoined:i:1 and
                  enablerdsaadauth:i:1. Without these the RDP stack attempts
                  NTLM/Kerberos against a domain that does not exist in this
                  Entra-ID-only environment.
        Fix     : Append both properties to the host pool's customRdpProperty.

.NOTES
    Date    : 2026-08-13
    Env     : dwp-lab-rg / POOL-FIN-01 / Central US
    Tested  : az desktopvirtualization 1.0.0
#>

$az  = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd'
$sub = 'e9d6a1e0-74ba-4519-8a8c-2cd97b40a046'
$rg  = 'dwp-lab-rg'
$dag = "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/applicationgroups/POOL-FIN-01-DAG"
$vm  = "/subscriptions/$sub/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/avd-sh-fin-01"

# ── FIX 1: Assign missing roles to p08@zippyops.in ───────────────────────────
Write-Host "[Fix 1] Assigning Desktop Virtualization User on app group..."
& $az role assignment create `
    --assignee p08@zippyops.in `
    --role "Desktop Virtualization User" `
    --scope $dag `
    -o json 2>&1 | Out-Null
Write-Host "  Done"

Write-Host "[Fix 1] Assigning Virtual Machine User Login on VM..."
& $az role assignment create `
    --assignee p08@zippyops.in `
    --role "Virtual Machine User Login" `
    --scope $vm `
    -o json 2>&1 | Out-Null
Write-Host "  Done"

# Verify
Write-Host "`n[Fix 1] Verification — App group roles:"
& $az role assignment list --scope $dag -o json 2>&1 | ConvertFrom-Json |
    Select-Object roleDefinitionName, principalName | Format-Table -AutoSize

Write-Host "[Fix 1] Verification — VM roles:"
& $az role assignment list --scope $vm -o json 2>&1 | ConvertFrom-Json |
    Select-Object roleDefinitionName, principalName | Format-Table -AutoSize

# ── FIX 2: Add Entra ID RDP properties to the host pool ──────────────────────
Write-Host "[Fix 2] Reading current customRdpProperty..."
$current = (& $az desktopvirtualization hostpool show `
    --resource-group $rg --name POOL-FIN-01 `
    --query customRdpProperty -o tsv 2>&1).Trim()
Write-Host "  Current: $current"

# Only append if not already present (idempotent)
if ($current -notmatch 'targetisaadjoined') {
    $updated = $current + "targetisaadjoined:i:1;enablerdsaadauth:i:1;"
    Write-Host "[Fix 2] Appending targetisaadjoined:i:1 and enablerdsaadauth:i:1..."
    & $az desktopvirtualization hostpool update `
        --resource-group $rg --name POOL-FIN-01 `
        --custom-rdp-property $updated `
        -o json 2>&1 | Out-Null
    Write-Host "  Done"
} else {
    Write-Host "  Already present — no change needed"
}

# Verify
Write-Host "`n[Fix 2] Verification — customRdpProperty:"
& $az desktopvirtualization hostpool show `
    --resource-group $rg --name POOL-FIN-01 `
    --query customRdpProperty -o tsv 2>&1

Write-Host "`nAll fixes applied. Re-launch the desktop from the AVD feed to pick up the new RDP properties."
