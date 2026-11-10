<#
.SYNOPSIS
    Detection: the device has not really restarted for more than 14 days.

.DESCRIPTION
    Finding ID: SYS.UPTIME.LONG (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reads the last boot time of the kernel. With Fast Startup, "Shut down" only
    hibernates the kernel, so the uptime keeps counting and updates, drivers and policies
    that wait for a restart are never finished.

    Exit 0 = restarted within 14 days, exit 1 = longer.

.NOTES
    File Name : Detect-LongUptime.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-LongUptime.ps1
#>

$FindingId = 'SYS.UPTIME.LONG'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Detect] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
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

$MaxUptimeDays = 14   # same threshold as Get-ClientHealth.ps1

try {
    $boot = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    $days = [math]::Round(((Get-Date) - $boot).TotalDays, 1)
    $fastStartup = (Get-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled') -eq 1
    if ($days -gt $MaxUptimeDays) {
        $msg = "No real restart for $days days (limit $MaxUptimeDays). Fast Startup enabled: $fastStartup."
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = "Last restart $days days ago."
    Write-FixLog $msg
    Write-Output "$FindingId | OK | $msg"
    exit 0
}
catch {
    $msg = "State could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
