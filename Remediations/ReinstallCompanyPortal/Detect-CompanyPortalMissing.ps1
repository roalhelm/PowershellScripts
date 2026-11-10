<#
.SYNOPSIS
    Detection: Company Portal is not installed on the device.

.DESCRIPTION
    Finding ID: CP.APP.MISSING (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Reports an issue when no user on the device has the Microsoft.CompanyPortal
    package. Pair it with remediation.ps1 in this folder. Unlike detection.ps1 (which asks
    for a reinstall every few days on purpose), this detection only triggers when the app
    is really missing.

    Exit 0 = installed, exit 1 = missing.

.NOTES
    File Name : Detect-CompanyPortalMissing.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-CompanyPortalMissing.ps1
#>

$FindingId = 'CP.APP.MISSING'
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
    $pkg = Get-AppxPackage -AllUsers -Name 'Microsoft.CompanyPortal' -ErrorAction Stop | Sort-Object Version -Descending | Select-Object -First 1
    if ($pkg) {
        Write-FixLog "Company Portal $($pkg.Version) is installed."
        Write-Output "$FindingId | OK | Company Portal $($pkg.Version) is installed."
        exit 0
    }
    $msg = 'Company Portal is not installed.'
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "Company Portal state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
