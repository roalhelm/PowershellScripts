# Diagnostic data blocked (Intune Remediation)

Finding ID: `WU.TELEMETRY.BLOCKED` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Windows Autopatch and Windows Update for Business reports need at least "Required" diagnostic data. Detects `AllowTelemetry = 0` from Group Policy or Intune and a missing or disabled `DiagTrack` service. The remediation removes a leftover Group Policy `AllowTelemetry = 0` (key exported to `C:\ProgramData\ClientFix\Backup` first, skipped with a Configuration Manager client or `-removePolicyBlocks 0`), reports an Intune policy without changing it, and sets `DiagTrack` back to Automatic and starts it.

## Files

- `Detect-DiagnosticData.ps1`: read-only detection. Exit 0 = healthy, exit 1 = issue (Intune runs the remediation).
- `Remediate-DiagnosticData.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
