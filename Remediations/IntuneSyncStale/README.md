# Intune sync stale (Intune Remediation)

Finding ID: `MDM.SYNC.STALE` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects when the Intune sync tasks are missing, all disabled, have not run for 7 days, or when `dmwappushservice` is disabled. The remediation enables disabled sync tasks, sets `dmwappushservice` back to Manual and starts it, and starts the `PushLaunch` and `Schedule #3 created by enrollment client` tasks to trigger a sync. Nothing is deleted. Missing sync tasks mean the enrollment is damaged: the script reports that, see `MDM.ENROLLMENT.BROKEN` on the ClientFixPage.

## Files

- `Detect-IntuneSync.ps1`: read-only detection. Exit 0 = healthy, exit 1 = issue (Intune runs the remediation).
- `Remediate-IntuneSync.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (runs as SYSTEM) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
