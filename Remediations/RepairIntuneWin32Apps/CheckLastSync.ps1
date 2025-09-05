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