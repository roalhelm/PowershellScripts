
# 🛠️ PowerShell Administrative Scripts Collection

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-GPL%20v3-green.svg)](LICENSE)
[![Last Update](https://img.shields.io/badge/Last%20Update-October%202025-brightgreen)](https://github.com/roalhelm/PowershellScripts)
[![Scripts](https://img.shields.io/badge/Scripts-30%2B-orange)](https://github.com/roalhelm/PowershellScripts)

Eine umfassende Sammlung von PowerShell-Skripten für Systemadministration, Microsoft Intune, Windows Updates, Netzwerk-Diagnostik, Benutzer-/Gruppenverwaltung und Remediation-Aufgaben in modernen Windows-Unternehmensumgebungen.

## 🌟 Neueste Features & Highlights

- **🔌 Microsoft Endpoint Connectivity Tester V2.1** - Erweiterte Konnektivitäts-, Latenz- und Performance-Tests mit HTML-Reports
- **🔄 Comprehensive Intune Management** - Vollständige Suite für Intune-Verwaltung und Problembehandlung  
- **📊 Professional HTML Reports** - Responsive Design mit Microsoft Look & Feel
- **🎯 Selective Service Testing** - Wählen Sie spezifische Services für gezielte Überprüfungen
- **⚡ Performance-Optimized** - Konfigurierbare Tests für schnelle oder umfassende Analysen
- **🏥 Advanced Remediation Scripts** - Für Intune, Office, Windows Update, Dell Management

---

## 🚀 Quick Start

```powershell
# Repository klonen
git clone https://github.com/roalhelm/PowershellScripts.git
cd PowershellScripts

# ⭐ Featured: Microsoft Endpoint Connectivity Test mit HTML-Report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport -OpenReport

# Beispiel: Nur kritische Services testen  
.\CheckMicrosoftEndpointsV2.ps1 -Services Intune,WindowsUpdate,AzureAD

# Intune Management Extension reparieren
.\PSrepairIntuneManagementextention.ps1

# Windows Update Probleme beheben
.\REP_WindowsUpdate.ps1
```

## 📋 Systemanforderungen

| Anforderung | Details | Verwendung |
|-------------|---------|------------|
| **PowerShell** | 5.1 oder höher | Alle Scripts |
| **Berechtigung** | Administrator (meist) | System-/Registry-Operationen |
| **Betriebssystem** | Windows 10/11, Server 2016+ | Getestet auf modernen Systemen |
| **Internet** | Erforderlich | Cloud-Service Tests, Downloads |

### Erforderliche PowerShell-Module:
```powershell
# Automatisch installieren
Install-Module PSWindowsUpdate, Microsoft.Graph, ActiveDirectory -Force -AllowClobber

# Für Graph API (Intune/Azure Scripts)
Connect-MgGraph -Scopes "Device.Read.All", "Group.ReadWrite.All"
```


---

## 🏆 Featured Script: Microsoft Endpoint Connectivity Tester V2.1

### ✨ Was ist neu in Version 2.1?
- **🎨 HTML-Report Generation** - Professionelle, responsive Berichte mit Microsoft Design
- **🎯 Service-Auswahl** - Interactive Menu + Parameter-basierte Auswahl (10 Microsoft Services)
- **⚡ Performance-Optionen** - Konfigurierbare Test-Tiefe (Skip Ping/Speed für schnellere Ausführung)
- **📱 Mobile-Optimiert** - Reports funktionieren perfekt auf Desktop, Tablet und Mobile
- **🔍 Enhanced Analytics** - Detaillierte Performance-Statistiken mit automatischer Bewertung

### 🎮 Einfache Verwendung
```powershell
# Interaktiver Modus (empfohlen für neue Benutzer)
.\CheckMicrosoftEndpointsV2.ps1

# Alle Services mit HTML-Report und Browser-Öffnung
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport -OpenReport

# Schneller Test nur kritische Services
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate,Intune,AzureAD -SkipSpeed -Quiet

# Automatisiert für CI/CD
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "report-$(Get-Date -Format 'yyyy-MM-dd').html" -Quiet
```

### 🎯 Unterstützte Microsoft Services
| Service | Beschreibung | Endpunkte |
|---------|-------------|-----------|
| **WindowsUpdate** | Windows Update for Business | Update-Delivery, WSUS, Microsoft Update |
| **Autopatch** | Windows Autopatch Management | Automatisches Patch-Management |
| **Intune** | Microsoft Intune Device Management | Enrollment, Management, Compliance |
| **Defender** | Microsoft Defender Security | Antivirus, Threat Protection, Cloud Security |
| **AzureAD** | Azure Active Directory | Authentication, Device Registration |
| **Microsoft365** | Office 365 Suite | Office Apps, SharePoint, OneDrive |
| **Store** | Microsoft Store | App Distribution, Updates |
| **Activation** | Windows Activation | Licensing, Validation |
| **Edge** | Microsoft Edge Browser | Updates, Enterprise Features |
| **Telemetry** | Windows Diagnostics | Telemetry, Error Reporting |

---

## 📦 Vollständige Script-Übersicht

### 🌐 Netzwerk & Konnektivität
| Script | Version | Beschreibung | Features |
|--------|---------|-------------|----------|
| **[CheckMicrosoftEndpointsV2.ps1](CheckMicrosoftEndpointsV2.ps1)** | v2.1 ⭐ | **Erweiterte Microsoft Endpoint Tests** | HTML-Reports, Service-Auswahl, Performance-Tests |
| **[CheckMicrosoftEndpointsV1.ps1](CheckMicrosoftEndpointsV1.ps1)** | v1.1 | Basis Microsoft Endpoint Tests | Konnektivität, Ping, Geschwindigkeit |

### 🔧 System & Updates
| Script | Beschreibung | Zweck | Admin-Rechte |
|--------|-------------|-------|--------------|
| **[DetectRuntime6.ps1](DetectRuntime6.ps1)** | .NET Desktop Runtime 6 Detection | Intune Detection Script | ❌ |
| **[DriverUpdate.ps1](DriverUpdate.ps1)** | System-Treiber Updates via Windows Update | BitLocker-aware Driver Updates | ✅ |
| **[REP_WindowsUpdate.ps1](REP_WindowsUpdate.ps1)** | Windows Update Component Reset | Reparatur bei Update-Problemen | ✅ |
| **[UnblockFiles.ps1](UnblockFiles.ps1)** | Datei-Entsperrung (Security Zones) | Security Zone Removal | ❌ |

### 🔄 Microsoft Intune & MDM
| Script | Kategorie | Beschreibung | Use Case |
|--------|-----------|-------------|----------|
| **[PSrepairIntuneManagementextention.ps1](PSrepairIntuneManagementextention.ps1)** | Repair | Intune Management Extension Reparatur | Win32 App Probleme |
| **[ReinstallCompanyPortal.ps1](ReinstallCompanyPortal.ps1)** | Reinstall | Company Portal via WinGet | Portal-Neuinstallation |

### 👥 Benutzer & Gruppen Management  
| Script | Zweck | Features | Datenquelle |
|--------|-------|----------|-------------|
| **[ADCompareUserGroups.ps1](ADCompareUserGroups.ps1)** | AD Gruppenmitgliedschaften vergleichen | Side-by-side Vergleich | Active Directory |
| **[IntuneCompareUser/IntuneCompareUser.ps1](IntuneCompareUser/IntuneCompareUser.ps1)** | Entra ID Benutzervergleich | Multi-User Analyse | Microsoft Graph |

### 🎯 Azure AD/Entra ID Device Management
| Script | Beschreibung | Use Case | Bulk Operations |
|--------|-------------|----------|-----------------|
| **[Add-DevicetoAADGroup/AADChecker.ps1](Add-DevicetoAADGroup/AADChecker.ps1)** | Azure AD Verbindung prüfen | Pre-flight Checks | ❌ |
| **[Add-DevicetoAADGroup/Add-DevicesToAADGroupFunction.ps1](Add-DevicetoAADGroup/Add-DevicesToAADGroupFunction.ps1)** | PowerShell Function für Bulk-Operations | Automation Function | ✅ |
| **[Add-DevicetoAADGroup/AddAADDeviceToAADGroup.ps1](Add-DevicetoAADGroup/AddAADDeviceToAADGroup.ps1)** | Einzelnes Gerät zu Gruppe hinzufügen | Manual Assignment | ❌ |
| **[Add-DevicetoAADGroup/AddDeviceCSV.ps1](Add-DevicetoAADGroup/AddDeviceCSV.ps1)** | CSV-basierte Device-Zuweisung | Bulk Import | ✅ |

### 🔄 Graph API & Remote Operations
| Script | API/Service | Funktion | Pagination |
|--------|-------------|----------|------------|
| **[GraphApiOdataNextLink.ps1](GraphApiOdataNextLink.ps1)** | Microsoft Graph | Paging für große Datensätze (>1000 Objekte) | ✅ |
| **[ExecuteRemoteScript.ps1](ExecuteRemoteScript.ps1)** | PSRemoting | Multi-Server Script Execution | ❌ |
| **[PSrepairWMI.ps1](PSrepairWMI.ps1)** | WMI | Local/Remote WMI Repository Repair | ✅ |

---

## 🏥 Remediation Scripts (Intune/SCCM/GPO Ready)

### 🛡️ Microsoft Defender Management
| Detection | Remediation | Zweck | Exit Codes |
|-----------|-------------|-------|------------|
| **[detectDefenderSignatur.txt](Remediations/detectDefenderSignatur.txt)** | ❌ Manual | Signature Aktualität prüfen | 0/1 |

### 🏢 Dell Hardware Management
| Detection | Remediation | Zweck | Impact |
|-----------|-------------|-------|---------|
| **[detectDellCommandUpdate.ps1](Remediations/detectDellCommandUpdate.ps1)** | **[remediatDellCommandUpdate.ps1](Remediations/remediatDellCommandUpdate.ps1)** | Dell Command Update entfernen | Reduziert Bloatware |

### 📋 Microsoft Office Management
| Detection | Remediation | Zweck | Update Method |
|-----------|-------------|-------|---------------|
| **[detectOfficeUpdates.ps1](Remediations/remediatOfficeUpdates/detectOfficeUpdates.ps1)** | **[remediatOfficeUpdates.ps1](Remediations/remediatOfficeUpdates/remediatOfficeUpdates.ps1)** | Office Updates installieren | Click-to-Run |

### 📱 Intune Device Synchronization
| Detection | Remediation | Zweck | Frequency |
|-----------|-------------|-------|-----------|
| **[Detection.ps1](Remediations/Intune-SyncDevice/Detection.ps1)** | **[Remediation.ps1](Remediations/Intune-SyncDevice/Remediation.ps1)** | Intune Sync erzwingen | Bei Bedarf |

### 📦 Intune Win32 App Management
| Script | Zweck | Features | Registry Impact |
|--------|-------|----------|----------------|
| **[CheckLastSync.ps1](Remediations/RepairIntuneWin32Apps/CheckLastSync.ps1)** | Sync-Trigger für alle Geräte | Bulk Operations | ❌ |
| **[detectIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/detectIntuneWin32Apps.ps1)** | Win32 App Fehler-Detection | Registry-Analyse | ❌ |
| **[remediateIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/remediateIntuneWin32Apps.ps1)** | Win32 App Reparatur | IME Restart, Registry Cleanup | ✅ |

### 🔄 Windows Update Repair (Mehrstufiger Prozess)
| Stufe | Detection | Remediation | Zweck | Severity |
|-------|-----------|-------------|-------|----------|
| **1** | **[detectSTEP1.ps1](Remediations/RepairWinUpdate/detectSTEP1.ps1)** | **[remediationSTEP1.ps1](Remediations/RepairWinUpdate/remediationSTEP1.ps1)** | Windows Update Service Reset | 🟡 Medium |
| **2** | **[detectSTEP2.ps1](Remediations/RepairWinUpdate/detectSTEP2.ps1)** | **[remediationSTEP2.ps1](Remediations/RepairWinUpdate/remediationSTEP2.ps1)** | SoftwareDistribution Reset | 🟠 High |
| **3** | **[detectSTEP3.ps1](Remediations/RepairWinUpdate/detectSTEP3.ps1)** | **[remediationSTEP3.ps1](Remediations/RepairWinUpdate/remediationSTEP3.ps1)** | Component Store Repair | 🔴 Critical |
| **All** | **[detection.ps1](Remediations/RepairWinUpdate/detection.ps1)** | ❌ Manual | Gesamtstatus-Check | 🔍 Info |

---

## 🔍 Troubleshooting & Diagnostics

### 🪟 Windows 11 24H2 Specialized Tools
| Script | Zweck | Sammelt | Output Format |
|--------|-------|---------|---------------|
| **[Collect-Win11_24H2_Diagnostics.ps1](TroubleshootingGuide/Collect-Win11_24H2_Diagnostics.ps1)** | Windows 11 24H2 spezifische Diagnose | System-Logs, Hardware-Info, Configs | ZIP Archive |

### 📖 Documentation & Guides
| Datei | Inhalt | Zielgruppe |
|-------|--------|------------|
| **[TroubleshootingGuide.md](TroubleshootingGuide/TroubleshootingGuide.md)** | Comprehensive Troubleshooting Guide | IT Professionals |

---

## 🎨 HTML-Report Features (CheckMicrosoftEndpointsV2.ps1)

### � Professional Dashboard
- **📈 Statistische Karten** - Getestete Endpoints, Erfolgs-/Fehlerrate, Performance-Metriken
- **🎯 Farbkodierte Indikatoren** - Sofortige visuelle Bewertung (Grün/Gelb/Rot)
- **📱 Responsive Grid-Layout** - Perfekte Darstellung auf Desktop, Tablet, Mobile
- **⏱️ Live-Statistiken** - Testdauer, Timestamp, System-Informationen

### 📋 Detaillierte Service-Analysen
- **🏢 Service-Gruppierung** - Übersichtliche Organisation nach Microsoft Services
- **✅ Status-Badges** - OK/FAILED mit aussagekräftiger Farbkodierung
- **🌐 Netzwerk-Details** - IP-Adressen für Troubleshooting und Firewall-Konfiguration
- **⚡ Performance-Metriken** - Latenz (ms) und Geschwindigkeitsdaten mit automatischer Bewertung

### 🚨 Impact-Analyse & Troubleshooting
- **⚠️ Service-Impact-Warnings** - Was bedeuten Ausfälle praktisch für den Geschäftsbetrieb
- **🔧 Remediation-Empfehlungen** - Konkrete Handlungsanweisungen bei Problemen
- **📊 Performance-Benchmarking** - Automatische Bewertung der Netzwerk-Qualität

---

## 💼 Praxisbeispiele & Workflows

### 🌅 Tägliche IT-Administration
```powershell
# Morgendlicher Netzwerk-Gesundheitscheck mit Report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Daily-$(Get-Date -Format 'yyyy-MM-dd').html" -OpenReport

# Intune-Probleme schnell diagnostizieren und beheben
.\Remediations\RepairIntuneWin32Apps\detectIntuneWin32Apps.ps1
if ($LASTEXITCODE -ne 0) {
    .\Remediations\RepairIntuneWin32Apps\remediateIntuneWin32Apps.ps1
}

# Windows Update Probleme systematisch beheben
.\REP_WindowsUpdate.ps1
.\Remediations\RepairWinUpdate\detection.ps1
```

### 🚀 Pre-Deployment Validation
```powershell
# Umfassende Netzwerk-Validierung vor Rollout
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate,Intune,AzureAD -HtmlReport "Pre-Deployment-$(Get-Date -Format 'yyyy-MM-dd-HHmm').html"

# Bulk Device Management für neue Geräte
.\Add-DevicetoAADGroup\AddDeviceCSV.ps1 -CsvPath ".\NewDevices.csv" -GroupName "Intune-Devices"

# System-Readiness Check
.\DetectRuntime6.ps1
.\DriverUpdate.ps1 -WhatIf
```

### 📊 Compliance & Monitoring
```powershell
# Wöchentliche Compliance-Reports für Management
$timestamp = Get-Date -Format "yyyy-MM-dd"
.\CheckMicrosoftEndpointsV2.ps1 -Services All -Quiet -HtmlReport "Weekly-Compliance-Report-$timestamp.html"

# Performance-Baseline für neue Standorte
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Baseline-Performance-$env:COMPUTERNAME.html"

# Automatisierte Remediation Chain
.\Remediations\Intune-SyncDevice\Detection.ps1
.\Remediations\remediatOfficeUpdates\detectOfficeUpdates.ps1
.\Remediations\RepairWinUpdate\detection.ps1
```

### 🔧 Troubleshooting-Workflows
```powershell
# Umfassende Problemdiagnose
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Incident-$(Get-Date -Format 'yyyy-MM-dd-HHmm').html"
.\TroubleshootingGuide\Collect-Win11_24H2_Diagnostics.ps1

# Spezifische Service-Probleme isolieren
.\CheckMicrosoftEndpointsV2.ps1 -Services Intune -SkipSpeed -HtmlReport "Intune-Specific-Analysis.html"

# Mehrstufige Windows Update Reparatur
.\Remediations\RepairWinUpdate\detectSTEP1.ps1
.\Remediations\RepairWinUpdate\remediationSTEP1.ps1
.\Remediations\RepairWinUpdate\detectSTEP2.ps1
.\Remediations\RepairWinUpdate\remediationSTEP2.ps1
```

---

## � Erweiterte Konfiguration & Best Practices

### ⚙️ CheckMicrosoftEndpointsV2.ps1 - Alle Parameter
```powershell
# Vollständige Parameter-Übersicht
-Services          # All, WindowsUpdate, Autopatch, Intune, Defender, AzureAD, Microsoft365, Store, Activation, Edge, Telemetry, Interactive
-SkipPing         # Ping-Tests überspringen (schnellere Ausführung)
-SkipSpeed        # Geschwindigkeitstests überspringen (noch schneller)
-Quiet            # Stiller Modus (ideal für Automation/CI-CD)
-HtmlReport       # Pfad für HTML-Report (automatischer Timestamp falls nicht angegeben)
-OpenReport       # Report automatisch im Standard-Browser öffnen
```

### 📁 Empfohlene Enterprise-Verzeichnisstruktur
```
C:\Scripts\PowershellScripts\
├── Core\
│   ├── CheckMicrosoftEndpointsV2.ps1
│   ├── PSrepairIntuneManagementextention.ps1
│   └── REP_WindowsUpdate.ps1
├── Reports\
│   ├── Daily\
│   ├── Weekly\
│   ├── Incident\
│   └── Baseline\
├── Logs\
│   ├── Remediation\
│   └── Diagnostics\
├── Config\
│   ├── DeviceGroups.csv
│   └── ServiceProfiles.json
└── Automation\
    ├── ScheduledTasks\
    └── CI-CD-Integration\
```

### 🔒 Security & Permissions Matrix
| Script-Kategorie | Windows-Berechtigung | Azure/Intune-Berechtigung | Netzwerk-Zugriff |
|------------------|----------------------|----------------------------|-------------------|
| **Network Tests** | Standard User | ❌ Nicht erforderlich | ✅ HTTPS (443) |
| **System Repair** | 🔑 Administrator | ❌ Nicht erforderlich | ⚠️ Windows Update |
| **Intune/Graph** | Standard User | 🔑 Graph API Scopes | ✅ Graph Endpoints |
| **Registry Ops** | 🔑 Administrator | ❌ Nicht erforderlich | ❌ Nicht erforderlich |
| **WMI Repair** | 🔑 Administrator | ❌ Nicht erforderlich | ⚠️ Remote WMI (falls remote) |

---

## 📚 Dokumentation & Support

### 📖 Script-spezifische Hilfe
```powershell
# Detaillierte Hilfe für jedes Script
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Full
Get-Help .\PSrepairIntuneManagementextention.ps1 -Examples
Get-Help .\Remediations\RepairIntuneWin32Apps\remediateIntuneWin32Apps.ps1 -Parameter All

# Parameter-spezifische Informationen
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Parameter Services
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Parameter HtmlReport
```

### 🔍 Troubleshooting-Ressourcen
- **[TroubleshootingGuide.md](TroubleshootingGuide/TroubleshootingGuide.md)** - Comprehensive Problem-Solving Guide
- **Script-Kommentare** - Ausführliche Inline-Dokumentation in jedem Script  
- **Error Handling** - Detaillierte Fehlermeldungen mit konkreten Lösungsvorschlägen
- **Exit Codes** - Standardisierte Return-Values für Automation

### 🎓 Learning Resources
```powershell
# Beispiel: Alle verfügbaren Scripts anzeigen
Get-ChildItem -Path . -Filter "*.ps1" -Recurse | Select-Object Name, Length, LastWriteTime

# Beispiel: Script-Abhängigkeiten prüfen
$RequiredModules = @('PSWindowsUpdate', 'Microsoft.Graph', 'ActiveDirectory')
$RequiredModules | ForEach-Object { 
    if (Get-Module -ListAvailable -Name $_) { 
        "✅ $_ verfügbar" 
    } else { 
        "❌ $_ fehlt - Install-Module $_ -Force" 
    }
}
```

---

## � Version History & Roadmap

### 🏆 CheckMicrosoftEndpointsV2.ps1 - Evolution Timeline

#### 🚀 Version 2.1 (Oktober 2025) - **Current Release**
- ✨ **HTML-Report Generation** - Responsive Design mit Microsoft Look & Feel
- 🎯 **Service Selection Framework** - Interactive Menu + Parameter-basierte Service-Auswahl
- ⚡ **Performance Optimization Options** - Konfigurierbare Test-Tiefe für verschiedene Szenarien
- 📱 **Mobile-First Design** - Reports funktionieren perfekt auf allen Geräten
- 🔍 **Enhanced Analytics Engine** - Detaillierte Performance-Statistiken mit automatischer Bewertung

#### 📊 Version 2.0 (Oktober 2025)
- 🎮 **Interactive Menu System** - Benutzerfreundliche Service-Auswahl für Non-Experts
- 📈 **Selective Service Testing** - Teste nur relevante Services für spezifische Use Cases
- 🚀 **Speed & Efficiency Modes** - Überspringe optionale Tests für schnellere CI/CD-Integration
- 🔇 **Automation-Ready Quiet Mode** - Perfekt für Scripting und unattended Operations

#### 🔧 Version 1.1 (Oktober 2025)
- 🏓 **Network Latency Analysis** - Ping-Tests für Performance-Monitoring
- 📈 **Bandwidth & Speed Testing** - Download-Speed-Analysen für Kapazitätsplanung
- 🎨 **Enhanced Console Output** - Farbkodierte Ergebnisse für bessere Readability
- 📊 **Performance Statistics** - Automatische Metriken und Service-Bewertungen

#### 🌱 Version 1.0 (Oktober 2025)
- 🔌 **Core Connectivity Framework** - TCP-Verbindungstests zu allen Microsoft Services
- 🌐 **Comprehensive Service Coverage** - Support für 10 kritische Microsoft Cloud Services
- 🎯 **Business Impact Analysis** - Verständnis der Auswirkungen von Verbindungsproblemen
- 📋 **Structured Reporting** - Organisierte Ergebnisse nach Service-Kategorien

### 🔮 Roadmap & Geplante Features
- 🤖 **AI-Powered Recommendations** - Intelligente Troubleshooting-Vorschläge
- 🔄 **Integration APIs** - REST API für SIEM/Monitoring-Systeme
- 📧 **Email Reports** - Automatischer Versand von Reports
- 🌍 **Multi-Language Support** - Internationale Lokalisierung
- 📱 **Mobile App Companion** - Native App für Report-Viewing

---

## 🛠️ Installation & Setup Guide

### 1️⃣ Initial Repository Setup
```powershell
# Schritt 1: Repository klonen und Setup
git clone https://github.com/roalhelm/PowershellScripts.git
cd PowershellScripts

# Schritt 2: Execution Policy anpassen (falls erforderlich)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Schritt 3: Verzeichnis zu PATH hinzufügen (optional)
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$scriptPath = (Get-Location).Path
if ($currentPath -notlike "*$scriptPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$scriptPath", "User")
}
```

### 2️⃣ Dependencies & Prerequisites  
```powershell
# PowerShell Module Installation
$RequiredModules = @('PSWindowsUpdate', 'Microsoft.Graph', 'ActiveDirectory')
$RequiredModules | ForEach-Object {
    Install-Module $_ -Force -AllowClobber -Scope CurrentUser
    Import-Module $_ -Force
}

# Graph API Authentication (für Intune/Azure Scripts)
Connect-MgGraph -Scopes @(
    "Device.Read.All", 
    "Group.ReadWrite.All", 
    "User.Read.All",
    "Directory.AccessAsUser.All"
)

# Connectivity Pre-Check
Test-NetConnection github.com -Port 443 -InformationLevel Quiet
```

### 3️⃣ First Run & Validation
```powershell
# Schritt 1: Basis-Funktionalität testen
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate -SkipPing -SkipSpeed -Quiet

# Schritt 2: Interaktiven Modus ausprobieren  
.\CheckMicrosoftEndpointsV2.ps1

# Schritt 3: Vollständigen Test mit HTML-Report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Initial-Test.html" -OpenReport

# Schritt 4: Remediation-Scripts testen (mit Vorsicht!)
.\DetectRuntime6.ps1
.\Remediations\Intune-SyncDevice\Detection.ps1
```

---

## 🔒 Security, Compliance & Best Practices

### 🛡️ Enterprise Security Guidelines
| Sicherheitsaspekt | Empfehlung | Implementierung | Compliance |
|-------------------|------------|-----------------|------------|
| **Execution Policy** | RemoteSigned minimum | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` | ✅ Corporate Policy |
| **Script Signing** | Empfohlen für Produktion | Code Signing Certificate verwenden | ✅ Enterprise Standard |
| **Credential Management** | Secure Store/Key Vault | `$cred = Get-Credential` statt Hardcoding | 🔒 Security Baseline |
| **Audit Logging** | Alle kritischen Operationen | Windows Event Log + Custom Logs | 📋 Compliance Ready |
| **Network Monitoring** | Firewall-Logs aktivieren | Überwachung ausgehender Verbindungen | 🔍 Network Security |

### 🔐 Recommended Deployment Strategy
```powershell
# 1. Test Environment Validation
$TestEnvironments = @("DEV", "TEST", "UAT")
$TestEnvironments | ForEach-Object {
    Write-Host "Testing in $_ environment..." -ForegroundColor Cyan
    .\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Test-$_-$(Get-Date -Format 'yyyy-MM-dd').html"
}

# 2. Staged Rollout
$ProductionGroups = @("Pilot-Users", "IT-Department", "All-Users")
# Implementierung je nach Unternehmens-Policy

# 3. Monitoring & Feedback Loop
# Scheduled Tasks für regelmäßige Health Checks
# Integration in bestehendes Monitoring (SCOM, PRTG, etc.)
```

---

## 🤝 Community & Contributing

### 🌟 How to Contribute
1. **🍴 Fork** das Repository auf GitHub
2. **🌿 Feature Branch** erstellen: `git checkout -b feature/amazing-new-feature`  
3. **💾 Commit** your changes: `git commit -am 'Add amazing new feature'`
4. **📤 Push** to branch: `git push origin feature/amazing-new-feature`
5. **🔄 Pull Request** erstellen mit detaillierter Beschreibung

### 📋 Contribution Standards
- **📝 Code Style**: PowerShell Best Practices und PSScriptAnalyzer Compliance
- **📚 Documentation**: Vollständige Comment-Based Help für alle Functions
- **🧪 Testing**: Validation in mindestens 2 verschiedenen Umgebungen
- **🔄 Backwards Compatibility**: Kompatibilität mit PowerShell 5.1+
- **🔒 Security**: Keine Hardcoded Credentials oder unsichere Praktiken

### 🐛 Issue Reporting & Support
Verwenden Sie [GitHub Issues](https://github.com/roalhelm/PowershellScripts/issues) für:

| Issue Type | Label | Template | Response Time |
|------------|-------|----------|---------------|
| 🐛 **Bug Reports** | `bug` | Bug Report Template | 24-48h |
| 💡 **Feature Requests** | `enhancement` | Feature Request Template | 1 Woche |
| 📖 **Documentation** | `documentation` | Documentation Template | 48h |
| ❓ **Questions** | `question` | Question Template | 24h |
| 🚨 **Security Issues** | `security` | Private Disclosure | Sofort |

---

## � Repository Statistics & Metrics

![Language Distribution](https://img.shields.io/badge/PowerShell-95%25-blue)
![Documentation](https://img.shields.io/badge/Documentation-Comprehensive-green)
![Maintenance](https://img.shields.io/badge/Maintenance-Active-brightgreen)
![Enterprise Ready](https://img.shields.io/badge/Enterprise-Ready-blue)

### 📈 Script Metrics
| Kategorie | Anzahl Scripts | Zeilen Code | Letzte Aktualisierung |
|-----------|----------------|-------------|----------------------|
| **Network & Connectivity** | 2 | 1,200+ | Oktober 2025 |
| **System & Updates** | 4 | 800+ | Oktober 2025 |
| **Intune & MDM** | 2 | 400+ | Oktober 2025 |
| **User & Group Management** | 6 | 600+ | Oktober 2025 |
| **Remediation Scripts** | 15+ | 1,000+ | Oktober 2025 |
| **Troubleshooting Tools** | 2 | 300+ | Oktober 2025 |
| **Total** | **30+** | **4,300+** | **Aktiv gepflegt** |

---

## 📄 License & Legal Information

### 📜 Open Source License
Dieses Projekt steht unter der **[GNU General Public License v3.0](LICENSE)**

**Kernpunkte der Lizenz:**
- ✅ **Kommerzielle Nutzung** erlaubt
- ✅ **Modification** und **Distribution** erlaubt  
- ✅ **Patent Use** geschützt
- ⚠️ **Source Code Disclosure** bei Distribution erforderlich
- ⚠️ **Same License** für derivative Werke erforderlich

### 👨‍💻 Author & Maintainer
**Ronny Alhelm**
- 🌐 **GitHub**: [@roalhelm](https://github.com/roalhelm)
- 📧 **Contact**: Via GitHub Issues (bevorzugt)
- 💼 **Professional**: Enterprise PowerShell Solutions

### 🙏 Acknowledgments & Credits
- **Microsoft Documentation Team** - Für umfassende API-Dokumentation
- **PowerShell Community** - Für Best Practices und Code-Reviews
- **Enterprise IT Feedback** - Für reale Anforderungen und Use Cases
- **Open Source Contributors** - Für Tests, Bug Reports und Feature-Vorschläge

---

<div align="center">

## 🎯 Ready for Enterprise Deployment

[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-Compatible-blue)](https://www.powershellgallery.com/)
[![Enterprise Ready](https://img.shields.io/badge/Enterprise-Ready-success)](https://github.com/roalhelm/PowershellScripts)
[![Security Tested](https://img.shields.io/badge/Security-Tested-green)](https://github.com/roalhelm/PowershellScripts)
[![Documentation](https://img.shields.io/badge/Documentation-Complete-brightgreen)](https://github.com/roalhelm/PowershellScripts)

### 💼 **Professional** | 🚀 **Continuously Updated** | 🛡️ **Security Focused** | 📱 **Modern Design** | 🏢 **Enterprise Grade**

---

*Diese Script-Sammlung wird aktiv in Unternehmensumgebungen eingesetzt und kontinuierlich weiterentwickelt.*

</div>