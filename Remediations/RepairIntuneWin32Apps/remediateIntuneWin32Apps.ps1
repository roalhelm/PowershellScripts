#
<#
.SYNOPSIS
    Intune remediation script for Win32 app deployment issues (cleans Win32Apps registry and restarts service).

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script remediates Intune Win32 app deployment issues by deleting all subkeys under
    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps and restarting the IntuneManagementExtension service.
    This forces Intune to re-evaluate Win32 app assignments and can resolve stuck or failed deployments.

.NOTES
    File Name     : remediateIntuneWin32Apps.ps1
    Author        : Ronny Alhelm
    Version       : 1.2
    Creation Date : October 13, 2025
    Requirements  : PowerShell 5.1 or higher, local admin rights
    Target Use    : Intune proactive remediation for Win32 app deployment

.CHANGES
    Version 1.2 (2025-10-13):
    - Enhanced documentation and header
    - Improved output formatting and error handling
    - Updated for Intune proactive remediation workflows
    Version 1.1 (2025-09-05):
    - Restart IntuneManagementExtension service after registry cleanup
    Version 1.0 (2025-09-05):
    - Initial release

.VERSION
    1.2

.EXAMPLE
    .\remediateIntuneWin32Apps.ps1
    # Deletes all subkeys under Win32Apps registry and restarts IntuneManagementExtension service.
    # Use as Intune remediation script for Win32 app deployment issues.

.EXAMPLE
    # Use in Intune proactive remediation:
    # Detection script: detectIntuneWin32Apps.ps1
    # Remediation script: remediateIntuneWin32Apps.ps1
    # Run as system context for registry and service access.

#>
# This script deletes all subkeys under
# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps

$regPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps'

if (Test-Path $regPath) {
    Get-ChildItem -Path $regPath | ForEach-Object {
        Remove-Item -Path $_.PsPath -Recurse -Force
    }
    Write-Output "All subkeys under $regPath have been deleted."
} else {
    Write-Output "The registry path $regPath does not exist."
}

# Restart the IntuneManagementExtension service
$serviceName = "IntuneManagementExtension"
try {
    if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
        Restart-Service -Name $serviceName -Force -ErrorAction Stop
        Write-Output "$serviceName service has been restarted."
    } else {
        Write-Output "$serviceName service not found."
    }
} catch {
    Write-Output "Failed to restart $serviceName service: $_"
}