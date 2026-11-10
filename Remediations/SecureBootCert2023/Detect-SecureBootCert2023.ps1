<#
.SYNOPSIS
    Detection: Secure Boot is on, but the 2023 Microsoft certificates are not installed in the firmware.

.DESCRIPTION
    Finding ID: SEC.SECUREBOOT.CERT2023 (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. The Microsoft Secure Boot certificates from 2011 expired in 2026. A device that
    still has only those keeps booting, but gets no new Secure Boot protections and no new
    boot manager. Reports an issue when Secure Boot is on and Windows has not finished the
    update to the 2023 certificates (UEFICA2023Status is not "Updated"; on builds without
    that value, the firmware variables db and KEK are searched for the 2023 certificates).

    Exit 0 = updated, or Secure Boot off or not supported. Exit 1 = update missing.

.NOTES
    File Name : Detect-SecureBootCert2023.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-SecureBootCert2023.ps1
#>

$FindingId = 'SEC.SECUREBOOT.CERT2023'
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

function Test-FirmwareHasCert {
    # $true / $false, or $null when the variable cannot be read.
    param([string]$Variable, [string]$CertName)
    try {
        $bytes = (Get-SecureBootUEFI -Name $Variable -ErrorAction Stop).Bytes
        return ([System.Text.Encoding]::ASCII.GetString($bytes) -match [regex]::Escape($CertName))
    }
    catch { return $null }
}

try {
    $secureBoot = $false
    try { $secureBoot = [bool](Confirm-SecureBootUEFI -ErrorAction Stop) } catch { $secureBoot = $false }
    if (-not $secureBoot) {
        $msg = 'Secure Boot is off or not supported: nothing to update.'
        Write-FixLog $msg
        Write-Output "$FindingId | OK | $msg"
        exit 0
    }

    $servicing = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
    $status    = [string](Get-RegValue -Path $servicing -Name 'UEFICA2023Status')
    $errorCode = Get-RegValue -Path $servicing -Name 'UEFICA2023Error'
    $dbHasCa   = Test-FirmwareHasCert -Variable 'db'  -CertName 'Windows UEFI CA 2023'
    $kekHasCa  = Test-FirmwareHasCert -Variable 'KEK' -CertName 'Microsoft Corporation KEK 2K CA 2023'

    $updated = ($status -eq 'Updated') -or (-not $status -and $dbHasCa -eq $true -and $kekHasCa -eq $true)
    if ($updated) {
        $msg = 'The 2023 Secure Boot certificates are installed.'
        Write-FixLog $msg
        Write-Output "$FindingId | OK | $msg"
        exit 0
    }
    $statusText = if ($status) { $status } else { 'not reported' }
    $msg = "2023 Secure Boot certificates not fully installed (status: $statusText; db has Windows UEFI CA 2023: $dbHasCa; KEK has KEK 2K CA 2023: $kekHasCa"
    if ($errorCode) { $msg += ('; last error 0x{0:X8}' -f [int64]$errorCode) }
    $msg += ').'
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "State could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
