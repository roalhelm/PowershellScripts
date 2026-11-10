<#
.SYNOPSIS
    Intune remediation: get Intune sync running again and trigger a sync.

.DESCRIPTION
    Finding ID: MDM.SYNC.STALE (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps (each one only when needed):
      1. Enables disabled sync tasks under \Microsoft\Windows\EnterpriseMgmt\<EnrollmentId>\.
      2. Sets dmwappushservice back to its default start type (Manual) when it is disabled, and starts it.
      3. Starts the PushLaunch task and the "Schedule #3 created by enrollment client" task,
         which make the device check in with Intune now.

    Nothing is deleted and the enrollment is not changed. When the sync tasks are missing,
    the enrollment itself is damaged and the script only reports that (see MDM.ENROLLMENT.BROKEN).

    Exit 0 = a sync was triggered, exit 1 = sync could not be triggered (see output and log).

.NOTES
    File Name : Remediate-IntuneSync.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-IntuneSync.ps1
#>

$FindingId = 'MDM.SYNC.STALE'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$SyncTaskNames = @('PushLaunch', 'Schedule #3 created by enrollment client')
$Notes = New-Object System.Collections.Generic.List[string]

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Remediate] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
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

Write-FixLog 'Started'

try {
    $ids = @(Get-IntuneEnrollmentId)
    if ($ids.Count -eq 0) {
        $msg = 'No Intune enrollment found. Enroll the device again (see MDM.ENROLLMENT.BROKEN).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    $tasks = @()
    foreach ($id in $ids) {
        $tasks += @(Get-ScheduledTask -TaskPath ("\Microsoft\Windows\EnterpriseMgmt\{0}\" -f $id) -ErrorAction SilentlyContinue)
    }
    if ($tasks.Count -eq 0) {
        $msg = 'Intune sync tasks are missing, so the enrollment is damaged. Enroll the device again (see MDM.ENROLLMENT.BROKEN).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    # 1. Enable disabled tasks.
    foreach ($task in ($tasks | Where-Object { [string]$_.State -eq 'Disabled' })) {
        try {
            Enable-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName -ErrorAction Stop | Out-Null
            Write-FixLog "Enabled task $($task.TaskPath)$($task.TaskName)"
            $Notes.Add("Enabled task '$($task.TaskName)'")
        }
        catch {
            Write-FixLog "Could not enable task $($task.TaskName): $($_.Exception.Message)" 'ERROR'
        }
    }

    # 2. dmwappushservice.
    $push = Get-Service -Name 'dmwappushservice' -ErrorAction SilentlyContinue
    if ($push) {
        if ([string]$push.StartType -eq 'Disabled') {
            try {
                Set-Service -Name 'dmwappushservice' -StartupType Manual -ErrorAction Stop
                Write-FixLog 'dmwappushservice start type set to Manual'
                $Notes.Add('dmwappushservice set to Manual')
            }
            catch {
                Write-FixLog "Could not change dmwappushservice: $($_.Exception.Message)" 'ERROR'
            }
        }
        if ((Get-Service -Name 'dmwappushservice').Status -ne 'Running') {
            try { Start-Service -Name 'dmwappushservice' -ErrorAction Stop; Write-FixLog 'Started dmwappushservice' }
            catch { Write-FixLog "Could not start dmwappushservice: $($_.Exception.Message)" 'WARN' }
        }
    }

    # 3. Trigger a sync.
    $started = 0
    foreach ($id in $ids) {
        $path = "\Microsoft\Windows\EnterpriseMgmt\$id\"
        foreach ($name in $SyncTaskNames) {
            $task = Get-ScheduledTask -TaskPath $path -TaskName $name -ErrorAction SilentlyContinue
            if (-not $task) { continue }
            try {
                Start-ScheduledTask -TaskPath $path -TaskName $name -ErrorAction Stop
                Write-FixLog "Started task $path$name"
                $started++
            }
            catch {
                Write-FixLog "Could not start task ${name}: $($_.Exception.Message)" 'ERROR'
            }
        }
    }

    $summary = if ($Notes.Count -gt 0) { ($Notes -join '; ') + '; ' } else { '' }
    if ($started -gt 0) {
        $msg = "${summary}sync triggered ($started task(s) started)."
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $msg = "${summary}no sync task could be started. Check the DeviceManagement-Enterprise-Diagnostics-Provider/Admin event log."
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
