<#
.SYNOPSIS
    Triggers Intune device sync for all managed devices using Microsoft Graph PowerShell.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script connects to Microsoft Graph, retrieves all Intune-managed devices, and triggers a remote sync for each device.
    It is useful for troubleshooting, bulk sync operations, or ensuring devices receive the latest Intune policies and app assignments.
    The script automatically installs and imports required Microsoft.Graph modules if missing, and cleans up after execution.

.NOTES
    File Name     : CheckLastSync.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025
    Requirements  : PowerShell 5.1 or higher, Microsoft.Graph modules, Intune admin permissions
    Target Use    : Intune device management and troubleshooting

.CHANGES
    Version 1.0 (2025-10-13):
    - Initial release with bulk Intune device sync via Microsoft Graph
    - Automatic module installation and cleanup
    - Error handling and output improvements

.VERSION
    1.0

.EXAMPLE
    .\CheckLastSync.ps1
    # Connects to Microsoft Graph, retrieves all managed devices, and triggers Intune sync for each device.

.EXAMPLE
    # Use in troubleshooting scenarios to force policy/app sync for all devices in tenant.

#>
try {
    # Install required modules only if not already installed
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
        Install-Module -Name Microsoft.Graph.DeviceManagement -Force -AllowClobber -ErrorAction Stop
    }
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement.Actions)) {
        Install-Module -Name Microsoft.Graph.DeviceManagement.Actions -Force -AllowClobber -ErrorAction Stop
    }

    # Import required modules (Remove -AllowClobber, not supported for Import-Module)
    Import-Module -Name Microsoft.Graph.DeviceManagement -ErrorAction Stop -Force
    Import-Module -Name Microsoft.Graph.DeviceManagement.Actions -ErrorAction Stop -Force

    # Connect to Microsoft Graph
    Connect-MgGraph -Scope DeviceManagementManagedDevices.PrivilegedOperations.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementManagedDevices.Read.All -ErrorAction Stop

    # Get all managed devices
    $managedDevices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop

    # Synchronize each managed device
    foreach ($device in $managedDevices) {
        try {
            Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -ErrorAction Stop
            Write-Host "Invoking Intune Sync for $($device.DeviceName)" -ForegroundColor Yellow
        }
        catch {
            Write-Error "Failed to sync device $($device.DeviceName). Error: $_"
        }
    }
}
catch {
    Write-Error "An error occurred. Error: $_"
}
finally {
    # Cleanup
    Remove-Module -Name Microsoft.Graph.DeviceManagement -ErrorAction SilentlyContinue
    Remove-Module -Name Microsoft.Graph.DeviceManagement.Actions -ErrorAction SilentlyContinue
}