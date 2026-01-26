<#
.SYNOPSIS
    Ermittelt Intune-verwaltete Clients für bestimmte Benutzer mit detaillierten Informationen.
    
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    Dieses Script liest Clients aus, bei denen ein bestimmter Benutzer als Primary User eingetragen ist.
    Es zeigt folgende Informationen:
    - Clientname
    - Primary User
    - Betriebssystem
    - OS Version/Buildversion
    - Letzter Login (LastSyncDateTime)
    - Freier Speicherplatz
    
    Das Script bietet ein interaktives Menü zur Auswahl der Eingabemethode und speichert
    die Ergebnisse automatisch in eine CSV-Datei mit aktuellem Datum.

.NOTES
    File Name     : GetClientsfromUser.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : 26.01.2026
    Requires      : Microsoft.Graph PowerShell Modules
    Permissions   : DeviceManagementManagedDevices.Read.All, Group.Read.All, User.Read.All

.CHANGES
    Version 1.0 (26.01.2026)
    - Initial release
    - Interactive menu for input selection
    - Support for single UPN, CSV file, and Azure AD group input
    - Automatic CSV export with timestamp

.AUTHOR
    Ronny Alhelm

.VERSION
    1.0

.EXAMPLE
    .\GetClientsfromUser.ps1

#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement, Microsoft.Graph.Groups

# Funktionen
function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Get Clients from User - Intune Geräteabfrage" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Wählen Sie die Eingabemethode:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Einzelne Benutzer (UPN eingeben)" -ForegroundColor White
    Write-Host "  [2] Benutzer aus CSV-Datei importieren" -ForegroundColor White
    Write-Host "  [3] Benutzer aus Azure AD Gruppe (Name)" -ForegroundColor White
    Write-Host "  [4] Benutzer aus Azure AD Gruppe (ID)" -ForegroundColor White
    Write-Host "  [0] Beenden" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Ihre Auswahl"
    return $choice
}

function Get-UserInput {
    param([string]$Choice)
    
    switch ($Choice) {
        '1' {
            Write-Host "`nEinzelne Benutzer eingeben" -ForegroundColor Cyan
            Write-Host "Geben Sie die UPN(s) ein (mehrere durch Komma getrennt):" -ForegroundColor Yellow
            $input = Read-Host "UPN(s)"
            return @{
                Type = 'UPN'
                Data = $input -split ',' | ForEach-Object { $_.Trim() }
            }
        }
        '2' {
            Write-Host "`nBenutzer aus CSV-Datei" -ForegroundColor Cyan
            Write-Host "Geben Sie den vollständigen Pfad zur CSV-Datei ein:" -ForegroundColor Yellow
            $path = Read-Host "CSV-Pfad"
            return @{
                Type = 'CSV'
                Data = $path
            }
        }
        '3' {
            Write-Host "`nBenutzer aus Azure AD Gruppe (Name)" -ForegroundColor Cyan
            Write-Host "Geben Sie den Namen der Gruppe ein:" -ForegroundColor Yellow
            $groupName = Read-Host "Gruppenname"
            return @{
                Type = 'GroupName'
                Data = $groupName
            }
        }
        '4' {
            Write-Host "`nBenutzer aus Azure AD Gruppe (ID)" -ForegroundColor Cyan
            Write-Host "Geben Sie die ID der Gruppe ein:" -ForegroundColor Yellow
            $groupId = Read-Host "Gruppen-ID"
            return @{
                Type = 'GroupId'
                Data = $groupId
            }
        }
        default {
            return $null
        }
    }
}

function Connect-ToMicrosoftGraph {
    Write-Host "Verbinde mit Microsoft Graph..." -ForegroundColor Cyan
    
    $requiredScopes = @(
        "DeviceManagementManagedDevices.Read.All",
        "Group.Read.All",
        "User.Read.All"
    )
    
    try {
        Connect-MgGraph -Scopes $requiredScopes -NoWelcome
        Write-Host "Erfolgreich mit Microsoft Graph verbunden." -ForegroundColor Green
    }
    catch {
        Write-Error "Fehler beim Verbinden mit Microsoft Graph: $_"
        exit 1
    }
}

function Get-UsersFromCsv {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Error "CSV-Datei nicht gefunden: $Path"
        exit 1
    }
    
    try {
        $csv = Import-Csv -Path $Path
        if ($csv[0].PSObject.Properties.Name -notcontains "UserPrincipalName") {
            Write-Error "CSV-Datei muss eine Spalte 'UserPrincipalName' enthalten"
            exit 1
        }
        return $csv.UserPrincipalName
    }
    catch {
        Write-Error "Fehler beim Lesen der CSV-Datei: $_"
        exit 1
    }
}

function Get-UsersFromGroup {
    param(
        [string]$GroupName,
        [string]$GroupId
    )
    
    try {
        if ($GroupName) {
            Write-Host "Suche Gruppe: $GroupName..." -ForegroundColor Cyan
            $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction Stop
            if (-not $group) {
                Write-Error "Gruppe '$GroupName' nicht gefunden"
                exit 1
            }
            $GroupId = $group.Id
        }
        
        Write-Host "Lade Gruppenmitglieder..." -ForegroundColor Cyan
        $members = Get-MgGroupMember -GroupId $GroupId -All
        
        $userUpns = @()
        foreach ($member in $members) {
            $user = Get-MgUser -UserId $member.Id -Property UserPrincipalName -ErrorAction SilentlyContinue
            if ($user) {
                $userUpns += $user.UserPrincipalName
            }
        }
        
        Write-Host "Gefunden: $($userUpns.Count) Benutzer in der Gruppe" -ForegroundColor Green
        return $userUpns
    }
    catch {
        Write-Error "Fehler beim Abrufen der Gruppenmitglieder: $_"
        exit 1
    }
}

function Get-IntuneDeviceDetails {
    param([string]$UserPrincipalName)
    
    Write-Host "Suche Geräte für: $UserPrincipalName" -ForegroundColor Cyan
    
    try {
        # Filtere Geräte nach Primary User
        $devices = Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq '$UserPrincipalName'" -All
        
        if ($devices.Count -eq 0) {
            Write-Host "  Keine Geräte gefunden" -ForegroundColor Yellow
            return @()
        }
        
        $results = @()
        foreach ($device in $devices) {
            # Berechne freien Speicherplatz
            $freeStorageGB = $null
            $totalStorageGB = $null
            if ($device.FreeStorageSpaceInBytes -and $device.TotalStorageSpaceInBytes) {
                $freeStorageGB = [math]::Round($device.FreeStorageSpaceInBytes / 1GB, 2)
                $totalStorageGB = [math]::Round($device.TotalStorageSpaceInBytes / 1GB, 2)
            }
            
            $deviceInfo = [PSCustomObject]@{
                ClientName          = $device.DeviceName
                PrimaryUser         = $device.UserPrincipalName
                EmailAddress        = $device.EmailAddress
                OS                  = $device.OperatingSystem
                OSVersion           = $device.OSVersion
                BuildVersion        = if ($device.AdditionalProperties.ContainsKey('osBuildNumber')) { 
                                        $device.AdditionalProperties['osBuildNumber'] 
                                      } else { 
                                        "N/A" 
                                      }
                LastSyncDateTime    = $device.LastSyncDateTime
                FreeDiskSpaceGB     = $freeStorageGB
                TotalDiskSpaceGB    = $totalStorageGB
                Model               = $device.Model
                Manufacturer        = $device.Manufacturer
                SerialNumber        = $device.SerialNumber
                EnrollmentDate      = $device.EnrolledDateTime
                ComplianceState     = $device.ComplianceState
                ManagedDeviceId     = $device.Id
            }
            
            $results += $deviceInfo
            Write-Host "  ✓ $($device.DeviceName)" -ForegroundColor Green
        }
        
        return $results
    }
    catch {
        Write-Error "Fehler beim Abrufen der Geräteinformationen für $UserPrincipalName : $_"
        return @()
    }
}

function Format-DeviceOutput {
    param([array]$Devices)
    
    if ($Devices.Count -eq 0) {
        Write-Host "`nKeine Geräte gefunden." -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Gefundene Geräte: $($Devices.Count)" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $Devices | Format-Table -AutoSize -Property ClientName, PrimaryUser, OS, OSVersion, BuildVersion, LastSyncDateTime, @{
        Name = 'FreeDiskSpace'
        Expression = { 
            if ($_.FreeDiskSpaceGB) { 
                "$($_.FreeDiskSpaceGB) GB / $($_.TotalDiskSpaceGB) GB" 
            } else { 
                "N/A" 
            }
        }
    }
}

# Hauptscript

# Menü anzeigen und Auswahl treffen
$choice = Show-Menu

if ($choice -eq '0' -or [string]::IsNullOrWhiteSpace($choice)) {
    Write-Host "`nScript beendet." -ForegroundColor Yellow
    exit 0
}

# Benutzereingabe abrufen
$userInput = Get-UserInput -Choice $choice

if ($null -eq $userInput) {
    Write-Host "`nUngültige Auswahl. Script wird beendet." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Verbindung herstellen
Connect-ToMicrosoftGraph

# Benutzerliste ermitteln
$users = @()
switch ($userInput.Type) {
    'UPN' {
        $users = $userInput.Data
        Write-Host "`nModus: Einzelne UPN(s)" -ForegroundColor Green
    }
    'CSV' {
        $users = Get-UsersFromCsv -Path $userInput.Data
        Write-Host "`nModus: CSV-Import ($($users.Count) Benutzer)" -ForegroundColor Green
    }
    'GroupName' {
        $users = Get-UsersFromGroup -GroupName $userInput.Data
        Write-Host "`nModus: Azure AD Gruppe (Name)" -ForegroundColor Green
    }
    'GroupId' {
        $users = Get-UsersFromGroup -GroupId $userInput.Data
        Write-Host "`nModus: Azure AD Gruppe (ID)" -ForegroundColor Green
    }
}

if ($users.Count -eq 0) {
    Write-Error "Keine Benutzer zum Verarbeiten gefunden."
    exit 1
}

Write-Host "`nVerarbeite $($users.Count) Benutzer...`n" -ForegroundColor Cyan

# Geräte für alle Benutzer abrufen
$allDevices = @()
foreach ($user in $users) {
    $devices = Get-IntuneDeviceDetails -UserPrincipalName $user
    $allDevices += $devices
}

# Ausgabe
Format-DeviceOutput -Devices $allDevices

# Automatischer Export mit Datum
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$scriptPath = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    $scriptPath = Get-Location
}

$exportPath = Join-Path -Path $scriptPath -ChildPath "ClientsFromUser_$timestamp.csv"

if ($allDevices.Count -gt 0) {
    try {
        $allDevices | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
        Write-Host "`n✓ Ergebnisse automatisch exportiert nach:" -ForegroundColor Green
        Write-Host "  $exportPath" -ForegroundColor White
    }
    catch {
        Write-Error "Fehler beim Exportieren der Ergebnisse: $_"
    }
}
else {
    Write-Host "`nKeine Geräte zum Exportieren gefunden." -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Script abgeschlossen!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Pause vor dem Beenden
Read-Host "`nDrücken Sie Enter zum Beenden"
