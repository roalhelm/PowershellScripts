# PowerShell Administrative Scripts Collection

A comprehensive collection of PowerShell scripts for system administration, focusing on Azure AD, Windows Updates, and system maintenance tasks.

## 🚀 Quick Start

Clone this repository and run the scripts with appropriate permissions. Most scripts require administrative privileges and specific PowerShell modules.

## 📋 Requirements

- PowerShell 5.1 or higher
- Administrative privileges
- Required PowerShell modules:
  - AzureAD
  - PSWindowsUpdate
  - ActiveDirectory
  - Microsoft.Graph (for some Azure AD operations)

## 📦 Script Overview

### Azure AD Management Scripts

#### [AADChecker.ps1](AddAADDeviceToAADGroup/AADChecker.ps1)
- Verifies device existence in Azure AD
- Processes devices from CSV input file
- Creates separate CSV files for found/not found devices
- Outputs detailed summary statistics

#### [AddAADDeviceToAADGroup.ps1](AddAADDeviceToAADGroup/AddAADDeviceToAADGroup.ps1)
- Adds devices to specified Azure AD groups
- Supports bulk operations via CSV input
- Checks for existing group memberships
- Provides detailed logging of operations

#### [AddDeviceCSV.ps1](AddAADDeviceToAADGroup/AddDeviceCSV.ps1)
- GUI tool for creating device lists
- Manages CSV files for AAD operations
- Supports comma, semicolon, or space-separated input
- Includes cleanup functionality

### System Maintenance Scripts

#### [PSrepairWMI.ps1](PSrepairWMI.ps1)
- Advanced WMI repository repair tool
- Supports local and remote computer repair
- Manages WMI repository folders
- Verifies and repairs WMI consistency

#### [PSrepairIntuneManagementextention.ps1](PSrepairIntuneManagementextention.ps1)
- Repairs/reinstalls Intune Management Extension
- Stops required services
- Removes existing installation
- Triggers new installation

#### [DriverUpdate.ps1](DriverUpdate.ps1)
- Updates system drivers via Windows Update
- Manages BitLocker status during updates
- Creates detailed operation logs
- Supports both local and remote execution

### Windows Update Management

#### [REP_WindowsUpdate.ps1](REP_WindowsUpdate.ps1)
- Resets Windows Update components
- Cleans update cache
- Removes problematic group policies
- Triggers update scan cycles

### User Management

#### [CompareUserGroups.ps1](CompareUserGroups.ps1)
- Compares group memberships between users
- Shows differences in group memberships
- Supports AD and Azure AD comparison

### Intune Management

#### [Intune-SyncDevice Scripts](Intune-SyncDevice/)
- **Detection.ps1**: Checks last Intune sync time
- **Remediation.ps1**: Forces Intune sync if needed

### Dell Management

#### [Dell Command Update Scripts](Remediations/)
- **detectDellCommandUpdate.ps1**: Checks DCU installation
- **remediatDellCommandUpdate.ps1**: Removes DCU if found

## 🔧 Usage

Most scripts include detailed help information. Use PowerShell's Get-Help for details:

```powershell
Get-Help .\ScriptName.ps1 -Full
```

Example for AADChecker:
```powershell
.\AddAADDeviceToAADGroup\AADChecker.ps1
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

This project is licensed under the GNU General Public License v3 - see the [LICENSE](LICENSE) file for details.