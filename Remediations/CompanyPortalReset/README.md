# Company Portal reset (Intune Remediation)

Finding ID: `CP.APP.BROKEN` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Resets the Company Portal app for the signed-in user, like Settings > Apps > Company Portal > Advanced options > Reset: closes the app and runs `Reset-AppxPackage` (fallback: empties the app's LocalState, LocalCache and TempState folders). The app stays installed, the enrollment is not touched, and the user signs in to Company Portal again. The detection triggers when the package status is not `Ok`.

## Files

- `Detect-CompanyPortal.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Reset-CompanyPortal.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | **Yes** (app data is per user) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

Run `Reset-CompanyPortal.ps1` by hand as the user when Company Portal hangs, loops at sign-in, shows a wrong compliance state or cannot install apps. The log is `%TEMP%\ClientFix.log` of the user.

Log: `%TEMP%\ClientFix.log` of the user. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
