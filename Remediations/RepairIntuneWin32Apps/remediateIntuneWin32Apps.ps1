<#
.SYNOPSIS
    Intune remediation script for Win32 app deployment issues with comprehensive logging.
    Cleans Win32Apps registry, resets Company Portal, restarts service, and logs all activities to Intune Management Extension log folder.
    Windows-only script.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script remediates Intune Win32 app deployment issues by deleting all subkeys under
    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps and restarting the IntuneManagementExtension service.
    This forces Intune to re-evaluate Win32 app assignments and can resolve stuck or failed deployments.

.NOTES
    File Name     : remediateIntuneWin32Apps.ps1
    Author        : Ronny Alhelm
    Version       : 1.4
    Creation Date : October 13, 2025
    Last Modified : November 25, 2025
    Requirements  : PowerShell 5.1 or higher, local admin rights, Windows OS
    Platform      : Windows only (uses Windows Registry and Services)
    Target Use    : Intune proactive remediation for Win32 app deployment

.PLATFORM COMPATIBILITY
    - Windows: Fully supported (requires admin rights)
    - macOS: Not supported (Windows-specific Registry and Services)
    - Linux: Not supported (Windows-specific Registry and Services)

.CHANGES
    Version 1.4 (2025-11-25):
    - Added backup of registry before deletion
    - Enhanced service restart with status verification
    - Added Company Portal app reset
    - Improved error handling and logging
    - Added retry logic for service restart
    - Better output formatting
    Version 1.3 (2025-11-25):
    - Added platform compatibility notes
    - Added Windows-only validation check
    - Enhanced documentation
    Version 1.2 (2025-10-13):
    - Enhanced documentation and header
    - Improved output formatting and error handling
    - Updated for Intune proactive remediation workflows
    Version 1.1 (2025-09-05):
    - Restart IntuneManagementExtension service after registry cleanup
    Version 1.0 (2025-09-05):
    - Initial release

.VERSION
    1.4

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

# Windows-only: Intune Remediation Script
# Check if running on Windows
if ($PSVersionTable.Platform -eq 'Unix') {
    Write-Output "ERROR: This script is Windows-only and cannot run on macOS/Linux."
    Write-Output "Windows Registry and Services are required for this remediation."
    exit 1
}

# ========================================
# LOGGING FUNCTION
# ========================================
$Script:LogFilePath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\RepairIntuneWin32Apps_Remediation.log"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp [$Level] $Message"
    
    # Write to log file
    try {
        $logEntry | Out-File -FilePath $Script:LogFilePath -Append -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Output "Warning: Could not write to log file: $_"
    }
    
    # Also write to console for Intune
    Write-Output $Message
}

# ========================================
# START REMEDIATION
# ========================================
Write-Log "=========================================="
Write-Log "INTUNE WIN32 APP REMEDIATION" -Level INFO
Write-Log "Script Version: 1.5" -Level INFO
Write-Log "=========================================="
Write-Log "Starting remediation process..." -Level INFO
Write-Log ""

# 1. Backup and clean Win32Apps registry
$regPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps'
$backupPath = "$env:TEMP\IntuneWin32AppsBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"

if (Test-Path $regPath) {
    try {
        # Create backup
        Write-Log "[STEP 1/4] Creating registry backup..." -Level INFO
        $null = reg export "HKLM\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps" $backupPath /y 2>&1
        if (Test-Path $backupPath) {
            Write-Log "  ✓ Backup created: $backupPath" -Level SUCCESS
        } else {
            Write-Log "  ⚠ Warning: Backup creation failed, but continuing..." -Level WARNING
        }
        
        # Delete registry keys
        Write-Log "[STEP 2/4] Deleting Win32Apps registry keys..." -Level INFO
        $keysDeleted = 0
        Get-ChildItem -Path $regPath -ErrorAction Stop | ForEach-Object {
            try {
                Write-Log "  Deleting registry key: $($_.PSChildName)" -Level INFO
                Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction Stop
                $keysDeleted++
            } catch {
                Write-Log "  ⚠ Warning: Could not delete $($_.PSChildName): $_" -Level WARNING
            }
        }
        Write-Log "  ✓ Deleted $keysDeleted subkey(s) under Win32Apps" -Level SUCCESS
    } catch {
        Write-Log "  ✗ ERROR: Failed to clean registry: $_" -Level ERROR
        exit 1
    }
} else {
    Write-Log "[STEP 1-2/4] Registry path not found: $regPath" -Level WARNING
    Write-Log "  ⓘ This may indicate Intune Management Extension is not installed" -Level INFO
}

# 2. Reset Company Portal app (if exists)
Write-Log "[STEP 3/4] Checking Company Portal app..." -Level INFO
$companyPortalPackage = Get-AppxPackage -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue

if ($companyPortalPackage) {
    try {
        Write-Log "  ⓘ Resetting Company Portal app..." -Level INFO
        Get-AppxPackage -Name "Microsoft.CompanyPortal" | Reset-AppxPackage -ErrorAction Stop
        Write-Log "  ✓ Company Portal reset successfully" -Level SUCCESS
    } catch {
        Write-Log "  ⚠ Warning: Could not reset Company Portal: $_" -Level WARNING
    }
} else {
    Write-Log "  ⓘ Company Portal app not found (OK)" -Level INFO
}

# 3. Restart IntuneManagementExtension service with retry
Write-Log "[STEP 4/4] Restarting Intune Management Extension service..." -Level INFO
$serviceName = "IntuneManagementExtension"
$maxRetries = 3
$retryCount = 0
$serviceRestarted = $false

while ($retryCount -lt $maxRetries -and -not $serviceRestarted) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        
        if ($service.Status -eq 'Running') {
            Write-Log "  ⓘ Stopping service... (Attempt $($retryCount + 1)/$maxRetries)" -Level INFO
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
        }
        
        Write-Log "  ⓘ Starting service... (Attempt $($retryCount + 1)/$maxRetries)" -Level INFO
        Start-Service -Name $serviceName -ErrorAction Stop
        Start-Sleep -Seconds 3
        
        # Verify service is running
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -eq 'Running') {
            Write-Log "  ✓ Service restarted successfully" -Level SUCCESS
            $serviceRestarted = $true
        } else {
            throw "Service status is $($service.Status), not Running"
        }
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Log "  ⚠ Retry $retryCount failed: $_" -Level WARNING
            Start-Sleep -Seconds 5
        } else {
            Write-Log "  ✗ ERROR: Failed to restart service after $maxRetries attempts: $_" -Level ERROR
            Write-Log ""
            Write-Log "==========================================" -Level WARNING
            Write-Log "REMEDIATION COMPLETED WITH WARNINGS" -Level WARNING
            Write-Log "==========================================" -Level WARNING
            Write-Log "Registry was cleaned, but service restart failed." -Level WARNING
            Write-Log "Recommendation: Manually restart the service or reboot the device." -Level WARNING
            exit 1
        }
    }
}

if (-not $serviceRestarted) {
    Write-Log "  ⓘ Service not found: $serviceName" -Level WARNING
    Write-Log "  ⓘ This may indicate Intune Management Extension is not installed" -Level INFO
}

Write-Log ""
Write-Log "==========================================" -Level SUCCESS
Write-Log "REMEDIATION COMPLETED SUCCESSFULLY" -Level SUCCESS
Write-Log "==========================================" -Level SUCCESS
Write-Log "✓ Win32Apps registry cleaned" -Level SUCCESS
Write-Log "✓ Company Portal reset (if applicable)" -Level SUCCESS
Write-Log "✓ Intune Management Extension service restarted" -Level SUCCESS
Write-Log ""
Write-Log "Next steps:" -Level INFO
Write-Log "1. Intune will re-evaluate app assignments automatically" -Level INFO
Write-Log "2. Wait 15-30 minutes for apps to redeploy" -Level INFO
Write-Log "3. Check Company Portal for app status" -Level INFO
Write-Log "==========================================" -Level SUCCESS

exit 0