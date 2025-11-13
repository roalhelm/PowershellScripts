<#
.SYNOPSIS
    Lists duplicate Windows devices with Corporate ownership from Entra ID and exports the results to CSV.

    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script connects to Microsoft Entra ID (Azure AD) and retrieves all Windows devices with Corporate ownership.
    It identifies duplicate device names and displays them along with important information such as:
    - Last sign-in date (ApproximateLastSignInDateTime)
    - Registration date
    - Compliance and management status
    - Operating system version
    - Trust type
    
    The results are displayed in the console and automatically exported to a CSV file in the same directory as the script.
    This is useful for identifying stale or duplicate device registrations that may need cleanup.

.NOTES
    File Name     : Get-DuplicateEntraDevices.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : 13.11.2025
    Requires      : Microsoft.Graph PowerShell Module
    Permissions   : Device.Read.All

.CHANGES
    Version 1.0 (13.11.2025)
    - Initial release
    - Interactive authentication with Microsoft Graph
    - Filters for Windows devices with Corporate ownership
    - Identifies and reports duplicate device names
    - Exports results to CSV in script directory

.VERSION
    1.0

.EXAMPLE
    .\Get-DuplicateEntraDevices.ps1
    
    Connects to Entra ID with interactive login, retrieves all Windows Corporate devices,
    identifies duplicates, displays them in the console, and exports to CSV file.

.EXAMPLE
    .\Get-DuplicateEntraDevices.ps1
    
    Example output:
    Found 450 Windows devices with Corporate ownership
    Found 12 device names with duplicates
    Total duplicate device objects: 28
    Results exported to: C:\Dev\DuplicateEntraDevices_20251113_143052.csv
#>

# ================================================================================================================
# Script: Get-DuplicateEntraDevices.ps1
# Description: Lists duplicate Windows devices with Corporate ownership from Entra ID
# ================================================================================================================

# ----------------------------------------- Install Required Modules -------------------------------------------------
if(!(Get-Module -Name Microsoft.Graph -ListAvailable))
{
    Write-Host "Installing Microsoft.Graph module..." -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph -Force -AllowClobber
}

# ----------------------------------------- Connect to Microsoft Graph -----------------------------------------------
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Device.Read.All" -NoWelcome

Write-Host "Successfully connected to Microsoft Graph" -ForegroundColor Green
Write-Host ""

# ----------------------------------------- Get All Entra Devices ----------------------------------------------------
Write-Host "Retrieving all devices from Entra ID..." -ForegroundColor Cyan
$AllDevices = Get-MgDevice -All | Where-Object {
    $_.OperatingSystem -like "*Windows*" -and 
    $_.DeviceOwnership -eq "Company"
}

Write-Host "Found $($AllDevices.Count) Windows devices with Corporate ownership" -ForegroundColor Green
Write-Host ""

# ----------------------------------------- Find Duplicate Devices ---------------------------------------------------
Write-Host "Analyzing for duplicate device names..." -ForegroundColor Cyan

# Group devices by DisplayName
$GroupedDevices = $AllDevices | Group-Object -Property DisplayName

# Filter only duplicates (Count > 1)
$DuplicateDevices = $GroupedDevices | Where-Object { $_.Count -gt 1 }

if($DuplicateDevices.Count -eq 0)
{
    Write-Host "No duplicate devices found!" -ForegroundColor Green
    Disconnect-MgGraph | Out-Null
    exit
}

Write-Host "Found $($DuplicateDevices.Count) device names with duplicates" -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------- Prepare Results ----------------------------------------------------------
$Results = @()

foreach($Group in $DuplicateDevices)
{
    $DeviceName = $Group.Name
    $DeviceCount = $Group.Count
    
    Write-Host "Processing: $DeviceName ($DeviceCount duplicates)" -ForegroundColor Cyan
    
    foreach($Device in $Group.Group)
    {
        $Results += [PSCustomObject]@{
            DeviceName          = $Device.DisplayName
            DeviceId            = $Device.DeviceId
            ObjectId            = $Device.Id
            OperatingSystem     = $Device.OperatingSystem
            OSVersion           = $Device.OperatingSystemVersion
            TrustType           = $Device.TrustType
            IsCompliant         = $Device.IsCompliant
            IsManaged           = $Device.IsManaged
            ApproximateLastSignInDateTime = $Device.ApproximateLastSignInDateTime
            RegistrationDateTime = $Device.RegistrationDateTime
            AccountEnabled      = $Device.AccountEnabled
            DuplicateCount      = $DeviceCount
        }
    }
}

# ----------------------------------------- Display Results ----------------------------------------------------------
Write-Host ""
Write-Host "========================================================================================================" -ForegroundColor Green
Write-Host "DUPLICATE WINDOWS DEVICES (Corporate Ownership)" -ForegroundColor Green
Write-Host "========================================================================================================" -ForegroundColor Green
Write-Host ""

# Display results sorted by DeviceName and LastSignIn
$Results | Sort-Object DeviceName, ApproximateLastSignInDateTime -Descending | Format-Table -AutoSize

# ----------------------------------------- Export to CSV ------------------------------------------------------------
# Get script directory
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

$ExportFile = "$ScriptPath\DuplicateEntraDevices_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$Results | Sort-Object DeviceName, ApproximateLastSignInDateTime -Descending | Export-Csv -Path $ExportFile -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Results exported to: $ExportFile" -ForegroundColor Green

# ----------------------------------------- Summary ------------------------------------------------------------------
Write-Host ""
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "Total Windows Corporate Devices: $($AllDevices.Count)" -ForegroundColor White
Write-Host "Device names with duplicates: $($DuplicateDevices.Count)" -ForegroundColor Yellow
Write-Host "Total duplicate device objects: $($Results.Count)" -ForegroundColor Yellow
Write-Host ""

# Show top duplicates
Write-Host "Top 5 Device Names by Duplicate Count:" -ForegroundColor Cyan
$DuplicateDevices | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Host "  - $($_.Name): $($_.Count) instances" -ForegroundColor White
}

Write-Host ""

# ----------------------------------------- Disconnect ---------------------------------------------------------------
Disconnect-MgGraph | Out-Null
Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Green
