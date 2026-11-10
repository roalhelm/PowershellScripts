<#
.SYNOPSIS
    Detection: the Windows Recovery Environment (WinRE) is disabled.

.DESCRIPTION
    Finding ID: BL.WINRE.DISABLED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reads C:\Windows\System32\Recovery\ReAgent.xml, which is language independent
    (the output of reagentc /info is localized). InstallState 1 means enabled.
    Silent BitLocker encryption through Intune, Autopilot reset and remote wipe need WinRE.

    Exit 0 = enabled, exit 1 = disabled or not configured.

.NOTES
    File Name : Detect-WinRE.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-WinRE.ps1
#>

$FindingId = 'BL.WINRE.DISABLED'
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
    $path = Join-Path $env:SystemRoot 'System32\Recovery\ReAgent.xml'
    if (-not (Test-Path -LiteralPath $path)) {
        $msg = 'WinRE is not configured (ReAgent.xml missing).'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    [xml]$xml = Get-Content -LiteralPath $path -Raw
    $state = [string]$xml.WindowsRE.InstallState.state
    if ($state -eq '1') {
        Write-FixLog 'WinRE is enabled.'
        Write-Output "$FindingId | OK | WinRE is enabled."
        exit 0
    }
    $msg = "WinRE is disabled (InstallState $state)."
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "WinRE state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
