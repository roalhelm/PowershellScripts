<#
.SYNOPSIS
    Remediation: back up the BitLocker recovery key of the OS drive to Entra ID.

.DESCRIPTION
    Finding ID: BL.RECOVERYKEY.NOTESCROWED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps:
      1. Adds a recovery password protector when none exists. If your BitLocker policy does
         not allow a 48-digit recovery password, this step fails and the script says so.
      2. Runs BackupToAAD-BitLockerKeyProtector for every recovery password protector.
         Backing up a key that is already in Entra ID is harmless.

    No protector is removed and nothing is decrypted.

    Exit 0 = backed up, exit 1 = backup failed (see output and log).

.NOTES
    File Name : Remediate-BitLockerKeyBackup.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11 Pro/Enterprise/Education, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-BitLockerKeyBackup.ps1
#>

$FindingId = 'BL.RECOVERYKEY.NOTESCROWED'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$Notes     = New-Object System.Collections.Generic.List[string]

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
    if ([string]$volume.VolumeStatus -eq 'FullyDecrypted') {
        $msg = 'The OS drive is not encrypted, so there is no key to back up (see BL.OSVOLUME.NOTENCRYPTED).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    $recovery = @($volume.KeyProtector | Where-Object { [string]$_.KeyProtectorType -eq 'RecoveryPassword' })
    if ($recovery.Count -eq 0) {
        try {
            Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
            Write-FixLog 'Added a recovery password protector'
            $Notes.Add('recovery password added')
        }
        catch {
            $msg = "Could not add a recovery password (does your BitLocker policy allow one?): $($_.Exception.Message)"
            Write-FixLog $msg 'ERROR'
            Write-Output "$FindingId | Failed | $msg"
            exit 1
        }
        $volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
        $recovery = @($volume.KeyProtector | Where-Object { [string]$_.KeyProtectorType -eq 'RecoveryPassword' })
    }

    $ok = 0
    $errors = @()
    foreach ($protector in $recovery) {
        try {
            BackupToAAD-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $protector.KeyProtectorId -ErrorAction Stop | Out-Null
            Write-FixLog "Backed up protector $($protector.KeyProtectorId) to Entra ID"
            $ok++
        }
        catch {
            $errors += $_.Exception.Message
            Write-FixLog "Backup of $($protector.KeyProtectorId) failed: $($_.Exception.Message)" 'ERROR'
        }
    }

    $summary = if ($Notes.Count -gt 0) { ($Notes -join '; ') + '; ' } else { '' }
    if ($ok -gt 0 -and $errors.Count -eq 0) {
        $msg = "${summary}$ok recovery key(s) backed up to Entra ID."
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $msg = "${summary}backup failed: " + ($errors -join ' | ') + ' Check the device object in Entra ID and access to enterpriseregistration.windows.net.'
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
