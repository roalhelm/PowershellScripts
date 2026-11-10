<#
.SYNOPSIS
    Remediation: turn off Fast Startup so that the next shutdown is a real restart.

.DESCRIPTION
    Finding ID: SYS.UPTIME.LONG (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Sets HiberbootEnabled to 0 (Fast Startup off). Hibernate itself stays available. The
    script never restarts the device: the user (or a restart deadline policy) has to do that.
    Nothing is changed when a Group Policy or Intune policy controls Fast Startup.

    Exit 0 = Fast Startup turned off (restart still needed), exit 1 = Fast Startup was already
    off or is set by policy, so only a restart helps.

.NOTES
    File Name : Remediate-LongUptime.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-LongUptime.ps1
#>

$FindingId = 'SYS.UPTIME.LONG'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Remediate] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try {
        $folder = Split-Path -Path $LogFile -Parent
        if (-not (Test-Path -LiteralPath $folder)) { New-Item -Path $folder -ItemType Directory -Force | Out-Null }
        Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop
    }
    catch { }
}

function Get-RegValue {
    param([string]$Path, [string]$Name)
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name }
    catch { return $null }
}

$PowerKey  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
$PolicyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'

Write-FixLog 'Started'

try {
    $boot = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    $days = [math]::Round(((Get-Date) - $boot).TotalDays, 1)

    $policy = Get-RegValue -Path $PolicyKey -Name 'HiberbootEnabled'
    if ($null -ne $policy) {
        $msg = "Fast Startup is set by policy (HiberbootEnabled = $policy), not changed. Uptime $days days: restart the device."
        Write-FixLog "Finished: $msg" 'WARN'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    if ((Get-RegValue -Path $PowerKey -Name 'HiberbootEnabled') -ne 1) {
        $msg = "Fast Startup is already off. Uptime $days days: the device was simply not restarted. Restart it, or set a restart deadline in the update ring."
        Write-FixLog "Finished: $msg" 'WARN'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    Set-ItemProperty -LiteralPath $PowerKey -Name 'HiberbootEnabled' -Value 0 -Type DWord -ErrorAction Stop
    $msg = "Fast Startup turned off. Uptime $days days: the next shutdown or restart by the user is a real restart."
    Write-FixLog "Finished: $msg"
    Write-Output "$FindingId | Fixed | $msg"
    exit 0
}
catch {
    $msg = "Unexpected error: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
