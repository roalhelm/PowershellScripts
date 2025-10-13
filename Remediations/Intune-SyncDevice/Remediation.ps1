<#
.SYNOPSIS
    Triggers an immediate Intune sync by running the PushLaunch scheduled task.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script performs the following tasks:
    - Locates the PushLaunch scheduled task
    - Triggers immediate execution of the task
    - Reports success or failure of the sync attempt
    - Provides appropriate exit codes for Intune remediation

.NOTES
    Filename: Remediation.ps1
    Prerequisites:
        - Windows OS with Intune client
        - Access to execute scheduled tasks
        - PushLaunch scheduled task must exist
    
    Exit Codes:
        - 0: Success (sync initiated successfully)
        - 1: Failure (error during sync attempt)
    
.AUTHOR
    Ronny Alhelm

.VERSION
    1.0.0

.EXAMPLE
    .\Remediation.ps1
    # Initiates Intune sync and exits with code 0 on success

.EXAMPLE
    .\Remediation.ps1
    # Returns error message and exits with code 1 if sync fails
#>


$taskName = 'PushLaunch'
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($null -eq $task) {
    Write-Error "Scheduled task '$taskName' does not exist. Intune sync cannot be triggered."
    Exit 1
}

try {
    Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
    Start-Sleep -Seconds 2
    $taskState = (Get-ScheduledTask -TaskName $taskName).State
    if ($taskState -eq 'Running' -or $taskState -eq 'Ready') {
        Write-Output "Intune sync triggered successfully via '$taskName' (State: $taskState)."
        Exit 0
    } else {
        Write-Error "Scheduled task '$taskName' did not start as expected (State: $taskState)."
        Exit 1
    }
}
catch {
    Write-Error "Failed to start scheduled task '$taskName': $_"
    Exit 1
}
