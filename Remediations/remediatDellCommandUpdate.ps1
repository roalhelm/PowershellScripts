<#
.SYNOPSIS
    Uninstalls Dell Command Update from the system.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script removes Dell Command Update by:
    1. Identifying installed versions through registry and WMI
    2. Stopping related processes
    3. Uninstalling the application using appropriate method
    4. Cleaning up remaining files and registry entries

.NOTES
    File Name      : Uninstall-DellCommandUpdate.ps1
    Author         : Ronny Alhelm
    Prerequisite   : PowerShell 5.1 or higher
    Version        : 1.0
    Creation Date  : 2025-03-18
#>

# Stop Dell Command Update processes if running
$processNames = @("DellCommandUpdate", "DellCommandUpdateApp", "DellCommandUpdateCliApp")
foreach ($process in $processNames) {
    Get-Process -Name $process -ErrorAction SilentlyContinue | Stop-Process -Force
}

# Function to write logs
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path "$env:ProgramData\DellCommandUpdateUninstall.log" -Value $logMessage
}

# Get Dell Command Update installations
$installations = Get-WmiObject -Class Win32_Product | Where-Object { 
    $_.Name -like "*Dell Command*Update*" #-or 
    #$_.Name -like "*Dell Update*" 
}

if ($installations) {
    foreach ($app in $installations) {
        Write-Log "Attempting to uninstall: $($app.Name)"
        try {
            $app.Uninstall()
            Write-Log "Successfully uninstalled $($app.Name)"
        }
        catch {
            Write-Log "Error uninstalling $($app.Name): $_"
        }
    }
}

# Check for MSI-based installation
$msiPaths = @(
    "${env:ProgramFiles(x86)}\Dell\CommandUpdate",
    "$env:ProgramFiles\Dell\CommandUpdate"
)

foreach ($path in $msiPaths) {
    if (Test-Path $path) {
        Write-Log "Found Dell Command Update installation at: $path"
        $uninstallString = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Where-Object { $_.DisplayName -like "*Dell Command*Update*" }).UninstallString

        if ($uninstallString) {
            Write-Log "Executing uninstall string: $uninstallString"
            Start-Process "msiexec.exe" -ArgumentList "/x $($uninstallString.Split()[0]) /qn" -Wait
        }
    }
}

# Cleanup remaining files and folders
$foldersToRemove = @(
    "${env:ProgramFiles(x86)}\Dell\CommandUpdate",
    "$env:ProgramFiles\Dell\CommandUpdate",
    "$env:ProgramData\Dell\CommandUpdate"
)

foreach ($folder in $foldersToRemove) {
    if (Test-Path $folder) {
        try {
            Remove-Item -Path $folder -Recurse -Force
            Write-Log "Removed folder: $folder"
        }
        catch {
            Write-Log "Error removing folder $folder : $_"
        }
    }
}

# Cleanup registry entries
$registryPaths = @(
    "HKLM:\SOFTWARE\Dell\CommandUpdate",
    "HKLM:\SOFTWARE\WOW6432Node\Dell\CommandUpdate"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Log "Removed registry key: $regPath"
        }
        catch {
            Write-Log "Error removing registry key $regPath : $_"
        }
    }
}

Write-Log "Dell Command Update uninstallation process completed"