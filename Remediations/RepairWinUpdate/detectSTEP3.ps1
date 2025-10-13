<#
.SYNOPSIS
    Detection script for advanced Windows Update remediation (STEP3).
    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    Checks if Windows Update registry keys and service states are compliant.
    Returns exit code 0 if compliant, 1 if remediation is needed.

.NOTES
    File Name     : detectSTEP3.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025

.CHANGES
    1.0 - Initial version

.VERSION
    1.0

.EXAMPLE
    .\detectSTEP3.ps1
#>

$needsRemediation = $false

# Check registry keys for paused updates
$updateKey = "HKLM:\\SOFTWARE\\Microsoft\\PolicyManager\\current\\device\\Update"
if (Test-Path $updateKey) {
    $val = Get-Item $updateKey
    if ($val.GetValue("PauseQualityUpdates", 0) -ne 0 -or $val.GetValue("PauseFeatureUpdates", 0) -ne 0) {
        $needsRemediation = $true
    }
}

# Check Windows Update services
$wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
$bitsService = Get-Service -Name BITS -ErrorAction SilentlyContinue
if ($wuService.Status -ne 'Running' -or $bitsService.Status -ne 'Running') {
    $needsRemediation = $true
}

if ($needsRemediation) { exit 1 } else { exit 0 }