<#
.SYNOPSIS
    This script adds devices to an Azure AD group based on a list provided in a CSV file.
    It also checks if the device is already in the group before attempting to add it.
    GitHub Repository: https://github.com/roalhelm/

.CHANGES
    Version 1.3 (2025-04-28):
    - Added CSV header validation to ensure "DeviceName" column exists
    - Added detailed error messaging for CSV format issues

    Version 1.2 (2025-03-13):
    - Added group existence validation
    - Added multiple group detection
    - Improved error handling for group operations
    - Added separate error log file

    Version 1.1 (2025-03-11):
    - Added support for multiple CSV file selection
    - Enhanced logging with timestamps
    - Added try-catch blocks for better error handling

    Version 1.0 (2025-03-10):
    - Initial release
    - Basic functionality to add devices to AAD group
    - CSV file support
    - Basic logging

.DESCRIPTION
    The script prompts the user for an Azure AD group name, then reads a CSV file named 'Devices.csv' containing device names.
    It verifies if each device is already a member of the specified Azure AD group before adding it.
    A log file is created to track successes, failures, and already existing devices.

.NOTES
    - Ensure that you have the AzureAD module installed before running this script.
    - The script connects to Azure AD and requires appropriate permissions.
    - The CSV file must be placed in the same directory as this script.

.AUTHOR

    Original script by Ronny Alhelm
    Version        : 1.3
    Creation Date  : 2025-03-10
    Last Modified  : 2025-04-28

.EXAMPLE
    PS C:\> .\Add-DevicesToAADGroup.ps1
    Enter the Azure AD group name: MyDeviceGroup
    The script will process the devices listed in 'Devices.csv' and attempt to add them to 'MyDeviceGroup'.
#>

# Prompt the user for the group name
$groupName = Read-Host "Enter the Azure AD group name"

# Check if the AzureAD module is installed
$module = Get-Module -ListAvailable -Name AzureAD

if (-not $module) {
    Install-Module AzureAD -Scope CurrentUser -Force
    Write-Output "AzureAD module has been installed successfully."
} else {
    Write-Output "AzureAD module is already installed."
}

# Prompt the user for CSV file choice
$csvChoice = Read-Host "Which CSV file do you want to use? Enter 1 for Devices.csv or 2 for Devices_In_AAD.csv"

# Set the CSV file path based on user choice
$csvPath = switch ($csvChoice) {
    "1" { ".\Devices.csv" }
    "2" { ".\Devices_In_AAD.csv" }
    default {
        Write-Host "Invalid choice. Defaulting to Devices.csv" -ForegroundColor Yellow
        ".\Devices.csv"
    }
}

# Check if the selected CSV file exists
if (-not (Test-Path $csvPath)) {
    Write-Host "Error: The selected CSV file '$csvPath' does not exist." -ForegroundColor Red
    exit 1
}

# Validate CSV header
$csvHeader = Get-Content -Path $csvPath -TotalCount 1
if ($csvHeader -ne "DeviceName") {
    Write-Host "Error: The CSV file must have 'DeviceName' as the header in the first row." -ForegroundColor Red
    Write-Host "Current header is: $csvHeader" -ForegroundColor Yellow
    exit 1
}

# Inform the user about the required CSV format
Write-Host "The CSV file should have the following format:"
Write-Host "DeviceName"
Write-Host "Device1"
Write-Host "Device2"
Write-Host "..."
Write-Host "Ensure the file is placed in the same directory as this script."

try {
    $deviceList = Import-Csv -Path $csvPath
    Connect-AzureAD
    
    # Get the Azure AD group object and test if it exists
    $groupObj = Get-AzureADGroup -SearchString $groupName
    
    if ($null -eq $groupObj) {
        Write-Host "Error: The specified Azure AD group '$groupName' does not exist." -ForegroundColor Red
        exit 1
    }
    
    if ($groupObj.Count -gt 1) {
        Write-Host "Warning: Multiple groups found with the name '$groupName'. Please specify a more precise group name." -ForegroundColor Yellow
        Write-Host "Found groups:"
        $groupObj | Format-Table DisplayName, ObjectId
        exit 1
    }
    
    # Get the current members of the group
    $groupMembers = Get-AzureADGroupMember -ObjectId $groupObj.ObjectId | Select-Object -ExpandProperty ObjectId
    
    # Define log files with timestamps
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile = "./Device_Addition_Log_$timestamp.txt"
    $errorLogFile = "./Device_Addition_ErrorLog_$timestamp.txt"
    
    # Create header for log files
    $logHeader = "=== Device Addition Log - Started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
    Add-Content -Path $logFile -Value $logHeader
    Add-Content -Path $errorLogFile -Value $logHeader
    
    foreach ($device in $deviceList) {
        $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $deviceObj = Get-AzureADDevice -SearchString $device.DeviceName
        
        if ($deviceObj -ne $null) {
            foreach ($dev in $deviceObj) {
                if ($groupMembers -contains $dev.ObjectId) {
                    $alreadyInGroupMessage = "[$currentTime] INFO: Device $($device.DeviceName) is already a member of group $groupName."
                    Write-Host $alreadyInGroupMessage
                    Add-Content -Path $logFile -Value $alreadyInGroupMessage
                } else {
                    try {
                        Add-AzureADGroupMember -ObjectId $groupObj.ObjectId -RefObjectId $dev.ObjectId       
                        $successMessage = "[$currentTime] SUCCESS: Device $($device.DeviceName) added to group $groupName."
                        Write-Host $successMessage
                        Add-Content -Path $logFile -Value $successMessage
                    }
                    catch {
                        $errorMessage = "[$currentTime] ERROR: Device $($device.DeviceName) could not be added to the group. Error: $($_.Exception.Message)"
                        Write-Host $errorMessage -ForegroundColor Red
                        Add-Content -Path $logFile -Value $errorMessage
                        Add-Content -Path $errorLogFile -Value $errorMessage
                    }
                }
            }
        } else {
            $notFoundMessage = "[$currentTime] WARNING: No device found in AAD for $($device.DeviceName)."
            Write-Host $notFoundMessage -ForegroundColor Yellow
            Add-Content -Path $logFile -Value $notFoundMessage
            Add-Content -Path $errorLogFile -Value $notFoundMessage
        }
    }
}
catch {
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $exceptionMessage = "[$currentTime] FATAL ERROR: $($_.Exception.Message)"
    Write-Host $exceptionMessage -ForegroundColor Red
    Add-Content -Path $logFile -Value $exceptionMessage
    Add-Content -Path $errorLogFile -Value $exceptionMessage
}

# Add footer to log files
$logFooter = "`n=== Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
Add-Content -Path $logFile -Value $logFooter
Add-Content -Path $errorLogFile -Value $logFooter

Write-Host "`nScript completed. Check the following files for details:"
Write-Host "Main Log: $logFile"
Write-Host "Error Log: $errorLogFile"
