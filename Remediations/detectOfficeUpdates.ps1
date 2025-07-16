<#
.SYNOPSIS
    Detects if the latest monthly Office updates are installed.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script checks for pending Office updates from the last month using Windows Update.
    If any Office updates from the previous month are pending, it returns exit code 1 (not compliant).
    If all Office updates from the previous month are installed, it returns exit code 0 (compliant).
    The script uses the PSWindowsUpdate module and works interactively or in automation.

.NOTES
    Filename: detectOfficeUpdates.ps1
    Requires: PSWindowsUpdate PowerShell module
    Permission: Requires rights to query Windows Update

.AUTHOR
    Ronny Alhelm

.VERSION
    1.1

.HISTORY
    1.0 - Initial version
    1.1 - Improved detection logic and module handling

.EXAMPLE
    .\detectOfficeUpdates.ps1
    # Checks if all Office updates from last month are installed and returns exit code 0 (compliant) or
    exit code 1 (not compliant) accordingly.
#>

# Import PSWindowsUpdate module (install if missing)
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    try {
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
    } catch {
        Write-Host "Failed to install PSWindowsUpdate module. Please install manually."
        exit 1
    }
}
Import-Module PSWindowsUpdate

# Get the first day of last month
$lastMonth = (Get-Date).AddMonths(-1)
$firstDayLastMonth = Get-Date -Year $lastMonth.Year -Month $lastMonth.Month -Day 1
$firstDayThisMonth = Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day 1

# Get all available Office updates
$officeUpdates = Get-WindowsUpdate -MicrosoftUpdate | Where-Object {
    $_.Categories -contains 'Office'
}

# Filter updates released last month and not installed
$pendingLastMonth = $officeUpdates | Where-Object {
    $_.Date -ge $firstDayLastMonth -and $_.Date -lt $firstDayThisMonth -and $_.Status -ne 'Installed'
}

if ($pendingLastMonth) {
    Write-Host "Pending Office updates from last month found."
    exit 1
} else {
    Write-Host "All Office updates from last month are installed."
    exit 0
}