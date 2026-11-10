<#
.SYNOPSIS
    Resets the Company Portal app for the signed-in user.

.DESCRIPTION
    Finding ID: CP.APP.BROKEN (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Same as Settings > Apps > Company Portal > Advanced options > Reset:
      1. Closes the Company Portal app.
      2. Runs Reset-AppxPackage, which clears the app's data and cached sign-in.
         On Windows builds without Reset-AppxPackage it empties the LocalState, LocalCache
         and TempState folders of the app instead.
    The app stays installed and the device enrollment is not touched. The user signs in to
    Company Portal again afterwards.

    Use it as the remediation script of the CompanyPortalReset package, or run it by hand as
    the user when Company Portal hangs, loops at sign-in, shows a wrong compliance state or
    cannot install apps.

    Exit 0 = reset done, exit 1 = reset failed (see output and log).

.NOTES
    File Name : Reset-CompanyPortal.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run with the logged-on credentials (not as SYSTEM)
    Log       : %TEMP%\ClientFix.log of the user

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Reset-CompanyPortal.ps1
#>

$FindingId = 'CP.APP.BROKEN'
$LogFile   = Join-Path $env:TEMP 'ClientFix.log'

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Remediate] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
}

Write-FixLog 'Started'

try {
    if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') {
        $msg = 'Runs as SYSTEM, but Company Portal data is per user. Set "Run this script using the logged-on credentials" to Yes.'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    $pkg = Get-AppxPackage -Name 'Microsoft.CompanyPortal' -ErrorAction Stop | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $pkg) {
        $msg = 'Company Portal is not installed for this user. Install it first (CP.APP.MISSING on the ClientFixPage).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    Get-Process -Name 'CompanyPortal' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    if (Get-Command -Name 'Reset-AppxPackage' -ErrorAction SilentlyContinue) {
        $pkg | Reset-AppxPackage -ErrorAction Stop
        Write-FixLog "Reset-AppxPackage run for $($pkg.PackageFullName)"
        $how = 'Reset-AppxPackage'
    }
    else {
        $dataRoot = Join-Path $env:LOCALAPPDATA ('Packages\' + $pkg.PackageFamilyName)
        foreach ($folder in 'LocalState', 'LocalCache', 'TempState') {
            $path = Join-Path $dataRoot $folder
            if (Test-Path -LiteralPath $path) {
                Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-FixLog "Emptied $path"
            }
        }
        $how = 'app data folders emptied'
    }

    $pkg = Get-AppxPackage -Name 'Microsoft.CompanyPortal' -ErrorAction Stop | Sort-Object Version -Descending | Select-Object -First 1
    if ($pkg -and [string]$pkg.Status -eq 'Ok') {
        $msg = "Company Portal reset ($how). Open it and sign in again."
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $status = if ($pkg) { [string]$pkg.Status } else { 'not installed' }
    $msg = "Reset done ($how), but the package status is still '$status'. Reinstall Company Portal (CP.APP.MISSING on the ClientFixPage)."
    Write-FixLog "Finished: $msg" 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
catch {
    $msg = "Unexpected error: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
