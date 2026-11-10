<#
.SYNOPSIS
    Remediation: trigger automatic Intune enrollment on an Entra joined or hybrid joined device.

.DESCRIPTION
    Finding ID: MDM.ENROLLMENT.MISSING (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps:
      1. Stops when the device is not Entra joined or the join has no MDM URL, because
         enrollment cannot work then. The output names what to fix.
      2. Starts the auto-enrollment scheduled task that the GPO "Enable automatic MDM enrollment
         using default Azure AD credentials" creates. Without that task it runs
         deviceenroller.exe /c /AutoEnrollMDM.
      3. Waits up to 3 minutes for the Intune enrollment to appear. On failure it reports the
         newest error code from the DeviceManagement-Enterprise-Diagnostics-Provider/Admin log.

    Nothing is deleted. A user must be signed in with a working Primary Refresh Token, because
    automatic enrollment uses the user's Entra credentials by default.

    Exit 0 = enrolled, exit 1 = not enrolled (see output and log).

.NOTES
    File Name : Remediate-IntuneAutoEnroll.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    psexec.exe -s powershell.exe -ExecutionPolicy Bypass -File .\Remediate-IntuneAutoEnroll.ps1
#>

$FindingId   = 'MDM.ENROLLMENT.MISSING'
$LogFile     = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$WaitSeconds = 180
$Hints = @{
    '0x80180018' = 'user has no Intune license'
    '0x8018002B' = 'UPN domain not verified or user outside the MDM user scope'
    '0x80180014' = 'blocked by an enrollment restriction'
    '0x8018000A' = 'device already enrolled (leftover enrollment entries)'
    '0x80192EE7' = 'name resolution failed (DNS/proxy)'
    '0x80192EE2' = 'connection timed out (proxy/firewall)'
}

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

function Get-DsregStatus {
    $status = @{}
    foreach ($line in (& (Join-Path $env:SystemRoot 'System32\dsregcmd.exe') /status 2>$null)) {
        if ($line -match '^\s*([A-Za-z][A-Za-z0-9 ]*?)\s*:\s*(.+?)\s*$') { $status[$Matches[1].Trim()] = $Matches[2].Trim() }
    }
    return $status
}

function Test-IntuneEnrolled {
    foreach ($key in (Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue)) {
        $provider = (Get-ItemProperty -LiteralPath $key.PSPath -Name 'ProviderID' -ErrorAction SilentlyContinue).ProviderID
        if ($provider -eq 'MS DM Server') { return $true }
    }
    return $false
}

function Get-LastEnrollError {
    param([datetime]$Since)
    try {
        $entry = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'; Id = 76; StartTime = $Since } -MaxEvents 1 -ErrorAction Stop
        if ($entry -and $entry.Message -match '0x[0-9A-Fa-f]{8}') { return ('0x' + $Matches[0].Substring(2).ToUpper()) }
    }
    catch { }
    return $null
}

Write-FixLog 'Started'

try {
    if (Test-IntuneEnrolled) {
        Write-FixLog 'Already enrolled, nothing to do.'
        Write-Output "$FindingId | Fixed | Device is already enrolled in Intune."
        exit 0
    }

    $dsreg = Get-DsregStatus
    if ($dsreg['AzureAdJoined'] -ne 'YES') {
        $msg = 'Device is not Entra joined. Fix the join first (AAD.HYBRIDJOIN.PENDING or AAD.PRT.MISSING on the ClientFixPage).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    if (-not $dsreg['MdmUrl']) {
        $msg = 'The Entra join has no MDM URL. Add the user to the MDM user scope (Entra admin center > Mobility (MDM and WIP) > Microsoft Intune).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    $start = Get-Date
    $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\' -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -like '*automatically enrolling in MDM*' } | Select-Object -First 1
    if ($task) {
        Start-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName -ErrorAction Stop
        Write-FixLog "Started task $($task.TaskPath)$($task.TaskName)"
    }
    else {
        $enroller = Join-Path $env:SystemRoot 'System32\deviceenroller.exe'
        $process = Start-Process -FilePath $enroller -ArgumentList '/c', '/AutoEnrollMDM' -Wait -PassThru -WindowStyle Hidden
        Write-FixLog "deviceenroller.exe /c /AutoEnrollMDM exit code $($process.ExitCode)"
    }

    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    while ((Get-Date) -lt $deadline -and -not (Test-IntuneEnrolled)) { Start-Sleep -Seconds 10 }

    if (Test-IntuneEnrolled) {
        $msg = 'Automatic enrollment succeeded.'
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }

    $code = Get-LastEnrollError -Since $start
    $msg = 'Enrollment did not complete within {0} seconds.' -f $WaitSeconds
    if ($code) {
        $msg += " Error $code"
        if ($Hints.ContainsKey($code)) { $msg += ' (' + $Hints[$code] + ')' }
        $msg += '.'
    }
    else {
        $msg += ' No error logged yet: make sure a user is signed in and check the DeviceManagement-Enterprise-Diagnostics-Provider/Admin log.'
    }
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
