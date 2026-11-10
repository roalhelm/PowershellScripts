<#
.SYNOPSIS
    Intune remediation: unblock Windows diagnostic data so Autopatch and Windows Update reports work.

.DESCRIPTION
    Finding ID: WU.TELEMETRY.BLOCKED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps (each one only when needed):
      1. Removes a leftover Group Policy value AllowTelemetry = 0
         (HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection). The key is exported to
         C:\ProgramData\ClientFix\Backup first. Skipped when -removePolicyBlocks 0 or a
         Configuration Manager client (CcmExec) is installed.
      2. Reports, but does not change, an Intune policy with AllowTelemetry = 0. Change the
         Intune policy instead (Settings catalog > System > Allow Telemetry = Required or higher).
      3. Sets the DiagTrack service back to Automatic and starts it.

    Nothing else is changed. The diagnostic data level itself is not raised by this script.

    Exit 0 = nothing blocks diagnostic data afterwards, exit 1 = still blocked (see output and log).

.PARAMETER removePolicyBlocks
    1 (default) removes the Group Policy value, 0 only reports it.

.NOTES
    File Name : Remediate-DiagnosticData.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-DiagnosticData.ps1 -removePolicyBlocks 0
#>
param(
    [int]$removePolicyBlocks = 1
)

$FindingId = 'WU.TELEMETRY.BLOCKED'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$BackupDir = Join-Path $env:ProgramData 'ClientFix\Backup'
$GpoKey    = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
$MdmKey    = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\System'
$Notes = New-Object System.Collections.Generic.List[string]

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Remediate] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
}

function Get-RegValue {
    param([string]$Path, [string]$Name)
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null }
}

function Backup-RegistryKey {
    param([string]$Path, [string]$Label)
    try {
        if (-not (Test-Path -LiteralPath $BackupDir)) { New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null }
        $file = Join-Path $BackupDir ('{0}-{1}.reg' -f $Label, (Get-Date -Format 'yyyyMMdd-HHmmss'))
        $regPath = $Path -replace '^HKLM:\\', 'HKLM\'
        $null = & reg.exe export $regPath $file /y 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-FixLog "Backed up $Path to $file"
            return $true
        }
        Write-FixLog "Backup of $Path failed (reg.exe exit $LASTEXITCODE)" 'ERROR'
        return $false
    }
    catch {
        Write-FixLog "Backup of $Path failed: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Test-Blocked {
    $gpo = Get-RegValue -Path $GpoKey -Name 'AllowTelemetry'
    $mdm = Get-RegValue -Path $MdmKey -Name 'AllowTelemetry'
    $svc = Get-Service -Name 'DiagTrack' -ErrorAction SilentlyContinue
    $blocked = @()
    if ($null -ne $gpo -and [int]$gpo -eq 0) { $blocked += 'Group Policy AllowTelemetry=0' }
    if ($null -ne $mdm -and [int]$mdm -eq 0) { $blocked += 'Intune policy AllowTelemetry=0' }
    if (-not $svc) { $blocked += 'DiagTrack missing' }
    elseif ([string]$svc.StartType -eq 'Disabled') { $blocked += 'DiagTrack disabled' }
    return $blocked
}

Write-FixLog "Started (removePolicyBlocks=$removePolicyBlocks)"

try {
    # 1. Group Policy value.
    $gpo = Get-RegValue -Path $GpoKey -Name 'AllowTelemetry'
    if ($null -ne $gpo -and [int]$gpo -eq 0) {
        if ($removePolicyBlocks -ne 1) {
            $Notes.Add('Group Policy AllowTelemetry=0 left unchanged (-removePolicyBlocks 0)')
        }
        elseif (Get-Service -Name 'CcmExec' -ErrorAction SilentlyContinue) {
            Write-FixLog 'Configuration Manager client found (CcmExec): AllowTelemetry left unchanged'
            $Notes.Add('Group Policy AllowTelemetry=0 left unchanged because of the Configuration Manager client')
        }
        elseif (Backup-RegistryKey -Path $GpoKey -Label 'DataCollectionPolicies') {
            try {
                Remove-ItemProperty -LiteralPath $GpoKey -Name 'AllowTelemetry' -ErrorAction Stop
                Write-FixLog 'Removed Group Policy value AllowTelemetry=0'
                $Notes.Add('Removed Group Policy AllowTelemetry=0')
            }
            catch {
                Write-FixLog "Could not remove AllowTelemetry: $($_.Exception.Message)" 'ERROR'
            }
        }
        else {
            $Notes.Add('Group Policy value not removed because the backup failed')
        }
    }

    # 2. Intune policy: report only.
    $mdm = Get-RegValue -Path $MdmKey -Name 'AllowTelemetry'
    if ($null -ne $mdm -and [int]$mdm -eq 0) {
        Write-FixLog 'Intune policy sets AllowTelemetry=0. Not changed on the device.' 'WARN'
        $Notes.Add('Intune policy sets AllowTelemetry=0: change it to Required or higher in Intune')
    }

    # 3. DiagTrack.
    $svc = Get-Service -Name 'DiagTrack' -ErrorAction SilentlyContinue
    if ($svc) {
        if ([string]$svc.StartType -eq 'Disabled') {
            try {
                Set-Service -Name 'DiagTrack' -StartupType Automatic -ErrorAction Stop
                Write-FixLog 'DiagTrack start type set to Automatic'
                $Notes.Add('DiagTrack set to Automatic')
            }
            catch {
                Write-FixLog "Could not change DiagTrack: $($_.Exception.Message)" 'ERROR'
            }
        }
        if ((Get-Service -Name 'DiagTrack').Status -ne 'Running') {
            try {
                Start-Service -Name 'DiagTrack' -ErrorAction Stop
                Write-FixLog 'Started DiagTrack'
                $Notes.Add('Started DiagTrack')
            }
            catch {
                Write-FixLog "Could not start DiagTrack: $($_.Exception.Message)" 'ERROR'
            }
        }
    }

    $blocked = @(Test-Blocked)
    $summary = if ($Notes.Count -gt 0) { $Notes -join '; ' } else { 'No change made' }
    if ($blocked.Count -eq 0) {
        Write-FixLog "Finished: diagnostic data not blocked. $summary"
        Write-Output "$FindingId | Fixed | $summary"
        exit 0
    }
    Write-FixLog "Finished: still blocked by $($blocked -join ', '). $summary" 'ERROR'
    Write-Output "$FindingId | Failed | Still blocked: $($blocked -join ', '). $summary"
    exit 1
}
catch {
    $msg = "Unexpected error: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
