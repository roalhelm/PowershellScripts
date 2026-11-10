# Windows Firewall profile turned off (Intune Remediation)

Finding ID: `SEC.FIREWALL.OFF` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects a Windows Firewall profile (Domain, Private or Public) that is effectively off. The remediation starts the firewall service and turns the profiles on in the local store. Firewall rules are not changed. Devices with another firewall product registered in Windows Security Center are skipped.

If a profile stays off after the remediation, a Group Policy or Intune policy turns it off. Fix that in the policy (Endpoint security > Firewall).

## Files

- `Detect-FirewallOff.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-FirewallOff.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
