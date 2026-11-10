<#
.SYNOPSIS
    Detection: BitLocker protection on the OS drive is suspended indefinitely.

.DESCRIPTION
    Finding ID: BL.PROTECTION.SUSPENDED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when the OS drive is fully encrypted, has key protectors,
    protection is off, and the suspend count is 0 (it would never resume by itself).
    A suspension with a remaining restart count (for example during a BIOS update) is
    left alone: it resumes on its own.

    Exit 0 = healthy or not applicable, exit 1 = suspended indefinitely.

.NOTES
    File Name : Detect-BitLockerSuspended.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11 Pro/Enterprise/Education, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-BitLockerSuspended.ps1
#>

$FindingId = 'BL.PROTECTION.SUSPENDED'
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

try {
    $volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    if ([string]$volume.VolumeStatus -ne 'FullyEncrypted' -or @($volume.KeyProtector).Count -eq 0) {
        Write-Output "$FindingId | OK | Not applicable: OS drive is not encrypted and protected (see BL.OSVOLUME.NOTENCRYPTED)."
        exit 0
    }
    if ([string]$volume.ProtectionStatus -eq 'On') {
        Write-Output "$FindingId | OK | BitLocker protection is on."
        exit 0
    }
    $cim = Get-CimInstance -Namespace 'root\cimv2\Security\MicrosoftVolumeEncryption' -ClassName 'Win32_EncryptableVolume' `
        -Filter ("DriveLetter='{0}'" -f $env:SystemDrive) -ErrorAction Stop
    $count = (Invoke-CimMethod -InputObject $cim -MethodName 'GetSuspendCount' -ErrorAction Stop).SuspendCount
    if ($count -gt 0) {
        $msg = "Protection paused; resumes by itself after $count restart(s)."
        Write-FixLog $msg
        Write-Output "$FindingId | OK | $msg"
        exit 0
    }
    $msg = 'BitLocker protection on the OS drive is suspended indefinitely.'
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "BitLocker state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
