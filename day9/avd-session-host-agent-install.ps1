<#
.SYNOPSIS
    Installs the AVD RD Agent and Bootloader on a session host VM.
    This script is delivered to the VM via the CustomScriptExtension and run locally.

.NOTES
    The MSIs are downloaded from a private Azure Blob Storage account via SAS URL
    rather than the public CDN, which can return BlobNotFound in some Azure regions.
    The REGISTRATIONTOKEN must match the host pool's current registration token.

    Prerequisites on the VM:
    - Outbound internet (NAT Gateway or equivalent)
    - PowerShell 5.1+
    - AADLoginForWindows extension already installed (Entra ID join)
#>

param(
    [Parameter(Mandatory)][string]$RDAgentSasUrl,
    [Parameter(Mandatory)][string]$BootloaderSasUrl,
    [Parameter(Mandatory)][string]$RegistrationToken
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$workDir = 'C:\AVDInstall'
New-Item -Path $workDir -ItemType Directory -Force | Out-Null

Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Downloading RD Agent..."
(New-Object Net.WebClient).DownloadFile($RDAgentSasUrl, "$workDir\RDAgent.msi")
Write-Output "  Size: $((Get-Item $workDir\RDAgent.msi).Length) bytes"

Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Downloading RD Agent Bootloader..."
(New-Object Net.WebClient).DownloadFile($BootloaderSasUrl, "$workDir\RDAgentBootloader.msi")
Write-Output "  Size: $((Get-Item $workDir\RDAgentBootloader.msi).Length) bytes"

Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Installing RD Agent..."
$agentArgs = "/i `"$workDir\RDAgent.msi`" REGISTRATIONTOKEN=$RegistrationToken /quiet /l*v $workDir\RDAgent.log"
$proc = Start-Process msiexec.exe -ArgumentList $agentArgs -Wait -PassThru
if ($proc.ExitCode -ne 0) { throw "RD Agent install failed with exit code $($proc.ExitCode)" }

Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Installing RD Agent Bootloader..."
$bootArgs = "/i `"$workDir\RDAgentBootloader.msi`" /quiet /l*v $workDir\Bootloader.log"
$proc = Start-Process msiexec.exe -ArgumentList $bootArgs -Wait -PassThru
if ($proc.ExitCode -ne 0) { throw "Bootloader install failed with exit code $($proc.ExitCode)" }

"Install completed at $(Get-Date -Format 'o')" | Set-Content "$workDir\done.txt"
Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Done. Service status:"
Get-Service RDAgentBootLoader -ErrorAction SilentlyContinue | Select-Object Name, Status
