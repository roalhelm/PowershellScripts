<#
.SYNOPSIS
    Remediation: rescan devices and install driver updates that Windows Update offers.

.DESCRIPTION
    Finding ID: DRV.DEVICE.ERROR (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Steps:
      1. pnputil /scan-devices: Windows looks again for a matching driver in the driver store.
      2. Searches Windows Update for driver updates (Type='Driver') and installs the ones
         offered for this device. Your update policies decide what is offered: if drivers
         are excluded (DRV.WU.EXCLUDED on the ClientFixPage), nothing is installed.
      3. Checks the devices again.

    No driver is removed and the device is not restarted. Exit 0 also when only a restart is
    still needed; the output says so.

    Exit 0 = no problem devices left (or only a restart is missing), exit 1 = problems remain.

.NOTES
    File Name : Remediate-DriverProblems.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10 2004 or later / Windows 11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-DriverProblems.ps1
#>

$FindingId = 'DRV.DEVICE.ERROR'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$Notes     = New-Object System.Collections.Generic.List[string]

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

function Get-ProblemDevices {
    return @(Get-CimInstance -ClassName Win32_PnPEntity -Filter 'ConfigManagerErrorCode <> 0' -ErrorAction Stop |
        Where-Object { $_.ConfigManagerErrorCode -notin @(22, 45) })
}

Write-FixLog 'Started'

try {
    $before = Get-ProblemDevices
    Write-FixLog ("{0} problem device(s) before: {1}" -f $before.Count, (($before | ForEach-Object { '{0} ({1})' -f $_.Name, $_.ConfigManagerErrorCode }) -join ', '))

    # 1. Rescan.
    $output = & (Join-Path $env:SystemRoot 'System32\pnputil.exe') /scan-devices 2>&1
    Write-FixLog ("pnputil /scan-devices exit code {0}: {1}" -f $LASTEXITCODE, (($output | Out-String).Trim() -replace '\s+', ' '))
    Start-Sleep -Seconds 15

    # 2. Driver updates from Windows Update.
    $rebootRequired = $false
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $session.ClientApplicationID = 'ClientFix DRV.DEVICE.ERROR'
        $result = $session.CreateUpdateSearcher().Search("IsInstalled=0 and IsHidden=0 and Type='Driver'")
        $updates = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $result.Updates) {
            if (-not $update.EulaAccepted) { $update.AcceptEula() }
            [void]$updates.Add($update)
            Write-FixLog "Offered driver: $($update.Title)"
        }
        if ($updates.Count -gt 0) {
            $downloader = $session.CreateUpdateDownloader()
            $downloader.Updates = $updates
            [void]$downloader.Download()
            $installer = $session.CreateUpdateInstaller()
            $installer.Updates = $updates
            $install = $installer.Install()
            $rebootRequired = [bool]$install.RebootRequired
            Write-FixLog ("Installed {0} driver update(s), result code {1}, restart required {2}" -f $updates.Count, $install.ResultCode, $rebootRequired)
            $Notes.Add("$($updates.Count) driver update(s) installed")
        }
        else {
            Write-FixLog 'Windows Update offers no driver updates.'
        }
    }
    catch {
        Write-FixLog "Windows Update driver search/install failed: $($_.Exception.Message)" 'WARN'
        $Notes.Add('Windows Update driver search failed')
    }

    # 3. Check again.
    Start-Sleep -Seconds 10
    $after = Get-ProblemDevices
    $onlyRestart = ($after.Count -gt 0 -and @($after | Where-Object { $_.ConfigManagerErrorCode -ne 14 }).Count -eq 0)
    $summary = if ($Notes.Count -gt 0) { ($Notes -join '; ') + '; ' } else { '' }

    if ($after.Count -eq 0) {
        $msg = "${summary}no problem devices left."
        if ($rebootRequired) { $msg += ' Restart to finish the driver installation.' }
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    if ($onlyRestart -or $rebootRequired) {
        $msg = "${summary}restart required to finish ($($after.Count) device(s) still pending)."
        Write-FixLog "Finished: $msg" 'WARN'
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $list = ($after | Select-Object -First 5 | ForEach-Object { '{0} (code {1})' -f $_.Name, $_.ConfigManagerErrorCode }) -join ', '
    $msg = "${summary}$($after.Count) device(s) still have problems: $list. Install the driver from the manufacturer (OEM tool or driver pack)."
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
