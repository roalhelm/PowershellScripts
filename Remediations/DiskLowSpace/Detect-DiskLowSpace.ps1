<#
.SYNOPSIS
    Intune detection: not enough free space on the system drive for Windows updates.

.DESCRIPTION
    Finding ID: SYS.DISK.LOWSPACE (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when the system drive has less than $MinFreeSpaceGB GB free.
    Feature updates need about 20 GB, monthly updates several GB.

    Exit 0 = enough space, exit 1 = issue found (Intune runs the remediation).

.NOTES
    File Name : Detect-DiskLowSpace.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-DiskLowSpace.ps1
#>

$FindingId      = 'SYS.DISK.LOWSPACE'
$MinFreeSpaceGB = 20   # same threshold as Get-ClientHealth.ps1
$LogFile        = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Detect] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
}

try {
    $drive = if ($env:SystemDrive) { $env:SystemDrive } else { 'C:' }
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $drive) -ErrorAction Stop
    $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    $sizeGB = [math]::Round($disk.Size / 1GB, 1)

    if ($freeGB -lt $MinFreeSpaceGB) {
        $msg = "$freeGB GB free on $drive of $sizeGB GB (minimum $MinFreeSpaceGB GB)."
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }

    $msg = "$freeGB GB free on $drive of $sizeGB GB."
    Write-FixLog $msg
    Write-Output "$FindingId | OK | $msg"
    exit 0
}
catch {
    $msg = "Free space could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
