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

# CHANGELOG
#   1.2 (2025-09-12) - Output now includes app name or policyId and error type if available; all comments in English
#   1.1 (2025-09-12) - Only checks log entries from the last 10 days
#   1.0 (2025-09-05) - Initial release
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


# Only check log entries from the last 10 days
$cutoff = (Get-Date).AddDays(-10)
$logLines = Get-Content -Path $logPath
$recentLines = $logLines | Where-Object {
    # Try to detect a date at the beginning of the line (format: yyyy-MM-dd HH:mm:ss)
    if ($_ -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
        $date = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
        return $date -ge $cutoff
    } else {
        return $false
    }
}

$foundIssues = $false
$issueCount = 0
foreach ($line in $recentLines) {
    foreach ($pattern in $patterns) {
        if ($line -match $pattern) {
            # Try to extract app name or policy id from the line
            $appName = $null
            $policyId = $null
            if ($line -match 'App Name: ([^,;\|]+)') {
                $appName = $matches[1].Trim()
            } elseif ($line -match 'policy with id: ([a-fA-F0-9\-]+)') {
                $policyId = $matches[1]
            }
            $errorText = $pattern
            if ($appName) {
                Write-Output "Issue found for App: $appName | Error: $errorText"
            } elseif ($policyId) {
                Write-Output "Issue found for PolicyId: $policyId | Error: $errorText"
            } else {
                Write-Output "Issue found: $line"
            }
            $foundIssues = $true
            $issueCount++
            break
        }
    }
}

if ($foundIssues) {
    Write-Output "Total issues found: $issueCount"
    exit 1  # Detection: Issue found
} else {
    Write-Output "No app detection or installation issues found in log (last 10 days)."
    exit 0  # Detection: No issue
}