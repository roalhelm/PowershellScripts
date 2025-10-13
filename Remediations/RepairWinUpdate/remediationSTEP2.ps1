
#
<#
.SYNOPSIS
    Remediation script for Windows Update error 0Xc1900200, checking system requirements and resetting update components.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script checks for TPM activation, Secure Boot status, and available disk space, and logs the results. It is designed to help remediate Windows Update error 0Xc1900200 on Intune-managed devices. The script also resets Windows Update components, checks for setup block registry values, and logs all actions to a specified log file. Optionally, DISM health scan steps are included (commented).

.NOTES
    File Name     : remediationSTEP2.ps1
    Author        : Ronny Alhelm
    Version       : 1.1
    Creation Date : October 13, 2025
    Requirements  : PowerShell 5.1 or higher, local admin rights
    Target Use    : Intune remediation for Windows Update errors

.CHANGES
    Version 1.1 (2025-10-13):
    - Enhanced documentation and header
    - Improved output formatting and error handling
    - Updated for Intune proactive remediation workflows
    Version 1.0 (2025-09-19):
    - Initial version

.VERSION
    1.1

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\remediationSTEP2.ps1
    # Runs the remediation script to check system requirements, reset update components, and log results for Windows Update remediation.

.EXAMPLE
    .\remediationSTEP2.ps1
    # Use in Intune proactive remediation to resolve Windows Update error 0Xc1900200 on managed devices.

#>

# PowerShell Remediation Script for Windows Update Error 0Xc1900200


# Function to log output to file and console
$global:LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\RepairWinUpdate_remediation.log"
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp - $message"
    Write-Output $logLine
    Add-Content -Path $global:LogPath -Value $logLine
}

Write-Log "Starting remediation for Windows Update error 0Xc1900200"

# Check for TPM
$tpmStatus = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm
if ($tpmStatus -and $tpmStatus.IsActivated_InitialValue -eq $true) {
    Write-Log "TPM is activated"
} else {
    Write-Log "TPM is not activated or not present"
}

# Check Secure Boot status
$secureBoot = Confirm-SecureBootUEFI
if ($secureBoot) {
    Write-Log "Secure Boot is enabled"
} else {
    Write-Log "Secure Boot is not enabled"
}

# Check free disk space on system drive
$sysDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($sysDrive.FreeSpace / 1GB, 2)
Write-Log "Free disk space on C: drive: $freeSpaceGB GB"
if ($freeSpaceGB -lt 20) {
    Write-Log "Warning: Low disk space. Minimum 20 GB recommended for upgrade."
}

# Run DISM health scan
# Write-Log "Running DISM health scan..."
# DISM /Online /Cleanup-Image /ScanHealth
# DISM /Online /Cleanup-Image /RestoreHealth

# Reset Windows Update components
Write-Log "Resetting Windows Update components..."
Stop-Service -Name BITS -Force -Verbose -ErrorAction SilentlyContinue
Stop-Service -Name wuauserv -Force -Verbose -ErrorAction SilentlyContinue
#net stop appidsvc
#net stop cryptsvc

Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue

Start-Service -Name BITS -Verbose
Start-Service -Name wuauserv -Verbose 
#net start appidsvc
#net start cryptsvc

# Check registry for setup block
$setupBlock = Get-ItemProperty -Path "HKLM:\SYSTEM\Setup" -ErrorAction SilentlyContinue
if ($setupBlock -and $setupBlock.SetupType) {
    Write-Log "SetupType registry value found: $($setupBlock.SetupType)"
} else {
    Write-Log "No SetupType registry value found"
}

Write-Log "Remediation script completed"
