# Windows Recovery Environment disabled (Intune Remediation)

Finding ID: `BL.WINRE.DISABLED` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects a disabled WinRE with `reagentc /info`: it looks for the WinRE location `\\?\GLOBALROOT\device\...`, which only appears while WinRE is enabled and is the same in every language (fallback: `ReAgent.xml`). Silent BitLocker encryption, Autopilot reset and remote wipe need WinRE. The remediation runs `reagentc /enable`. No partition is changed: a missing `Winre.wim` or a broken recovery partition is reported for manual repair.

## Files

- `Detect-WinRE.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-WinRE.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
