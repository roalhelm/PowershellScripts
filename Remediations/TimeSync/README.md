# System clock wrong / Windows Time disabled (Intune Remediation)

Finding ID: `SYS.TIME.SKEW` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects a clock more than 5 minutes off (compared with the HTTPS `Date` header of login.microsoftonline.com, language independent, no UDP 123 needed) or a disabled W32Time service. The remediation restores the default start type of W32Time (Automatic on domain members, Manual otherwise), runs `w32tm /resync /force`, and only if the clock is still more than 5 minutes off sets it once from the HTTPS header. The time source configuration is not changed.

## Files

- `Detect-TimeSync.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-TimeSync.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
