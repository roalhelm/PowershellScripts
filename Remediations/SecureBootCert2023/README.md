# Secure Boot 2023 certificates missing (Intune Remediation)

Finding ID: `SEC.SECUREBOOT.CERT2023` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

The Microsoft Secure Boot certificates from 2011 expired in 2026. Devices that still have only those keep booting, but get no new Secure Boot protections and no new boot manager. The detection reports devices with Secure Boot on where Windows has not finished the update to the 2023 certificates. The remediation uses the method Microsoft documents for IT-managed devices: it sets `AvailableUpdates` to `0x5944` and starts the scheduled task `\Microsoft\Windows\PI\Secure-Boot-Update`. One or two restarts are needed.

**This changes firmware variables.** Test it on each device model first and install the current BIOS/UEFI of the OEM, because old firmware is the usual reason the update fails. Devices where Microsoft already rolls the certificates out through Windows Update do not need this package.

## Files

- `Detect-SecureBootCert2023.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-SecureBootCert2023.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (runs as SYSTEM) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily (the update needs restarts, so the detection can report the issue for a day or two) |

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
