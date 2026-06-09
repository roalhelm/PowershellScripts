param(
    [Parameter(Mandatory = $false)]
    [int]$ReinstallWindowDays = 3
)

$ErrorActionPreference = "Stop"
$LogPath = Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\CompanyPortal-Detection.log"
$RemediationLogPath = Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\CompanyPortal-Remediation.log"
$SuccessMarker = "Remediation successful. Company Portal installed."

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [Detection] $Message"
    Add-Content -Path $LogPath -Value $line
}

function Get-LatestSuccessfulReinstallTime {
    param(
        [string]$Path,
        [string]$Marker
    )

    if (-not (Test-Path -Path $Path)) {
        return $null
    }

    $latest = $null
    $lines = Get-Content -Path $Path -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        if ($line -notlike "*$Marker*") {
            continue
        }

        if ($line -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
            $parsed = $null
            if ([datetime]::TryParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
                if ($null -eq $latest -or $parsed -gt $latest) {
                    $latest = $parsed
                }
            }
        }
    }

    return $latest
}

try {
    if (-not (Test-Path -Path (Split-Path -Path $LogPath -Parent))) {
        New-Item -Path (Split-Path -Path $LogPath -Parent) -ItemType Directory -Force | Out-Null
    }

    if ($ReinstallWindowDays -lt 1) {
        $ReinstallWindowDays = 1
    }

    $cutoff = (Get-Date).AddDays(-$ReinstallWindowDays)
    Write-Log "Detection started. Reinstall window: last $ReinstallWindowDays day(s). Cutoff: $cutoff"

    $latestSuccess = Get-LatestSuccessfulReinstallTime -Path $RemediationLogPath -Marker $SuccessMarker
    if ($null -eq $latestSuccess) {
        Write-Log "No successful reinstall marker found in remediation log."
        Write-Output "NonCompliant: no successful reinstall logged"
        exit 1
    }

    if ($latestSuccess -ge $cutoff) {
        Write-Log "Compliant. Latest successful reinstall: $latestSuccess"
        Write-Output "Compliant: Company Portal reinstalled within last $ReinstallWindowDays day(s)"
        exit 0
    }

    Write-Log "Non-compliant. Latest successful reinstall ($latestSuccess) is older than cutoff ($cutoff)."
    Write-Output "NonCompliant: last reinstall older than $ReinstallWindowDays day(s)"
    exit 1
}
catch {
    Write-Log "Detection error: $($_.Exception.Message)"
    Write-Output "NonCompliant: detection error, remediation requested"
    exit 1
}
