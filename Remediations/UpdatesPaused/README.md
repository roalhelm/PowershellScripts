# Windows updates paused on the device (Intune Remediation)

Finding ID: `WU.UPDATES.PAUSED` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects a pause that a user set in Settings > Windows Update > "Pause updates" and that is still active. The remediation removes the pause values under `HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` and starts an update scan. A pause set by an Intune update ring or Group Policy is deliberate: it is mentioned in the output and never changed.

To stop users from pausing again, set "Block user from pausing Windows updates" in the update ring (policy `Update/SetDisablePauseUXAccess`).

## Files

- `Detect-UpdatesPaused.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-UpdatesPaused.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

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
