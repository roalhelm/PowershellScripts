<#
.SYNOPSIS
    Remediation: resume BitLocker protection on the OS drive.

.DESCRIPTION
    Finding ID: BL.PROTECTION.SUSPENDED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Runs Resume-BitLocker on the OS drive and checks that protection is on afterwards.
    Nothing is decrypted, and no key protector is added or removed.

    Do not run it while a BIOS/firmware update is staged and waiting for a restart:
    resuming before that restart can make the device ask for the recovery key.

    Exit 0 = protection on, exit 1 = still off (see output and log).

.NOTES
    File Name : Remediate-BitLockerSuspended.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11 Pro/Enterprise/Education, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-BitLockerSuspended.ps1
#>

$FindingId = 'BL.PROTECTION.SUSPENDED'
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

Write-FixLog 'Started'

try {
    $volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ([string]$volume.ProtectionStatus -eq 'On') {
        Write-Output "$FindingId | Fixed | BitLocker protection is already on."
        exit 0
    }
    if ([string]$volume.VolumeStatus -ne 'FullyEncrypted' -or @($volume.KeyProtector).Count -eq 0) {
        $msg = 'The OS drive is not encrypted with key protectors, so there is nothing to resume (see BL.OSVOLUME.NOTENCRYPTED).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    Resume-BitLocker -MountPoint $env:SystemDrive -ErrorAction Stop | Out-Null
    Write-FixLog "Resume-BitLocker run on $env:SystemDrive"

    $volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ([string]$volume.ProtectionStatus -eq 'On') {
        $msg = 'BitLocker protection resumed.'
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $msg = 'Protection is still off after Resume-BitLocker. Check the BitLocker Management event log and the TPM (BL.TPM.NOTREADY).'
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
