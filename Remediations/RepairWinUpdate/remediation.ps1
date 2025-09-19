
#region PowerShell Help
<#
.SYNOPSIS
    Remediation script for Windows Update error 0Xc1900200, checking system requirements and logging results.

    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script checks for TPM activation, Secure Boot status, and available disk space, and logs the results. It is designed to help remediate Windows Update error 0Xc1900200 on Intune-managed devices. The script also runs a DISM health scan and logs all actions to a specified log file.

.NOTES
    File Name     : remediation.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : 2025-09-19

.CHANGES
    1.0 - Initial version

.VERSION
    1.0

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\remediation.ps1
    # Runs the remediation script to check system requirements and log results for Windows Update remediation.
#>
#endregion

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
