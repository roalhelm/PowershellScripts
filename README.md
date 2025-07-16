# PowerShell Administrative Scripts Collection

A comprehensive collection of PowerShell scripts for system administration, focusing on Azure AD, Windows Updates, and system maintenance tasks.

## 🚀 Quick Start

Clone this repository and run the scripts with appropriate permissions. Most scripts require administrative privileges and specific PowerShell modules.

```powershell
# Clone the repository
git clone https://github.com/roalhelm/PowershellScripts.git

# Navigate to the script directory
cd PowershellScripts

# Run GUI tool for device management
.\AddAADDeviceToAADGroup\DevicetoAADGroupGUI.ps1
```

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

#### GUI Tools
- **[DevicetoAADGroupGUI.ps1](AddAADDeviceToAADGroup/DevicetoAADGroupGUI.ps1)**
  - Modern Windows Forms interface
  - Live device list preview
  - Multiple input format support
  - Integrated AAD group management
  - Real-time validation

#### Core Functions
- **[Add-DevicesToAADGroupFunction.ps1](AddAADDeviceToAADGroup/Add-DevicesToAADGroupFunction.ps1)**
  - Reusable AAD group management function
  - Detailed operation logging
  - Error handling and reporting
  - Status object return
  - CSV file support

#### Utility Scripts
- **[AADChecker.ps1](AddAADDeviceToAADGroup/AADChecker.ps1)**
  - Verifies device existence in Azure AD
  - Processes devices from CSV input file
  - Creates separate CSV files for found/not found devices
  - Outputs detailed summary statistics

- **[AddAADDeviceToAADGroup.ps1](AddAADDeviceToAADGroup/AddAADDeviceToAADGroup.ps1)**
  - Adds devices to specified Azure AD groups
  - Supports bulk operations via CSV input
  - Checks for existing group memberships
  - Provides detailed logging of operations

- **[AddDeviceCSV.ps1](AddAADDeviceToAADGroup/AddDeviceCSV.ps1)**
  - GUI tool for creating device lists
  - Manages CSV files for AAD operations
  - Supports comma, semicolon, or space-separated input
  - Includes cleanup functionality

### System Maintenance Scripts

- **[PSrepairWMI.ps1](PSrepairWMI.ps1)**
  - Advanced WMI repository repair tool
  - Supports local and remote computer repair
  - Manages WMI repository folders
  - Verifies and repairs WMI consistency

- **[PSrepairIntuneManagementextention.ps1](PSrepairIntuneManagementextention.ps1)**
  - Repairs/reinstalls Intune Management Extension
  - Stops required services
  - Removes existing installation
  - Triggers new installation

- **[DriverUpdate.ps1](DriverUpdate.ps1)**
  - Updates system drivers via Windows Update
  - Manages BitLocker status during updates
  - Creates detailed operation logs
  - Supports both local and remote execution

### Windows Update Management

- **[REP_WindowsUpdate.ps1](REP_WindowsUpdate.ps1)**
  - Resets Windows Update components
  - Cleans update cache
  - Removes problematic group policies
  - Triggers update scan cycles

- **[detectOfficeUpdates.ps1](Remediations/detectOfficeUpdates.ps1)**
  - Detects if the latest monthly Office updates are installed
  - Uses PSWindowsUpdate module for compliance detection

- **[remediatOfficeUpdates.ps1](Remediations/remediatOfficeUpdates.ps1)**
  - Installs all missing Office updates via Windows Update
  - Uses PSWindowsUpdate module and reboots if required

### User Management

- **[CompareUserGroups.ps1](CompareUserGroups.ps1)**
  - Compares group memberships between users
  - Shows differences in group memberships
  - Supports AD and Azure AD comparison

- **[IntuneCompareUser.ps1](IntuneCompareUser/IntuneCompareUser.ps1)**
  - Compares multiple users in Microsoft Entra ID (Azure AD)
  - Displays selected properties and group membership differences

### Intune Management

- **[Intune-SyncDevice Scripts](Intune-SyncDevice/)**
  - **Detection.ps1**: Checks last Intune sync time
  - **Remediation.ps1**: Forces Intune sync if needed

### Dell Management

- **[Dell Command Update Scripts](Remediations/)**
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

## 📊 Usage Examples

```powershell
# Add devices to AAD group using GUI
.\DevicetoAADGroupGUI.ps1

# Add devices using function
$result = Add-DevicesToAADGroup -GroupName "TestGroup" -CsvPath ".\Devices.csv"

# Check AAD device status
.\AADChecker.ps1 -InputFile "devices.csv"

# Detect missing Office updates
.\Remediations\detectOfficeUpdates.ps1

# Remediate missing Office updates
.\Remediations\remediatOfficeUpdates.ps1
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