# TLS 1.2 disabled (Intune Remediation)

Finding ID: `NET.TLS12.DISABLED` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Intune, Entra ID, Windows Update and Defender need TLS 1.2 or newer. Old hardening scripts and Group Policies sometimes switch it off. The detection reports SCHANNEL values that disable the TLS 1.2 client and a WinHTTP `DefaultSecureProtocols` value that leaves TLS 1.2 out. The remediation corrects only those values (`Enabled = 1`, `DisabledByDefault = 0`, adds flag `0x800`). Other protocols and cipher settings are not changed.

A restart is needed afterwards. If a Group Policy writes these values, fix the policy too, otherwise it sets them back.

## Files

- `Detect-Tls12.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-Tls12.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
