<#
.SYNOPSIS
Collects diagnostic information relevant to Windows 11 24H2 Feature Update troubleshooting (Intune-managed devices).

.DESCRIPTION
Performs hardware prerequisite checks, Intune / Update policy indicators, Windows Update state, driver summary,
AV status, disk space, pending reboot, integrity checks (optional), and gathers key logs into an output folder.

.OUTPUTS
Creates a timestamped folder (default: .\Win11_24H2_Diagnostics_yyyyMMdd_HHmmss) containing:
 - Summary.txt (human readable consolidated report)
 - Raw subfolder with individual section logs (each .log/.txt)
 - Collected log copies (WindowsUpdate.log if generated, Panther logs if present)
 - Optional ZIP archive if -ZipOutput is used

.PARAMETER OutputPath
Base path where the diagnostic folder will be created. Defaults to current directory.

.PARAMETER IncludeSfcDism
Runs sfc /scannow and DISM /RestoreHealth (can take time). Captured to IntegrityChecks.log.

.PARAMETER GenerateWindowsUpdateLog
Calls Get-WindowsUpdateLog to materialize WindowsUpdate.log into the diagnostics folder.

.PARAMETER SkipDrivers
Skips extended driver enumeration (faster on some systems).

.PARAMETER ZipOutput
Creates a ZIP file of the final folder.

.PARAMETER Quiet
Minimizes console output (only high-level progress + final path).

.EXAMPLE
PS> .\Collect-Win11_24H2_Diagnostics.ps1 -IncludeSfcDism -GenerateWindowsUpdateLog -ZipOutput

.NOTES
Run in elevated PowerShell for best results. Does not modify system state (except optional integrity scans).
#>
[CmdletBinding()] param(
    [string]$OutputPath = (Get-Location).Path,
    [switch]$IncludeSfcDism,
    [switch]$GenerateWindowsUpdateLog,
    [switch]$SkipDrivers,
    [switch]$ZipOutput,
    [switch]$Quiet
)

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
}
function Write-SectionFile {
    param(
        [string]$Name,
        [string]$Content
    )
    $file = Join-Path $rawDir ("{0}.log" -f $Name)
    $Content | Out-File -FilePath $file -Encoding UTF8 -Force
    return $file
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$sanitizedComputerName = ($env:COMPUTERNAME -replace '[^A-Za-z0-9_-]','_')
$baseName  = "Win11_24H2_Diagnostics_${sanitizedComputerName}_$timestamp"
$rootDir   = Join-Path (Resolve-Path $OutputPath) $baseName
$rawDir    = Join-Path $rootDir 'Raw'
New-Item -ItemType Directory -Path $rawDir -Force | Out-Null

Write-Info "Creating diagnostics folder: $rootDir"

$summaryLines = @()
$summaryLines += "Windows 11 24H2 Feature Update Diagnostic Summary"
$summaryLines += "Timestamp: $(Get-Date)"
$summaryLines += "Computer: $env:COMPUTERNAME"
$summaryLines += "User: $env:USERNAME"
$summaryLines += "---"

# 1. Hardware & Firmware
Write-Info "Collecting hardware / firmware prerequisites"
$hwObj = [PSCustomObject]@{
    TPM             = $null
    TPM_Activated   = $null
    SecureBoot      = $null
    SystemType      = $null
    ProductName     = $null
    WindowsVersion  = $null
    OSBuild         = $null
}
try {
    $tpm = Get-WmiObject -Class Win32_Tpm -ErrorAction Stop | Select-Object -First 1
    $hwObj.TPM = $tpm.IsEnabled_InitialValue
    $hwObj.TPM_Activated = $tpm.IsActivated_InitialValue
} catch { $hwObj.TPM = 'Unavailable' }
try { $hwObj.SecureBoot = (Confirm-SecureBootUEFI) } catch { $hwObj.SecureBoot = 'Unavailable' }
try {
    $sysType = (systeminfo | Select-String 'System Type').ToString().Split(':')[-1].Trim()
    $hwObj.SystemType = $sysType
} catch { $hwObj.SystemType = 'Unknown' }
try {
    $ci = Get-ComputerInfo | Select-Object -First 1 WindowsProductName, WindowsVersion, OsBuildNumber
    $hwObj.ProductName    = $ci.WindowsProductName
    $hwObj.WindowsVersion = $ci.WindowsVersion
    $hwObj.OSBuild        = $ci.OsBuildNumber
} catch {}
$summaryLines += "Hardware / Firmware:" 
$summaryLines += ($hwObj | Format-List | Out-String)
Write-SectionFile -Name 'HardwarePrereqs' -Content ($hwObj | Format-List | Out-String)

# 2. Intune Enrollment Indicators
Write-Info "Collecting Intune enrollment registry"
$enrollmentRaw = try { Get-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\Enrollments' -ErrorAction Stop | Out-String } catch { $_.Exception.Message }
Write-SectionFile -Name 'IntuneEnrollment' -Content $enrollmentRaw

# 3. Windows Update Policy Indicators
Write-Info "Collecting WUfB / policy indicators"
$wuPol  = try { Get-ItemProperty -Path 'HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -ErrorAction Stop | Out-String } catch { $_.Exception.Message }
$doPol  = try { Get-ItemProperty -Path 'HKLM:SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -ErrorAction Stop | Out-String } catch { $_.Exception.Message }
Write-SectionFile -Name 'WU_Policies' -Content $wuPol | Out-Null
Write-SectionFile -Name 'DO_Policies' -Content $doPol | Out-Null

# 4. Hotfixes / Update History (partial)
Write-Info "Collecting hotfix summary"
$hotfix = try { Get-WmiObject -Class Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 25 HotFixID, InstalledOn, Description | Format-Table -AutoSize | Out-String } catch { $_.Exception.Message }
Write-SectionFile -Name 'Hotfixes' -Content $hotfix | Out-Null

# 5. Disk Space
Write-Info "Collecting disk space"
$disk = Get-PSDrive -Name C | ForEach-Object {
    [PSCustomObject]@{
        Name   = $_.Name
        FreeGB = [math]::Round( $_.Free/1GB, 2)
        UsedGB = [math]::Round( $_.Used/1GB, 2)
        TotalGB= [math]::Round( ($_.Free+ $_.Used)/1GB, 2)
    }
}
Write-SectionFile -Name 'Disk' -Content ($disk | Format-Table -AutoSize | Out-String) | Out-Null
$summaryLines += "Disk (C:) FreeGB: $($disk.FreeGB) / TotalGB: $($disk.TotalGB)"

# 6. Driver Summary (optional)
if (-not $SkipDrivers) {
    Write-Info "Collecting top driver versions"
    $drivers = try {
        Get-WmiObject Win32_PnPSignedDriver | Sort-Object DriverDate -Descending | Select-Object -First 40 DeviceName, DriverVersion, DriverDate | Format-Table -AutoSize | Out-String
    } catch { $_.Exception.Message }
    Write-SectionFile -Name 'Drivers' -Content $drivers | Out-Null
} else {
    Write-Info "Skipping driver enumeration (SkipDrivers)"
}

# 7. AV / Defender Status
Write-Info "Collecting Defender status"
$defStatus = try { Get-MpComputerStatus | Select-Object AMServiceEnabled, AntispywareEnabled, RealTimeProtectionEnabled, AntivirusEnabled | Format-List | Out-String } catch { $_.Exception.Message }
Write-SectionFile -Name 'DefenderStatus' -Content $defStatus | Out-Null

# 8. Pending Reboot Keys
Write-Info "Checking pending reboot indicators"
$rebootKeys = @(
  'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:SOFTWARE\Microsoft\Updates'
)
$pending = foreach($rk in $rebootKeys){ if(Test-Path $rk){ "Pending: $rk" } }
if(-not $pending){ $pending = 'No pending reboot keys detected.' }
Write-SectionFile -Name 'PendingReboot' -Content ($pending | Out-String) | Out-Null
$summaryLines += "Pending Reboot: " + ($pending -join '; ')

# 9. Optional Integrity Checks
if ($IncludeSfcDism) {
    Write-Info "Running SFC and DISM (this may take a while)"
    $integrityLog = New-Object System.Text.StringBuilder
    $integrityLog.AppendLine('== SFC ==') | Out-Null
    $sfc = cmd /c 'sfc /scannow' 2>&1 | Out-String
    $integrityLog.AppendLine($sfc) | Out-Null
    $integrityLog.AppendLine('== DISM /RestoreHealth ==') | Out-Null
    $dism = cmd /c 'dism /online /cleanup-image /restorehealth' 2>&1 | Out-String
    $integrityLog.AppendLine($dism) | Out-Null
    Write-SectionFile -Name 'IntegrityChecks' -Content $integrityLog.ToString() | Out-Null
} else {
    Write-Info "Skipping SFC/DISM (IncludeSfcDism not specified)"
}

# 10. Generate WindowsUpdate.log (optional)
if ($GenerateWindowsUpdateLog) {
    Write-Info "Generating WindowsUpdate.log"
    $wuOut = Join-Path $rootDir 'WindowsUpdate.log'
    try {
        Get-WindowsUpdateLog -LogPath $wuOut -ErrorAction Stop | Out-Null
    } catch {
        Write-Info "Failed to generate WindowsUpdate.log: $($_.Exception.Message)"
    }
}

# 11. Copy Panther Logs if present
Write-Info "Collecting Panther logs if available"
$panther = 'C:\Windows\Panther'
if (Test-Path $panther) {
    $pantherTargets = @('setuperr.log','setupact.log')
    foreach ($p in $pantherTargets) {
        $src = Join-Path $panther $p
        if (Test-Path $src) {
            Copy-Item $src -Destination (Join-Path $rootDir $p) -Force -ErrorAction SilentlyContinue
        }
    }
}

# 12. Delivery Optimization Status
try {
    $doStatus = Get-DeliveryOptimizationStatus | Select-Object FileName, Status, BytesDownloaded, BytesFromPeers | Format-Table -AutoSize | Out-String
    Write-SectionFile -Name 'DeliveryOptimization' -Content $doStatus | Out-Null
} catch {}

# 13. Running update processes
$proc = Get-Process | Where-Object { $_.Name -match 'wu|setup|update' } | Select-Object Name, Id, CPU, StartTime | Format-Table -AutoSize | Out-String
Write-SectionFile -Name 'Processes' -Content $proc | Out-Null

# Summary file
$summaryPath = Join-Path $rootDir 'Summary.txt'
$summaryLines += "--- Raw Section Files:"
Get-ChildItem $rawDir -File | ForEach-Object { $summaryLines += $_.Name }
$summaryLines | Out-File -FilePath $summaryPath -Encoding UTF8 -Force

# 14. Optional ZIP
if ($ZipOutput) {
    Write-Info "Creating ZIP archive"
    $zipPath = "$rootDir.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($rootDir, $zipPath)
    Write-Info "ZIP created: $zipPath"
}

Write-Info "Diagnostics complete. Root folder: $rootDir"
if (-not $Quiet) { Write-Host "Summary file: $summaryPath" -ForegroundColor Green }

# End
