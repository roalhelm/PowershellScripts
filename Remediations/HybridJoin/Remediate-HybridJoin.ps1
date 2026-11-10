<#
.SYNOPSIS
    Remediation: start the hybrid Entra join again.

.DESCRIPTION
    Finding ID: AAD.HYBRIDJOIN.PENDING (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps (each one only when needed):
      1. Enables the scheduled task \Microsoft\Windows\Workplace Join\Automatic-Device-Join.
      2. Runs dsregcmd /join (needs SYSTEM).
      3. Waits up to 2 minutes and reads dsregcmd /status again.

    Nothing is deleted or left. The join only completes after Entra Connect (or Cloud Sync)
    has synced the computer object to Entra ID. Right after a new device is domain joined
    this can take one sync cycle (30 minutes), so a first "Failed" is normal: the task runs
    again at the next sign-in.

    Exit 0 = joined, exit 1 = still not joined (see output and log).

.NOTES
    File Name : Remediate-HybridJoin.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    psexec.exe -s powershell.exe -ExecutionPolicy Bypass -File .\Remediate-HybridJoin.ps1
#>

$FindingId   = 'AAD.HYBRIDJOIN.PENDING'
$LogFile     = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$WaitSeconds = 120
$Dsregcmd    = Join-Path $env:SystemRoot 'System32\dsregcmd.exe'

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
    foreach ($line in (& $Dsregcmd /status 2>$null)) {
        if ($line -match '^\s*([A-Za-z][A-Za-z0-9 ]*?)\s*:\s*(.+?)\s*$') { $status[$Matches[1].Trim()] = $Matches[2].Trim() }
    }
    return $status
}

Write-FixLog 'Started'

try {
    if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -ne 'S-1-5-18') {
        $msg = 'dsregcmd /join only works as SYSTEM. Run the script as SYSTEM (Intune, ConfigMgr or psexec -s).'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    $dsreg = Get-DsregStatus
    if ($dsreg['AzureAdJoined'] -eq 'YES') {
        Write-Output "$FindingId | Fixed | Device is already hybrid joined."
        exit 0
    }
    if ($dsreg['DomainJoined'] -ne 'YES') {
        $msg = 'Device is not domain joined, so hybrid join does not apply.'
        Write-FixLog $msg 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }

    $taskPath = '\Microsoft\Windows\Workplace Join\'
    $task = Get-ScheduledTask -TaskPath $taskPath -TaskName 'Automatic-Device-Join' -ErrorAction SilentlyContinue
    if ($task -and [string]$task.State -eq 'Disabled') {
        Enable-ScheduledTask -TaskPath $taskPath -TaskName 'Automatic-Device-Join' -ErrorAction Stop | Out-Null
        Write-FixLog 'Enabled task Automatic-Device-Join'
    }

    $output = & $Dsregcmd /join 2>&1
    Write-FixLog ("dsregcmd /join exit code {0}: {1}" -f $LASTEXITCODE, (($output | Out-String).Trim() -replace '\s+', ' '))

    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    do {
        Start-Sleep -Seconds 10
        $dsreg = Get-DsregStatus
    } while ($dsreg['AzureAdJoined'] -ne 'YES' -and (Get-Date) -lt $deadline)

    if ($dsreg['AzureAdJoined'] -eq 'YES') {
        $msg = 'Device is hybrid Entra joined. The user gets a Primary Refresh Token at the next sign-in.'
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }

    $msg = 'Not joined yet'
    if ($dsreg['Client ErrorCode'] -or $dsreg['Server ErrorCode']) {
        $msg += ' (phase {0}, client error {1}, server error {2})' -f $dsreg['Error Phase'], $dsreg['Client ErrorCode'], $dsreg['Server ErrorCode']
    }
    $msg += '. Check that Entra Connect syncs this computer object (it needs the userCertificate attribute), then try again after the next sync.'
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
