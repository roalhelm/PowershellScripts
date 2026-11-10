# Delivery Optimization disabled or bypassed (Intune Remediation)

Finding ID: `WU.DO.BROKEN` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Windows Update, Microsoft Store and Intune Win32 app downloads go through the Delivery Optimization service (`DoSvc`). The detection reports a missing or disabled service, and download mode 100 (Bypass) on Windows 11, where that mode is deprecated. The remediation sets the service back to Automatic (delayed start) and starts it.

Download mode 100 comes from a policy, so the remediation only reports it. Change the Delivery Optimization policy to 0 (HTTP only) or 1 (LAN).

## Files

- `Detect-DeliveryOptimization.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-DeliveryOptimization.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
