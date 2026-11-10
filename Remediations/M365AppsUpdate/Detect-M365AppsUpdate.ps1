<#
.SYNOPSIS
    Detection: Microsoft 365 Apps (Click-to-Run) cannot update itself.

.DESCRIPTION
    Finding ID: APP.M365.UPDATESTUCK (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only, no module needed. Reports an issue when the Click-to-Run service is missing or
    disabled, automatic updates are turned off in the Click-to-Run configuration, or the
    scheduled task "Office Automatic Updates 2.0" is missing, disabled or has not run for
    14 days. Not applicable when Microsoft 365 Apps is not installed, when Configuration
    Manager manages the updates (OfficeMgmtCOM) or when a policy turns automatic updates off.

    Exit 0 = healthy or not applicable, exit 1 = issue found.

.NOTES
    File Name : Detect-M365AppsUpdate.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-M365AppsUpdate.ps1
#>

$FindingId = 'APP.M365.UPDATESTUCK'
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

try {
    $state = Get-OfficeUpdateState
    if (-not $state) { $msg = 'Microsoft 365 Apps (Click-to-Run) is not installed.' }
    elseif ($state.configMgr) { $msg = "Version $($state.version). Updates are managed by Configuration Manager: not checked." }
    elseif ($state.policyOff) { $msg = "Version $($state.version). Automatic updates are turned off by policy: not checked." }
    else {
        $problems = @(Get-OfficeUpdateProblems -State $state)
        if ($problems.Count -gt 0) {
            $msg = "Version $($state.version): " + ($problems -join '; ') + '.'
            Write-FixLog $msg 'WARN'
            Write-Output "$FindingId | Issue | $msg"
            exit 1
        }
        $msg = "Version $($state.version). Update service and task are OK."
    }
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
