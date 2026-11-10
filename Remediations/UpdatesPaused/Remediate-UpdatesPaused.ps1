<#
.SYNOPSIS
    Remediation: remove the local update pause and start an update scan.

.DESCRIPTION
    Finding ID: WU.UPDATES.PAUSED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Removes the pause values that Settings > Windows Update > "Pause updates" writes to
    HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings and starts a scan with UsoClient.
    A pause set by policy is not touched.

    Exit 0 = local pause removed, exit 1 = still paused.

.NOTES
    File Name : Remediate-UpdatesPaused.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-UpdatesPaused.ps1
#>

$FindingId = 'WU.UPDATES.PAUSED'
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

$UxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
$PauseValues = 'PauseUpdatesExpiryTime', 'PauseUpdatesStartTime', 'PauseQualityUpdatesStartTime', 'PauseQualityUpdatesEndTime',
               'PauseFeatureUpdatesStartTime', 'PauseFeatureUpdatesEndTime'

Write-FixLog 'Started'

try {
    $removed = @()
    foreach ($name in $PauseValues) {
        if ($null -ne (Get-RegValue -Path $UxKey -Name $name)) {
            Remove-ItemProperty -LiteralPath $UxKey -Name $name -ErrorAction Stop
            $removed += $name
        }
    }
    Write-FixLog ('Removed values: ' + $(if ($removed.Count) { $removed -join ', ' } else { 'none' }))

    $uso = Join-Path $env:SystemRoot 'System32\UsoClient.exe'
    if (Test-Path -LiteralPath $uso) {
        & $uso StartScan 2>&1 | Out-Null
        Write-FixLog 'Started an update scan (UsoClient StartScan)'
    }

    $left = @($PauseValues | Where-Object { $null -ne (Get-RegValue -Path $UxKey -Name $_) })
    if ($left.Count -gt 0) {
        $msg = 'Pause values are still present: ' + ($left -join ', ')
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    $msg = if ($removed.Count) { "Local update pause removed ($($removed.Count) values), update scan started." } else { 'No local pause found, update scan started.' }
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
