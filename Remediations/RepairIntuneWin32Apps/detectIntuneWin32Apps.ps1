<#
.SYNOPSIS
    Detects failed or not detected Win32 app installations by scanning the AppWorkload.log.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script analyzes the AppWorkload.log for patterns indicating failed or not detected Win32 app installations.
    It returns exit code 1 if any issues are found, otherwise exit code 0.

.NOTES
    File Name      : detectIntuneWin32Apps.ps1
    Author         : Ronny Alhelm
    Prerequisite   : PowerShell 5.1 or higher
    Version        : 1.0
    Creation Date  : 2025-09-05

.CHANGELOG
    1.0 (2025-09-05) - Initial release.
#>
# Intune Detection Script: Checks AppWorkload.log for failed or not detected Win32 app installations

$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log"

if (-not (Test-Path $logPath)) {
    Write-Output "Log file not found."
    exit 1
}

# Define patterns that indicate detection or installation issues
$patterns = @(
    "detection state: NotDetected",
    "detection state: Failed",
    "DetectionErrorOccurred.:true",
    "EnforcementErrorCode",
    "Status: Failed",
    "Status: NotInstalled",
    "Status: NotDetected",
    "ErrorCode",
    "App installation failed",
    "App install failed",
    "Detection for policy with id: .* resulted in action status: Failure",
    "Detection for policy with id: .* resulted in action status: Success and detection state: NotDetected"
)

# Read log and search for patterns
$logContent = Get-Content -Path $logPath -Raw

$foundIssues = $false

foreach ($pattern in $patterns) {
    if ($logContent -match $pattern) {
        Write-Output "Issue found in log: $pattern"
        $foundIssues = $true
    }
}

if ($foundIssues) {
    exit 1  # Detection: Issue found
} else {
    Write-Output "No app detection or installation issues found in log."
    exit 0  # Detection: No issue
}