
# 🛠️ PowerShell Administrative Scripts Collection

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-GPL%20v3-green.svg)](LICENSE)
[![Last Update](https://img.shields.io/badge/Last%20Update-October%202025-brightgreen)](https://github.com/roalhelm/PowershellScripts)
[![Scripts](https://img.shields.io/badge/Scripts-25%2B-orange)](https://github.com/roalhelm/PowershellScripts)

Eine umfassende Sammlung von PowerShell-Skripten für Systemadministration, Microsoft Intune, Windows Updates, Benutzer-/Gruppenverwaltung, Netzwerk-Diagnostik und Remediation-Aufgaben in modernen Windows-Unternehmensumgebungen.

## 🌟 Highlights

- **🔌 Microsoft Endpoint Connectivity Tester V2.1** - Erweiterte Konnektivitäts-, Latenz- und Performance-Tests mit HTML-Reports
- **🔄 Intune Management & Remediation** - Komplette Suite für Intune-Verwaltung und Problembehandlung
- **📊 Automatisierte Berichte** - Professionelle HTML-Reports mit responsivem Design
- **🎯 Selektive Tests** - Wählen Sie spezifische Services für gezielte Überprüfungen
- **⚡ Performance-Optimiert** - Konfigurierbare Tests für schnelle oder umfassende Analysen

---

## 🚀 Quick Start

```powershell
# Repository klonen
git clone https://github.com/roalhelm/PowershellScripts.git
cd PowershellScripts

# Beispiel: Microsoft Endpoint Connectivity Test mit HTML-Report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport -OpenReport

# Beispiel: Nur Intune und Defender testen
.\CheckMicrosoftEndpointsV2.ps1 -Services Intune,Defender -HtmlReport "MyReport.html"
```

---

## 📋 Systemanforderungen

| Anforderung | Details |
|-------------|---------|
| **PowerShell** | 5.1 oder höher |
| **Berechtigung** | Administratorrechte für die meisten Scripts |
| **Betriebssystem** | Windows 10/11, Windows Server 2016+ |
| **Module** | PSWindowsUpdate, Microsoft.Graph, ActiveDirectory |

### Erforderliche PowerShell-Module installieren:
```powershell
Install-Module PSWindowsUpdate, Microsoft.Graph, ActiveDirectory -Force -AllowClobber
```

---

## 🏆 Featured Script: Microsoft Endpoint Connectivity Tester V2.1

### ✨ Neue Funktionen in Version 2.1
- **🎨 HTML-Report Generation** - Professionelle, responsive Berichte
- **🎯 Service-Auswahl** - Teste nur relevante Microsoft Services
- **⚡ Performance-Optionen** - Überspringe Ping/Speed-Tests für schnellere Ausführung
- **📱 Responsive Design** - Reports funktionieren auf allen Geräten
- **🔍 Interaktives Menü** - Benutzerfreundliche Service-Auswahl

### 🎮 Verwendung

```powershell
# Interaktiver Modus (empfohlen für neue Benutzer)
.\CheckMicrosoftEndpointsV2.ps1

# Alle Services mit vollem Report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport -OpenReport

# Schneller Test nur kritische Services
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate,Intune,AzureAD -SkipSpeed

# Automatisierter Test für CI/CD
.\CheckMicrosoftEndpointsV2.ps1 -Services All -Quiet -HtmlReport "report.html"
```

### 🎯 Unterstützte Microsoft Services
- **Windows Update for Business** - Update-Endpunkte und Delivery-Services
- **Windows Autopatch** - Automatisches Patch-Management
- **Microsoft Intune** - Gerätemanagement und Compliance
- **Microsoft Defender** - Security und Threat Protection
- **Azure Active Directory** - Identitätsdienste und Authentication
- **Microsoft 365** - Office-Apps und Cloud-Services
- **Microsoft Store** - App-Verteilung und Updates
- **Windows Activation** - Lizenzierung und Aktivierung
- **Microsoft Edge** - Browser-Services und Enterprise-Features
- **Windows Telemetry** - Diagnosedaten und Fehlerberichterstattung

---

## 📦 Vollständige Script-Übersicht

### 🌐 Netzwerk & Konnektivität
| Script | Beschreibung | Version | Features |
|--------|-------------|---------|----------|
| **[CheckMicrosoftEndpointsV2.ps1](CheckMicrosoftEndpointsV2.ps1)** | 🏆 **Erweiterte Microsoft Endpoint Tests** | v2.1 | HTML-Reports, Service-Auswahl, Performance-Tests |
| **[CheckMicrosoftEndpointsV1.ps1](CheckMicrosoftEndpointsV1.ps1)** | Basis Microsoft Endpoint Tests | v1.1 | Konnektivität, Ping, Geschwindigkeit |

### 🔧 System & Updates
| Script | Beschreibung | Zweck |
|--------|-------------|-------|
| **[DetectRuntime6.ps1](DetectRuntime6.ps1)** | .NET Desktop Runtime 6 Detection | Intune Detection |
| **[DriverUpdate.ps1](DriverUpdate.ps1)** | System-Treiber Updates | BitLocker-aware Updates |
| **[REP_WindowsUpdate.ps1](REP_WindowsUpdate.ps1)** | Windows Update Reset | Component-Reparatur |
| **[UnblockFiles.ps1](UnblockFiles.ps1)** | Datei-Entsperrung | Security Zone Removal |

### 🔄 Intune & MDM Management
| Script | Kategorie | Beschreibung |
|--------|-----------|-------------|
| **[PSrepairIntuneManagementextention.ps1](PSrepairIntuneManagementextention.ps1)** | Repair | Intune Management Extension Reparatur |
| **[ReinstallCompanyPortal.ps1](ReinstallCompanyPortal.ps1)** | Reinstall | Company Portal via WinGet |

### 👥 Benutzer & Gruppen
| Script | Zweck | Features |
|--------|-------|----------|
| **[ADCompareUserGroups.ps1](ADCompareUserGroups.ps1)** | AD Gruppenmitgliedschaften vergleichen | Side-by-side Vergleich |
| **[IntuneCompareUser/IntuneCompareUser.ps1](IntuneCompareUser/IntuneCompareUser.ps1)** | Entra ID Benutzervergleich | Multi-User Analyse |

### 🎯 AAD/Entra ID Device Management
| Script | Beschreibung | Use Case |
|--------|-------------|----------|
| **[Add-DevicetoAADGroup/AADChecker.ps1](Add-DevicetoAADGroup/AADChecker.ps1)** | Azure AD Verbindung prüfen | Pre-flight Checks |
| **[Add-DevicetoAADGroup/Add-DevicesToAADGroupFunction.ps1](Add-DevicetoAADGroup/Add-DevicesToAADGroupFunction.ps1)** | Bulk-Device zu Gruppe hinzufügen | Automation Function |
| **[Add-DevicetoAADGroup/AddAADDeviceToAADGroup.ps1](Add-DevicetoAADGroup/AddAADDeviceToAADGroup.ps1)** | Einzelnes Gerät zu Gruppe | Manual Assignment |
| **[Add-DevicetoAADGroup/AddDeviceCSV.ps1](Add-DevicetoAADGroup/AddDeviceCSV.ps1)** | CSV-basierte Device-Zuweisung | Bulk Operations |

### 🔄 Graph API & Remote Operations
| Script | API/Service | Funktion |
|--------|-------------|----------|
| **[GraphApiOdataNextLink.ps1](GraphApiOdataNextLink.ps1)** | Microsoft Graph | Paging für große Datensätze |
| **[ExecuteRemoteScript.ps1](ExecuteRemoteScript.ps1)** | PSRemoting | Multi-Server Script Execution |
| **[PSrepairWMI.ps1](PSrepairWMI.ps1)** | WMI | Local/Remote WMI Repository Repair |

---

## 🏥 Remediation Scripts (Intune/SCCM/GPO)

### 🛡️ Microsoft Defender
| Detection | Remediation | Zweck |
|-----------|-------------|--------|
| **[detectDefenderSignatur.txt](Remediations/detectDefenderSignatur.txt)** | - | Signature Aktualität |

### 🏢 Dell Management
| Detection | Remediation | Zweck |
|-----------|-------------|--------|
| **[detectDellCommandUpdate.ps1](Remediations/detectDellCommandUpdate.ps1)** | **[remediatDellCommandUpdate.ps1](Remediations/remediatDellCommandUpdate.ps1)** | Dell Command Update Verwaltung |

### 📋 Microsoft Office
| Detection | Remediation | Zweck |
|-----------|-------------|--------|
| **[detectOfficeUpdates.ps1](Remediations/remediatOfficeUpdates/detectOfficeUpdates.ps1)** | **[remediatOfficeUpdates.ps1](Remediations/remediatOfficeUpdates/remediatOfficeUpdates.ps1)** | Office Update Management |

### 📱 Intune Device Sync
| Detection | Remediation | Zweck |
|-----------|-------------|--------|
| **[Detection.ps1](Remediations/Intune-SyncDevice/Detection.ps1)** | **[Remediation.ps1](Remediations/Intune-SyncDevice/Remediation.ps1)** | Intune Sync erzwingen |

### 📦 Intune Win32 Apps
| Script | Zweck | Features |
|--------|--------|----------|
| **[CheckLastSync.ps1](Remediations/RepairIntuneWin32Apps/CheckLastSync.ps1)** | Sync-Trigger für alle Geräte | Bulk Operations |
| **[detectIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/detectIntuneWin32Apps.ps1)** | Win32 App Fehler-Detection | Registry-Analyse |
| **[remediateIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/remediateIntuneWin32Apps.ps1)** | Win32 App Reparatur | IME Restart, Registry Cleanup |

### 🔄 Windows Update Repair (3-Stufen-Prozess)
| Stufe | Detection | Remediation | Zweck |
|-------|-----------|-------------|--------|
| **1** | **[detectSTEP1.ps1](Remediations/RepairWinUpdate/detectSTEP1.ps1)** | **[remediationSTEP1.ps1](Remediations/RepairWinUpdate/remediationSTEP1.ps1)** | Windows Update Service Reset |
| **2** | **[detectSTEP2.ps1](Remediations/RepairWinUpdate/detectSTEP2.ps1)** | **[remediationSTEP2.ps1](Remediations/RepairWinUpdate/remediationSTEP2.ps1)** | SoftwareDistribution Reset |
| **3** | **[detectSTEP3.ps1](Remediations/RepairWinUpdate/detectSTEP3.ps1)** | **[remediationSTEP3.ps1](Remediations/RepairWinUpdate/remediationSTEP3.ps1)** | Component Store Repair |
| **All** | **[detection.ps1](Remediations/RepairWinUpdate/detection.ps1)** | - | Gesamtstatus-Check |

---

## 🔍 Troubleshooting & Diagnostics

### 🪟 Windows 11 24H2 Diagnostics
| Script | Zweck | Sammelt |
|--------|--------|---------|
| **[Collect-Win11_24H2_Diagnostics.ps1](TroubleshootingGuide/Collect-Win11_24H2_Diagnostics.ps1)** | Windows 11 24H2 Problemdiagnose | System-Logs, Configs, Hardware-Info |

### 📖 Documentation
| Datei | Inhalt |
|-------|--------|
| **[TroubleshootingGuide.md](TroubleshootingGuide/TroubleshootingGuide.md)** | Umfassende Troubleshooting-Anleitung |

---

## 🎨 HTML-Report Features (CheckMicrosoftEndpointsV2.ps1)

### 📊 Dashboard-Übersicht
- **Statistische Karten** - Getestete Endpoints, Erfolgs-/Fehlerrate, Performance-Metriken
- **Farbkodierte Indikatoren** - Sofortige visuelle Bewertung
- **Responsive Grid-Layout** - Funktioniert auf Desktop, Tablet, Mobile

### 📋 Detaillierte Service-Tabellen
- **Service-spezifische Gruppierung** - Übersichtliche Organisation nach Microsoft Services
- **Status-Badges** - OK/FAILED mit Farbkodierung
- **IP-Adressen** - Für Netzwerk-Troubleshooting
- **Performance-Metriken** - Latenz und Geschwindigkeitsdaten (optional)

### 📈 Performance-Analyse
- **Latenz-Bewertung** - Automatische Einstufung (Exzellent/Gut/Verbesserungsbedarf)
- **Geschwindigkeits-Statistiken** - Min/Max/Durchschnitt
- **Service-Impact-Analyse** - Was bedeuten Ausfälle praktisch

### 🎨 Moderne Gestaltung
- **Microsoft Design Language** - Vertraute Optik für IT-Profis
- **Gradient-Header** - Professioneller Look
- **Schatten und Animationen** - Moderne Web-Ästhetik
- **Druckfreundlich** - Optimiert für PDF-Export

---

## 💼 Praxisbeispiele

### 🔧 Tägliche IT-Administration
```powershell
# Morgendlicher Netzwerk-Check mit Report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Daily-$(Get-Date -Format 'yyyy-MM-dd').html" -OpenReport

# Intune-Probleme diagnostizieren
.\Remediations\RepairIntuneWin32Apps\detectIntuneWin32Apps.ps1
.\PSrepairIntuneManagementextention.ps1

# Windows Update Probleme beheben
.\REP_WindowsUpdate.ps1
.\Remediations\RepairWinUpdate\detection.ps1
```

### 🚀 Deployment-Vorbereitung
```powershell
# Pre-Deployment Netzwerk-Validierung
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate,Intune,AzureAD -HtmlReport "Pre-Deployment-Check.html"

# Bulk Device Management
.\Add-DevicetoAADGroup\AddDeviceCSV.ps1

# System-Vorbereitung
.\DetectRuntime6.ps1
.\DriverUpdate.ps1
```

### 📊 Monitoring & Reporting
```powershell
# Scheduled Task für regelmäßige Reports
.\CheckMicrosoftEndpointsV2.ps1 -Services All -Quiet -HtmlReport "Weekly-Report-$(Get-Date -Format 'yyyy-MM-dd').html"

# Performance-Baseline erstellen
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Baseline-Performance.html"
```

---

## 🔧 Erweiterte Konfiguration

### ⚙️ Script-Parameter Übersicht

#### CheckMicrosoftEndpointsV2.ps1
```powershell
# Alle verfügbaren Parameter
-Services        # All, WindowsUpdate, Intune, Defender, AzureAD, Microsoft365, Store, Activation, Edge, Telemetry, Interactive
-SkipPing        # Ping-Tests überspringen (schneller)
-SkipSpeed       # Geschwindigkeitstests überspringen (schneller)
-Quiet           # Stiller Modus (für Automation)
-HtmlReport      # Pfad für HTML-Report
-OpenReport      # Report automatisch im Browser öffnen
```

### 📁 Empfohlene Verzeichnisstruktur
```
C:\Scripts\PowershellScripts\
├── CheckMicrosoftEndpointsV2.ps1
├── Reports\
│   ├── Daily\
│   ├── Weekly\
│   └── Incident\
├── Logs\
└── Config\
```

---

## 📈 Version History & Changelog

### 🏆 CheckMicrosoftEndpointsV2.ps1 Evolution

#### Version 2.1 (Oktober 2025) - Current
- ✨ **HTML-Report Generation** - Responsive Design mit Microsoft Look & Feel
- 🎯 **Service-Auswahl** - Interactive Menu + Parameter-basierte Auswahl
- ⚡ **Performance-Optionen** - Konfigurierbare Test-Tiefe
- 📱 **Mobile-Optimiert** - Reports funktionieren auf allen Geräten
- 🔍 **Enhanced Analytics** - Detaillierte Performance-Statistiken

#### Version 2.0 (Oktober 2025)
- 🎮 **Interactive Menu** - Benutzerfreundliche Service-Auswahl
- 📊 **Selective Testing** - Teste nur relevante Services
- 🚀 **Speed Optimizations** - Überspringe optionale Tests
- 🔇 **Quiet Mode** - Für Automation und Scripting

#### Version 1.1 (Oktober 2025)
- 🏓 **Ping Latency Tests** - Netzwerk-Performance Messung
- 📈 **Download Speed Tests** - Bandbreiten-Analyse
- 🎨 **Enhanced Output** - Farbkodierte Ergebnisse
- 📊 **Statistics** - Performance-Metriken und Bewertungen

#### Version 1.0 (Oktober 2025)
- 🔌 **Basic Connectivity** - TCP-Verbindungstests zu Microsoft Services
- 🌐 **Service Coverage** - Alle wichtigen Microsoft Cloud Services
- 🎯 **Impact Analysis** - Auswirkungen von Verbindungsproblemen
- 📋 **Structured Output** - Organisierte Ergebnisse nach Services

---

## 🛠️ Installation & Setup

### 1️⃣ Repository Setup
```powershell
# Repository klonen
git clone https://github.com/roalhelm/PowershellScripts.git
cd PowershellScripts

# Execution Policy setzen (falls nötig)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2️⃣ Abhängigkeiten installieren
```powershell
# PowerShell Module installieren
Install-Module PSWindowsUpdate, Microsoft.Graph, ActiveDirectory -Force

# Graph API Berechtigung (für Intune/Azure Scripts)
Connect-MgGraph -Scopes "Device.Read.All", "Group.ReadWrite.All"
```

### 3️⃣ Erste Tests
```powershell
# Basis-Funktionalität testen
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate -SkipPing -SkipSpeed

# Vollständigen Test mit Report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "FirstTest.html" -OpenReport
```

---

## 🔒 Security & Permissions

### 🛡️ Erforderliche Berechtigungen
| Script-Kategorie | Berechtigungen | Begründung |
|------------------|----------------|------------|
| **Network Tests** | Standard User | Nur TCP-Verbindungen testen |
| **System Repair** | Administrator | Windows-Komponenten ändern |
| **Intune/Graph** | Graph API | Cloud-Services verwalten |
| **Registry Operations** | Administrator | System-Registry ändern |

### 🔐 Best Practices
- **Least Privilege Principle** - Nur minimale Berechtigungen verwenden
- **Test Environment First** - Neue Scripts in Testumgebung validieren
- **Audit Logs** - Wichtige Operationen protokollieren
- **Code Review** - Scripts vor Produktiv-Einsatz prüfen

---

## 📚 Dokumentation & Hilfe

### 📖 Script-spezifische Hilfe
```powershell
# Detaillierte Hilfe anzeigen
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Full
Get-Help .\PSrepairIntuneManagementextention.ps1 -Examples

# Parameter-Informationen
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Parameter Services
```

### 🔍 Troubleshooting-Ressourcen
- **[TroubleshootingGuide.md](TroubleshootingGuide/TroubleshootingGuide.md)** - Umfassende Problemlösung
- **Script-Comments** - Inline-Dokumentation in jedem Script
- **Error Handling** - Detaillierte Fehlermeldungen und Lösungsvorschläge

---

## 🤝 Contributing & Community

### 🌟 Beitragen
1. **Fork** das Repository
2. **Feature Branch** erstellen (`feature/amazing-feature`)
3. **Änderungen committen** (`git commit -m 'Add amazing feature'`)
4. **Branch pushen** (`git push origin feature/amazing-feature`)
5. **Pull Request** erstellen

### 📋 Contribution Guidelines
- **Code Style** - PowerShell Best Practices befolgen
- **Documentation** - README und Inline-Comments aktualisieren
- **Testing** - Scripts in Testumgebung validieren
- **Backwards Compatibility** - Kompatibilität mit älteren Versionen beachten

### 🐛 Bug Reports
Bitte verwenden Sie die [GitHub Issues](https://github.com/roalhelm/PowershellScripts/issues) für:
- 🐛 Bug Reports
- 💡 Feature Requests  
- 📖 Dokumentations-Verbesserungen
- ❓ Fragen und Diskussionen

---

## 📄 License & Credits

### 📜 Lizenz
Dieses Projekt steht unter der [GNU General Public License v3.0](LICENSE) - siehe LICENSE-Datei für Details.

### 👨‍💻 Author
**Ronny Alhelm**
- 🌐 GitHub: [@roalhelm](https://github.com/roalhelm)
- 📧 Contact: Über GitHub Issues

### 🙏 Acknowledgments
- Microsoft Documentation & Best Practices
- PowerShell Community
- Enterprise IT Feedback
- Open Source Contributors

---

## 📊 Repository Stats

![Repository Stats](https://img.shields.io/badge/Scripts-25%2B-blue)
![PowerShell](https://img.shields.io/badge/Language-PowerShell-blue)
![Maintained](https://img.shields.io/badge/Maintained-Yes-green)
![Last Commit](https://img.shields.io/github/last-commit/roalhelm/PowershellScripts)

---

**💼 Ready for Enterprise Use** | **🚀 Continuously Updated** | **🛡️ Security Focused** | **📱 Modern Design**