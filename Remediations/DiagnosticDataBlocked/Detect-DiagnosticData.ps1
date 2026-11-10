<#
.SYNOPSIS
    Intune detection: Windows diagnostic data is blocked, which breaks Autopatch and Windows Update reports.

.DESCRIPTION
    Finding ID: WU.TELEMETRY.BLOCKED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when
      - a Group Policy sets AllowTelemetry = 0 (HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection),
      - an Intune policy sets AllowTelemetry = 0 (HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\System), or
      - the Connected User Experiences and Telemetry service (DiagTrack) is missing or disabled.
    Windows Autopatch and the Windows Update for Business reports need at least "Required" diagnostic data.

    Exit 0 = healthy, exit 1 = issue found (Intune runs the remediation).

.NOTES
    File Name : Detect-DiagnosticData.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-DiagnosticData.ps1
#>

$FindingId = 'WU.TELEMETRY.BLOCKED'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Detect] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
}

function Get-RegValue {
    param([string]$Path, [string]$Name)
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null }
}

try {
    $gpo = Get-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry'
    $mdm = Get-RegValue -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\System' -Name 'AllowTelemetry'
    $diagTrack = Get-Service -Name 'DiagTrack' -ErrorAction SilentlyContinue

    $problems = @()
    if ($null -ne $gpo -and [int]$gpo -eq 0) { $problems += 'Group Policy sets AllowTelemetry=0' }
    if ($null -ne $mdm -and [int]$mdm -eq 0) { $problems += 'Intune policy sets AllowTelemetry=0' }
    if (-not $diagTrack) { $problems += 'DiagTrack service missing' }
    elseif ([string]$diagTrack.StartType -eq 'Disabled') { $problems += 'DiagTrack service disabled' }

    if ($problems.Count -gt 0) {
        $msg = ($problems -join '; ') + '.'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }

    $msg = "Diagnostic data is not blocked (GPO=$gpo, MDM=$mdm, DiagTrack $($diagTrack.Status))."
    Write-FixLog $msg
    Write-Output "$FindingId | OK | $msg"
    exit 0
}
catch {
    $msg = "Diagnostic data state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
