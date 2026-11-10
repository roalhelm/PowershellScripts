<#
.SYNOPSIS
    Detection: the BitLocker recovery key of the OS drive is not backed up to Entra ID.

.DESCRIPTION
    Finding ID: BL.RECOVERYKEY.NOTESCROWED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. For an Entra joined (or hybrid joined) device with an encrypted OS drive it
    reports an issue when
      - no recovery password protector exists,
      - the newest backup event in the BitLocker Management log is a failure (846), or
      - there is no success event (845) at all.
    The client cannot ask Entra ID directly, so the event log is the evidence. A re-backup
    by the remediation is harmless when the key is already there.

    Exit 0 = backed up or not applicable, exit 1 = issue found.

.NOTES
    File Name : Detect-BitLockerKeyBackup.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11 Pro/Enterprise/Education, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-BitLockerKeyBackup.ps1
#>

$FindingId    = 'BL.RECOVERYKEY.NOTESCROWED'
$LogFile      = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$BitLockerLog = 'Microsoft-Windows-BitLocker/BitLocker Management'

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

# Event Viewer shows this channel as BitLocker-API > Management; resolve the name on the device.
try {
    $found = @(Get-WinEvent -ListLog 'Microsoft-Windows-BitLocker*' -ErrorAction Stop | Where-Object { $_.LogName -like '*Management' })
    if ($found.Count -gt 0) { $BitLockerLog = $found[0].LogName }
}
catch { }

function Get-RecoveryKeyBackupTimes {
    # Newest success (845) for one of the current recovery password protectors, newest failure (846)
    # for the OS drive. Events of other volumes or removed protectors are ignored.
    param([string[]]$ProtectorIds)
    $result = @{ ok = $null; fail = $null }
    $events = @()
    try { $events = @(Get-WinEvent -FilterHashtable @{ LogName = $BitLockerLog; Id = 845, 846 } -MaxEvents 200 -ErrorAction Stop) } catch { }
    foreach ($entry in $events) {
        $message = [string]$entry.Message
        if ($entry.Id -eq 845 -and -not $result.ok) {
            foreach ($id in $ProtectorIds) { if ($id -and $message -like ('*' + $id.Trim('{}') + '*')) { $result.ok = $entry.TimeCreated } }
        }
        elseif ($entry.Id -eq 846 -and -not $result.fail -and $message -like ('*' + $env:SystemDrive + '*')) {
            $result.fail = $entry.TimeCreated
        }
    }
    return $result
}

try {
    $joined = $false
    foreach ($line in (& (Join-Path $env:SystemRoot 'System32\dsregcmd.exe') /status 2>$null)) {
        if ($line -match '^\s*AzureAdJoined\s*:\s*YES') { $joined = $true }
    }
    if (-not $joined) {
        Write-Output "$FindingId | OK | Not applicable: device is not Entra joined."
        exit 0
    }
    $volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ([string]$volume.VolumeStatus -eq 'FullyDecrypted') {
        Write-Output "$FindingId | OK | Not applicable: OS drive is not encrypted (see BL.OSVOLUME.NOTENCRYPTED)."
        exit 0
    }
    $recovery = @($volume.KeyProtector | Where-Object { [string]$_.KeyProtectorType -eq 'RecoveryPassword' })
    $backup = Get-RecoveryKeyBackupTimes -ProtectorIds @($recovery | ForEach-Object { [string]$_.KeyProtectorId })
    $lastOk = $backup.ok
    $lastFail = $backup.fail

    $problem = $null
    if ($recovery.Count -eq 0) { $problem = 'no recovery password protector exists' }
    elseif ($lastFail -and (-not $lastOk -or $lastFail -gt $lastOk)) { $problem = ('last backup to Entra ID failed ({0:yyyy-MM-dd HH:mm})' -f $lastFail) }
    elseif (-not $lastOk) { $problem = 'no successful backup of the current recovery password logged' }

    if ($problem) {
        $msg = "Recovery key not confirmed in Entra ID: $problem."
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = ('Recovery key backed up to Entra ID ({0:yyyy-MM-dd HH:mm}).' -f $lastOk)
    Write-FixLog $msg
    Write-Output "$FindingId | OK | $msg"
    exit 0
}
catch {
    $msg = "BitLocker state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
