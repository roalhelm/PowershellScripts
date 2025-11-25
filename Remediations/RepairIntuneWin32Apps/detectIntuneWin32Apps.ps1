
<#
.SYNOPSIS
    Intune detection script for failed or not detected Win32 app installations (AppWorkload.log analysis).
    Windows-only script.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script scans the Intune Management Extension AppWorkload.log for patterns indicating failed or not detected Win32 app installations.
    It is designed for use as an Intune proactive remediation detection script and returns:
    - Exit code 1 if any issues are found (non-compliant)
    - Exit code 0 if no issues are found (compliant)

    The script checks log entries from the last 10 days and outputs details about any detected issues, including app name or policy ID if available.

.NOTES
    File Name     : detectIntuneWin32Apps.ps1
    Author        : Ronny Alhelm
    Version       : 1.5
    Creation Date : October 13, 2025
    Last Modified : November 25, 2025
    Requirements  : PowerShell 5.1 or higher, Windows OS
    Platform      : Windows only (uses Windows-specific paths and services)
    Target Use    : Intune proactive remediation detection for Win32 app deployment

.PLATFORM COMPATIBILITY
    - Windows: ✅ Fully supported
    - macOS: ❌ Not supported (Windows-specific Intune Management Extension)
    - Linux: ❌ Not supported (Windows-specific Intune Management Extension)

.CHANGES
    Version 1.5 (2025-11-25):
    - Enhanced error pattern detection (added timeout, network, and download errors)
    - Added Company Portal specific error detection
    - Improved date parsing with error handling
    - Added multiple log file support (AppWorkload.log.old)
    - Better error categorization and reporting
    - Added summary statistics
    Version 1.4 (2025-11-25):
    - Added platform compatibility notes
    - Added Windows-only clarification
    Version 1.3 (2025-10-13):
    - Enhanced documentation and header
    - Improved pattern matching and output formatting
    - Updated for Intune proactive remediation workflows
    Version 1.2 (2025-09-12):
    - Output now includes app name or policyId and error type if available; all comments in English
    Version 1.1 (2025-09-12):
    - Only checks log entries from the last 10 days
    Version 1.0 (2025-09-05):
    - Initial release

.VERSION
    1.5

.EXAMPLE
    .\detectIntuneWin32Apps.ps1
    # Checks AppWorkload.log for failed or not detected Win32 app installations in the last 10 days.
    # Returns exit code 1 if issues are found, otherwise exit code 0.

.EXAMPLE
    # Use in Intune proactive remediation:
    # Detection script: detectIntuneWin32Apps.ps1
    # Remediation script: remediateIntuneWin32Apps.ps1
    # Run as system or user context as required.

#>

# Windows-only: Intune Detection Script
# Check if running on Windows
if ($PSVersionTable.Platform -eq 'Unix') {
    Write-Output "ERROR: This script is Windows-only and cannot run on macOS/Linux."
    Write-Output "Intune Management Extension is only available on Windows."
    exit 1
}

# Intune Detection Script: Checks AppWorkload.log for failed or not detected Win32 app installations

$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log"
$logPathOld = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log.old"

# Check if log files exist
$logFiles = @()
if (Test-Path $logPath) {
    $logFiles += $logPath
}
if (Test-Path $logPathOld) {
    $logFiles += $logPathOld
}

if ($logFiles.Count -eq 0) {
    Write-Output "No log files found. Intune Management Extension may not be installed or running."
    exit 1
}

# Define enhanced patterns that indicate detection or installation issues
$patterns = @{
    # Detection failures
    "DetectionFailed" = @(
        "detection state: NotDetected",
        "detection state: Failed",
        "DetectionErrorOccurred.:true",
        "Detection for policy with id: .* resulted in action status: Failure",
        "Detection for policy with id: .* resulted in action status: Success and detection state: NotDetected"
    )
    # Installation failures
    "InstallationFailed" = @(
        "Status: Failed",
        "Status: NotInstalled",
        "EnforcementErrorCode",
        "App installation failed",
        "App install failed",
        "Installation failed with exit code"
    )
    # Download and network errors
    "DownloadError" = @(
        "Failed to download content",
        "Download failed",
        "Content download error",
        "Unable to download",
        "DownloadContentFailed"
    )
    # Timeout errors
    "TimeoutError" = @(
        "Installation timed out",
        "Timeout during installation",
        "ExecutionTimeout",
        "Process timed out"
    )
    # Company Portal specific errors
    "CompanyPortalError" = @(
        "CompanyPortal.*error",
        "CompanyPortal.*failed",
        "User enrollment failed",
        "Self-service install failed"
    )
    # Registry and service errors
    "SystemError" = @(
        "Access denied",
        "Permission denied",
        "Service not running",
        "Registry error",
        "WMI error"
    )
}

# Only check log entries from the last 10 days
$cutoff = (Get-Date).AddDays(-10)
$allIssues = @()

foreach ($logFile in $logFiles) {
    Write-Output "Scanning log file: $logFile"
    
    try {
        $logLines = Get-Content -Path $logFile -ErrorAction Stop
        
        foreach ($line in $logLines) {
            # Try to parse date with error handling
            $lineDate = $null
            if ($line -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
                try {
                    $lineDate = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
                } catch {
                    # If date parsing fails, skip this line
                    continue
                }
            } else {
                # No date found, skip line
                continue
            }
            
            # Skip if line is older than cutoff
            if ($lineDate -lt $cutoff) {
                continue
            }
            
            # Check against all pattern categories
            foreach ($category in $patterns.Keys) {
                foreach ($pattern in $patterns[$category]) {
                    if ($line -match $pattern) {
                        # Extract app name or policy ID
                        $appName = $null
                        $policyId = $null
                        
                        if ($line -match 'App Name: ([^,;\|]+)') {
                            $appName = $matches[1].Trim()
                        } elseif ($line -match 'ApplicationName.:."([^"]+)"') {
                            $appName = $matches[1].Trim()
                        } elseif ($line -match 'policy with id: ([a-fA-F0-9\-]+)') {
                            $policyId = $matches[1]
                        } elseif ($line -match 'PolicyId.:."([a-fA-F0-9\-]+)"') {
                            $policyId = $matches[1]
                        }
                        
                        $allIssues += [PSCustomObject]@{
                            Category = $category
                            AppName = $appName
                            PolicyId = $policyId
                            Pattern = $pattern
                            Date = $lineDate
                            LogFile = Split-Path $logFile -Leaf
                        }
                        
                        break  # Exit inner loop after first match
                    }
                }
            }
        }
    } catch {
        Write-Output "Error reading log file $logFile : $_"
    }
}

# Output results
if ($allIssues.Count -gt 0) {
    Write-Output "`n=========================================="
    Write-Output "INTUNE WIN32 APP ISSUES DETECTED"
    Write-Output "=========================================="
    Write-Output "Total issues found: $($allIssues.Count)"
    Write-Output "Time period: Last 10 days"
    Write-Output "=========================================="
    
    # Group by category
    $groupedIssues = $allIssues | Group-Object -Property Category
    
    foreach ($group in $groupedIssues) {
        Write-Output "`n[$($group.Name)] - $($group.Count) issue(s):"
        
        # Get unique apps/policies in this category
        $uniqueItems = $group.Group | Select-Object AppName, PolicyId -Unique
        
        foreach ($item in $uniqueItems) {
            if ($item.AppName) {
                Write-Output "  - App: $($item.AppName)"
            } elseif ($item.PolicyId) {
                Write-Output "  - Policy ID: $($item.PolicyId)"
            } else {
                Write-Output "  - Unknown app (check logs for details)"
            }
        }
    }
    
    Write-Output "`n=========================================="
    Write-Output "RECOMMENDATION: Run remediation script to clean Win32Apps registry and restart Intune service."
    Write-Output "=========================================="
    
    exit 1  # Non-compliant
} else {
    Write-Output "No Intune Win32 app issues detected in the last 10 days."
    Write-Output "System is compliant."
    exit 0  # Compliant
}