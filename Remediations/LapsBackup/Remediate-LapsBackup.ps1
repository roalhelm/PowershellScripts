<#
.SYNOPSIS
    Remediation: run the Windows LAPS policy processing again and report the result.

.DESCRIPTION
    Finding ID: SEC.LAPS.BACKUPFAILED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Runs Invoke-LapsPolicyProcessing (the same as the hourly background cycle) and then reads
    the newest result from the LAPS event log. The password is only rotated when Windows LAPS
    itself decides that it is due. If processing still fails, the output contains the newest
    LAPS error event, which names the cause (for example LAPS not enabled in the tenant,
    the managed account does not exist, or no line of sight to a domain controller).

    Exit 0 = processing succeeded, exit 1 = still failing.

.NOTES
    File Name : Remediate-LapsBackup.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-LapsBackup.ps1
#>

$FindingId = 'SEC.LAPS.BACKUPFAILED'
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

$LapsLog = 'Microsoft-Windows-LAPS/Operational'

Write-FixLog 'Started'

try {
    if (-not (Get-Command -Name 'Invoke-LapsPolicyProcessing' -ErrorAction SilentlyContinue)) {
        $msg = 'The Windows LAPS PowerShell module is missing. Windows LAPS needs the April 2023 update or newer.'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    $startTime = Get-Date
    $invokeError = $null
    try { Invoke-LapsPolicyProcessing -ErrorAction Stop }
    catch { $invokeError = $_.Exception.Message; Write-FixLog "Invoke-LapsPolicyProcessing: $invokeError" 'WARN' }
    Start-Sleep -Seconds 10

    $last = $null
    try { $last = Get-WinEvent -FilterHashtable @{ LogName = $LapsLog; Id = 10004, 10005; StartTime = $startTime.AddSeconds(-5) } -MaxEvents 1 -ErrorAction Stop } catch { }
    if ($last -and $last.Id -eq 10004) {
        $msg = 'LAPS policy processing succeeded.'
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }

    $cause = $invokeError
    try {
        $errorEvent = Get-WinEvent -FilterHashtable @{ LogName = $LapsLog; Level = 2; StartTime = $startTime.AddSeconds(-5) } -MaxEvents 5 -ErrorAction Stop |
            Where-Object { $_.Id -ne 10005 } | Select-Object -First 1
        if ($errorEvent) { $cause = 'event {0}: {1}' -f $errorEvent.Id, (([string]$errorEvent.Message -replace '\s+', ' ').Trim()) }
    }
    catch { }
    if (-not $cause) { $cause = 'no result event was written; check the log Microsoft-Windows-LAPS/Operational' }
    if ($cause.Length -gt 400) { $cause = $cause.Substring(0, 400) + '...' }
    $msg = "LAPS policy processing still fails ($cause)"
    Write-FixLog "Finished: $msg" 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
catch {
    $msg = "Unexpected error: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
