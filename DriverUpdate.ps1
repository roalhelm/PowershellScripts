<#
.SYNOPSIS
    Updates drivers and firmware on Windows devices using native Windows methods and PSWindowsUpdate module.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script automates the process of updating device drivers on Windows systems by:
    1. Checking for available driver updates using Windows Update services
    2. Automatically installing the PSWindowsUpdate module if not present
    3. Downloading and installing driver updates with detailed logging
    4. Handling BitLocker protection by temporarily suspending it during updates
    5. Providing comprehensive error handling and status reporting
    6. Supporting both interactive and remote execution modes
    
    The script requires administrator privileges and logs all activities to a central log file
    for auditing and troubleshooting purposes.

.NOTES
    File Name     : DriverUpdate.ps1
    Author        : Ronny Alhelm
    Version       : 1.1
    Creation Date : October 13, 2025
    Prerequisite  : PowerShell 5.1 or higher, Administrator rights
    Dependencies  : PSWindowsUpdate module (auto-installed)

.CHANGES
    Version 1.1 (2025-10-13):
    - Updated documentation structure and formatting
    - Enhanced error handling and logging details
    - Improved BitLocker handling with better error reporting
    - Added detailed update information display (size in MB)
    - Enhanced remote execution capabilities

    Version 1.0 (2025-03-18):
    - Initial release with core functionality
    - Basic driver update functionality via Windows Update
    - PSWindowsUpdate module integration
    - BitLocker status checking and suspension
    - Comprehensive logging implementation

.VERSION
    1.1

.EXAMPLE
    .\DriverUpdate.ps1
    Runs the driver update process interactively, prompting user for confirmation before installing updates.

.EXAMPLE
    .\DriverUpdate.ps1 -Remote
    Runs the driver update process in remote/automated mode without user interaction.

.EXAMPLE
    # Schedule as a task for automated driver updates
    schtasks /create /tn "Driver Update" /tr "powershell.exe -ExecutionPolicy Bypass -File 'C:\Scripts\DriverUpdate.ps1' -Remote" /sc weekly /d sun /st 02:00

#>

# Add parameter block at the beginning of the script
param(
    [Parameter(Mandatory=$false)]
    [switch]$Remote
)

# Function to write logs
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path "$env:ProgramData\DriverUpdate.log" -Value $logMessage
}

# Function to ensure required modules are installed
function Ensure-RequiredModules {
    param (
        [string[]]$ModuleNames
    )
    foreach ($module in $ModuleNames) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Log "Installing required module: $module"
            try {
                Install-Module -Name $module -Force -Scope CurrentUser -ErrorAction Stop
                Write-Log "Successfully installed $module module"
            }
            catch {
                Write-Log "Error installing $module module: $_"
                return $false
            }
        }
        else {
            Write-Log "Required module already installed: $module"
        }
        
        Import-Module -Name $module -Force
    }
    return $true
}

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Error: Script must be run as Administrator"
    exit 1
}

# Check and handle BitLocker status
function Handle-BitLocker {
    $bitlockerVolumes = Get-BitLockerVolume | Where-Object { $_.ProtectionStatus -eq "On" }
    if ($bitlockerVolumes) {
        Write-Log "BitLocker is enabled. Suspending protection..."
        foreach ($volume in $bitlockerVolumes) {
            try {
                Suspend-BitLocker -MountPoint $volume.MountPoint -RebootCount 1
                Write-Log "Suspended BitLocker for volume $($volume.MountPoint)"
            }
            catch {
                Write-Log "Error suspending BitLocker: $_"
                return $false
            }
        }
    }
    return $true
}

# Function to scan and install Windows updates
function Update-Drivers {
    param(
        [bool]$IsRemote = $false
    )
    try {
        Write-Log "Checking required modules..."
        if (-not (Ensure-RequiredModules -ModuleNames @('PSWindowsUpdate'))) {
            Write-Log "Failed to ensure required modules are installed"
            return 1
        }

        Write-Log "Scanning for driver updates..."
        $updates = Get-WindowsUpdate -Category "Drivers" -AcceptAll
        
        if ($updates.Count -eq 0) {
            Write-Log "No driver updates found."
            return $true
        }

        Write-Log "Found $($updates.Count) driver updates:"
        Write-Log "----------------------------------------"
        foreach ($update in $updates) {
            Write-Log "Title: $($update.Title)"
            Write-Log "KB Article: $($update.KB)"
            Write-Log "Size: $([math]::Round($update.Size / 1MB, 2)) MB"
            Write-Log "Description: $($update.Description)"
            Write-Log "----------------------------------------"
        }

        if (-not $IsRemote) {
            $proceed = Read-Host "Do you want to proceed with installation? (Y/N)"
            if ($proceed -ne "Y") {
                Write-Log "Update installation cancelled by user."
                return 3
            }
        }

        Write-Log "Starting installation of driver updates..."
        
        if (Handle-BitLocker) {
            $result = Install-WindowsUpdate -Category "Drivers" -AcceptAll -AutoReboot:$false
            
            foreach ($update in $result) {
                Write-Log "Update: $($update.Title)"
                Write-Log "Status: $($update.Status)"
                Write-Log "Result Code: $($update.ResultCode)"
                Write-Log "----------------------------------------"
            }
            
            if ($result.RebootRequired) {
                Write-Log "Updates installed. Reboot required to complete installation."
                return 2
            }
            
            Write-Log "All updates installed successfully."
            return 0
        }
        else {
            Write-Log "Failed to handle BitLocker. Aborting update process."
            return 1
        }
    }
    catch {
        Write-Log "Error during update process: $_"
        return 1
    }
}

# Main execution
Write-Log "Starting driver update process..."
$updateResult = Update-Drivers

switch ($updateResult) {
    0 { Write-Log "Driver update process completed successfully" }
    1 { Write-Log "Error occurred during driver update process" }
    2 { 
        Write-Log "Updates installed successfully. System requires reboot to complete installation."
        Write-Log "Please restart your computer at a convenient time."
    }
    3 { Write-Log "Update process cancelled by user" }
}

exit $updateResult