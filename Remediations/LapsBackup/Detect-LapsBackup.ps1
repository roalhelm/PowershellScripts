<#
.SYNOPSIS
    Detection: a Windows LAPS policy is set, but the last policy processing failed.

.DESCRIPTION
    Finding ID: SEC.LAPS.BACKUPFAILED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Only for the built-in Windows LAPS (not the legacy LAPS MSI). Reports an issue
    when a LAPS policy with a backup directory (Entra ID or Active Directory) is present and
    the newest processing result in the LAPS event log is a failure (event 10005) instead of
    a success (event 10004).

    Exit 0 = healthy or no LAPS policy, exit 1 = last processing failed.

.NOTES
    File Name : Detect-LapsBackup.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-LapsBackup.ps1
#>

$FindingId = 'SEC.LAPS.BACKUPFAILED'
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

$LapsLog = 'Microsoft-Windows-LAPS/Operational'

function Get-LapsBackupDirectory {
    # 1 = Entra ID, 2 = Active Directory, 0 or $null = LAPS not configured. Same order as Windows uses.
    foreach ($path in 'HKLM:\SOFTWARE\Microsoft\Policies\LAPS', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\LAPS', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\LAPS\Config') {
        $value = Get-RegValue -Path $path -Name 'BackupDirectory'
        if ($null -ne $value) { return [int]$value }
    }
    return $null
}

try {
    $directory = Get-LapsBackupDirectory
    if (-not $directory) {
        $msg = 'No Windows LAPS policy with a backup directory: nothing to check.'
        Write-FixLog $msg
        Write-Output "$FindingId | OK | $msg"
        exit 0
    }
    $target = if ($directory -eq 1) { 'Entra ID' } else { 'Active Directory' }
    $last = $null
    try { $last = Get-WinEvent -FilterHashtable @{ LogName = $LapsLog; Id = 10004, 10005 } -MaxEvents 1 -ErrorAction Stop } catch { }
    if ($last -and $last.Id -eq 10005) {
        $message = ([string]$last.Message -replace '\s+', ' ').Trim()
        if ($message.Length -gt 300) { $message = $message.Substring(0, 300) + '...' }
        $msg = 'LAPS backup to {0} failed at {1}: {2}' -f $target, $last.TimeCreated.ToString('yyyy-MM-dd HH:mm'), $message
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = if ($last) { 'LAPS policy processing for {0} succeeded at {1}.' -f $target, $last.TimeCreated.ToString('yyyy-MM-dd HH:mm') } else { "LAPS policy for $target is set; no processing result in the event log yet." }
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
