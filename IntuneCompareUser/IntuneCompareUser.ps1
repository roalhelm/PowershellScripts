<#
.SYNOPSIS
    Compares multiple users in Microsoft Entra ID (Azure AD) based on selected properties and group memberships.

.DESCRIPTION
    This script allows you to compare multiple users in Microsoft Entra ID (Azure AD).
    After signing in with your own user account, you will be prompted to enter the number of users and then the UserPrincipalNames or ObjectIds of the users to compare.
    The script outputs selected properties (DisplayName, Mail, AccountEnabled) of all users side by side.
    Additionally, it compares the group memberships of all users and lists which groups are missing for each user.

.NOTES
    Filename: IntuneCompareUser.ps1
    Requirements:
        - PowerShell with internet access
        - AzureAD module installed (will be installed automatically if missing)
        - Permission to read user and group information in Entra ID (Azure AD)

.AUTHOR
    Ronny Alhelm

.VERSION
    1.2.0

.VERSIONHISTORY
    1.0.0 - Initial version
    1.1.0 - Added group membership comparison
    1.2.0 - Support for comparing multiple users

.EXAMPLE
    .\IntuneCompareUser.ps1
    # After entering the number of users and their UserPrincipalNames or ObjectIds, the main properties and group memberships of all users will be compared and displayed.
#>

# Install the AzureAD module if not already present
if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    Install-Module -Name AzureAD -Force -Scope CurrentUser
}

# Sign in with your user account
Connect-AzureAD

# Prompt for number of users
$userCount = Read-Host "How many users do you want to compare?"
if (-not ($userCount -as [int]) -or $userCount -lt 2) {
    Write-Host "Please enter a valid number (at least 2)." -ForegroundColor Red
    exit 1
}

# Prompt for user identifiers
$userIds = @()
for ($i = 1; $i -le $userCount; $i++) {
    $userId = Read-Host "Enter the UserPrincipalName or ObjectId of user $i"
    $userIds += $userId
}

# Get user objects
$users = @()
foreach ($id in $userIds) {
    $user = Get-AzureADUser -ObjectId $id
    if ($null -eq $user) {
        Write-Host "User '$id' not found." -ForegroundColor Red
        exit 1
    }
    $users += $user
}

# Compare selected properties
$comparison = foreach ($user in $users) {
    [PSCustomObject]@{
        DisplayName    = $user.DisplayName
        Mail           = $user.Mail
        AccountEnabled = $user.AccountEnabled
    }
}
Write-Host "`nUser Properties:" -ForegroundColor Cyan
$comparison | Format-Table -AutoSize

# Compare group memberships
$userGroups = @{}
foreach ($user in $users) {
    $groups = Get-AzureADUserMembership -ObjectId $user.ObjectId | Where-Object {$_.ObjectType -eq "Group"}
    $userGroups[$user.DisplayName] = $groups.DisplayName
}

Write-Host "`nGroup Membership Differences:" -ForegroundColor Cyan
foreach ($user in $users) {
    $otherUsers = $users | Where-Object { $_.ObjectId -ne $user.ObjectId }
    $otherGroupNames = $otherUsers | ForEach-Object { $userGroups[$_.DisplayName] } | Select-Object -Unique
    $missingGroups = $otherGroupNames | Where-Object { $_ -notin $userGroups[$user.DisplayName] }
    Write-Host "`nGroups assigned to at least one other user but missing for $($user.DisplayName):" -ForegroundColor Yellow
    if ($missingGroups) {
        $missingGroups | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "None"
    }
}