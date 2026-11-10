<#
.SYNOPSIS
    Detection: the Windows Recovery Environment (WinRE) is disabled.

.DESCRIPTION
    Finding ID: BL.WINRE.DISABLED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Runs reagentc /info and looks for the WinRE location (\\?\GLOBALROOT\device\...),
    which only appears while WinRE is enabled and is the same in every language.
    Falls back to ReAgent.xml when reagentc fails; if the state stays unknown, it reports an issue.
    Silent BitLocker encryption through Intune, Autopilot reset and remote wipe need WinRE.

    Exit 0 = enabled, exit 1 = disabled or not configured.

.NOTES
    File Name : Detect-WinRE.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-WinRE.ps1
#>

$FindingId = 'BL.WINRE.DISABLED'
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

function Get-WinREState {
    # Returns 'enabled', 'disabled' or $null (unknown). reagentc /info shows the WinRE location as
    # \\?\GLOBALROOT\device\... only while WinRE is enabled; that path is language independent.
    $output = & (Join-Path $env:SystemRoot 'System32\reagentc.exe') /info 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        if ($output -match '\\\\\?\\GLOBALROOT\\device\\') { return 'enabled' }
        return 'disabled'
    }
    # Fallback only: ReAgent.xml InstallState is 1 while enabled.
    try {
        [xml]$xml = Get-Content -LiteralPath (Join-Path $env:SystemRoot 'System32\Recovery\ReAgent.xml') -Raw -ErrorAction Stop
        if ([string]$xml.WindowsRE.InstallState.state -eq '1') { return 'enabled' }
    }
    catch { }
    return $null
}

try {
    $state = Get-WinREState
    if ($state -eq 'enabled') {
        Write-FixLog 'WinRE is enabled.'
        Write-Output "$FindingId | OK | WinRE is enabled."
        exit 0
    }
    $msg = if ($state -eq 'disabled') { 'WinRE is disabled.' } else { 'WinRE state could not be read (reagentc /info failed).' }
    Write-FixLog $msg 'WARN'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
catch {
    $msg = "WinRE state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
