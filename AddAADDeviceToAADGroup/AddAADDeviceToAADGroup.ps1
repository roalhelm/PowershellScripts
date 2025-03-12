<#
.SYNOPSIS
    This script adds devices to an Azure AD group based on a list provided in a CSV file.

.DESCRIPTION
    The script prompts the user for an Azure AD group name, then reads a CSV file named 'Devices.csv' containing device names.
    It attempts to add each device to the specified Azure AD group. A log file is created to track successes and failures.

.NOTES
    - Ensure that you have the AzureAD module installed before running this script.
    - The script connects to Azure AD and requires appropriate permissions.
    - The CSV file must be placed in the same directory as this script.

.AUTHOR
        Script created by Ronny Alhelm
        Date: 12.03.2025

.EXAMPLE
    PS C:\> .\Add-DevicesToAADGroup.ps1
    Enter the Azure AD group name: MyDeviceGroup
    The script will process the devices listed in 'Devices.csv' and attempt to add them to 'MyDeviceGroup'.
#>

# Prompt the user for the group name
$groupName = Read-Host "Enter the Azure AD group name"

# Check if the AzureAD module is installed
$module = Get-Module -ListAvailable -Name AzureAD

if (-not $module)
{
    # If the module is not found, install it for the current user
    Install-Module AzureAD -Scope CurrentUser -Force
    Write-Output "AzureAD module has been installed successfully."
}
else
{
    # If the module is already installed, inform the user
    Write-Output "AzureAD module is already installed."
}

# Inform the user about the required CSV format
Write-Host "The CSV file must be named 'Devices.csv' and should have the following format:"
Write-Host "DeviceName"
Write-Host "Device1"
Write-Host "Device2"
Write-Host "..."
Write-Host "Ensure the file is placed in the same directory as this script."

# Import-Module AzureAD

try {
    $deviceList = Import-Csv -Path ".\Devices.csv"
    Connect-AzureAD
    
    # Get the Azure AD group object
    $groupObj = Get-AzureADGroup -SearchString $groupName
    
    $logFile = "./Device_Addition_Log.txt"
    
    foreach ($device in $deviceList) {
        $deviceObj = Get-AzureADDevice -SearchString $device.DeviceName
        
        if ($deviceObj -ne $null) {
            try {
                foreach ($dev in $deviceObj) {
                    Add-AzureADGroupMember -ObjectId $groupObj.ObjectId -RefObjectId $dev.ObjectId       
                    Add-Content -Path $logFile -Value "SUCCESS: Device $($device.DeviceName) added to group $groupName."
                }
            }
            catch {
                $errorMessage = "ERROR: Device $($device.DeviceName) could not be added to the group."
                Write-Host $errorMessage
                Add-Content -Path $logFile -Value $errorMessage
            }
        }
        else {
            $notFoundMessage = "WARNING: No device found in AAD for $($device.DeviceName)."
            Write-Host $notFoundMessage
            Add-Content -Path $logFile -Value $notFoundMessage
        }
    }
}
catch {
    $exceptionMessage = "FATAL ERROR: $($_.Exception.Message)"
    Write-Host $exceptionMessage
    Add-Content -Path "./Device_Addition_Log.txt" -Value $exceptionMessage
}