# Microsoft Store or App Installer (winget) broken (Intune Remediation)

Finding ID: `APP.STORE.BROKEN` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Store apps from Intune, Company Portal updates and winget need the packages `Microsoft.WindowsStore` and `Microsoft.DesktopAppInstaller` and the services `AppXSvc`, `ClipSVC` and `InstallService`. The detection reports a disabled service or a missing or damaged package. A Store that is turned off by policy (`RemoveWindowsStore`) is not reported.

The remediation works in two contexts, because app packages are registered per user:

- **As SYSTEM**: sets the three services back to Manual when they are disabled (active after a restart).
- **As the signed-in user**: registers both packages again for that user from the copy already on the device (`Add-AppxPackage -RegisterByFamilyName`). No download, app data is kept.

So create the remediation twice if you need both: once as SYSTEM, once with "Run this script using the logged-on credentials" = Yes.

## Files

- `Detect-StoreAppInstaller.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-StoreAppInstaller.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (SYSTEM) for the services. Assign it a second time with Yes to repair the packages of the user |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
