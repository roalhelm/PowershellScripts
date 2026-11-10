<#
.SYNOPSIS
    Detection: Windows updates were paused locally in Settings.

.DESCRIPTION
    Finding ID: WU.UPDATES.PAUSED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when a pause set in Settings > Windows Update ("Pause updates")
    is still active. A pause set by policy (Intune update ring or Group Policy) is deliberate
    and only mentioned in the output.

    Exit 0 = not paused locally, exit 1 = paused locally.

.NOTES
    File Name : Detect-UpdatesPaused.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-UpdatesPaused.ps1
#>

$FindingId = 'WU.UPDATES.PAUSED'
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

$UxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'

function Get-PauseEnd {
    # Newest pause end date in the future, or $null.
    $latest = $null
    $styles = [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal
    foreach ($name in 'PauseUpdatesExpiryTime', 'PauseQualityUpdatesEndTime', 'PauseFeatureUpdatesEndTime') {
        $value = [string](Get-RegValue -Path $UxKey -Name $name)
        if (-not $value) { continue }
        try { $date = [datetime]::Parse($value, [System.Globalization.CultureInfo]::InvariantCulture, $styles) } catch { continue }
        if ($date -gt [datetime]::UtcNow -and (-not $latest -or $date -gt $latest)) { $latest = $date }
    }
    return $latest
}

function Test-PolicyPause {
    $mdm = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update'
    $gpo = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    if ((Get-RegValue -Path $mdm -Name 'PauseQualityUpdates') -eq 1) { return $true }
    if ((Get-RegValue -Path $mdm -Name 'PauseFeatureUpdates') -eq 1) { return $true }
    if ([string](Get-RegValue -Path $gpo -Name 'PauseQualityUpdatesStartTime')) { return $true }
    if ([string](Get-RegValue -Path $gpo -Name 'PauseFeatureUpdatesStartTime')) { return $true }
    return $false
}

try {
    $end = Get-PauseEnd
    $policyPause = Test-PolicyPause
    if ($end) {
        $msg = 'Updates are paused locally until {0} UTC.' -f $end.ToString('yyyy-MM-dd HH:mm')
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = if ($policyPause) { 'No local pause. Updates are paused by policy (update ring or Group Policy): not changed.' } else { 'Updates are not paused.' }
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
