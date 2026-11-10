<#
.SYNOPSIS
    Intune remediation: free space on the system drive by cleaning Windows caches only.

.DESCRIPTION
    Finding ID: SYS.DISK.LOWSPACE (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Cleans only data that Windows creates again by itself. User files, user profiles, the recycle bin,
    Downloads folders and the Windows.old folder are never touched.

      1. Delivery Optimization cache (Delete-DeliveryOptimizationCache).
      2. Files older than $MinFileAgeDays days in C:\Windows\Temp.
      3. Windows Error Reporting queue and archive older than $MinFileAgeDays days.
      4. Old Windows Update downloads in C:\Windows\SoftwareDistribution\Download
         (older than $MinFileAgeDays days, only while no update is installing).
      5. Component store cleanup: DISM /Online /Cleanup-Image /StartComponentCleanup
         (without /ResetBase, so installed updates can still be uninstalled).

    The freed space is written to the output and the log. When the drive is still below the limit,
    the rest is user data or apps, which needs a person to decide (see the guide on ClientFixPage).

    Exit 0 = enough free space afterwards, exit 1 = still below the limit.

.NOTES
    File Name : Remediate-DiskLowSpace.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, run as SYSTEM in 64-bit PowerShell
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-DiskLowSpace.ps1
#>

$FindingId      = 'SYS.DISK.LOWSPACE'
$MinFreeSpaceGB = 20
$MinFileAgeDays = 7
$DismTimeoutMin = 60
$LogFile        = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'
$Notes = New-Object System.Collections.Generic.List[string]

function Write-FixLog {
    param([string]$Message, [string]$Level = 'INFO')
    $line = '{0} [{1}] [{2}] [Remediate] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $FindingId, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop } catch { }
}

function Get-FreeGB {
    $drive = if ($env:SystemDrive) { $env:SystemDrive } else { 'C:' }
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $drive) -ErrorAction Stop
    return [math]::Round($disk.FreeSpace / 1GB, 2)
}

function Remove-OldFile {
    # Removes files older than $MinFileAgeDays below $Path. Returns the freed size in MB.
    # Files in use are skipped. Folders are left in place.
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $cutoff = (Get-Date).AddDays(-$MinFileAgeDays)
    $freed = 0
    $files = Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($f in $files) {
        try {
            $size = $f.Length
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
            $freed += $size
        }
        catch { }
    }
    $mb = [math]::Round($freed / 1MB, 0)
    Write-FixLog "${Label}: removed files older than $MinFileAgeDays days, $mb MB"
    return $mb
}

function Test-UpdateInstalling {
    # True while Windows Update or the servicing stack is busy, so its download cache stays untouched.
    foreach ($name in @('TiWorker', 'TrustedInstaller', 'wuauclt', 'MoUsoCoreWorker')) {
        if (Get-Process -Name $name -ErrorAction SilentlyContinue) { return $true }
    }
    return $false
}

Write-FixLog 'Started'

try {
    $before = Get-FreeGB
    Write-FixLog "Free before: $before GB"

    # 1. Delivery Optimization cache.
    if (Get-Command -Name 'Delete-DeliveryOptimizationCache' -ErrorAction SilentlyContinue) {
        try {
            Delete-DeliveryOptimizationCache -Force -ErrorAction Stop
            Write-FixLog 'Delivery Optimization cache cleared'
            $Notes.Add('Delivery Optimization cache cleared')
        }
        catch {
            Write-FixLog "Delivery Optimization cache not cleared: $($_.Exception.Message)" 'WARN'
        }
    }

    # 2. + 3. Temp and error reports.
    $mb = 0
    $mb += Remove-OldFile -Path (Join-Path $env:SystemRoot 'Temp') -Label 'Windows Temp'
    $mb += Remove-OldFile -Path (Join-Path $env:ProgramData 'Microsoft\Windows\WER\ReportQueue') -Label 'WER ReportQueue'
    $mb += Remove-OldFile -Path (Join-Path $env:ProgramData 'Microsoft\Windows\WER\ReportArchive') -Label 'WER ReportArchive'
    if ($mb -gt 0) { $Notes.Add("Temp and error reports: $mb MB") }

    # 4. Old update downloads.
    if (Test-UpdateInstalling) {
        Write-FixLog 'An update is installing: SoftwareDistribution\Download left unchanged'
    }
    else {
        $mb = Remove-OldFile -Path (Join-Path $env:SystemRoot 'SoftwareDistribution\Download') -Label 'SoftwareDistribution\Download'
        if ($mb -gt 0) { $Notes.Add("Old update downloads: $mb MB") }
    }

    # 5. Component store cleanup, only when still needed.
    if ((Get-FreeGB) -lt $MinFreeSpaceGB) {
        $dism = Join-Path $env:SystemRoot 'System32\dism.exe'
        Write-FixLog 'Running DISM /StartComponentCleanup'
        try {
            $p = Start-Process -FilePath $dism -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup /Quiet /NoRestart' -PassThru -WindowStyle Hidden -ErrorAction Stop
            if ($p.WaitForExit($DismTimeoutMin * 60000)) {
                Write-FixLog "DISM exit code $($p.ExitCode)"
                if ($p.ExitCode -eq 0) { $Notes.Add('Component store cleaned') }
            }
            else {
                # DISM keeps running in the background; do not kill it in the middle of servicing.
                Write-FixLog "DISM still running after $DismTimeoutMin minutes, left running" 'WARN'
            }
        }
        catch {
            Write-FixLog "DISM could not start: $($_.Exception.Message)" 'ERROR'
        }
    }

    $after = Get-FreeGB
    $freed = [math]::Round($after - $before, 1)
    $summary = if ($Notes.Count -gt 0) { $Notes -join '; ' } else { 'nothing to clean' }
    if ($after -ge $MinFreeSpaceGB) {
        $msg = "$after GB free now (freed $freed GB). $summary."
        Write-FixLog "Finished: $msg"
        Write-Output "$FindingId | Fixed | $msg"
        exit 0
    }
    $msg = "Still only $after GB free (freed $freed GB, minimum $MinFreeSpaceGB GB). $summary. The rest is user data or apps: see the guide on ClientFixPage."
    Write-FixLog "Finished: $msg" 'WARN'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
catch {
    $msg = "Unexpected error: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
