# PowerShell Scripts Repository

A collection of useful PowerShell scripts for system administration and management tasks.

## Scripts

### Driver and Firmware Management
- **DriverUpdate.ps1**
  - Updates drivers using Windows Update
  - Handles BitLocker status automatically
  - Creates detailed logs
  - No automatic reboots

### Azure AD Management
- **AADChecker.ps1**
  - Checks device existence in Azure AD
  - Creates separate CSV files for found/not found devices
  - Supports bulk device verification

- **AddAADDeviceToAADGroup.ps1**
  - Adds devices to Azure AD groups
  - Supports CSV input for bulk operations
  - Verifies existing group membership

### User Management
- **CompareUserGroups.ps1**
  - Compares group memberships across platforms:
    - Active Directory
    - Entra ID (Azure AD)
    - Intune
  - Shows missing group memberships
  - Supports detailed comparison reports

### CSV Management
- **AddDeviceCSV.ps1**
  - Creates and manages device lists in CSV format
  - GUI-based interface
  - Supports cleanup operations

## Prerequisites

- PowerShell 5.1 or higher
- Required PowerShell modules:
  - AzureAD
  - Microsoft.Graph
  - PSWindowsUpdate
  - ActiveDirectory

## Installation

1. Clone the repository:
```powershell
git clone https://github.com/yourusername/PowershellScripts.git
```

2. Navigate to the script directory:
```powershell
cd PowershellScripts
```

## Usage

Each script includes detailed help information. Use Get-Help to view:

```powershell
Get-Help .\ScriptName.ps1 -Full
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.