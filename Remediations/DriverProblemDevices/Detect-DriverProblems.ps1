<#
.SYNOPSIS
    Detection: devices with a driver problem (yellow mark in Device Manager).

.DESCRIPTION
    Finding ID: DRV.DEVICE.ERROR (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Lists present devices whose ConfigManagerErrorCode is not 0, except code 22
    (disabled on purpose) and 45 (not connected). Uses Get-CimInstance, no WMIC.

    Exit 0 = no problem devices, exit 1 = problem devices found.

.NOTES
    File Name : Detect-DriverProblems.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-DriverProblems.ps1
#>

$FindingId = 'DRV.DEVICE.ERROR'
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
    $bad = @(Get-CimInstance -ClassName Win32_PnPEntity -Filter 'ConfigManagerErrorCode <> 0' -ErrorAction Stop |
        Where-Object { $_.ConfigManagerErrorCode -notin @(22, 45) })
    if ($bad.Count -eq 0) {
        Write-FixLog 'No devices with driver problems.'
        Write-Output "$FindingId | OK | No devices with driver problems."
        exit 0
    }
    $list = ($bad | Select-Object -First 5 | ForEach-Object { '{0} (code {1})' -f $_.Name, $_.ConfigManagerErrorCode }) -join ', '
    $msg = "$($bad.Count) device(s) with driver problems: $list."
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "Devices could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
