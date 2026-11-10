<#
.SYNOPSIS
    Detection: the device is not enrolled in Intune.

.DESCRIPTION
    Finding ID: MDM.ENROLLMENT.MISSING (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when no enrollment with provider "MS DM Server" exists
    under HKLM:\SOFTWARE\Microsoft\Enrollments, and names the most likely cause.

    An Intune Remediation cannot reach a device that is not enrolled. Run this pair through
    ConfigMgr, a GPO scheduled task, or manually as SYSTEM (for example psexec -s).

    Exit 0 = enrolled, exit 1 = not enrolled.

.NOTES
    File Name : Detect-IntuneAutoEnroll.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-IntuneAutoEnroll.ps1
#>

$FindingId = 'MDM.ENROLLMENT.MISSING'
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

try {
    $enrolled = $false
    foreach ($key in (Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue)) {
        $provider = (Get-ItemProperty -LiteralPath $key.PSPath -Name 'ProviderID' -ErrorAction SilentlyContinue).ProviderID
        if ($provider -eq 'MS DM Server') { $enrolled = $true }
    }
    if ($enrolled) {
        Write-FixLog 'Device is enrolled in Intune.'
        Write-Output "$FindingId | OK | Device is enrolled in Intune."
        exit 0
    }

    $dsreg = Get-DsregStatus
    if ($dsreg['AzureAdJoined'] -ne 'YES') { $cause = 'device is not Entra joined (fix the join first)' }
    elseif (-not $dsreg['MdmUrl']) { $cause = 'no MDM URL: user outside the MDM user scope or auto-enrollment not configured' }
    else { $cause = 'MDM URL present, enrollment can be triggered' }

    $msg = "Device is not enrolled in Intune; $cause."
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "Enrollment state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
