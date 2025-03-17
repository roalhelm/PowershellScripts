<#
.SYNOPSIS
    Repairs Windows Management Instrumentation (WMI) on a remote computer.

.DESCRIPTION
    This script performs the following tasks:
    - Connects to a remote computer
    - Verifies network connectivity
    - Stops and starts the WMI service
    - Verifies and repairs the WMI repository
    - Provides status updates throughout the process

.NOTES
    Filename: PSrepairWMI.ps1
    Prerequisites:
        - Administrative rights on the remote machine
        - PowerShell remoting enabled
        - Network connectivity to the target machine
        - Valid credentials for the remote machine
    
    Known Issues:
        - WMI repository repair might require multiple attempts
        - Requires manual credential entry
    
.AUTHOR
    Ronny Alhelm

.VERSION
    1.0.0

.EXAMPLE
    .\PSrepairWMI.ps1
    Bitte geben Sie den Namen des Clients ein: SERVER01
    # This will repair WMI on SERVER01

.EXAMPLE
    .\PSrepairWMI.ps1
    Bitte geben Sie den Namen des Clients ein: WORKSTATION-PC
    # Repairs WMI on WORKSTATION-PC with credential prompt
#>

# Abfrage des Clientnamens
$remoteComputer = Read-Host -Prompt "Bitte geben Sie den Namen des Clients ein"

if ([string]::IsNullOrWhiteSpace($remoteComputer)) {
    Write-Host "Es wurde kein Clientname eingegeben. Das Skript wird beendet."
    exit
}

# Überprüfen, ob der Remote-Computer erreichbar ist
$pingResult = Test-Connection -ComputerName $remoteComputer -Count 2 -Quiet
if (-not $pingResult) {
    Write-Host "Der Remote-Computer $remoteComputer ist nicht erreichbar."
    exit
}

# WMI-Dienst auf dem Remote-Computer neu starten
try {
    Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
        # Starten des WMI-Dienstes
        Write-Host "Starte den WMI-Dienst neu..."
        Stop-Service -Name winmgmt -Force
        Start-Service -Name winmgmt

        # Reparieren des WMI-Repositorys
        Write-Host "Repariere das WMI-Repository..."
        winmgmt /verifyrepository
        $repositoryStatus = winmgmt /salvagerepository
        if ($repositoryStatus -like "*success*") {
            Write-Host "Das WMI-Repository wurde erfolgreich repariert."
        } else {
            Write-Host "Fehler bei der Reparatur des WMI-Repositorys."
        }

        # WMI-Dienst nach der Reparatur neu starten
        Start-Service -Name winmgmt
    } -Credential (Get-Credential) -ErrorAction Stop
} catch {
    Write-Host "Fehler beim Verbinden mit dem Client '$remoteComputer': $_" -ForegroundColor Red
    exit
}

Write-Host "WMI-Reparatur auf dem Remote-Computer $remoteComputer abgeschlossen."
