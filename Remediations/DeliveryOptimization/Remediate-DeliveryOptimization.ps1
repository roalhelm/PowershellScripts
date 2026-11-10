<#
.SYNOPSIS
    Remediation: enable and start the Delivery Optimization service.

.DESCRIPTION
    Finding ID: WU.DO.BROKEN (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Sets DoSvc back to its default start type (Automatic, delayed start) and starts it.
    Download mode 100 (Bypass) comes from a policy and cannot be fixed on the device: the
    script reports it and exits 1, change the policy to 0 (HTTP only) or 1 (LAN) instead.

    Exit 0 = service enabled and no bypass policy, exit 1 = still broken.

.NOTES
    File Name : Remediate-DeliveryOptimization.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-DeliveryOptimization.ps1
#>

$FindingId = 'WU.DO.BROKEN'
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

$ServiceKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\DoSvc'

function Get-DownloadModePolicy {
    foreach ($path in 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\DeliveryOptimization', 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization') {
        $value = Get-RegValue -Path $path -Name 'DODownloadMode'
        if ($null -ne $value) { return [int]$value }
    }
    return $null
}

Write-FixLog 'Started'

try {
    $notes = @()
    $start = Get-RegValue -Path $ServiceKey -Name 'Start'
    if ($null -eq $start) {
        $msg = 'The DoSvc service does not exist on this device. Repair Windows (DISM /RestoreHealth or an in-place upgrade).'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    if ($start -eq 4) {
        $output = & sc.exe config DoSvc start= delayed-auto 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-FixLog ("sc config failed ({0}): {1}. Writing the registry values instead." -f $LASTEXITCODE, (($output | Out-String).Trim() -replace '\s+', ' ')) 'WARN'
            Set-ItemProperty -LiteralPath $ServiceKey -Name 'Start' -Value 2 -Type DWord -ErrorAction Stop
            Set-ItemProperty -LiteralPath $ServiceKey -Name 'DelayedAutostart' -Value 1 -Type DWord -ErrorAction Stop
        }
        Write-FixLog 'DoSvc start type set to Automatic (delayed start)'
        $notes += 'DoSvc enabled'
    }
    try {
        if ((Get-Service -Name 'DoSvc' -ErrorAction Stop).Status -ne 'Running') {
            Start-Service -Name 'DoSvc' -ErrorAction Stop
            Write-FixLog 'Started DoSvc'
            $notes += 'DoSvc started'
        }
    }
    catch {
        # After a registry-only change the service control manager needs a restart to see the new start type.
        Write-FixLog "DoSvc could not be started now: $($_.Exception.Message)" 'WARN'
        $notes += 'DoSvc starts after the next restart'
    }

    $summary = if ($notes.Count) { ($notes -join '; ') + '. ' } else { '' }
    $mode  = Get-DownloadModePolicy
    $build = [int](Get-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuildNumber')
    if ($mode -eq 100 -and $build -ge 22000) {
        $msg = "${summary}Download mode 100 (Bypass) is set by policy and deprecated on Windows 11. Change the Delivery Optimization policy to 0 (HTTP only) or 1 (LAN)."
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    if ((Get-RegValue -Path $ServiceKey -Name 'Start') -eq 4) {
        $msg = "${summary}DoSvc is still disabled. A policy or a tuning tool sets it back."
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    $msg = "${summary}Delivery Optimization service is enabled."
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
