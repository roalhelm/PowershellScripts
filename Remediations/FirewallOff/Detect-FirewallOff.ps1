<#
.SYNOPSIS
    Detection: a Windows Firewall profile (Domain, Private or Public) is turned off.

.DESCRIPTION
    Finding ID: SEC.FIREWALL.OFF (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reads the effective state (active policy store) of the three firewall profiles.
    Not applicable when another firewall product is registered in Windows Security Center.

    Exit 0 = all profiles on or third-party firewall, exit 1 = at least one profile off.

.NOTES
    File Name : Detect-FirewallOff.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-FirewallOff.ps1
#>

$FindingId = 'SEC.FIREWALL.OFF'
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

function Get-ThirdPartyFirewall {
    try {
        $products = @(Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName 'FirewallProduct' -ErrorAction Stop)
        return (($products | ForEach-Object { [string]$_.displayName }) -join ', ')
    }
    catch { return '' }
}

try {
    $thirdParty = Get-ThirdPartyFirewall
    if ($thirdParty) {
        $msg = "Another firewall product is registered ($thirdParty): Windows Firewall not checked."
        Write-FixLog $msg
        Write-Output "$FindingId | OK | $msg"
        exit 0
    }
    $off = @(Get-NetFirewallProfile -PolicyStore ActiveStore -ErrorAction Stop | Where-Object { [string]$_.Enabled -ne 'True' } | ForEach-Object { [string]$_.Name })
    if ($off.Count -gt 0) {
        $msg = 'Firewall profile off: ' + ($off -join ', ') + '.'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = 'All firewall profiles are on.'
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
