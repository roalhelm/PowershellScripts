<#
.SYNOPSIS
    Detection script for Windows Update requirements and error 0Xc1900200 (STEP2).
    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    Checks TPM activation, Secure Boot, and disk space for Windows Update readiness.
    Returns exit code 0 if compliant, 1 if remediation is needed.

.NOTES
    File Name     : detectSTEP2.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025

.CHANGES
    1.0 - Initial version

.VERSION
    1.0

.EXAMPLE
    .\detectSTEP2.ps1
#>

$compliant = $true

# Check TPM
$tpm = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm
if (-not ($tpm -and $tpm.IsActivated_InitialValue -eq $true)) { $compliant = $false }

# Check Secure Boot
try { $secureBoot = Confirm-SecureBootUEFI } catch { $secureBoot = $false }
if (-not $secureBoot) { $compliant = $false }

# Check disk space
$sysDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($sysDrive.FreeSpace / 1GB, 2)
if ($freeSpaceGB -lt 20) { $compliant = $false }

if ($compliant) { exit 0 } else { exit 1 }