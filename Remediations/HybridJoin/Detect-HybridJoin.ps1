<#
.SYNOPSIS
    Detection: a domain-joined device that should be hybrid Entra joined is not joined.

.DESCRIPTION
    Finding ID: AAD.HYBRIDJOIN.PENDING (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when the device is domain joined, not Entra joined, and a
    service connection point (SCP) for hybrid join exists (client-side in the registry or in
    Active Directory). Devices without an SCP are not meant to be hybrid joined: exit 0.

    Exit 0 = joined or not applicable, exit 1 = hybrid join pending.

.NOTES
    File Name : Detect-HybridJoin.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-HybridJoin.ps1
#>

$FindingId = 'AAD.HYBRIDJOIN.PENDING'
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

function Get-DsregStatus {
    $status = @{}
    foreach ($line in (& (Join-Path $env:SystemRoot 'System32\dsregcmd.exe') /status 2>$null)) {
        if ($line -match '^\s*([A-Za-z][A-Za-z0-9 ]*?)\s*:\s*(.+?)\s*$') { $status[$Matches[1].Trim()] = $Matches[2].Trim() }
    }
    return $status
}

function Test-HybridJoinScp {
    # Returns $true (SCP found), $false (no SCP) or $null (AD could not be read).
    $tenant = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CDJ\AAD' -Name 'TenantId' -ErrorAction SilentlyContinue).TenantId
    if ($tenant) { return $true }
    try {
        $configNc = [string]([ADSI]'LDAP://RootDSE').Properties['configurationNamingContext'].Value
        $scp = [ADSI]("LDAP://CN=62a0ff2e-97b9-4513-943f-0d221bd30080,CN=Device Registration Configuration,CN=Services," + $configNc)
        foreach ($keyword in @($scp.Properties['keywords'])) { if ([string]$keyword -like 'azureADId:*') { return $true } }
        return $false
    }
    catch {
        return $null
    }
}

try {
    $dsreg = Get-DsregStatus
    if ($dsreg['DomainJoined'] -ne 'YES') {
        Write-Output "$FindingId | OK | Not domain joined: hybrid join does not apply."
        exit 0
    }
    if ($dsreg['AzureAdJoined'] -eq 'YES') {
        Write-FixLog 'Device is hybrid joined.'
        Write-Output "$FindingId | OK | Device is hybrid Entra joined."
        exit 0
    }
    $scp = Test-HybridJoinScp
    if ($scp -eq $false) {
        Write-Output "$FindingId | OK | No hybrid join SCP found: the device is not meant to be hybrid joined."
        exit 0
    }
    $msg = 'Domain joined but not hybrid joined'
    if ($null -eq $scp) { $msg += ' (SCP could not be read from Active Directory)' }
    if ($dsreg['Client ErrorCode'] -or $dsreg['Server ErrorCode']) {
        $msg += '; last attempt: client error {0}, server error {1}' -f $dsreg['Client ErrorCode'], $dsreg['Server ErrorCode']
    }
    $msg += '.'
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "Join state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
