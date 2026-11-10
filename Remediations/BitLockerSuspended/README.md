# BitLocker protection suspended (Intune Remediation)

Finding ID: `BL.PROTECTION.SUSPENDED` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects an encrypted OS drive whose protection is suspended indefinitely (suspend count 0). A suspension that resumes after N restarts (BIOS update) is left alone. The remediation runs `Resume-BitLocker` and checks the result. Nothing is decrypted, no protector is added or removed.

## Files

- `Detect-BitLockerSuspended.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-BitLockerSuspended.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (runs as SYSTEM) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

Do not run the remediation while a BIOS/firmware update waits for its restart: resuming before that restart can trigger a recovery key prompt.

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
