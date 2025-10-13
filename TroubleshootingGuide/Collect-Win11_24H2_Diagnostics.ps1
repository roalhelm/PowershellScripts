<#
.SYNOPSIS
    Comprehensive diagnostic data collector for Windows 11 24H2 Feature Update troubleshooting in Intune-managed environments.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This comprehensive diagnostic script collects critical system information to troubleshoot Windows 11 24H2 
    Feature Update deployment issues, particularly in Microsoft Intune-managed enterprise environments.
    
    The script performs extensive system analysis including:
    1. Hardware and firmware prerequisite validation (TPM, SecureBoot, UEFI)
    2. Intune enrollment status and device management state
    3. Windows Update for Business (WUfB) policy configuration analysis
    4. Update history, hotfixes, and patch deployment status
    5. Disk space analysis and storage requirements validation
    6. Driver compatibility assessment and version analysis
    7. Microsoft Defender antivirus status and security state
    8. Pending reboot detection and system state analysis
    9. Optional system integrity checks (SFC/DISM scans)
    10. Windows Update service logs and delivery optimization status
    11. Setup and deployment log collection from Panther directory
    12. Running process analysis for update-related services
    
    All diagnostic data is organized into a timestamped folder structure with both raw data files
    and a consolidated human-readable summary report for efficient troubleshooting workflows.

.NOTES
    File Name     : Collect-Win11_24H2_Diagnostics.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025
    Requirements  : PowerShell 5.1 or higher
    Permissions   : Elevated PowerShell recommended for complete data collection
    Compatibility : Windows 10 version 1909+ and Windows 11 (all versions)
    Target Use    : Windows 11 24H2 Feature Update troubleshooting

.CHANGES
    Version 1.0 (2025-10-13):
    - Initial release with comprehensive diagnostic collection
    - Added hardware prerequisite validation (TPM, SecureBoot, UEFI)
    - Implemented Intune enrollment status detection
    - Added Windows Update for Business policy analysis
    - Included driver compatibility assessment
    - Added Microsoft Defender status monitoring
    - Implemented pending reboot detection
    - Added optional system integrity checks (SFC/DISM)
    - Included Windows Update log generation
    - Added Panther setup log collection
    - Implemented delivery optimization status analysis
    - Added process monitoring for update services
    - Created structured output with summary reporting
    - Added ZIP compression option for easy sharing

.VERSION
    1.0

.EXAMPLE
    .\Collect-Win11_24H2_Diagnostics.ps1
    Performs basic diagnostic collection with hardware checks, Intune status, policies, and system state.
    Creates a timestamped folder with all diagnostic data.

.EXAMPLE
    .\Collect-Win11_24H2_Diagnostics.ps1 -IncludeSfcDism -GenerateWindowsUpdateLog -ZipOutput
    Comprehensive diagnostic collection including system integrity scans, Windows Update log generation,
    and ZIP compression of results for easy sharing with support teams.

.EXAMPLE
    .\Collect-Win11_24H2_Diagnostics.ps1 -OutputPath "C:\Diagnostics" -Quiet -ZipOutput
    Runs diagnostic collection with minimal console output, saves to custom location,
    and creates compressed archive for enterprise support workflows.

.EXAMPLE
    .\Collect-Win11_24H2_Diagnostics.ps1 -SkipDrivers -Quiet
    Quick diagnostic run skipping driver enumeration for faster execution on systems
    with many installed drivers or in time-sensitive troubleshooting scenarios.

.PARAMETER OutputPath
    Base directory path where the diagnostic folder will be created. 
    Defaults to current working directory if not specified.

.PARAMETER IncludeSfcDism
    Executes system file checker (sfc /scannow) and DISM restore health operations.
    WARNING: These operations can take 15-30 minutes to complete.

.PARAMETER GenerateWindowsUpdateLog
    Creates consolidated Windows Update log file using Get-WindowsUpdateLog cmdlet.
    Useful for detailed update service troubleshooting.

.PARAMETER SkipDrivers
    Bypasses driver enumeration and analysis to speed up execution.
    Recommended for systems with extensive driver installations.

.PARAMETER ZipOutput
    Creates compressed ZIP archive of the complete diagnostic folder.
    Facilitates easy sharing with support teams or remote analysis.

.PARAMETER Quiet
    Suppresses detailed console output, showing only essential progress information.
    Ideal for automated execution or batch processing scenarios.

.OUTPUTS
    Creates timestamped diagnostic folder containing:
    - Summary.txt: Consolidated human-readable diagnostic report
    - Raw/: Subfolder with individual diagnostic section files (.log/.txt)
    - WindowsUpdate.log: Consolidated update service log (if -GenerateWindowsUpdateLog used)
    - setupact.log, setuperr.log: Setup logs from Panther directory (if available)
    - Optional ZIP archive of complete diagnostic data (if -ZipOutput used)

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
