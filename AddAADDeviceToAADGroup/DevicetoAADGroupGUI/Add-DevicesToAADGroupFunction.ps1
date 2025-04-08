function Add-DevicesToAADGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        
        [Parameter(Mandatory = $false)]
        [string]$CsvPath = ".\Devices.csv"
    )

    # Function to write logs
    function Write-Log {
        param($Message, [switch]$IsError)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] $Message"
        
        if ($IsError) {
            Write-Host $logMessage -ForegroundColor Red
            Add-Content -Path $errorLogFile -Value $logMessage
        }
        Write-Host $logMessage
        Add-Content -Path $logFile -Value $logMessage
    }

    try {
        # Check if the AzureAD module is installed
        if (-not (Get-Module -ListAvailable -Name AzureAD)) {
            Install-Module AzureAD -Scope CurrentUser -Force
        }

        # Check if CSV exists
        if (-not (Test-Path $CsvPath)) {
            throw "The CSV file '$CsvPath' does not exist."
        }

        $deviceList = Import-Csv -Path $CsvPath
        Connect-AzureAD
        
        # Get the Azure AD group object and test if it exists
        $groupObj = Get-AzureADGroup -SearchString $GroupName
        
        if ($null -eq $groupObj) {
            throw "The specified Azure AD group '$GroupName' does not exist."
        }
        
        if ($groupObj.Count -gt 1) {
            throw "Multiple groups found with the name '$GroupName'. Please specify a more precise group name."
        }
        
        # Define log files with timestamps
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $logFile = "./Device_Addition_Log_$timestamp.txt"
        $errorLogFile = "./Device_Addition_ErrorLog_$timestamp.txt"
        
        # Create header for log files
        $logHeader = "=== Device Addition Log - Started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
        Add-Content -Path $logFile -Value $logHeader
        Add-Content -Path $errorLogFile -Value $logHeader
        
        # Get current group members
        $groupMembers = Get-AzureADGroupMember -ObjectId $groupObj.ObjectId | 
                       Select-Object -ExpandProperty ObjectId
        
        $results = @{
            Success = 0
            AlreadyMember = 0
            NotFound = 0
            Failed = 0
        }

        foreach ($device in $deviceList) {
            $deviceObj = Get-AzureADDevice -SearchString $device.DeviceName
            
            if ($null -ne $deviceObj) {
                foreach ($dev in $deviceObj) {
                    if ($groupMembers -contains $dev.ObjectId) {
                        Write-Log "Device $($device.DeviceName) is already a member of group $GroupName"
                        $results.AlreadyMember++
                    } else {
                        try {
                            Add-AzureADGroupMember -ObjectId $groupObj.ObjectId -RefObjectId $dev.ObjectId
                            Write-Log "SUCCESS: Device $($device.DeviceName) added to group $GroupName"
                            $results.Success++
                        }
                        catch {
                            Write-Log "ERROR: Failed to add $($device.DeviceName) to group. Error: $_" -IsError
                            $results.Failed++
                        }
                    }
                }
            } else {
                Write-Log "WARNING: Device $($device.DeviceName) not found in Azure AD" -IsError
                $results.NotFound++
            }
        }

        # Return results
        return [PSCustomObject]@{
            GroupName = $GroupName
            Success = $results.Success
            AlreadyMember = $results.AlreadyMember
            NotFound = $results.NotFound
            Failed = $results.Failed
            LogFile = $logFile
            ErrorLogFile = $errorLogFile
        }
    }
    catch {
        Write-Log "FATAL ERROR: $_" -IsError
        throw $_
    }
}

<#
# Example usage:

try {
    $result = Add-DevicesToAADGroup -GroupName "MyAADGroup" -CsvPath ".\Devices.csv"
    Write-Host "`nSummary:"
    Write-Host "Successfully added: $($result.Success)"
    Write-Host "Already members: $($result.AlreadyMember)"
    Write-Host "Not found: $($result.NotFound)"
    Write-Host "Failed: $($result.Failed)"
    Write-Host "`nLog files:"
    Write-Host "Main log: $($result.LogFile)"
    Write-Host "Error log: $($result.ErrorLogFile)"
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

#>