<#
.SYNOPSIS
    Detects if the last Intune sync was performed within the last 2 days.

.DESCRIPTION
    This script performs the following tasks:
    - Retrieves the last run time of the PushLaunch scheduled task
    - Calculates the time difference between now and last sync
    - Reports if the device is compliant (synced within 2 days)
    - Returns exit code 0 for success (recent sync) or 1 for failure (old sync)

.NOTES
    Filename: Detection.ps1
    Prerequisites:
        - Windows OS with Intune client
        - Access to read scheduled tasks
        - PushLaunch scheduled task must exist
    
    Exit Codes:
        - 0: Success (sync within last 2 days)
        - 1: Failure (sync older than 2 days)
    
.AUTHOR
    Ronny Alhelm

.VERSION
    1.0.0

.EXAMPLE
    .\Detection.ps1
    # Returns: "Sync Complete" and exits with 0 if sync is recent

.EXAMPLE
    .\Detection.ps1
    # Returns: "Last Sync was more than 2 days ago" and exits with 1 if sync is old
#>

# Create variable for the time of the last Intune sync.
$PushInfo = Get-ScheduledTask -TaskName PushLaunch | Get-ScheduledTaskInfo
$LastPush = $PushInfo.LastRunTime
$CurrentTime=(GET-DATE)

# Calculate the time difference between the current date/time and the date stored in the variable.
$TimeDiff = New-TimeSpan -Start $LastPush -End $CurrentTime

# If/Else statement checking whether the Time Difference between the Last Sync and the current time is less or greater than 2 days
if ($TimeDiff.Days -gt 2) {
    # The time difference is more than 2 days
    Write-Host "Last Sync was more than 2 days ago"
    Exit 1
} else {
    # The time difference is less than 2 days
    Write-Host "Sync Complete"
    Exit 0
}
