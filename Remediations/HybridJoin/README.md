# Hybrid Entra join pending (Intune Remediation)

Finding ID: `AAD.HYBRIDJOIN.PENDING` (same ID as [Get-ClientHealth.ps1](https://github.com/roalhelm/ClientFixPage)). The [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) recommends this package when its report shows the finding.

Detects a domain-joined device that has a hybrid join SCP (client-side registry or Active Directory) but is not Entra joined. Devices without an SCP count as OK. The remediation enables the `Automatic-Device-Join` task, runs `dsregcmd /join` as SYSTEM, waits 2 minutes and reports the join error codes. Nothing is left or deleted.

## Files

- `Detect-HybridJoin.ps1`: read-only detection. Exit 0 = healthy or not applicable, exit 1 = issue (Intune runs the remediation).
- `Remediate-HybridJoin.ps1`: remediation. Exit 0 = fixed, exit 1 = still broken. Writes one summary line for the Intune device status.

## Intune settings

Devices > Scripts and remediations > Remediations > + Create

| Setting | Value |
|---|---|
| Run this script using the logged-on credentials | No (runs as SYSTEM, required for dsregcmd /join) |
| Enforce script signature check | No (unless you sign the scripts) |
| Run script in 64-bit PowerShell | Yes |
| Schedule | Daily |

The join completes only after Entra Connect or Cloud Sync has synced the computer object (with its `userCertificate`). A first `Failed` right after a new domain join is normal. A device that is not hybrid joined is usually not Intune enrolled either, so ConfigMgr, a GPO task or `psexec -s` is often the only way to run it.

Log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log`. Windows PowerShell 5.1, no WMIC.

Status: written 2026-11-10, not yet tested on a real Windows device.
