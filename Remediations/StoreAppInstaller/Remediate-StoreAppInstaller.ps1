<#
.SYNOPSIS
    Remediation: enable the Store services and register Microsoft Store and App Installer again.

.DESCRIPTION
    Finding ID: APP.STORE.BROKEN (same ID as Get-ClientHealth.ps1 in roalhelm/ClientFixPage).

    What it does depends on the context:
      - As SYSTEM or elevated: sets the services AppXSvc, ClipSVC and InstallService back to
        their default start type (Manual) when they are disabled.
      - As the signed-in user (not SYSTEM): registers Microsoft.WindowsStore and
        Microsoft.DesktopAppInstaller again for that user from the copy that is already on
        the device (Add-AppxPackage -RegisterByFamilyName). No download, app data is kept.

    App packages are registered per user, so SYSTEM cannot repair them for a user. If the
    packages are missing or damaged, assign this package a second time with
    "Run this script using the logged-on credentials" = Yes.

    Exit 0 = everything this context can fix is fixed, exit 1 = something is still broken.

.NOTES
    File Name : Remediate-StoreAppInstaller.ps1
    Author    : Ronny Alhelm
    Version   : 1.0
    Created   : 2026-11-10
    Requires  : Windows 10/11, Windows PowerShell 5.1, 64-bit PowerShell. As SYSTEM: services and all users. As the user: the packages of that user
    Log       : C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientFix.log

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Remediate-StoreAppInstaller.ps1
#>

$FindingId = 'APP.STORE.BROKEN'
$LogFile   = Join-Path $env:ProgramData 'Microsoft\IntuneManagementExtension\Logs\ClientFix.log'

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

Write-FixLog 'Started'

try {
    $isSystem   = Test-IsSystem
    $isElevated = Test-IsElevated
    $notes  = @()
    $failed = @()

    if ($isSystem -or $isElevated) {
        foreach ($name in (Get-DisabledServices)) {
            try {
                Set-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$name" -Name 'Start' -Value 3 -Type DWord -ErrorAction Stop
                Write-FixLog "$name start type set to Manual"
                $notes += "$name enabled (active after a restart)"
            }
            catch {
                Write-FixLog "$name could not be enabled: $($_.Exception.Message)" 'ERROR'
                $failed += "$name is still disabled"
            }
        }
    }
    elseif ((Get-DisabledServices).Count -gt 0) {
        $failed += 'disabled services need the SYSTEM run of this script: ' + ((Get-DisabledServices) -join ', ')
    }

    if ($isSystem) {
        $problems = @(Get-PackageProblems -AllUsers $true)
        if ($problems.Count -gt 0) { $failed += ($problems -join '; ') + ' (run this script in the user context to register the packages again)' }
    }
    else {
        foreach ($name in $Families.Keys) {
            $package = Get-AppxPackage -Name $name -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
            if ($package -and [string]$package.Status -eq 'Ok') { continue }
            if ($name -eq 'Microsoft.WindowsStore' -and (Get-RegValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' -Name 'RemoveWindowsStore') -eq 1) { continue }
            try {
                Add-AppxPackage -RegisterByFamilyName -MainPackage $Families[$name] -ErrorAction Stop
                Write-FixLog "Registered $name for $env:USERNAME"
                $notes += "$name registered"
            }
            catch {
                Write-FixLog "$name could not be registered: $($_.Exception.Message)" 'ERROR'
                $failed += "$name could not be registered (not on the device any more? Reinstall it: wsreset.exe -i for the Store, or the App Installer page in the Store)"
            }
        }
    }

    $summary = if ($notes.Count) { ($notes -join '; ') + '.' } else { 'Nothing to change in this context.' }
    if ($failed.Count -gt 0) {
        $msg = "$summary Still open: " + ($failed -join '; ') + '.'
        Write-FixLog "Finished: $msg" 'ERROR'
        Write-Output "$FindingId | Failed | $msg"
        exit 1
    }
    Write-FixLog "Finished: $summary"
    Write-Output "$FindingId | Fixed | $summary"
    exit 0
}
catch {
    $msg = "Unexpected error: $($_.Exception.Message)"
    Write-FixLog $msg 'ERROR'
    Write-Output "$FindingId | Failed | $msg"
    exit 1
}
