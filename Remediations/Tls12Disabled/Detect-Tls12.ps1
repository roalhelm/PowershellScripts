<#
.SYNOPSIS
    Detection: TLS 1.2 is disabled for client connections.

.DESCRIPTION
    Finding ID: NET.TLS12.DISABLED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Intune, Entra ID, Windows Update and Defender need TLS 1.2 or newer. Reports
    an issue when the SCHANNEL registry values disable the TLS 1.2 client, or when the WinHTTP
    value DefaultSecureProtocols is set and leaves TLS 1.2 out. Missing values are the Windows
    default (TLS 1.2 on) and are fine.

    Exit 0 = TLS 1.2 available, exit 1 = disabled.

.NOTES
    File Name : Detect-Tls12.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-Tls12.ps1
#>

$FindingId = 'NET.TLS12.DISABLED'
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

try {
    $problems = @(Get-TlsProblems)
    if ($problems.Count -gt 0) {
        $msg = ($problems -join '; ') + '.'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = 'TLS 1.2 is not disabled.'
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
