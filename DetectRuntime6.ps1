<#
.SYNOPSIS
    Intune detection script to check if Microsoft Windows Desktop Runtime 6.x is installed on the system.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script is designed for use with Microsoft Intune as a detection script for application deployment.
    It searches the Windows registry to determine if any version of Microsoft Windows Desktop Runtime 6.x
    is installed on the system. The script checks both 32-bit and 64-bit registry locations to ensure
    comprehensive detection across different system architectures.
    
    The script returns appropriate exit codes for Intune:
    - Exit 1: Runtime detected (application is installed)
    - Exit 0: Runtime not detected (application is not installed)
    
    This is useful for conditional application deployment where .NET 6 runtime is a prerequisite.

.NOTES
    File Name     : DetectRuntime6.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025
    Purpose       : Intune application detection script
    Requirements  : PowerShell 5.1 or higher
    Registry Paths: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
                   HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall

.CHANGES
    Version 1.0 (2025-10-13):
    - Initial release
    - Added registry scanning for both x86 and x64 locations
    - Implemented proper Intune exit codes
    - Added German language output messages
    - Error handling for registry access

.VERSION
    1.0

.EXAMPLE
    .\DetectRuntime6.ps1
    Runs the detection script and outputs whether Microsoft Windows Desktop Runtime 6.x is found.
    
    Example Output (if found):
    Gefunden: Microsoft Windows Desktop Runtime - 6.0.25
    Microsoft Windows Desktop Runtime - 6.* wurde gefunden.
    Exit Code: 1

.EXAMPLE
    # Use in Intune Win32 App as detection rule
    # Detection Rule Type: Use a custom detection script
    # Script file: DetectRuntime6.ps1
    # Run script as 32-bit process on 64-bit clients: No

.EXAMPLE
    # Manual testing from PowerShell
    & ".\DetectRuntime6.ps1"
    $exitCode = $LASTEXITCODE
    Write-Host "Exit code: $exitCode"

#>

# Intune Detection Script: Prüft, ob eine oder mehrere Versionen von "Microsoft Windows Desktop Runtime - 6.*" installiert sind

$found = $false
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($path in $registryPaths) {
    $subKeys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    foreach ($subKey in $subKeys) {
        $displayName = (Get-ItemProperty -Path "$path\$($subKey.PSChildName)" -ErrorAction SilentlyContinue).DisplayName
        if ($displayName -like "Microsoft Windows Desktop Runtime - 6*") {
            Write-Output "Gefunden: $displayName"
            $found = $true
        }
    }
}

if ($found) {
    Write-Output "Microsoft Windows Desktop Runtime - 6.* wurde gefunden."
    exit 1  # Detected
} else {
    Write-Output "Microsoft Windows Desktop Runtime - 6.* wurde nicht gefunden."
    exit 0  # Not detected
}