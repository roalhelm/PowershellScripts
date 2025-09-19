#region PowerShell Help
<#
.SYNOPSIS
    Detects if the current Windows OS version meets the required minimum for Windows 10 24H2 or Windows 11 24H2 and checks for recent Windows Updates.

    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script checks the OS version and ensures it is at least 10.0.26100 for both Windows 10 and Windows 11 24H2. It also verifies that a recent Windows Update has been installed. If the requirements are not met, the script exits with an error code. If WMI is not available, it attempts a WMI repair.

.NOTES
    File Name     : detection.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : 2025-09-19

.CHANGES
    1.0 - Initial version

.VERSION
    1.0

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\detection.ps1
    # Runs the detection script to check OS version and recent Windows Updates.
#>
#endregion
# Both Windows 10 24H2 and Windows 11 24H2 use version 10.0.26100
$RequiredWin10 = [Version]"10.0.26100"
$RequiredWin11 = [Version]"10.0.26100"

$GetOS = Get-ComputerInfo -property OsVersion
$OSversion = [Version]$GetOS.OsVersion

if  ($OSversion -match [Version]"10.0.1")
    {
    if  ($OSversion -lt $RequiredWin10)
        {
        Write-Output "OS version currently on $OSversion (Windows 10 < 24H2)"
        exit 1
        }
    }

if  ($OSversion -match [Version]"10.0.2")
    {
    if  ($OSversion -lt $RequiredWin11)
        {
        Write-Output "OS version currently on $OSversion (Windows 11 < 24H2)"
        exit 1
        }
    }

do  {
    try {
        $lastupdate = Get-HotFix | Sort-Object -Property InstalledOn | Select-Object -Last 1 -ExpandProperty InstalledOn
        $Date = Get-Date

        $diff = New-TimeSpan -Start $lastupdate -end $Date
        $days = $diff.Days
        }
    catch   {
            Write-Output "Attempting WMI repair"
            Start-Process "C:\Windows\System32\wbem\WMIADAP.exe" -ArgumentList "/f"
            Start-Sleep -Seconds 120
            }
    }
    until ($null -ne $days)

$Date = Get-Date

$diff = New-TimeSpan -Start $lastupdate -end $Date
$days = $diff.Days

if  ($days -ge 40 -or $null -eq $days)
    {
    Write-Output "Troubleshooting Updates - Last update was $days days ago"
    exit 1
    }
else{
    Write-Output "Windows Updates ran $days days ago"
    exit 0
    }