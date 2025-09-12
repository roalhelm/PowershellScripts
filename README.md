
# PowerShell Administrative Scripts Collection

A comprehensive collection of PowerShell scripts for system administration, Intune, Windows Updates, user/group management, and remediation tasks.

## 🚀 Quick Start

Clone this repository and run the scripts with appropriate permissions. Most scripts require administrative privileges and specific PowerShell modules.

```powershell
# Clone the repository
git clone https://github.com/roalhelm/PowershellScripts.git

# Navigate to the script directory
cd PowershellScripts

# Example: Run a detection script
.\DetectRuntime6.ps1
```

## 📋 Requirements

- PowerShell 5.1 or higher
- Administrative privileges
- Required PowerShell modules:
  - PSWindowsUpdate
  - Microsoft.Graph (for Azure/Intune/Graph operations)
  - ActiveDirectory (for AD scripts)


## 📦 Script Overview

### System & Update Scripts

- **[DetectRuntime6.ps1](DetectRuntime6.ps1)**: Detects if .NET Desktop Runtime 6 is installed
- **[DriverUpdate.ps1](DriverUpdate.ps1)**: Updates system drivers via Windows Update (BitLocker aware)
- **[ExecuteRemoteScript.ps1](ExecuteRemoteScript.ps1)**: Runs a script on multiple remote servers
- **[GraphApiOdataNextLink.ps1](GraphApiOdataNextLink.ps1)**: Retrieves all Azure AD groups/devices via Graph API (paging)
- **[PSrepairIntuneManagementextention.ps1](PSrepairIntuneManagementextention.ps1)**: Repairs/reinstalls Intune Management Extension
- **[PSrepairWMI.ps1](PSrepairWMI.ps1)**: Repairs local/remote WMI repository
- **[ReinstallCompanyPortal.ps1](ReinstallCompanyPortal.ps1)**: Removes and reinstalls Company Portal (WinGet)
- **[REP_WindowsUpdate.ps1](REP_WindowsUpdate.ps1)**: Resets Windows Update components

### User & Group Management

- **[ADCompareUserGroups.ps1](ADCompareUserGroups.ps1)**: Compares group memberships of two AD users
- **[IntuneCompareUser.ps1](IntuneCompareUser/IntuneCompareUser.ps1)**: Compares multiple users in Entra ID (Azure AD)

### Remediations & Detection (Intune, Office, Dell, Defender)

- **[Remediations/detectDefenderSignatur.txt](Remediations/detectDefenderSignatur.txt)**: Checks if Defender signature is up to date
- **[Remediations/detectDellCommandUpdate.ps1](Remediations/detectDellCommandUpdate.ps1)**: Detects Dell Command Update installation
- **[Remediations/remediatDellCommandUpdate.ps1](Remediations/remediatDellCommandUpdate.ps1)**: Uninstalls Dell Command Update
- **[Remediations/detectOfficeUpdates.ps1](Remediations/detectOfficeUpdates.ps1)**: Detects if latest Office updates are installed
- **[Remediations/remediatOfficeUpdates.ps1](Remediations/remediatOfficeUpdates.ps1)**: Installs missing Office updates

#### Intune Sync & Win32 Apps

- **[Remediations/Intune-SyncDevice/Detection.ps1](Remediations/Intune-SyncDevice/Detection.ps1)**: Checks if last Intune sync was recent
- **[Remediations/Intune-SyncDevice/Remediation.ps1](Remediations/Intune-SyncDevice/Remediation.ps1)**: Forces Intune sync
- **[Remediations/RepairIntuneWin32Apps/CheckLastSync.ps1](Remediations/RepairIntuneWin32Apps/CheckLastSync.ps1)**: Triggers Intune sync for all devices
- **[Remediations/RepairIntuneWin32Apps/detectIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/detectIntuneWin32Apps.ps1)**: Detects failed Win32 app installations
- **[Remediations/RepairIntuneWin32Apps/remediateIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/remediateIntuneWin32Apps.ps1)**: Cleans up Win32 app registry and restarts IntuneManagementExtension

## 🔧 Usage

Most scripts include detailed help information. Use PowerShell's Get-Help for details:

```powershell
Get-Help .\ScriptName.ps1 -Full
```


Example for detection:
```powershell
.\DetectRuntime6.ps1
.\Remediations\detectOfficeUpdates.ps1
.\Remediations\remediatOfficeUpdates.ps1
.\Remediations\Intune-SyncDevice\Detection.ps1
.\Remediations\Intune-SyncDevice\Remediation.ps1
```

## 📊 Usage Examples


```powershell
# Detect .NET 6 Runtime
.\DetectRuntime6.ps1

# Update drivers
.\DriverUpdate.ps1

# Reset Windows Update
.\REP_WindowsUpdate.ps1

# Detect/Remediate Office Updates
.\Remediations\detectOfficeUpdates.ps1
.\Remediations\remediatOfficeUpdates.ps1

# Intune Win32 App Remediation
.\Remediations\RepairIntuneWin32Apps\detectIntuneWin32Apps.ps1
.\Remediations\RepairIntuneWin32Apps\remediateIntuneWin32Apps.ps1
```

## 📝 Logging

Scripts create logs in appropriate locations:
- Windows Event Log for system operations
- Custom log files in %ProgramData% for specific operations
- Text file logs in script directories

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the GNU General Public License v3 - see the [LICENSE](LICENSE) file