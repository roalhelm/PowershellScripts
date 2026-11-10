<#
.SYNOPSIS
    Remediation: get the Windows Time service running and correct the clock.

.DESCRIPTION
    Finding ID: SYS.TIME.SKEW (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps (each one only when needed):
      1. Sets W32Time back to its default start type when it is disabled
         (Automatic on domain members, Manual on other devices) and starts it.
      2. Runs w32tm /resync /force. The time source configuration is not changed.
      3. Measures the offset again against the Date header of https://login.microsoftonline.com.
         Only if the clock is still more than 5 minutes off, it sets the clock once from that
         header (accurate to about one second), so sign-in works again, and logs it.

    Exit 0 = clock in sync, exit 1 = still wrong (see output and log).

.NOTES
    File Name : Remediate-TimeSync.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-TimeSync.ps1
#>

$FindingId      = 'SYS.TIME.SKEW'
$MaxSkewSeconds = 300
$LogFile        = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$Notes          = New-Object System.Collections.Generic.List[string]

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

function Get-ServerUtc {
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
        return [datetime]::Parse($response.Headers['Date'], [System.Globalization.CultureInfo]::InvariantCulture, $styles)
    }
    catch {
        return $null
    }
    finally {
        if ($response) { $response.Close() }
    }
}

function Get-ClockSkewSeconds {
    $server = Get-ServerUtc
    if (-not $server) { return $null }
    return [math]::Round(([datetime]::UtcNow - $server).TotalSeconds, 0)
}

Write-FixLog 'Started'

try {
    # 1. Service.
    $service = Get-Service -Name 'W32Time' -ErrorAction SilentlyContinue
    if (-not $service) {
        & w32tm.exe /register 2>&1 | Out-Null
        Write-FixLog 'W32Time was missing: ran w32tm /register'
        $Notes.Add('W32Time registered')
        $service = Get-Service -Name 'W32Time' -ErrorAction SilentlyContinue
    }
    if ($service -and [string]$service.StartType -eq 'Disabled') {
        $domainMember = $false
        try { $domainMember = [bool](Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).PartOfDomain } catch { }
        $startType = if ($domainMember) { 'Automatic' } else { 'Manual' }
        Set-Service -Name 'W32Time' -StartupType $startType -ErrorAction Stop
        Write-FixLog "W32Time start type set to $startType"
        $Notes.Add("W32Time set to $startType")
    }
    if ($service -and (Get-Service -Name 'W32Time').Status -ne 'Running') {
        Start-Service -Name 'W32Time' -ErrorAction Stop
        Write-FixLog 'Started W32Time'
    }

    # 2. Resync.
    $output = & w32tm.exe /resync /force 2>&1
    Write-FixLog ("w32tm /resync /force exit code {0}: {1}" -f $LASTEXITCODE, (($output | Out-String).Trim() -replace '\s+', ' '))
    Start-Sleep -Seconds 5

    # 3. Check, and set the clock once if it is still far off.
    $skew = Get-ClockSkewSeconds
    if ($null -ne $skew -and [math]::Abs($skew) -gt $MaxSkewSeconds) {
        $server = Get-ServerUtc
        if ($server) {
            Set-Date -Date $server.ToLocalTime() -ErrorAction Stop | Out-Null
            Write-FixLog "Clock was $skew seconds off after resync; set from the HTTPS Date header" 'WARN'
            $Notes.Add("clock corrected by $skew seconds")
            $skew = Get-ClockSkewSeconds
        }
    }

    $summary = if ($Notes.Count -gt 0) { ($Notes -join '; ') + '; ' } else { '' }
    if ($null -eq $skew) {
        $msg = "${summary}resync done, offset not measured (no answer from login.microsoftonline.com)."
        Write-FixLog "Finished: $msg" 'WARN'
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    if ([math]::Abs($skew) -le $MaxSkewSeconds) {
        $msg = "${summary}clock offset now $skew seconds."
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $msg = "${summary}clock is still $skew seconds off. Check the time source (w32tm /query /source) and UDP 123."
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
