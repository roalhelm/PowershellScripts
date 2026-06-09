param(
    [Parameter(Mandatory = $false)]
    [string]$PackageId = "9WZDNCRFJ3PZ",

    [Parameter(Mandatory = $false)]
    [int]$MaxAttempts = 2
)

$ErrorActionPreference = "Stop"
$LogPath = Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\CompanyPortal-Remediation.log"
$Source = "msstore"

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [Remediation] $Message"
    Add-Content -Path $LogPath -Value $line
}

function Resolve-StoreInstallerPath {
    $direct = Get-Command -Name winget.exe -ErrorAction SilentlyContinue
    if ($direct -and (Test-Path -Path $direct.Source)) {
        return $direct.Source
    }

    $appInstaller = Get-AppxPackage -AllUsers -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($appInstaller -and -not [string]::IsNullOrWhiteSpace($appInstaller.InstallLocation)) {
        $candidate = Join-Path $appInstaller.InstallLocation "winget.exe"
        if (Test-Path -Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Invoke-StoreCommand {
    param(
        [string]$InstallerPath,
        [string[]]$Arguments
    )

    Write-Log "Running store command: $($Arguments -join ' ')"
    $output = & $InstallerPath @Arguments 2>&1
    $code = $LASTEXITCODE

    if ($null -ne $output) {
        foreach ($line in $output) {
            Write-Log "store-cli: $line"
        }
    }

    return $code
}

function Test-CompanyPortalInstalled {
    param(
        [string]$InstallerPath,
        [string]$Id,
        [string]$StoreSource
    )

    $args = @(
        "list",
        "--id", $Id,
        "--source", $StoreSource,
        "--exact",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    Write-Log "Checking if package is installed: $Id"
    $output = & $InstallerPath @args 2>&1
    $code = $LASTEXITCODE

    if ($null -ne $output) {
        foreach ($line in $output) {
            Write-Log "store-cli: $line"
        }
    }

    if ($code -ne 0) {
        return $false
    }

    $joined = ($output | Out-String)
    return ($joined -match [regex]::Escape($Id))
}

try {
    if (-not (Test-Path -Path (Split-Path -Path $LogPath -Parent))) {
        New-Item -Path (Split-Path -Path $LogPath -Parent) -ItemType Directory -Force | Out-Null
    }

    Write-Log "Remediation started. PackageId: $PackageId"

    $installerPath = Resolve-StoreInstallerPath
    if ([string]::IsNullOrWhiteSpace($installerPath)) {
        Write-Log "Store installer binary not available in SYSTEM context."
        Write-Output "Failed: store installer not available in SYSTEM context"
        exit 1
    }

    Write-Log "Store installer path resolved: $installerPath"

    $isInstalled = Test-CompanyPortalInstalled -InstallerPath $installerPath -Id $PackageId -StoreSource $Source
    Write-Log "Installed before remediation: $isInstalled"

    $attempt = 0
    $success = $false

    while ($attempt -lt $MaxAttempts -and -not $success) {
        $attempt++
        Write-Log "Attempt $attempt of $MaxAttempts"

        if ($isInstalled) {
            $uninstallArgs = @(
                "uninstall",
                "--id", $PackageId,
                "--source", $Source,
                "--exact",
                "--accept-source-agreements",
                "--disable-interactivity"
            )

            [void](Invoke-StoreCommand -InstallerPath $installerPath -Arguments $uninstallArgs)
        }

        $installArgs = @(
            "install",
            "--id", $PackageId,
            "--source", $Source,
            "--exact",
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--silent",
            "--disable-interactivity"
        )

        $installCode = Invoke-StoreCommand -InstallerPath $installerPath -Arguments $installArgs
        if ($installCode -eq 0) {
            Write-Log "Store install returned success."
            $success = $true
        }
        else {
            Write-Log "Store install failed with exit code $installCode"
        }
    }

    $installedAfter = Test-CompanyPortalInstalled -InstallerPath $installerPath -Id $PackageId -StoreSource $Source
    if ($success -and $installedAfter) {
        Write-Log "Remediation successful. Company Portal installed."
        Write-Output "Remediated: Company Portal installed"
        exit 0
    }

    Write-Log "Remediation failed. Company Portal not confirmed as installed."
    Write-Output "Failed: Company Portal reinstall unsuccessful"
    exit 1
}
catch {
    Write-Log "Remediation error: $($_.Exception.Message)"
    Write-Output "Failed: remediation script error"
    exit 1
}
