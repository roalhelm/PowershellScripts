# BitLocker recovery key not in Entra ID (Intune Remediation)

Finding ID: `BL.RECOVERYKEY.NOTESCROWED` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects an Entra joined device whose OS drive has no recovery password, or whose newest key backup event in the BitLocker Management log is a failure (846), or that has no success event (845) at all. The remediation adds a recovery password if none exists and runs `BackupToAAD-BitLockerKeyProtector` for every recovery password. Backing up a key that is already in Entra ID is harmless. No protector is removed.

## Files

- `Detect-BitLockerKeyBackup.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-BitLockerKeyBackup.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (runs as SYSTEM) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

If your BitLocker policy does not allow a 48-digit recovery password, adding one fails and the script reports that.

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
