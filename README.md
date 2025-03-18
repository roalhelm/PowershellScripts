# PowerShell Scripts Collection

A collection of administrative PowerShell scripts for Windows system management, Azure AD, and remote maintenance tasks.

## Scripts Overview

### WMI Management
- [PSrepairWMI.ps1](PSrepairWMI.ps1)
  - Repairs WMI (Windows Management Instrumentation) on remote computers
  - Restarts WMI service and repairs repository
  - Includes remote connectivity checks and error handling

### Azure AD Device Management
- [AddAADDeviceToAADGroup/AddAADDeviceToAADGroup.ps1](AddAADDeviceToAADGroup/AddAADDeviceToAADGroup.ps1)
  - Adds devices to Azure AD groups
  - Reads device names from CSV file
  - Creates detailed operation logs
  - Supports both Devices.csv and Devices_In_AAD.csv formats

### Intune Management
- [PSrepairIntuneManagementextention.ps1](PSrepairIntuneManagementextention.ps1)
  - Repairs/reinstalls Intune Management Extension
  - Performs service management and cleanup
  - Supports remote execution

### Windows Update Management
- [REP_WindowsUpdate.ps1](REP_WindowsUpdate.ps1)
  - Resets Windows Update components
  - Clears update cache
  - Triggers update scans
  - Manages related services

### Active Directory Tools
- [CompareUserGroups.ps1](CompareUserGroups.ps1)
  - Compares group memberships between two AD users
  - Displays membership differences
  - Color-coded output
- [Get-ADUserLastLogon.ps1](Get-ADUserLastLogon.ps1)
  - Retrieves last logon information for AD users
  - Supports bulk user checking
  - Exports results to CSV

### Remote Management
- [ExecuteRemoteScript.ps1](ExecuteRemoteScript.ps1)
  - Executes PowerShell scripts on remote servers
  - Reads server list from file
  - Handles remote execution errors
- [Test-RemoteConnection.ps1](Test-RemoteConnection.ps1)
  - Tests connectivity to remote systems
  - Verifies WinRM and RPC ports
  - Provides detailed connection status

### System Maintenance
- [Clear-TempFiles.ps1](Clear-TempFiles.ps1)
  - Cleans temporary files and folders
  - Supports multiple temp locations
  - Optional age-based cleanup

## Prerequisites

- PowerShell 5.1 or higher
- Administrative privileges
- Network connectivity to target systems
- Required modules:
  - AzureAD (for Azure AD scripts)
  - ActiveDirectory (for AD scripts)
  - Remote management enabled on target systems

## Installation

1. Clone or download this repository
2. Ensure required PowerShell modules are installed
3. Configure execution policy if needed:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser