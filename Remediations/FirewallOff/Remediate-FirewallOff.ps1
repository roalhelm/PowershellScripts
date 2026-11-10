<#
.SYNOPSIS
    Remediation: turn the Windows Firewall profiles on again.

.DESCRIPTION
    Finding ID: SEC.FIREWALL.OFF (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Starts the firewall service (mpssvc) when it is stopped and turns on the profiles that
    are off in the local store. Firewall rules are not changed. If a profile stays off, a
    Group Policy or Intune policy turns it off: that has to be fixed in the policy.
    Nothing is changed when another firewall product is registered in Windows Security Center.

    Exit 0 = all profiles on, exit 1 = a profile is still off.

.NOTES
    File Name : Remediate-FirewallOff.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-FirewallOff.ps1
#>

$FindingId = 'SEC.FIREWALL.OFF'
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

Write-FixLog 'Started'

try {
    $thirdParty = ''
    try { $thirdParty = ((@(Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName 'FirewallProduct' -ErrorAction Stop) | ForEach-Object { [string]$_.displayName }) -join ', ') } catch { }
    if ($thirdParty) {
        $msg = "Another firewall product is registered ($thirdParty): nothing changed."
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }

    $service = Get-Service -Name 'mpssvc' -ErrorAction SilentlyContinue
    if ($service -and $service.Status -ne 'Running') {
        try { Start-Service -Name 'mpssvc' -ErrorAction Stop; Write-FixLog 'Started mpssvc' }
        catch { Write-FixLog "mpssvc could not be started: $($_.Exception.Message)" 'WARN' }
    }

    $off = @(Get-NetFirewallProfile -PolicyStore ActiveStore -ErrorAction Stop | Where-Object { [string]$_.Enabled -ne 'True' } | ForEach-Object { [string]$_.Name })
    if ($off.Count -gt 0) {
        Set-NetFirewallProfile -Name $off -Enabled True -ErrorAction Stop
        Write-FixLog ('Turned on in the local store: ' + ($off -join ', '))
    }

    $stillOff = @(Get-NetFirewallProfile -PolicyStore ActiveStore -ErrorAction Stop | Where-Object { [string]$_.Enabled -ne 'True' } | ForEach-Object { [string]$_.Name })
    if ($stillOff.Count -gt 0) {
        $msg = 'Still off: ' + ($stillOff -join ', ') + '. A Group Policy or Intune policy turns the profile off; change it there (Endpoint security > Firewall).'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    $msg = if ($off.Count) { 'Turned on: ' + ($off -join ', ') + '. All firewall profiles are on.' } else { 'All firewall profiles are on.' }
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
