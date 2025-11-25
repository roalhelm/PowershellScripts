<#
.SYNOPSIS
    Intune remediation script for Win32 app deployment issues (cleans Win32Apps registry and restarts service).
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
    - Windows: ✅ Fully supported (requires admin rights)
    - macOS: ❌ Not supported (Windows-specific Registry and Services)
    - Linux: ❌ Not supported (Windows-specific Registry and Services)

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

Write-Output "=========================================="
Write-Output "INTUNE WIN32 APP REMEDIATION"
Write-Output "=========================================="
Write-Output "Starting remediation process..."
Write-Output ""

# 1. Backup and clean Win32Apps registry
$regPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps'
$backupPath = "$env:TEMP\IntuneWin32AppsBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"

if (Test-Path $regPath) {
    try {
        # Create backup
        Write-Output "[STEP 1/4] Creating registry backup..."
        $null = reg export "HKLM\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps" $backupPath /y 2>&1
        if (Test-Path $backupPath) {
            Write-Output "  ✓ Backup created: $backupPath"
        } else {
            Write-Output "  ⚠ Warning: Backup creation failed, but continuing..."
        }
        
        # Delete registry keys
        Write-Output "[STEP 2/4] Deleting Win32Apps registry keys..."
        $keysDeleted = 0
        Get-ChildItem -Path $regPath -ErrorAction Stop | ForEach-Object {
            try {
                Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction Stop
                $keysDeleted++
            } catch {
                Write-Output "  ⚠ Warning: Could not delete $($_.PSChildName): $_"
            }
        }
        Write-Output "  ✓ Deleted $keysDeleted subkey(s) under Win32Apps"
    } catch {
        Write-Output "  ✗ ERROR: Failed to clean registry: $_"
        exit 1
    }
} else {
    Write-Output "[STEP 1-2/4] Registry path not found: $regPath"
    Write-Output "  ⓘ This may indicate Intune Management Extension is not installed"
}

# 2. Reset Company Portal app (if exists)
Write-Output "[STEP 3/4] Checking Company Portal app..."
$companyPortalPackage = Get-AppxPackage -Name "Microsoft.CompanyPortal" -ErrorAction SilentlyContinue

if ($companyPortalPackage) {
    try {
        Write-Output "  ⓘ Resetting Company Portal app..."
        Get-AppxPackage -Name "Microsoft.CompanyPortal" | Reset-AppxPackage -ErrorAction Stop
        Write-Output "  ✓ Company Portal reset successfully"
    } catch {
        Write-Output "  ⚠ Warning: Could not reset Company Portal: $_"
    }
} else {
    Write-Output "  ⓘ Company Portal app not found (OK)"
}

# 3. Restart IntuneManagementExtension service with retry
Write-Output "[STEP 4/4] Restarting Intune Management Extension service..."
$serviceName = "IntuneManagementExtension"
$maxRetries = 3
$retryCount = 0
$serviceRestarted = $false

while ($retryCount -lt $maxRetries -and -not $serviceRestarted) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        
        if ($service.Status -eq 'Running') {
            Write-Output "  ⓘ Stopping service... (Attempt $($retryCount + 1)/$maxRetries)"
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
        }
        
        Write-Output "  ⓘ Starting service... (Attempt $($retryCount + 1)/$maxRetries)"
        Start-Service -Name $serviceName -ErrorAction Stop
        Start-Sleep -Seconds 3
        
        # Verify service is running
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -eq 'Running') {
            Write-Output "  ✓ Service restarted successfully"
            $serviceRestarted = $true
        } else {
            throw "Service status is $($service.Status), not Running"
        }
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Output "  ⚠ Retry $retryCount failed: $_"
            Start-Sleep -Seconds 5
        } else {
            Write-Output "  ✗ ERROR: Failed to restart service after $maxRetries attempts: $_"
            Write-Output ""
            Write-Output "=========================================="
            Write-Output "REMEDIATION COMPLETED WITH WARNINGS"
            Write-Output "=========================================="
            Write-Output "Registry was cleaned, but service restart failed."
            Write-Output "Recommendation: Manually restart the service or reboot the device."
            exit 1
        }
    }
}

if (-not $serviceRestarted) {
    Write-Output "  ⓘ Service not found: $serviceName"
    Write-Output "  ⓘ This may indicate Intune Management Extension is not installed"
}

Write-Output ""
Write-Output "=========================================="
Write-Output "REMEDIATION COMPLETED SUCCESSFULLY"
Write-Output "=========================================="
Write-Output "✓ Win32Apps registry cleaned"
Write-Output "✓ Company Portal reset (if applicable)"
Write-Output "✓ Intune Management Extension service restarted"
Write-Output ""
Write-Output "Next steps:"
Write-Output "1. Intune will re-evaluate app assignments automatically"
Write-Output "2. Wait 15-30 minutes for apps to redeploy"
Write-Output "3. Check Company Portal for app status"
Write-Output "=========================================="

exit 0