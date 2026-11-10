<#
.SYNOPSIS
    Remediation: enable the Windows Recovery Environment (WinRE).

.DESCRIPTION
    Finding ID: BL.WINRE.DISABLED (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Runs reagentc.exe /enable and reads ReAgent.xml again. No partition is changed.
    When enabling fails, Winre.wim is usually missing (C:\Windows\System32\Recovery) or the
    recovery partition is damaged or too small. Those cases need a manual repair, see the
    step-by-step guide for BL.WINRE.DISABLED on the ClientFixPage.

    Exit 0 = enabled, exit 1 = still disabled (see output and log).

.NOTES
    File Name : Remediate-WinRE.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-WinRE.ps1
#>

$FindingId = 'BL.WINRE.DISABLED'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$Xml       = Join-Path $env:SystemRoot 'System32\Recovery\ReAgent.xml'

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

function Test-WinREEnabled {
    if (-not (Test-Path -LiteralPath $Xml)) { return $false }
    try {
        [xml]$content = Get-Content -LiteralPath $Xml -Raw
        return ([string]$content.WindowsRE.InstallState.state -eq '1')
    }
    catch {
        return $false
    }
}

Write-FixLog 'Started'

try {
    if (Test-WinREEnabled) {
        Write-Output "$FindingId | Fixed | WinRE is already enabled."
        exit 0
    }
    $output = & (Join-Path $env:SystemRoot 'System32\reagentc.exe') /enable 2>&1
    $code = $LASTEXITCODE
    Write-FixLog ("reagentc /enable exit code {0}: {1}" -f $code, (($output | Out-String).Trim() -replace '\s+', ' '))

    if (Test-WinREEnabled) {
        $msg = 'WinRE enabled.'
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $wim = Join-Path $env:SystemRoot 'System32\Recovery\Winre.wim'
    $msg = "reagentc /enable failed (exit code $code)."
    if (-not (Test-Path -LiteralPath $wim)) { $msg += ' Winre.wim is missing in C:\Windows\System32\Recovery: copy it from installation media of the same Windows build.' }
    else { $msg += ' The recovery partition may be damaged or too small: see the guide for BL.WINRE.DISABLED.' }
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
