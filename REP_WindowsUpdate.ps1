#Trigger reset Windows Update
# Stop Services
Stop-Service -Name 'wuauserv' -Force

Stop-Service -Name 'BITS' -Force

# Delete Content in SoftwareDistribution
Remove-Item  -PATH "C:\Windows\SoftwareDistribution" -Recurse -Force

Remove-Item "C:\Windows\System32\GroupPolicy\Machine\Registry.pol" -Force



# Start Services
Start-Service -Name 'wuauserv' 

Start-Service -Name 'BITS'

# Software Update Scan Cycle
([wmiclass]'root\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000113}')

# Software Updates Assignments Evaluation Cycle
([wmiclass]'root\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000108}')
