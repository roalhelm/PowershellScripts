<#
.SYNOPSIS
    Retrieves all Azure AD groups and devices using Microsoft Graph API with support for @odata.nextLink paging.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script connects to Microsoft Graph using the Microsoft Graph PowerShell SDK.
    It retrieves all Azure AD groups and all devices by handling paginated results via the @odata.nextLink property.
    The script demonstrates how to loop through paged Graph API results and aggregate all objects into arrays.
    At the end, it outputs the total count of groups and devices retrieved.

.NOTES
    Filename: GraphApiOdataNextLink.ps1
    Requires: Microsoft.Graph PowerShell module
    Permissions: Directory.Read.All or higher

.AUTHOR
    Ronny Alhelm

.VERSION
    1.0

.HISTORY
    1.0 - Initial version

.EXAMPLE
    .\GraphApiOdataNextLink.ps1
    # Connects to Microsoft Graph, retrieves all groups and devices, and outputs their counts.
#>

Connect-MgGraph

$groupsUri = "https://graph.microsoft.com/beta/groups"

$allGroups = @()

do {
    $response = Invoke-MgGraphRequest -Uri $groupsUri -Method Get
    $allGroups += $response.value
    $groupsUri = $response.'@odata.nextLink'
} while ($groupsUri)

$allGroups.Count

$devicesUri = "https://graph.microsoft.com/beta/devices"

$allDevices = @()

do {
    $response = Invoke-MgGraphRequest -Uri $devicesUri -Method Get
    $allDevices += $response.value
    $devicesUri = $response.'@odata.nextLink'
} while ($devicesUri)

$allDevices.Count
