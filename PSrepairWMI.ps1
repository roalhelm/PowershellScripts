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
