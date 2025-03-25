<#
.SYNOPSIS
    Triggers Intune sync for all devices in a specified Azure AD group.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script connects to Microsoft Graph API, retrieves all devices from a specified
    Azure AD group, and triggers an Intune sync for each device.

.CHANGES
    Version 1.0 (2025-03-25):
    - Initial release
    - Basic functionality to sync devices in AAD group
    - Error handling and logging
    - Progress tracking

.PARAMETER GroupName
    The name of the Azure AD group containing the devices to sync

.NOTES
    File Name      : SyncAADGroup.ps1
    Author         : Ronny Alhelm
    Prerequisite   : PowerShell 5.1 or higher
                    Microsoft.Graph.Authentication module
                    Microsoft.Graph.Groups module
                    Microsoft.Graph.DeviceManagement module
    Version        : 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$GroupName
)

# Function to write logs
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "$PSScriptRoot\SyncAADGroup.log" -Value $logMessage
}

# Function to ensure required modules
function Install-RequiredModule {
    param([string]$ModuleName)
    
    if (!(Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Log "Installing $ModuleName module..."
        Install-Module -Name $ModuleName -Force -AllowClobber -Scope CurrentUser
    }
    Import-Module -Name $ModuleName -Force
}

try {
    # Install and import required modules
    $requiredModules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Groups',
        'Microsoft.Graph.DeviceManagement'
    )

    foreach ($module in $requiredModules) {
        Install-RequiredModule -ModuleName $module
    }

    # Connect to Microsoft Graph with error handling
    Write-Log "Connecting to Microsoft Graph..."
    try {
        $context = Connect-MgGraph -Scopes @(
            "Device.Read.All", 
            "Group.Read.All",
            "DeviceManagementManagedDevices.PrivilegedOperations.All"
        ) -ErrorAction Stop
        
        if ($null -eq $context) {
            throw "Failed to establish Microsoft Graph connection"
        }
        Write-Log "Successfully connected to Microsoft Graph"
    }
    catch {
        throw "Failed to connect to Microsoft Graph: $_"
    }

    # Get the group
    Write-Log "Finding group: $GroupName"
    $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
    
    if (!$group) {
        throw "Group '$GroupName' not found!"
    }

    # Get all devices in the group
    Write-Log "Retrieving devices from group..."
    $groupMembers = Get-MgGroupMember -GroupId $group.Id
    $totalDevices = $groupMembers.Count
    $currentDevice = 0

    Write-Log "Found $totalDevices devices in group"

    # Process each device
    foreach ($member in $groupMembers) {
        $currentDevice++
        $progress = [math]::Round(($currentDevice / $totalDevices) * 100, 2)
        
        try {
            # Get the Intune device ID
            $intuneDevice = Get-MgDeviceManagementManagedDevice -Filter "azureADDeviceId eq '$($member.Id)'"
            
            if ($intuneDevice) {
                Write-Log "($progress%) Syncing device: $($intuneDevice.DeviceName)"
                Invoke-MgDeviceManagementManagedDeviceSyncDevice -ManagedDeviceId $intuneDevice.Id
                Write-Log "Sync initiated successfully for device: $($intuneDevice.DeviceName)"
            } else {
                Write-Log "($progress%) WARNING: Device $($member.Id) not found in Intune"
            }
        }
        catch {
            Write-Log "ERROR syncing device $($member.Id): $_"
        }
    }

    Write-Log "Sync process completed for all devices"
}
catch {
    Write-Log "FATAL ERROR: $_"
}
finally {
    # Only disconnect if we have an active connection
    if (Get-MgContext) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            Write-Log "Disconnected from Microsoft Graph"
        }
        catch {
            Write-Log "Warning: Could not properly disconnect from Microsoft Graph"
        }
    }
}