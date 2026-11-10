# Microsoft 365 Apps do not update (Intune Remediation)

Finding ID: `APP.M365.UPDATESTUCK` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects Microsoft 365 Apps (Click-to-Run) that cannot update itself: the Click-to-Run service is missing or disabled, automatic updates are turned off in the Click-to-Run configuration, or the scheduled task "Office Automatic Updates 2.0" is missing, disabled or has not run for 14 days. No PowerShell module is needed.

The remediation enables the service, the setting and the task and starts an update in the background (`OfficeC2RClient.exe /update user`) without closing open Office apps. Channel and update source are not changed. Devices where Configuration Manager manages Office updates, or where a policy turns automatic updates off, are skipped.

The older pair in `Remediations/remediatOfficeUpdates` looks for Office updates through Windows Update with the PSWindowsUpdate module. That covers MSI-based Office; Click-to-Run installations update through their own service, which this package checks.

## Files

- `Detect-M365AppsUpdate.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-M365AppsUpdate.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
