# Windows LAPS does not back up the password (Intune Remediation)

Finding ID: `SEC.LAPS.BACKUPFAILED` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

For the built-in Windows LAPS (not the legacy LAPS MSI). The detection reports devices that have a LAPS policy with a backup directory (Entra ID or Active Directory) and whose newest processing result in the log `Microsoft-Windows-LAPS/Operational` is a failure (event 10005). The remediation runs `Invoke-LapsPolicyProcessing` and reports the result.

If it still fails, the output contains the LAPS error event that names the cause. Typical causes that need a change outside the device: LAPS is not enabled in Entra ID (Devices > Device settings > Enable Microsoft Entra Local Administrator Password Solution), the managed local account does not exist or is disabled, or the device has no line of sight to a domain controller.

## Files

- `Detect-LapsBackup.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-LapsBackup.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
