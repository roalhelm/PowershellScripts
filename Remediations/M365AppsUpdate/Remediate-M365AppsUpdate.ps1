<#
.SYNOPSIS
    Remediation: get the Microsoft 365 Apps update mechanism running and start an update.

.DESCRIPTION
    Finding ID: APP.M365.UPDATESTUCK (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps (each one only when needed):
      1. Sets the Click-to-Run service back to Automatic and starts it.
      2. Sets UpdatesEnabled back to True (only when no policy turns updates off).
      3. Enables the scheduled task "Office Automatic Updates 2.0".
      4. Starts an update in the background (OfficeC2RClient.exe /update user) without
         closing open Office apps. The update is applied when the apps are closed.

    The update channel and the update source are not changed. Nothing is changed when
    Configuration Manager manages the updates or a policy turns automatic updates off.

    Exit 0 = update mechanism repaired and update started, exit 1 = still broken.

.NOTES
    File Name : Remediate-M365AppsUpdate.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-M365AppsUpdate.ps1
#>

$FindingId = 'APP.M365.UPDATESTUCK'
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

$ConfigKey = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
$PolicyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate'
$TaskPath  = '\Microsoft\Office\'
$TaskName  = 'Office Automatic Updates 2.0'
$MaxDaysSinceUpdateCheck = 14

function Get-OfficeUpdateState {
    # $null when Microsoft 365 Apps (Click-to-Run) is not installed.
    $version = [string](Get-RegValue -Path $ConfigKey -Name 'VersionToReport')
    if (-not $version) { return $null }
    $state = [ordered]@{
        version       = $version
        channel       = [string](Get-RegValue -Path $ConfigKey -Name 'CDNBaseUrl')
        configMgr     = ([string](Get-RegValue -Path $ConfigKey -Name 'OfficeMgmtCOM') -eq 'True') -or ((Get-RegValue -Path $PolicyKey -Name 'officemgmtcom') -eq 1)
        policyOff     = (Get-RegValue -Path $PolicyKey -Name 'enableautomaticupdates') -eq 0
        updatesOff    = [string](Get-RegValue -Path $ConfigKey -Name 'UpdatesEnabled') -eq 'False'
        serviceStart  = Get-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\ClickToRunSvc' -Name 'Start'
        taskState     = $null
        daysSinceTask = $null
    }
    $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        $state.taskState = [string]$task.State
        $info = $task | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
        if ($info -and $info.LastRunTime -and $info.LastRunTime.Year -gt 2000) {
            $state.daysSinceTask = [math]::Round(((Get-Date) - $info.LastRunTime).TotalDays, 1)
        }
    }
    return $state
}

function Get-OfficeUpdateProblems {
    param($State)
    $problems = @()
    if ($null -eq $State.serviceStart) { $problems += 'ClickToRunSvc service is missing' }
    elseif ($State.serviceStart -eq 4) { $problems += 'ClickToRunSvc service is disabled' }
    if ($State.updatesOff) { $problems += 'automatic updates are turned off (UpdatesEnabled = False)' }
    if (-not $State.taskState) { $problems += "scheduled task '$TaskName' is missing" }
    elseif ($State.taskState -eq 'Disabled') { $problems += "scheduled task '$TaskName' is disabled" }
    elseif ($null -ne $State.daysSinceTask -and $State.daysSinceTask -gt $MaxDaysSinceUpdateCheck) { $problems += "no update check for $($State.daysSinceTask) days" }
    return $problems
}

Write-FixLog 'Started'

try {
    $state = Get-OfficeUpdateState
    $skip = $null
    if (-not $state) { $skip = 'Microsoft 365 Apps (Click-to-Run) is not installed: nothing changed.' }
    elseif ($state.configMgr) { $skip = 'Updates are managed by Configuration Manager: nothing changed.' }
    elseif ($state.policyOff) { $skip = 'Automatic updates are turned off by policy: nothing changed.' }
    if ($skip) {
        Write-FixLog "Finished: $skip"
        Write-Output "$FindingId | Fixed | $skip"
        exit 0
    }

    $notes = @()
    if ($null -eq $state.serviceStart) {
        $msg = 'The Click-to-Run service is missing. Repair Microsoft 365 Apps (Settings > Apps > Microsoft 365 > Modify > Online Repair) or reinstall it from Intune.'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    if ($state.serviceStart -eq 4) {
        Set-Service -Name 'ClickToRunSvc' -StartupType Automatic -ErrorAction Stop
        Write-FixLog 'ClickToRunSvc start type set to Automatic'
        $notes += 'service enabled'
    }
    if ((Get-Service -Name 'ClickToRunSvc' -ErrorAction Stop).Status -ne 'Running') {
        Start-Service -Name 'ClickToRunSvc' -ErrorAction Stop
        Write-FixLog 'Started ClickToRunSvc'
        $notes += 'service started'
    }
    if ($state.updatesOff) {
        Set-ItemProperty -LiteralPath $ConfigKey -Name 'UpdatesEnabled' -Value 'True' -Type String -ErrorAction Stop
        Write-FixLog 'UpdatesEnabled set to True'
        $notes += 'automatic updates turned on'
    }
    if ($state.taskState -eq 'Disabled') {
        Enable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop | Out-Null
        Write-FixLog "Enabled task $TaskName"
        $notes += 'update task enabled'
    }

    $client = Join-Path $env:CommonProgramFiles 'microsoft shared\ClickToRun\OfficeC2RClient.exe'
    if (Test-Path -LiteralPath $client) {
        Start-Process -FilePath $client -ArgumentList '/update user displaylevel=false forceappshutdown=false' -WindowStyle Hidden -ErrorAction Stop
        Write-FixLog 'Started OfficeC2RClient.exe /update user'
        $notes += 'update started in the background'
    }
    else {
        Write-FixLog "OfficeC2RClient.exe not found at $client" 'WARN'
    }

    $left = @(Get-OfficeUpdateProblems -State (Get-OfficeUpdateState) | Where-Object { $_ -notlike 'no update check*' })
    $summary = if ($notes.Count) { ($notes -join '; ') + '.' } else { 'Nothing had to be changed.' }
    if ($left.Count -gt 0) {
        $msg = "$summary Still open: " + ($left -join '; ') + '. A missing task is recreated by an Online Repair of Microsoft 365 Apps.'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    Write-FixLog "Finished: $summary"
    Write-Output "$FindingId | Fixed | $summary"
    exit 0
}
catch {
    $msg = "Unexpected error: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
