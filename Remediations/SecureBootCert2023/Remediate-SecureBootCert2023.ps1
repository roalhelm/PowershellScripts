<#
.SYNOPSIS
    Remediation: ask Windows to install the 2023 Secure Boot certificates and the 2023 boot manager.

.DESCRIPTION
    Finding ID: SEC.SECUREBOOT.CERT2023 (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Uses the method Microsoft documents for IT-managed devices: sets
    HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\AvailableUpdates to 0x5944 and starts the
    scheduled task \Microsoft\Windows\PI\Secure-Boot-Update. Windows then writes the 2023
    certificates to the firmware (db and KEK) and installs the boot manager signed with the
    2023 certificate. This needs one or two restarts and can take some hours, because the
    task continues every 12 hours.

    This changes firmware variables. Install the current BIOS/UEFI version of the OEM first
    on device models you have not tested. Nothing is written when Secure Boot is off, when
    the update is already done or when it is already in progress.

    Exit 0 = update done or started, exit 1 = could not start or Windows reports an error.

.NOTES
    File Name : Remediate-SecureBootCert2023.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-SecureBootCert2023.ps1
#>

$FindingId = 'SEC.SECUREBOOT.CERT2023'
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

$SecureBootKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
$Servicing     = Join-Path $SecureBootKey 'Servicing'
$AllUpdates    = 0x5944   # all certificates plus the 2023 boot manager

Write-FixLog 'Started'

try {
    $secureBoot = $false
    try { $secureBoot = [bool](Confirm-SecureBootUEFI -ErrorAction Stop) } catch { $secureBoot = $false }
    if (-not $secureBoot) {
        $msg = 'Secure Boot is off or not supported: nothing changed.'
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    if ([string](Get-RegValue -Path $Servicing -Name 'UEFICA2023Status') -eq 'Updated') {
        $msg = 'The 2023 certificates are already installed.'
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }

    $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update' -ErrorAction SilentlyContinue
    if (-not $task) {
        $msg = 'Scheduled task \Microsoft\Windows\PI\Secure-Boot-Update is missing. Install the latest cumulative update first.'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    $pending = Get-RegValue -Path $SecureBootKey -Name 'AvailableUpdates'
    if ($pending) {
        Write-FixLog ('AvailableUpdates is already 0x{0:X}: update in progress, value not changed' -f [int64]$pending)
    }
    else {
        Set-ItemProperty -LiteralPath $SecureBootKey -Name 'AvailableUpdates' -Value $AllUpdates -Type DWord -ErrorAction Stop
        Write-FixLog ('Set AvailableUpdates to 0x{0:X}' -f $AllUpdates)
    }

    Start-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update' -ErrorAction Stop
    Write-FixLog 'Started task Secure-Boot-Update'
    Start-Sleep -Seconds 30

    $status    = [string](Get-RegValue -Path $Servicing -Name 'UEFICA2023Status')
    $errorCode = Get-RegValue -Path $Servicing -Name 'UEFICA2023Error'
    if ($errorCode) {
        $msg = ('Windows reports error 0x{0:X8} for the certificate update (status: {1}). Update the BIOS/UEFI from the OEM and check the System event log (source TPM-WMI, event 1795 and following).' -f [int64]$errorCode, $status)
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    if ($status -eq 'Updated') { $msg = 'The 2023 certificates are installed.' }
    else { $msg = "Update started (status: $status). Restart the device, it can need two restarts; the task continues every 12 hours." }
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
