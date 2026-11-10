# Intune auto-enrollment (Intune Remediation)

Finding ID: `MDM.ENROLLMENT.MISSING` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects a device without an Intune enrollment and names the likely cause (not Entra joined, no MDM URL). The remediation starts the auto-enrollment task created by the GPO, or runs `deviceenroller.exe /c /AutoEnrollMDM`, waits up to 3 minutes and reports the enrollment error code with a hint when it fails. Nothing is deleted.

## Files

- `Detect-IntuneAutoEnroll.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-IntuneAutoEnroll.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (runs as SYSTEM) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

**An Intune Remediation cannot reach a device that is not enrolled.** Deploy the pair with ConfigMgr (co-management), a GPO scheduled task, or run it by hand as SYSTEM: `psexec.exe -s powershell.exe -ExecutionPolicy Bypass -File .\Remediate-IntuneAutoEnroll.ps1`. A user must be signed in with a working Primary Refresh Token.

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
