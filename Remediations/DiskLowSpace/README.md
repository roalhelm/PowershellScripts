# Low disk space (Intune Remediation)

Finding ID: `SYS.DISK.LOWSPACE` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects less than 20 GB free on the system drive. The remediation cleans only caches that Windows recreates: Delivery Optimization cache, files older than 7 days in `C:\Windows\Temp`, Windows Error Reporting queue/archive and `SoftwareDistribution\Download` (skipped while an update installs), then `DISM /StartComponentCleanup` without `/ResetBase`. User files, profiles, Downloads, the recycle bin and `Windows.old` are never touched. If the drive is still below the limit, the rest needs a person (see the guide on the ClientFixPage).

## Files

- `Detect-DiskLowSpace.ps1`: read-only detection. Exit 0 = healthy, exit 1 = issue (Intune runs the remediation).
- `Remediate-DiskLowSpace.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
