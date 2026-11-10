<#
.SYNOPSIS
    Remediation: turn TLS 1.2 on again for client connections.

.DESCRIPTION
    Finding ID: NET.TLS12.DISABLED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Only corrects values that disable TLS 1.2:
      - SCHANNEL TLS 1.2 Client: Enabled = 1, DisabledByDefault = 0.
      - WinHTTP DefaultSecureProtocols: adds the TLS 1.2 flag (0x800) to the existing value.
    Other protocols and cipher settings are not changed. SCHANNEL changes need a restart.
    If a Group Policy writes these values, it sets them back: fix the policy as well.

    Exit 0 = TLS 1.2 enabled (restart needed), exit 1 = still disabled.

.NOTES
    File Name : Remediate-Tls12.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-Tls12.ps1
#>

$FindingId = 'NET.TLS12.DISABLED'
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

$ClientKey   = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
$WinHttpKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp',
               'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp'
$Tls12Flag   = 0x800

function Get-TlsProblems {
    # A missing value means the Windows default, which has TLS 1.2 enabled.
    $problems = @()
    if ((Get-RegValue -Path $ClientKey -Name 'Enabled') -eq 0) { $problems += 'SCHANNEL: TLS 1.2 client is disabled (Enabled = 0)' }
    if ((Get-RegValue -Path $ClientKey -Name 'DisabledByDefault') -eq 1) { $problems += 'SCHANNEL: TLS 1.2 client is disabled by default (DisabledByDefault = 1)' }
    foreach ($key in $WinHttpKeys) {
        $value = Get-RegValue -Path $key -Name 'DefaultSecureProtocols'
        if ($null -ne $value -and (([int64]$value -band $Tls12Flag) -eq 0)) {
            $problems += ('WinHTTP: DefaultSecureProtocols 0x{0:X} has no TLS 1.2 ({1})' -f [int64]$value, $(if ($key -like '*WOW6432Node*') { '32-bit' } else { '64-bit' }))
        }
    }
    return $problems
}

Write-FixLog 'Started'

try {
    $before = @(Get-TlsProblems)
    if ((Get-RegValue -Path $ClientKey -Name 'Enabled') -eq 0) {
        Set-ItemProperty -LiteralPath $ClientKey -Name 'Enabled' -Value 1 -Type DWord -ErrorAction Stop
        Write-FixLog 'SCHANNEL TLS 1.2 Client: Enabled set to 1'
    }
    if ((Get-RegValue -Path $ClientKey -Name 'DisabledByDefault') -eq 1) {
        Set-ItemProperty -LiteralPath $ClientKey -Name 'DisabledByDefault' -Value 0 -Type DWord -ErrorAction Stop
        Write-FixLog 'SCHANNEL TLS 1.2 Client: DisabledByDefault set to 0'
    }
    foreach ($key in $WinHttpKeys) {
        $value = Get-RegValue -Path $key -Name 'DefaultSecureProtocols'
        if ($null -ne $value -and (([int64]$value -band $Tls12Flag) -eq 0)) {
            $new = [int]([int64]$value -bor $Tls12Flag)
            Set-ItemProperty -LiteralPath $key -Name 'DefaultSecureProtocols' -Value $new -Type DWord -ErrorAction Stop
            Write-FixLog ('{0}: DefaultSecureProtocols 0x{1:X} -> 0x{2:X}' -f $key, [int64]$value, $new)
        }
    }

    $after = @(Get-TlsProblems)
    if ($after.Count -gt 0) {
        $msg = 'Still disabled: ' + ($after -join '; ') + '.'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    $msg = if ($before.Count) { "TLS 1.2 turned on ($($before.Count) values corrected). Restart the device so all services use it." } else { 'TLS 1.2 was not disabled: nothing changed.' }
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
