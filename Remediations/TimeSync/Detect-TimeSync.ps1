<#
.SYNOPSIS
    Detection: the system clock is wrong or the Windows Time service is disabled.

.DESCRIPTION
    Finding ID: SYS.TIME.SKEW (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Compares the clock with the Date header of https://login.microsoftonline.com
    (language independent, no NTP port needed) and checks the W32Time service.
    Reports an issue when the offset is above 5 minutes (Kerberos, Entra sign-in and
    certificate checks fail above that) or when W32Time is disabled or missing.

    Exit 0 = healthy, exit 1 = issue found.

.NOTES
    File Name : Detect-TimeSync.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-TimeSync.ps1
#>

$FindingId     = 'SYS.TIME.SKEW'
$MaxSkewSeconds = 300   # same threshold as Get-ClientHealth.ps1
$LogFile       = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

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

function Get-ClockSkewSeconds {
    # Local clock minus server clock, in seconds. $null when there is no answer.
    $response = $null
    try {
        $request = [System.Net.HttpWebRequest]::Create('https://login.microsoftonline.com/')
        $request.Method = 'HEAD'
        $request.Timeout = 10000
        $request.AllowAutoRedirect = $false
        try { $response = $request.GetResponse() }
        catch [System.Net.WebException] { $response = $_.Exception.Response }
        if (-not $response -or -not $response.Headers['Date']) { return $null }
        $styles = [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal
        $server = [datetime]::Parse($response.Headers['Date'], [System.Globalization.CultureInfo]::InvariantCulture, $styles)
        return [math]::Round(([datetime]::UtcNow - $server).TotalSeconds, 0)
    }
    catch {
        return $null
    }
    finally {
        if ($response) { $response.Close() }
    }
}

try {
    $problems = @()
    $service = Get-Service -Name 'W32Time' -ErrorAction SilentlyContinue
    if (-not $service) { $problems += 'W32Time service is missing' }
    elseif ([string]$service.StartType -eq 'Disabled') { $problems += 'W32Time service is disabled' }

    $skew = Get-ClockSkewSeconds
    if ($null -ne $skew -and [math]::Abs($skew) -gt $MaxSkewSeconds) { $problems += "clock is $skew seconds off" }

    if ($problems.Count -gt 0) {
        $msg = ($problems -join '; ') + '.'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = if ($null -eq $skew) { 'W32Time is enabled; offset not measured (no answer from login.microsoftonline.com).' } else { "Clock offset $skew seconds." }
    Write-FixLog $msg
    Write-Output "$FindingId | OK | $msg"
    exit 0
}
catch {
    $msg = "Time state could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
