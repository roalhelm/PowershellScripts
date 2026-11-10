<#
.SYNOPSIS
    Detection: the Delivery Optimization service is disabled, or download mode 100 (Bypass) is set on Windows 11.

.DESCRIPTION
    Finding ID: WU.DO.BROKEN (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Windows Update, Microsoft Store and Intune Win32 app downloads go through the
    Delivery Optimization service (DoSvc). Reports an issue when the service is missing or
    disabled, or when policy sets download mode 100 (Bypass), which is deprecated on
    Windows 11 and makes downloads fail or fall back.

    Exit 0 = healthy, exit 1 = issue found.

.NOTES
    File Name : Detect-DeliveryOptimization.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-DeliveryOptimization.ps1
#>

$FindingId = 'WU.DO.BROKEN'
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

function Get-DownloadModePolicy {
    foreach ($path in 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\DeliveryOptimization', 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization') {
        $value = Get-RegValue -Path $path -Name 'DODownloadMode'
        if ($null -ne $value) { return [int]$value }
    }
    return $null
}

try {
    $problems = @()
    $start = Get-RegValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\DoSvc' -Name 'Start'
    if ($null -eq $start) { $problems += 'DoSvc service is missing' }
    elseif ($start -eq 4) { $problems += 'DoSvc service is disabled' }

    $mode  = Get-DownloadModePolicy
    $build = [int](Get-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuildNumber')
    if ($mode -eq 100 -and $build -ge 22000) { $problems += 'policy sets download mode 100 (Bypass), which is deprecated on Windows 11' }

    if ($problems.Count -gt 0) {
        $msg = ($problems -join '; ') + '.'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = 'Delivery Optimization service is enabled' + $(if ($null -ne $mode) { " (download mode $mode by policy)." } else { '.' })
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
