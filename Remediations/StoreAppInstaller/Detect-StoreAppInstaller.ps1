<#
.SYNOPSIS
    Detection: Microsoft Store or App Installer (winget) is missing or damaged, or a service they need is disabled.

.DESCRIPTION
    Finding ID: APP.STORE.BROKEN (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    Read-only. Store apps from Intune, Company Portal updates and winget need the packages
    Microsoft.WindowsStore and Microsoft.DesktopAppInstaller and the services AppXSvc, ClipSVC
    and InstallService. Reports an issue when one of the services is disabled or a package is
    missing or damaged. Run as SYSTEM it looks at the packages of all users, run as the user
    at the packages of that user. A Store that is turned off by policy (RemoveWindowsStore)
    is not reported.

    Exit 0 = healthy, exit 1 = issue found.

.NOTES
    File Name : Detect-StoreAppInstaller.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, 64-bit PowerShell. As SYSTEM: services and all users. As the user: the packages of that user

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Detect-StoreAppInstaller.ps1
#>

$FindingId = 'APP.STORE.BROKEN'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

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

function Get-RegValue {
    param([string]$Path, [string]$Name)
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name }
    catch { return $null }
}

$Families = [ordered]@{
    'Microsoft.WindowsStore'        = 'Microsoft.WindowsStore_8wekyb3d8bbwe'
    'Microsoft.DesktopAppInstaller' = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
}
$Services = 'AppXSvc', 'ClipSVC', 'InstallService'   # default start type of all three: Manual (3)

function Test-IsSystem {
    try { return ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') } catch { return $false }
}

function Test-IsElevated {
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

function Get-DisabledServices {
    return @($Services | Where-Object { (Get-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$_" -Name 'Start') -eq 4 })
}

function Get-PackageProblems {
    # Missing or damaged packages. As SYSTEM or admin: for all users. Otherwise: for the current user.
    param([bool]$AllUsers)
    $storeRemoved = (Get-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' -Name 'RemoveWindowsStore') -eq 1
    $problems = @()
    foreach ($name in $Families.Keys) {
        if ($name -eq 'Microsoft.WindowsStore' -and $storeRemoved) { continue }   # Store is turned off by policy on purpose
        if ($AllUsers) { $packages = @(Get-AppxPackage -AllUsers -Name $name -ErrorAction Stop) }
        else { $packages = @(Get-AppxPackage -Name $name -ErrorAction Stop) }
        $package = $packages | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $package) { $problems += "$name is not installed" }
        elseif ([string]$package.Status -ne 'Ok') { $problems += "$name is damaged (status $($package.Status))" }
    }
    return $problems
}

try {
    $problems = @()
    $disabled = Get-DisabledServices
    if ($disabled.Count -gt 0) { $problems += 'service disabled: ' + ($disabled -join ', ') }
    $problems += @(Get-PackageProblems -AllUsers ((Test-IsSystem) -or (Test-IsElevated)))

    if ($problems.Count -gt 0) {
        $msg = ($problems -join '; ') + '.'
        Write-FixLog $msg 'WARN'
        Write-Output "$FindingId | Issue | $msg"
        exit 1
    }
    $msg = 'Microsoft Store, App Installer and their services are OK.'
    Write-FixLog $msg
    Write-Output "$FindingId | OK | $msg"
    exit 0
}
catch {
    $msg = "State could not be read: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Issue | $msg"
    exit 1
}
