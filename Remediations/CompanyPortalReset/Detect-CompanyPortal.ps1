<#
.SYNOPSIS
    Detection: the Company Portal app package of the signed-in user is damaged.

.DESCRIPTION
    Finding ID: CP.APP.BROKEN (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Runs in the context of the signed-in user (app data is per user).
    Reports an issue when the Microsoft.CompanyPortal package status is not "Ok".
    Not installed is not this finding (exit 0): see CP.APP.MISSING.

    Exit 0 = OK or not installed, exit 1 = package damaged.

.NOTES
    File Name : Detect-CompanyPortal.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run with the logged-on credentials

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-CompanyPortal.ps1
#>

$FindingId = 'CP.APP.BROKEN'
$LogFile   = Join-Path $env:TEMP 'ClientFix.log'

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Detect] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
}

try {
    $pkg = Get-AppxPackage -Name 'Microsoft.CompanyPortal' -ErrorAction Stop | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $pkg) {
        Write-Output "$FindingId | OK | Not applicable: Company Portal is not installed for this user (see CP.APP.MISSING)."
        exit 0
    }
    if ([string]$pkg.Status -eq 'Ok') {
        Write-FixLog "Company Portal $($pkg.Version) is OK."
        Write-Output "$FindingId | OK | Company Portal $($pkg.Version) is OK."
        exit 0
    }
    $msg = "Company Portal $($pkg.Version) package status: $($pkg.Status)."
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
