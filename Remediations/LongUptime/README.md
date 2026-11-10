# No real restart for more than 14 days (Intune Remediation)

Finding ID: `SYS.UPTIME.LONG` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects devices whose kernel has not restarted for more than 14 days. The usual cause is Fast Startup: "Shut down" only hibernates the kernel, so updates, drivers and policies that wait for a restart are never finished. The remediation turns Fast Startup off (`HiberbootEnabled = 0`), so the next shutdown by the user is a real restart. It never restarts the device itself and changes nothing when a policy controls Fast Startup.

The detection keeps reporting the issue until the device has restarted. To enforce restarts, set a deadline in the Intune update ring.

## Files

- `Detect-LongUptime.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-LongUptime.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
