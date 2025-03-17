<#
.SYNOPSIS
    Triggers an immediate Intune sync by running the PushLaunch scheduled task.

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

try {
    Get-ScheduledTask | ? {$_.TaskName -eq 'PushLaunch'} | Start-ScheduledTask
    Exit 0
}
catch {
    Write-Error $_
    Exit 1
}
