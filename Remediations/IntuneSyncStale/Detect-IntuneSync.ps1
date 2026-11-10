<#
.SYNOPSIS
    Intune detection: the device has not synced with Intune recently, or sync cannot be triggered.

.DESCRIPTION
    Finding ID: MDM.SYNC.STALE (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when, for the Intune (MS DM Server) enrollment,
      - the sync scheduled tasks under \Microsoft\Windows\EnterpriseMgmt\<EnrollmentId>\ are missing,
      - all of them are disabled,
      - none of them ran in the last $MaxDaysSinceSync days, or
      - the dmwappushservice service is disabled (sync from the Intune portal cannot reach the device).

    Not applicable (exit 0) when the device has no Intune enrollment: see MDM.ENROLLMENT.BROKEN.

    Exit 0 = healthy or not applicable, exit 1 = issue found (Intune runs the remediation).

.NOTES
    File Name : Detect-IntuneSync.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-IntuneSync.ps1
#>

$FindingId        = 'MDM.SYNC.STALE'
$MaxDaysSinceSync = 7   # same threshold as Get-ClientHealth.ps1
$LogFile          = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Detect] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
}

function Get-IntuneEnrollmentId {
    $ids = @()
    foreach ($key in (Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue)) {
        $provider = (Get-ItemProperty -LiteralPath $key.PSPath -Name 'ProviderID' -ErrorAction SilentlyContinue).ProviderID
        if ($provider -eq 'MS DM Server') { $ids += $key.PSChildName }
    }
    return $ids
}

try {
    $ids = @(Get-IntuneEnrollmentId)
    if ($ids.Count -eq 0) {
        $msg = 'Not applicable: no Intune enrollment found (see MDM.ENROLLMENT.BROKEN).'
        Write-FixLog $msg
        Write-Output "$FindingId | OK | $msg"
        exit 0
    }

    $tasks = @()
    foreach ($id in $ids) {
        $tasks += @(Get-ScheduledTask -TaskPath ("\Microsoft\Windows\EnterpriseMgmt\{0}\" -f $id) -ErrorAction SilentlyContinue)
    }
    if ($tasks.Count -eq 0) {
        $msg = 'Intune sync tasks are missing. The enrollment is damaged (see MDM.ENROLLMENT.BROKEN).'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }

    $disabled = @($tasks | Where-Object { [string]$_.State -eq 'Disabled' })
    $lastRun = $null
    foreach ($task in $tasks) {
        $info = $task | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
        if ($info -and $info.LastRunTime -and $info.LastRunTime.Year -gt 2000) {
            if (-not $lastRun -or $info.LastRunTime -gt $lastRun) { $lastRun = $info.LastRunTime }
        }
    }
    $push = Get-Service -Name 'dmwappushservice' -ErrorAction SilentlyContinue

    $problems = @()
    if ($disabled.Count -eq $tasks.Count) { $problems += 'all sync tasks are disabled' }
    if (-not $lastRun) { $problems += 'sync tasks have never run' }
    elseif (((Get-Date) - $lastRun).TotalDays -gt $MaxDaysSinceSync) { $problems += ('last sync task run {0:yyyy-MM-dd}' -f $lastRun) }
    if ($push -and [string]$push.StartType -eq 'Disabled') { $problems += 'dmwappushservice is disabled' }

    if ($problems.Count -gt 0) {
        $msg = ($problems -join '; ') + '.'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }

    $msg = ('Intune sync runs (last sync task run {0:yyyy-MM-dd HH:mm}).' -f $lastRun)
    Write-FixLog $msg
    Write-Output "$FindingId | OK | $msg"
    exit 0
}
catch {
    $msg = "Sync state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
