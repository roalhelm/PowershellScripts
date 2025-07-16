<#
.SYNOPSIS
    Installs all missing Office updates via Windows Update.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script checks for pending Office updates using Windows Update.
    If any Office updates are missing, it installs them automatically and reboots if required.
    The script uses the PSWindowsUpdate module and works interactively or in automation.

.NOTES
    Filename: remediatOfficeUpdates.ps1
    Requires: PSWindowsUpdate PowerShell module
    Permission: Requires rights to query Windows Update

.AUTHOR
    Ronny Alhelm

.VERSION
    1.0

.HISTORY
    1.0 - Initial version

.EXAMPLE
    .\remediatOfficeUpdates.ps1
    # Installs all missing Office updates
#>

# Installiert alle fehlenden Office-Updates über Windows Update

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

# Suche nach ausstehenden Office-Updates
$officeUpdates = Get-WindowsUpdate -MicrosoftUpdate | Where-Object {
    $_.Categories -contains 'Office' -and $_.Status -ne 'Installed'
}

if ($officeUpdates) {
    Write-Host "Es wurden ausstehende Office-Updates gefunden. Installation wird gestartet..."
    Install-WindowsUpdate -MicrosoftUpdate -Category 'Office' -AcceptAll -AutoReboot
    Write-Host "Office-Updates wurden installiert."
    exit 0
} else {
    Write-Host "Keine ausstehenden Office-Updates gefunden."
    exit 0
}