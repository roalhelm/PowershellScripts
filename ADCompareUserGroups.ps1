<#
.SYNOPSIS
    Compares the group memberships of two Active Directory users. (Version 1.0)
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script retrieves the group memberships of two users from Active Directory and compares them. It lists the groups for each user and highlights any groups that the second user is missing compared to the first user.

.NOTES
    Version:        1.1
    Requires:       Active Directory PowerShell Module
    Compatibility:  Windows Server with Active Directory

.AUTHOR
    Script created by Ronny Alhelm
    Date: 12.03.2025

.EXAMPLE
    PS C:\> .\Compare-UserGroups.ps1
    Enter User1 name: Max.Mustermann
    Enter User2 name: John.Doe
    Groups of Max.Mustermann:
    - Group1
    - Group2
    - Group3
    
    Groups of John.Doe:
    - Group1
    - Group3
    
    Groups missing for John.Doe:
    - Group2
#>

# Define users
$User1 = Read-Host "Enter User1 name"
$User2 = Read-Host "Enter User2 name"

# Function to retrieve a user's group names
function Get-UserGroups {
    param ($User)
    Get-ADUser -Identity $User -Property MemberOf | Select-Object -ExpandProperty MemberOf | ForEach-Object { ($_ -split ',')[0] -replace 'CN=' }
}

# Retrieve groups for each user
$GroupsUser1 = Get-UserGroups -User $User1
$GroupsUser2 = Get-UserGroups -User $User2

# Output groups for each user
Write-Host "Groups of $User1 :" -ForegroundColor Green
$GroupsUser1 | ForEach-Object { Write-Host $_ }

Write-Host "`nGroups of $User2 :" -ForegroundColor Cyan
$GroupsUser2 | ForEach-Object { Write-Host $_ }

# Compare groups: Which groups is User2 missing?
$MissingGroups = $GroupsUser1 | Where-Object { $_ -notin $GroupsUser2 }

Write-Host "`nGroups missing for $User2 :" -ForegroundColor Yellow
if ($MissingGroups) {
    $MissingGroups | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "No missing groups! Both users have the same groups."
}
