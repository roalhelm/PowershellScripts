<#
.SYNOPSIS
    Detection script for Office updates compliance - designed to work with remediatOfficeUpdates.ps1 remediation.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This Intune detection script determines if Office updates are pending and require remediation.
    It checks for any available Office updates through Windows Update that are not yet installed.
    
    The script performs the following checks:
    1. Verifies PSWindowsUpdate module availability (installs if missing)
    2. Queries Windows Update for all Office-category updates
    3. Identifies pending (not installed) Office updates
    4. Returns appropriate exit codes for Intune remediation workflow
    
    Exit Codes:
    - 0: Compliant (no pending Office updates found)
    - 1: Non-compliant (pending Office updates detected, remediation needed)
    - 2: Error (module installation failed or other critical error)
    
    This detection script is specifically designed to trigger the remediatOfficeUpdates.ps1
    remediation when Office updates are available but not installed.

.NOTES
    File Name     : detectOfficeUpdates.ps1
    Author        : Ronny Alhelm
    Version       : 2.0
    Creation Date : October 13, 2025
    Purpose       : Intune detection script for Office updates remediation
    Requirements  : PowerShell 5.1 or higher
    Dependencies  : PSWindowsUpdate module (auto-installed if missing)
    Permissions   : Standard user rights (module installs to CurrentUser scope)

.CHANGES
    Version 2.0 (2025-10-13):
    - Redesigned for Intune remediation workflow compatibility
    - Enhanced error handling and exit code management
    - Improved PSWindowsUpdate module handling
    - Added comprehensive logging for troubleshooting
    - Simplified detection logic for better reliability
    - Removed monthly filtering to detect all pending Office updates
    - Added detailed documentation and examples

    Version 1.1 (Previous):
    - Improved detection logic and module handling
    - Added monthly update filtering

    Version 1.0 (Previous):
    - Initial release with basic Office update detection

.VERSION
    2.0

.EXAMPLE
    .\detectOfficeUpdates.ps1
    Checks for pending Office updates and returns exit code 0 (compliant) if no updates
    are needed, or exit code 1 (non-compliant) if Office updates are pending.
    
    Example Output (Compliant):
    "No pending Office updates found. System is compliant."
    Exit Code: 0

.EXAMPLE
    # Use in Intune Proactive Remediation
    # Detection Rule Type: Use a custom detection script
    # Detection script file: detectOfficeUpdates.ps1
    # Remediation script file: remediatOfficeUpdates.ps1
    # Run this script using the logged-on credentials: Yes
    # Enforce script signature check: No

.EXAMPLE
    # Manual testing with exit code verification
    .\detectOfficeUpdates.ps1
    $detectionResult = $LASTEXITCODE
    switch ($detectionResult) {
        0 { Write-Host "System is compliant - no remediation needed" }
        1 { Write-Host "System is non-compliant - remediation will be triggered" }
        2 { Write-Host "Detection error occurred" }
    }

#>

# Initialize logging for troubleshooting
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output "[$timestamp] Starting Office Updates detection check"

try {
    # Check and install PSWindowsUpdate module if missing
    Write-Output "[$timestamp] Checking PSWindowsUpdate module availability"
    
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Output "[$timestamp] PSWindowsUpdate module not found. Installing..."
        try {
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
            Write-Output "[$timestamp] PSWindowsUpdate module installed successfully"
        } catch {
            Write-Output "[$timestamp] ERROR: Failed to install PSWindowsUpdate module: $($_.Exception.Message)"
            Write-Output "Module installation failed. Cannot proceed with Office update detection."
            exit 2
        }
    } else {
        Write-Output "[$timestamp] PSWindowsUpdate module found"
    }
    
    # Import the module
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
        Write-Output "[$timestamp] PSWindowsUpdate module imported successfully"
    } catch {
        Write-Output "[$timestamp] ERROR: Failed to import PSWindowsUpdate module: $($_.Exception.Message)"
        Write-Output "Module import failed. Cannot proceed with Office update detection."
        exit 2
    }
    
    # Query for pending Office updates
    Write-Output "[$timestamp] Querying Windows Update for Office updates"
    
    try {
        # Get all Office updates that are available but not installed
        $officeUpdates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop | Where-Object {
            $_.Categories -contains 'Office' -and $_.Status -ne 'Installed'
        }
        
        Write-Output "[$timestamp] Office update query completed"
        
        # Check if any pending Office updates were found
        if ($officeUpdates -and $officeUpdates.Count -gt 0) {
            Write-Output "[$timestamp] DETECTION RESULT: Non-compliant"
            Write-Output "Found $($officeUpdates.Count) pending Office update(s):"
            
            foreach ($update in $officeUpdates) {
                Write-Output "  - $($update.Title) (Size: $([math]::Round($update.Size/1MB, 2)) MB)"
            }
            
            Write-Output "Office updates are pending installation. Remediation required."
            exit 1  # Non-compliant - remediation needed
        } else {
            Write-Output "[$timestamp] DETECTION RESULT: Compliant"
            Write-Output "No pending Office updates found. System is compliant."
            exit 0  # Compliant - no remediation needed
        }
        
    } catch {
        Write-Output "[$timestamp] ERROR: Failed to query Windows Update: $($_.Exception.Message)"
        Write-Output "Windows Update query failed. Cannot determine Office update status."
        exit 2
    }
    
} catch {
    Write-Output "[$timestamp] ERROR: Unexpected error during detection: $($_.Exception.Message)"
    Write-Output "Detection script encountered an unexpected error."
    exit 2
}