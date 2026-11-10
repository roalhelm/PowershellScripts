# Devices with driver problems (Intune Remediation)

Finding ID: `DRV.DEVICE.ERROR` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects present devices with a Device Manager error code (except 22 = disabled and 45 = not connected), using `Get-CimInstance Win32_PnPEntity`. The remediation runs `pnputil /scan-devices`, installs the driver updates Windows Update offers for the device (your update policies decide what is offered) and checks again. No driver is removed and no restart is forced.

## Files

- `Detect-DriverProblems.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-DriverProblems.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (runs as SYSTEM) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

For an interactive choice of Windows, Office and driver updates use `Invoke-ManagedUpdates.ps1` from roalhelm/TEST-TreiberUpdateScript. Devices that Windows Update has no driver for need the manufacturer's driver (OEM tool or driver pack).

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
