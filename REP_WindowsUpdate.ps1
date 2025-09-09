# Author: Ronny Alhelm
# Date: 11/12/2024
# Version: 1.0

# Synopsis:
# This PowerShell script is designed to reset the Windows Update components on a Windows system.
# It accomplishes this by stopping necessary services, removing cached update files, and triggering
# update scans. This can help resolve issues with Windows Update when updates are stuck or fail to install.
# GitHub Repository: https://github.com/roalhelm/

# Description:
# This script will:
# 1. Stop the Windows Update service (`wuauserv`) and the Background Intelligent Transfer Service (`BITS`),
#    which are required to pause for clearing update files safely.
# 2. Delete the contents of the `SoftwareDistribution` folder, where Windows stores update files, and remove
#    any existing Group Policy registry configurations related to updates. This helps to remove any corrupted
#    update data or configurations that might be causing issues.
# 3. Restart the stopped services.
# 4. Trigger two update scan cycles: one for the update scan itself and one to evaluate any update assignments
#    or deployments. These triggers help ensure that updates are re-evaluated and new updates can be fetched.

# Script:

# Stop Services
Stop-Service -Name 'wuauserv' -Force
Stop-Service -Name 'BITS' -Force

# Delete Content in SoftwareDistribution
Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Force

# Remove Group Policy Update Registry (if present)
Remove-Item "C:\Windows\System32\GroupPolicy\Machine\Registry.pol" -Force

# Start Services
Start-Service -Name 'wuauserv'
Start-Service -Name 'BITS'

# Software Update Scan Cycle
([wmiclass]'root\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000113}')

# Software Updates Assignments Evaluation Cycle
([wmiclass]'root\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000108}')
