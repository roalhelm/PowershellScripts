<#
.SYNOPSIS
    Detects if Dell Command Update is installed on the system.

.DESCRIPTION
    This script checks for Dell Command Update installation using multiple methods:
    1. Windows Registry
    2. Program Files directories
    3. WMI/MSI installation records
    Returns exit code 1 if found, 0 if not found.

.NOTES
    File Name      : Detect-DellCommandUpdate.ps1
    Author         : Ronny Alhelm
    Prerequisite   : PowerShell 5.1 or higher
    Version        : 1.0
    Creation Date  : 2025-03-18
#>

# Initialize detection status
$dellCommandUpdateFound = $false

# Function to write logs
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path "$env:ProgramData\DellCommandUpdateDetection.log" -Value $logMessage
}

# Check Program Files locations
$installPaths = @(
    "${env:ProgramFiles(x86)}\Dell\CommandUpdate",
    "$env:ProgramFiles\Dell\CommandUpdate"
)

foreach ($path in $installPaths) {
    if (Test-Path $path) {
        Write-Log "Dell Command Update found in: $path"
        $dellCommandUpdateFound = $true
        break
    }
}

# Check Windows Registry
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($regPath in $registryPaths) {
    $installed = Get-ItemProperty $regPath | 
        Where-Object { $_.DisplayName -like "*Dell Command*Update*" -or $_.DisplayName -like "*Dell Update*" }
    
    if ($installed) {
        Write-Log "Dell Command Update found in registry: $($installed.DisplayName)"
        $dellCommandUpdateFound = $true
        break
    }
}

# Check WMI for installed software
$wmiCheck = Get-WmiObject -Class Win32_Product | 
    Where-Object { $_.Name -like "*Dell Command*Update*" -or $_.Name -like "*Dell Update*" }

if ($wmiCheck) {
    Write-Log "Dell Command Update found in WMI: $($wmiCheck.Name)"
    $dellCommandUpdateFound = $true
}

# Return result
if ($dellCommandUpdateFound) {
    Write-Log "Dell Command Update is installed on this system"
    exit 1
} else {
    Write-Log "Dell Command Update is not installed on this system"
    exit 0
}