<#
.SYNOPSIS
    Detection script for Windows Update deferral and pause settings (STEP1).
    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    Checks if Windows Update deferral and pause settings are compliant (not deferred/paused).
    Returns exit code 0 if compliant, 1 if remediation is needed.

.NOTES
    File Name     : detectSTEP1.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025

.CHANGES
    1.0 - Initial version

.VERSION
    1.0

.EXAMPLE
    .\detectSTEP1.ps1
#>

$regPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update"
if (Test-Path $regPath) {
    $val = Get-Item $regPath
    $defer = $val.GetValue("DeferFeatureUpdatesPeriodInDays", 0)
    $pauseQuality = $val.GetValue("PauseQualityUpdates", 0)
    $pauseFeature = $val.GetValue("PauseFeatureUpdates", 0)
    if ($defer -eq 0 -and $pauseQuality -eq 0 -and $pauseFeature -eq 0) {
        exit 0
    } else {
        exit 1
    }
} else {
    # Key missing, assume compliant
    exit 0
}