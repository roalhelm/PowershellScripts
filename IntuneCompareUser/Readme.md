# IntuneCompareUser.ps1

## Overview

**IntuneCompareUser.ps1** is a PowerShell script that allows you to compare multiple users in Microsoft Entra ID (Azure AD) based on selected user properties and group memberships.  
It is especially useful for administrators who need to analyze differences in group assignments or user attributes across several accounts.

---

## Features

- **Compare any number of users** (minimum 2, prompted at runtime)
- **Displays key user properties**: DisplayName, Mail, AccountEnabled
- **Compares group memberships** for all selected users
- **Lists missing groups** for each user (groups assigned to at least one other user but missing for the current user)
- **Interactive prompts** for user input
- **Automatic AzureAD module installation** if not present

---

## Requirements

- PowerShell (Windows, macOS, or Linux)
- Internet access (for module installation and Azure AD connection)
- AzureAD PowerShell module (installed automatically if missing)
- Permission to read user and group information in Microsoft Entra ID (Azure AD)

---

## Usage

1. **Clone or download** this repository.
2. Open a PowerShell terminal.
3. Run the script:

    ```powershell
    .\IntuneCompareUser.ps1
    ```

4. **Follow the prompts:**
    - Enter the number of users you want to compare (minimum 2).
    - Enter the UserPrincipalName or ObjectId for each user.

5. The script will display:
    - A table with the main properties of all users.
    - For each user, a list of groups that are assigned to at least one other user but missing for the current user.

---

## Example Output

```
How many users do you want to compare? 3
Enter the UserPrincipalName or ObjectId of user 1: user1@domain.com
Enter the UserPrincipalName or ObjectId of user 2: user2@domain.com
Enter the UserPrincipalName or ObjectId of user 3: user3@domain.com

User Properties:
DisplayName    Mail                  AccountEnabled
------------   -------------------   --------------
User One       user1@domain.com      True
User Two       user2@domain.com      True
User Three     user3@domain.com      False

Group Membership Differences:

Groups assigned to at least one other user but missing for User One:
Group A
Group B

Groups assigned to at least one other user but missing for User Two:
Group C

Groups assigned to at least one other user but missing for User Three:
None
```

---

## Notes

- The script uses the legacy `AzureAD` module. For new environments, consider migrating to the [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/).
- You must have sufficient permissions in Azure AD to read user and group information.
- The script will exit if any entered user cannot be found.

---

## Author

Ronny Alhelm

---

## Version History

- **1.0.0** - Initial version
- **1.1.0** - Added group membership comparison
- **1.2.0** - Support for comparing multiple users

---