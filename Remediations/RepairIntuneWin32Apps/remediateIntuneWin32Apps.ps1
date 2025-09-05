<#
.SYNOPSIS
    Removes all subkeys under HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps.
    GitHub Repository: https://github.com/roalhelm/
    
.DESCRIPTION
    This script deletes all registry subkeys located under:
    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps.
    Useful for remediating issues with Intune Win32 app deployments.

.NOTES
    File Name      : remediateIntuneWin32Apps.ps1
    Author         : Ronny Alhelm
    Prerequisite   : PowerShell 5.1 or higher
    Version        : 1.1
    Creation Date  : 2025-09-05

.CHANGELOG
    1.1 (2025-09-05) - Restart IntuneManagementExtension service after registry cleanup.
    1.0 (2025-09-05) - Initial release.
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