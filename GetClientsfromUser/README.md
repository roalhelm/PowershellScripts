# GetClientsfromUser

Dieses PowerShell-Script ermittelt Intune-verwaltete Clients für bestimmte Benutzer und zeigt detaillierte Informationen an. Das Script bietet ein **interaktives Menü** zur Eingabe und speichert die Ergebnisse automatisch in eine **CSV-Datei mit aktuellem Datum**.

## Voraussetzungen

- PowerShell 5.1 oder höher
- Microsoft Graph PowerShell Module:
  ```powershell
  Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
  Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
  Install-Module Microsoft.Graph.Groups -Scope CurrentUser
  ```

## Berechtigungen

Das Script benötigt folgende Microsoft Graph Berechtigungen:
- `DeviceManagementManagedDevices.Read.All`
- `Group.Read.All`
- `User.Read.All`

## Funktionen

Das Script gibt folgende Informationen aus:
- **ClientName**: Name des Geräts
- **Primary User**: UPN des primären Benutzers
- **OS**: Betriebssystem
- **OS Version**: Version des Betriebssystems
- **Build Version**: Build-Nummer des OS
- **Last Sync DateTime**: Zeitpunkt der letzten Synchronisation mit Intune
- **Free Disk Space**: Freier Speicherplatz (in GB)
- **Total Disk Space**: Gesamter Speicherplatz (in GB)
- Zusätzliche Informationen: Model, Manufacturer, SerialNumber, EnrollmentDate, ComplianceState

### Automatischer CSV-Export

Starten Sie das Script einfach:

```powershell
.\GetClientsfromUser.ps1
```

### Interaktives Menü

Nach dem Start erscheint ein Menü mit folgenden Optionen:

```
========================================
Get Clients from User - Intune Geräteabfrage
========================================

Wählen Sie die Eingabemethode:

  [1] Einzelne Benutzer (UPN eingeben)
  [2] Benutzer aus CSV-Datei importieren
  [3] Benutzer aus Azure AD Gruppe (Name)
  [4] Benutzer aus Azure AD Gruppe (ID)
  [0] Beenden

Ihre Auswahl:
```

### Eingabemethoden

#### Option 1: Einzelne Benutzer
Geben Sie eine oder mehrere UPNs ein (durch Komma getrennt):
```
user1@contoso.com, user2@contoso.com
```

#### Option 2: CSV-Datei
Geben Sie den vollständigen Pfad zur CSV-Datei ein:
```
C:\Temp\users.csv
```

Die CSV-Datei muss eine Spalte `UserPrincipalName` enthalten:
```csv
UserPrincipalName
user1@contoso.com
user2@contoso.com
user3@contoso.com
```

#### Option 3: Azure AD Gruppe (Name)
Geben Sie den Gruppennamen ein:
```
IT-Department
```

#### Option 4: Azure AD Gruppe (ID)
Geben Sie die Gruppen-ID ein:
```
12345678-1234-1234-1234-123456789012

```powershell
.\GetClientsfromUser.ps1 -AadGroupId "12345678-1234-1234-1234-123456789012"
```
Wählen Sie die Eingabemethode:

  [1] Einzelne Benutzer (UPN eingeben)
  [2] Benutzer aus CSV-Datei importieren
  [3] Benutzer aus Azure AD Gruppe (Name)
  [4] Benutzer aus Azure AD Gruppe (ID)
  [0] Beenden

Ihre Auswahl: 1

Einzelne Benutzer eingeben
Geben Sie die UPN(s) ein (mehrere durch Komma getrennt):
UPN(s): john.doe@contoso.com

Verbinde mit Microsoft Graph...
Erfolgreich mit Microsoft Graph verbunden.

Modus: Einzelne UPN(s)

Verarbeite 1 Benutzer...

Suche Geräte für: john.doe@contoso.com
  ✓ DESKTOP-ABC123
  ✓ LAPTOP-DEF456

========================================
Gefundene Geräte: 2
========================================

ClientName      PrimaryUser              OS      OSVersion    BuildVersion LastSyncDateTime     FreeDiskSpace
----------      -----------              --      ---------    ------------ ----------------     -------------
DESKTOP-ABC123  john.doe@contoso.com     Windows 10.0.19045.0 19045        2026-01-26 10:30:15  125.45 GB / 476.00 GB
LAPTOP-DEF456   john.doe@contoso.com     Windows 10.0.22631.0 22631        2026-01-26 09:15:42  89.32 GB / 238.00 GB

✓ Ergebnisse automatisch exportiert nach:
  C:\Tools\PowershellScripts\GetClientsfromUser\ClientsFromUser_2026-01-26_14-35-22.csv

========================================
Script abgeschlossen!
========================================

Drücken Sie Enter zum Beenden
  ✓ LAPTOP-DEF456

========================================
Gefundene Geräte: 2
========================================

ClientName      PrimaryUser              OS      OSVersion    BuildVersion LastSyncDateTime     FreeDiskSpace
----------      -----------              --      ---------    ------------ ----------------     -------------
DESKTOP-ABC123  john.doe@contoso.com     Windows 10.0.19045.0 19045        2026-01-26 10:30:15  125.45 GB / 476.00 GB
LAPTOP-DEF456   john.doe@contoso.com     Windows 10.0.22631.0 22631        2026-01-26 09:15:42  89.32 GB / 238.00 GB

========================================
Script abgeschlossen!
========================================
```

## Fehlerbehandlung

- Das Script überprüft die Graph-Verbindung
- CSV-Dateien werden auf die erforderliche Spalte geprüft
- Gruppennamen und IDs werden validiert
- Fehlende Geräte werden als Warnung angezeigt

## Hinweise

- Bei der ersten Ausführung wird ein Browser-Fenster für die Authentifizierung geöffnet
- Die Ausführungszeit hängt von der Anzahl der Benutzer und Geräte ab
- Manche Felder (z.B. BuildVersion) sind nicht für alle Gerätetypen verfügbar
