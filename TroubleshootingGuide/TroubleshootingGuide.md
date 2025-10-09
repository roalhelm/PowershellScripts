# Troubleshooting Guide – Windows 11 24H2 Feature Update (Intune-managed Clients)

This document helps administrators systematically isolate issues with the Windows 11 24H2 Feature Update on Intune-managed Windows 10/11 devices before opening a support ticket.

---
## 🧾 Quick Overview / Checklist
Work through the points (✔/✘). Attach results to a ticket when escalation is needed.

| Area | Check | Expected | Status (✔/✘) |
|------|-------|----------|---------------|
| Hardware | TPM 2.0 enabled? | Present & enabled | |
| Hardware | Secure Boot enabled? | True / Enabled | |
| Hardware | Windows 11 capable? | Meets minimum requirements | |
| Intune | Properly enrolled? | Device healthy | |
| Intune | Feature Update policy (24H2) assigned? | Policy visible | |
| WUfB | No WSUS conflict? | Only WUfB policies | |
| Storage | ≥ 20 GB free on system drive | OK | |
| Drivers | No outdated critical drivers | Current versions | |
| AV / Security | No 3rd‑party AV blocking | Defender healthy | |

---
## 1. Hardware & Firmware Prerequisites

### 1.1 TPM 2.0 / Secure Boot / Architecture
```powershell
# TPM status
Get-WmiObject -Class Win32_Tpm | Select-Object IsEnabled_InitialValue, IsActivated_InitialValue, PhysicalPresenceVersionInfo

# Secure Boot status (True = enabled)
Confirm-SecureBootUEFI

# System architecture (expect x64)
systeminfo | Select-String "System Type"
```

### 1.2 Windows 11 Minimum Requirements (Quick glance)
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber, CsSystemType
```

---
## 2. Intune Enrollment & Assignments

### 2.1 Device entry
In Intune Admin Center: Devices → All devices → Check compliance & policies applied.

### 2.2 Local enrollment registry check
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Enrollments" | Select-Object *Tenant* , *UPN*, *Enrollment* | Format-List
```

### 2.3 Feature Update (24H2) policy assigned?
Intune Admin Center: Devices → Windows Update rings / Feature updates → Verify 24H2 targeting policy.

Optional local indicators (depends on deployment style):
```powershell
# Windows Update policy indicators
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Format-List
```

---
## 3. Windows Update for Business (WUfB)

Ensure no legacy WSUS GPO is active:
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Select-Object WUServer, WUStatusServer, DoNotConnectToWindowsUpdateInternetLocations
```
Expected: WUServer / WUStatusServer empty if pure WUfB.

Optional Delivery Optimization policy check:
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" | Format-List
```

---
## 4. Client-Side Diagnostics

### 4.1 Update history & hotfixes
```powershell
Get-WmiObject -Class Win32_QuickFixEngineering | Select HotFixID, InstalledOn, Description | Sort-Object InstalledOn -Descending | Select -First 15
```
Record error codes from Settings → Windows Update → Update history.

### 4.2 Windows Update log / UpdateDiag
```powershell
# Generate merged WindowsUpdate.log (may take time)
Get-WindowsUpdateLog -LogPath "$env:TEMP\WindowsUpdate.log"
```
Optionally run UpdateDiag (Microsoft tool) and attach report.

### 4.3 Free disk space
```powershell
Get-PSDrive -Name C | Select-Object Name, Free, Used, @{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}
```
Recommendation: ≥ 20 GB free.

### 4.4 Driver freshness
```powershell
Get-WmiObject Win32_PnPSignedDriver |
  Sort-Object DriverDate -Descending |
  Select-Object -First 20 DeviceName, DriverVersion, DriverDate
```
Focus on graphics, storage, network, VPN, security drivers.

### 4.5 Antivirus / Endpoint protection
```powershell
Get-MpComputerStatus | Select-Object AMServiceEnabled, AntispywareEnabled, RealTimeProtectionEnabled, AntivirusEnabled
```
If 3rd‑party AV is present: temporary disable for test (then re-enable).

---
## 5. Test & Remediation Actions

### 5.1 Manual installation (A/B comparison)
1. Provide ISO (VLSC / Media Creation Tool / Volume media).
2. Run setup.exe and note outcome.
3. If failure: collect Panther logs.

### 5.2 Reset Windows Update components
Run elevated PowerShell:
```powershell
net stop wuauserv
net stop bits
net stop cryptsvc
Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue
Rename-Item -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old" -ErrorAction SilentlyContinue
net start cryptsvc
net start bits
net start wuauserv
```

### 5.3 Component & system integrity
```powershell
# System file check
sfc /scannow

# Repair servicing store
dism /online /cleanup-image /restorehealth
```

### 5.4 Pending reboot detection
```powershell
$rebootKeys = @(
  'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:SOFTWARE\Microsoft\Updates'
)
$rebootKeys | ForEach-Object { if (Test-Path $_) { "Pending: $_" } }
```

---
## 6. Relevant log sources for escalation
Collect (zip if large):
```
%TEMP%\WindowsUpdate.log
C:\Windows\Logs\WindowsUpdate\*
C:\Windows\Panther\setuperr.log
C:\Windows\Panther\setupact.log
Event Viewer: Application / System (export)
```

---
## 7. Information to include in a support ticket
* Device name + serial / asset ID
* Primary user (UPN)
* Intune device status (compliance, last sync)
* Assigned update / feature update policies (screenshot)
* Error code(s) from update history / setup (e.g. 0x8007000e)
* Manual install (in‑place upgrade) result
* Free disk space before / after attempt
* Extracts of WindowsUpdate.log / UpdateDiag report
* Whether 3rd‑party AV / VPN active during attempt

---
## 8. Common error code hints (examples)
| Code | Typical context | Quick approach |
|------|-----------------|----------------|
| 0x800F0922 | Servicing store / .NET / secure channel | Disconnect VPN, run DISM, check firewall |
| 0xC1900101 | Driver failure (storage / AV / network) | Update / remove problematic driver, temp disable AV |
| 0x8007000E | Resource exhaustion | Free disk/RAM, cleanup, retry |
| 0x80246019 | Download problem | Reset BITS/WU, check Delivery Optimization |

---
## 9. Useful supplemental commands
```powershell
# Recent Intune sync events
Get-EventLog -LogName Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin -Newest 30 |
  Select TimeGenerated, EntryType, Message | Out-String -Width 500

# Running update related processes
Get-Process | Where-Object { $_.Name -match 'wu|setup|update' } | Select Name, Id, CPU, StartTime

# Delivery Optimization status
Get-DeliveryOptimizationStatus | Select-Object FileName, Status, BytesDownloaded, BytesFromPeers
```

---
## 10. Post-remediation cleanup
If `SoftwareDistribution.old` exists and updates work again: delete after a few days to reclaim space. Re-enable any 3rd‑party tools disabled for testing.

---
### Notes
Run commands in elevated PowerShell when possible. Be cautious with registry and service modifications.

---
Good luck with your analysis! 🍀