# 🛠️ PowerShell Administrative Scripts Collection

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-GPL%20v3-green.svg)](LICENSE)
[![Last Update](https://img.shields.io/badge/Last%20Update-October%202025-brightgreen)](https://github.com/roalhelm/PowershellScripts)
[![Scripts](https://img.shields.io/badge/Scripts-30%2B-orange)](https://github.com/roalhelm/PowershellScripts)

A comprehensive collection of PowerShell scripts for system administration, Microsoft Intune, Windows Updates, network diagnostics, user/group management, and remediation tasks in modern Windows enterprise environments.

## 🌟 Latest Features & Highlights

- **🔌 Microsoft Endpoint Connectivity Tester V2.1** - Advanced connectivity, latency, and performance tests with HTML reports
- **🔄 Comprehensive Intune Management** - Complete suite for Intune management and troubleshooting  
- **📊 Professional HTML Reports** - Responsive design with Microsoft Look & Feel
- **🎯 Selective Service Testing** - Choose specific services for targeted checks
- **⚡ Performance-Optimized** - Configurable tests for quick or comprehensive analyses
- **🏥 Advanced Remediation Scripts** - For Intune, Office, Windows Update, Dell Management

---

## 🚀 Quick Start

```powershell
# Clone repository
git clone https://github.com/roalhelm/PowershellScripts.git
cd PowershellScripts

# ⭐ Featured: Microsoft Endpoint Connectivity Test with HTML report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport -OpenReport

# Example: Test only critical services  
.\CheckMicrosoftEndpointsV2.ps1 -Services Intune,WindowsUpdate,AzureAD

# Repair Intune Management Extension
.\PSrepairIntuneManagementextention.ps1

# Fix Windows Update issues
.\REP_WindowsUpdate.ps1
```

## 📋 System Requirements

| Requirement | Details | Usage |
|-------------|---------|-------|
| **PowerShell** | 5.1 or higher | All scripts |
| **Permissions** | Administrator (mostly) | System/Registry operations |
| **Operating System** | Windows 10/11, Server 2016+ | Tested on modern systems |
| **Internet** | Required | Cloud service tests, downloads |

### Required PowerShell Modules:
```powershell
# Auto-install
Install-Module PSWindowsUpdate, Microsoft.Graph, ActiveDirectory -Force -AllowClobber

# For Graph API (Intune/Azure scripts)
Connect-MgGraph -Scopes "Device.Read.All", "Group.ReadWrite.All"
```

---

## 🏆 Featured Script: Microsoft Endpoint Connectivity Tester V2.1

### ✨ What's New in Version 2.1?
- **🎨 HTML Report Generation** - Professional, responsive reports with Microsoft Design
- **🎯 Service Selection** - Interactive menu + parameter-based selection (10 Microsoft services)
- **⚡ Performance Options** - Configurable test depth (Skip Ping/Speed for faster execution)
- **📱 Mobile-Optimized** - Reports work perfectly on desktop, tablet, and mobile
- **🔍 Enhanced Analytics** - Detailed performance statistics with automatic assessment

### 🎮 Easy Usage
```powershell
# Interactive mode (recommended for new users)
.\CheckMicrosoftEndpointsV2.ps1

# All services with HTML report and browser opening
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport -OpenReport

# Quick test of critical services only
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate,Intune,AzureAD -SkipSpeed -Quiet

# Automated for CI/CD
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "report-$(Get-Date -Format 'yyyy-MM-dd').html" -Quiet
```

### 🎯 Supported Microsoft Services
| Service | Description | Endpoints |
|---------|-------------|-----------|
| **WindowsUpdate** | Windows Update for Business | Update delivery, WSUS, Microsoft Update |
| **Autopatch** | Windows Autopatch Management | Automatic patch management |
| **Intune** | Microsoft Intune Device Management | Enrollment, Management, Compliance |
| **Defender** | Microsoft Defender Security | Antivirus, Threat Protection, Cloud Security |
| **AzureAD** | Azure Active Directory | Authentication, Device Registration |
| **Microsoft365** | Office 365 Suite | Office Apps, SharePoint, OneDrive |
| **Store** | Microsoft Store | App Distribution, Updates |
| **Activation** | Windows Activation | Licensing, Validation |
| **Edge** | Microsoft Edge Browser | Updates, Enterprise Features |
| **Telemetry** | Windows Diagnostics | Telemetry, Error Reporting |

---

## 📦 Complete Script Overview

### 🌐 Network & Connectivity
| Script | Version | Description | Features |
|--------|---------|-------------|----------|
| **[CheckMicrosoftEndpointsV2.ps1](CheckMicrosoftEndpointsV2.ps1)** | v2.1 ⭐ | **Advanced Microsoft Endpoint Tests** | HTML reports, service selection, performance tests |
| **[CheckMicrosoftEndpointsV1.ps1](CheckMicrosoftEndpointsV1.ps1)** | v1.1 | Basic Microsoft Endpoint Tests | Connectivity, ping, speed |

### 🔧 System & Updates
| Script | Description | Purpose | Admin Rights |
|--------|-------------|---------|--------------|
| **[DetectRuntime6.ps1](DetectRuntime6.ps1)** | .NET Desktop Runtime 6 Detection | Intune Detection Script | ❌ |
| **[DriverUpdate.ps1](DriverUpdate.ps1)** | System driver updates via Windows Update | BitLocker-aware driver updates | ✅ |
| **[REP_WindowsUpdate.ps1](REP_WindowsUpdate.ps1)** | Windows Update component reset | Repair for update issues | ✅ |
| **[UnblockFiles.ps1](UnblockFiles.ps1)** | File unblocking (security zones) | Security zone removal | ❌ |

### 🔄 Microsoft Intune & MDM
| Script | Category | Description | Use Case |
|--------|----------|-------------|----------|
| **[PSrepairIntuneManagementextention.ps1](PSrepairIntuneManagementextention.ps1)** | Repair | Intune Management Extension repair | Win32 app issues |
| **[ReinstallCompanyPortal.ps1](ReinstallCompanyPortal.ps1)** | Reinstall | Company Portal via WinGet | Portal reinstallation |

### 👥 User & Group Management  
| Script | Purpose | Features | Data Source |
|--------|---------|----------|-------------|
| **[ADCompareUserGroups.ps1](ADCompareUserGroups.ps1)** | Compare AD group memberships | Side-by-side comparison | Active Directory |
| **[IntuneCompareUser/IntuneCompareUser.ps1](IntuneCompareUser/IntuneCompareUser.ps1)** | Entra ID user comparison | Multi-user analysis | Microsoft Graph |

### 🎯 Azure AD/Entra ID Device Management
| Script | Description | Use Case | Bulk Operations |
|--------|-------------|----------|-----------------|
| **[Add-DevicetoAADGroup/AADChecker.ps1](Add-DevicetoAADGroup/AADChecker.ps1)** | Check Azure AD connection | Pre-flight checks | ❌ |
| **[Add-DevicetoAADGroup/Add-DevicesToAADGroupFunction.ps1](Add-DevicetoAADGroup/Add-DevicesToAADGroupFunction.ps1)** | PowerShell function for bulk operations | Automation function | ✅ |
| **[Add-DevicetoAADGroup/AddAADDeviceToAADGroup.ps1](Add-DevicetoAADGroup/AddAADDeviceToAADGroup.ps1)** | Add single device to group | Manual assignment | ❌ |
| **[Add-DevicetoAADGroup/AddDeviceCSV.ps1](Add-DevicetoAADGroup/AddDeviceCSV.ps1)** | CSV-based device assignment | Bulk import | ✅ |

### 🔄 Graph API & Remote Operations
| Script | API/Service | Function | Pagination |
|--------|-------------|----------|------------|
| **[GraphApiOdataNextLink.ps1](GraphApiOdataNextLink.ps1)** | Microsoft Graph | Paging for large datasets (>1000 objects) | ✅ |
| **[ExecuteRemoteScript.ps1](ExecuteRemoteScript.ps1)** | PSRemoting | Multi-server script execution | ❌ |
| **[PSrepairWMI.ps1](PSrepairWMI.ps1)** | WMI | Local/Remote WMI repository repair | ✅ |

---

## 🏥 Remediation Scripts (Intune/SCCM/GPO Ready)

### 🛡️ Microsoft Defender Management
| Detection | Remediation | Purpose | Exit Codes |
|-----------|-------------|---------|------------|
| **[detectDefenderSignatur.txt](Remediations/detectDefenderSignatur.txt)** | ❌ Manual | Check signature currency | 0/1 |

### 🏢 Dell Hardware Management
| Detection | Remediation | Purpose | Impact |
|-----------|-------------|---------|---------|
| **[detectDellCommandUpdate.ps1](Remediations/detectDellCommandUpdate.ps1)** | **[remediatDellCommandUpdate.ps1](Remediations/remediatDellCommandUpdate.ps1)** | Remove Dell Command Update | Reduces bloatware |

### 📋 Microsoft Office Management
| Detection | Remediation | Purpose | Update Method |
|-----------|-------------|---------|---------------|
| **[detectOfficeUpdates.ps1](Remediations/remediatOfficeUpdates/detectOfficeUpdates.ps1)** | **[remediatOfficeUpdates.ps1](Remediations/remediatOfficeUpdates/remediatOfficeUpdates.ps1)** | Install Office updates | Click-to-Run |

### 📱 Intune Device Synchronization
| Detection | Remediation | Purpose | Frequency |
|-----------|-------------|---------|-----------|
| **[Detection.ps1](Remediations/Intune-SyncDevice/Detection.ps1)** | **[Remediation.ps1](Remediations/Intune-SyncDevice/Remediation.ps1)** | Force Intune sync | As needed |

### 📦 Intune Win32 App Management
| Script | Purpose | Features | Registry Impact |
|--------|---------|----------|----------------|
| **[CheckLastSync.ps1](Remediations/RepairIntuneWin32Apps/CheckLastSync.ps1)** | Sync trigger for all devices | Bulk operations | ❌ |
| **[detectIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/detectIntuneWin32Apps.ps1)** | Win32 app error detection | Registry analysis | ❌ |
| **[remediateIntuneWin32Apps.ps1](Remediations/RepairIntuneWin32Apps/remediateIntuneWin32Apps.ps1)** | Win32 app repair | IME restart, registry cleanup | ✅ |

### 🔄 Windows Update Repair (Multi-Stage Process)
| Stage | Detection | Remediation | Purpose | Severity |
|-------|-----------|-------------|---------|----------|
| **1** | **[detectSTEP1.ps1](Remediations/RepairWinUpdate/detectSTEP1.ps1)** | **[remediationSTEP1.ps1](Remediations/RepairWinUpdate/remediationSTEP1.ps1)** | Windows Update service reset | 🟡 Medium |
| **2** | **[detectSTEP2.ps1](Remediations/RepairWinUpdate/detectSTEP2.ps1)** | **[remediationSTEP2.ps1](Remediations/RepairWinUpdate/remediationSTEP2.ps1)** | SoftwareDistribution reset | 🟠 High |
| **3** | **[detectSTEP3.ps1](Remediations/RepairWinUpdate/detectSTEP3.ps1)** | **[remediationSTEP3.ps1](Remediations/RepairWinUpdate/remediationSTEP3.ps1)** | Component Store repair | 🔴 Critical |
| **All** | **[detection.ps1](Remediations/RepairWinUpdate/detection.ps1)** | ❌ Manual | Overall status check | 🔍 Info |

---

## 🔍 Troubleshooting & Diagnostics

### 🪟 Windows 11 24H2 Specialized Tools
| Script | Purpose | Collects | Output Format |
|--------|---------|----------|---------------|
| **[Collect-Win11_24H2_Diagnostics.ps1](TroubleshootingGuide/Collect-Win11_24H2_Diagnostics.ps1)** | Windows 11 24H2 specific diagnostics | System logs, hardware info, configs | ZIP Archive |

### 📖 Documentation & Guides
| File | Content | Target Audience |
|------|---------|-----------------|
| **[TroubleshootingGuide.md](TroubleshootingGuide/TroubleshootingGuide.md)** | Comprehensive troubleshooting guide | IT Professionals |

---

## 🎨 HTML Report Features (CheckMicrosoftEndpointsV2.ps1)

### 📊 Professional Dashboard
- **📈 Statistical Cards** - Tested endpoints, success/failure rate, performance metrics
- **🎯 Color-Coded Indicators** - Instant visual assessment (Green/Yellow/Red)
- **📱 Responsive Grid Layout** - Perfect display on desktop, tablet, mobile
- **⏱️ Live Statistics** - Test duration, timestamp, system information

### 📋 Detailed Service Analysis
- **🏢 Service Grouping** - Clear organization by Microsoft services
- **✅ Status Badges** - OK/FAILED with meaningful color coding
- **🌐 Network Details** - IP addresses for troubleshooting and firewall configuration
- **⚡ Performance Metrics** - Latency (ms) and speed data with automatic assessment

### 🚨 Impact Analysis & Troubleshooting
- **⚠️ Service Impact Warnings** - What failures practically mean for business operations
- **🔧 Remediation Recommendations** - Concrete action items for issues
- **📊 Performance Benchmarking** - Automatic network quality assessment

---

## 💼 Practical Examples & Workflows

### 🌅 Daily IT Administration
```powershell
# Morning network health check with report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Daily-$(Get-Date -Format 'yyyy-MM-dd').html" -OpenReport

# Quickly diagnose and fix Intune issues
.\Remediations\RepairIntuneWin32Apps\detectIntuneWin32Apps.ps1
if ($LASTEXITCODE -ne 0) {
    .\Remediations\RepairIntuneWin32Apps\remediateIntuneWin32Apps.ps1
}

# Systematically fix Windows Update issues
.\REP_WindowsUpdate.ps1
.\Remediations\RepairWinUpdate\detection.ps1
```

### 🚀 Pre-Deployment Validation
```powershell
# Comprehensive network validation before rollout
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate,Intune,AzureAD -HtmlReport "Pre-Deployment-$(Get-Date -Format 'yyyy-MM-dd-HHmm').html"

# Bulk device management for new devices
.\Add-DevicetoAADGroup\AddDeviceCSV.ps1 -CsvPath ".\NewDevices.csv" -GroupName "Intune-Devices"

# System readiness check
.\DetectRuntime6.ps1
.\DriverUpdate.ps1 -WhatIf
```

### 📊 Compliance & Monitoring
```powershell
# Weekly compliance reports for management
$timestamp = Get-Date -Format "yyyy-MM-dd"
.\CheckMicrosoftEndpointsV2.ps1 -Services All -Quiet -HtmlReport "Weekly-Compliance-Report-$timestamp.html"

# Performance baseline for new locations
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Baseline-Performance-$env:COMPUTERNAME.html"

# Automated remediation chain
.\Remediations\Intune-SyncDevice\Detection.ps1
.\Remediations\remediatOfficeUpdates\detectOfficeUpdates.ps1
.\Remediations\RepairWinUpdate\detection.ps1
```

### 🔧 Troubleshooting Workflows
```powershell
# Comprehensive problem diagnosis
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Incident-$(Get-Date -Format 'yyyy-MM-dd-HHmm').html"
.\TroubleshootingGuide\Collect-Win11_24H2_Diagnostics.ps1

# Isolate specific service issues
.\CheckMicrosoftEndpointsV2.ps1 -Services Intune -SkipSpeed -HtmlReport "Intune-Specific-Analysis.html"

# Multi-stage Windows Update repair
.\Remediations\RepairWinUpdate\detectSTEP1.ps1
.\Remediations\RepairWinUpdate\remediationSTEP1.ps1
.\Remediations\RepairWinUpdate\detectSTEP2.ps1
.\Remediations\RepairWinUpdate\remediationSTEP2.ps1
```

---

## 🔧 Advanced Configuration & Best Practices

### ⚙️ CheckMicrosoftEndpointsV2.ps1 - All Parameters
```powershell
# Complete parameter overview
-Services          # All, WindowsUpdate, Autopatch, Intune, Defender, AzureAD, Microsoft365, Store, Activation, Edge, Telemetry, Interactive
-SkipPing         # Skip ping tests (faster execution)
-SkipSpeed        # Skip speed tests (even faster)
-Quiet            # Silent mode (ideal for automation/CI-CD)
-HtmlReport       # Path for HTML report (automatic timestamp if not specified)
-OpenReport       # Automatically open report in default browser
```

### 📁 Recommended Enterprise Directory Structure
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
| Script Category | Windows Permission | Azure/Intune Permission | Network Access |
|-----------------|-------------------|-------------------------|----------------|
| **Network Tests** | Standard User | ❌ Not required | ✅ HTTPS (443) |
| **System Repair** | 🔑 Administrator | ❌ Not required | ⚠️ Windows Update |
| **Intune/Graph** | Standard User | 🔑 Graph API Scopes | ✅ Graph Endpoints |
| **Registry Ops** | 🔑 Administrator | ❌ Not required | ❌ Not required |
| **WMI Repair** | 🔑 Administrator | ❌ Not required | ⚠️ Remote WMI (if remote) |

---

## 📚 Documentation & Support

### 📖 Script-Specific Help
```powershell
# Detailed help for each script
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Full
Get-Help .\PSrepairIntuneManagementextention.ps1 -Examples
Get-Help .\Remediations\RepairIntuneWin32Apps\remediateIntuneWin32Apps.ps1 -Parameter All

# Parameter-specific information
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Parameter Services
Get-Help .\CheckMicrosoftEndpointsV2.ps1 -Parameter HtmlReport
```

### 🔍 Troubleshooting Resources
- **[TroubleshootingGuide.md](TroubleshootingGuide/TroubleshootingGuide.md)** - Comprehensive problem-solving guide
- **Script Comments** - Detailed inline documentation in each script  
- **Error Handling** - Detailed error messages with concrete solution suggestions
- **Exit Codes** - Standardized return values for automation

### 🎓 Learning Resources
```powershell
# Example: Show all available scripts
Get-ChildItem -Path . -Filter "*.ps1" -Recurse | Select-Object Name, Length, LastWriteTime

# Example: Check script dependencies
$RequiredModules = @('PSWindowsUpdate', 'Microsoft.Graph', 'ActiveDirectory')
$RequiredModules | ForEach-Object { 
    if (Get-Module -ListAvailable -Name $_) { 
        "✅ $_ available" 
    } else { 
        "❌ $_ missing - Install-Module $_ -Force" 
    }
}
```

---

## 📈 Version History & Roadmap

### 🏆 CheckMicrosoftEndpointsV2.ps1 - Evolution Timeline

#### 🚀 Version 2.1 (October 2025) - **Current Release**
- ✨ **HTML Report Generation** - Responsive design with Microsoft Look & Feel
- 🎯 **Service Selection Framework** - Interactive menu + parameter-based service selection
- ⚡ **Performance Optimization Options** - Configurable test depth for different scenarios
- 📱 **Mobile-First Design** - Reports work perfectly on all devices
- 🔍 **Enhanced Analytics Engine** - Detailed performance statistics with automatic assessment

#### 📊 Version 2.0 (October 2025)
- 🎮 **Interactive Menu System** - User-friendly service selection for non-experts
- 📈 **Selective Service Testing** - Test only relevant services for specific use cases
- 🚀 **Speed & Efficiency Modes** - Skip optional tests for faster CI/CD integration
- 🔇 **Automation-Ready Quiet Mode** - Perfect for scripting and unattended operations

#### 🔧 Version 1.1 (October 2025)
- 🏓 **Network Latency Analysis** - Ping tests for performance monitoring
- 📈 **Bandwidth & Speed Testing** - Download speed analysis for capacity planning
- 🎨 **Enhanced Console Output** - Color-coded results for better readability
- 📊 **Performance Statistics** - Automatic metrics and service assessments

#### 🌱 Version 1.0 (October 2025)
- 🔌 **Core Connectivity Framework** - TCP connection tests to all Microsoft services
- 🌐 **Comprehensive Service Coverage** - Support for 10 critical Microsoft cloud services
- 🎯 **Business Impact Analysis** - Understanding the effects of connectivity issues
- 📋 **Structured Reporting** - Organized results by service categories

### 🔮 Roadmap & Planned Features
- 🤖 **AI-Powered Recommendations** - Intelligent troubleshooting suggestions
- 🔄 **Integration APIs** - REST API for SIEM/monitoring systems
- 📧 **Email Reports** - Automatic report delivery
- 🌍 **Multi-Language Support** - International localization
- 📱 **Mobile App Companion** - Native app for report viewing

---

## 🛠️ Installation & Setup Guide

### 1️⃣ Initial Repository Setup
```powershell
# Step 1: Clone repository and setup
git clone https://github.com/roalhelm/PowershellScripts.git
cd PowershellScripts

# Step 2: Adjust execution policy (if required)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Step 3: Add directory to PATH (optional)
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$scriptPath = (Get-Location).Path
if ($currentPath -notlike "*$scriptPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$scriptPath", "User")
}
```

### 2️⃣ Dependencies & Prerequisites  
```powershell
# PowerShell module installation
$RequiredModules = @('PSWindowsUpdate', 'Microsoft.Graph', 'ActiveDirectory')
$RequiredModules | ForEach-Object {
    Install-Module $_ -Force -AllowClobber -Scope CurrentUser
    Import-Module $_ -Force
}

# Graph API authentication (for Intune/Azure scripts)
Connect-MgGraph -Scopes @(
    "Device.Read.All", 
    "Group.ReadWrite.All", 
    "User.Read.All",
    "Directory.AccessAsUser.All"
)

# Connectivity pre-check
Test-NetConnection github.com -Port 443 -InformationLevel Quiet
```

### 3️⃣ First Run & Validation
```powershell
# Step 1: Test basic functionality
.\CheckMicrosoftEndpointsV2.ps1 -Services WindowsUpdate -SkipPing -SkipSpeed -Quiet

# Step 2: Try interactive mode  
.\CheckMicrosoftEndpointsV2.ps1

# Step 3: Full test with HTML report
.\CheckMicrosoftEndpointsV2.ps1 -Services All -HtmlReport "Initial-Test.html" -OpenReport

# Step 4: Test remediation scripts (with caution!)
.\DetectRuntime6.ps1
.\Remediations\Intune-SyncDevice\Detection.ps1
```

---

## 🔒 Security, Compliance & Best Practices

### 🛡️ Enterprise Security Guidelines
| Security Aspect | Recommendation | Implementation | Compliance |
|-----------------|----------------|----------------|------------|
| **Execution Policy** | RemoteSigned minimum | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` | ✅ Corporate Policy |
| **Script Signing** | Recommended for production | Use code signing certificate | ✅ Enterprise Standard |
| **Credential Management** | Secure Store/Key Vault | `$cred = Get-Credential` instead of hardcoding | 🔒 Security Baseline |
| **Audit Logging** | All critical operations | Windows Event Log + Custom Logs | 📋 Compliance Ready |
| **Network Monitoring** | Enable firewall logs | Monitor outbound connections | 🔍 Network Security |

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
# Implementation according to company policy

# 3. Monitoring & Feedback Loop
# Scheduled tasks for regular health checks
# Integration with existing monitoring (SCOM, PRTG, etc.)
```

---

## 🤝 Community & Contributing

### 🌟 How to Contribute
1. **🍴 Fork** the repository on GitHub
2. **🌿 Feature Branch** create: `git checkout -b feature/amazing-new-feature`  
3. **💾 Commit** your changes: `git commit -am 'Add amazing new feature'`
4. **📤 Push** to branch: `git push origin feature/amazing-new-feature`
5. **🔄 Pull Request** create with detailed description

### 📋 Contribution Standards
- **📝 Code Style**: PowerShell Best Practices and PSScriptAnalyzer compliance
- **📚 Documentation**: Complete comment-based help for all functions
- **🧪 Testing**: Validation in at least 2 different environments
- **🔄 Backwards Compatibility**: Compatibility with PowerShell 5.1+
- **🔒 Security**: No hardcoded credentials or unsafe practices

### 🐛 Issue Reporting & Support
Use [GitHub Issues](https://github.com/roalhelm/PowershellScripts/issues) for:

| Issue Type | Label | Template | Response Time |
|------------|-------|----------|---------------|
| 🐛 **Bug Reports** | `bug` | Bug Report Template | 24-48h |
| 💡 **Feature Requests** | `enhancement` | Feature Request Template | 1 week |
| 📖 **Documentation** | `documentation` | Documentation Template | 48h |
| ❓ **Questions** | `question` | Question Template | 24h |
| 🚨 **Security Issues** | `security` | Private Disclosure | Immediate |

---

## 📈 Repository Statistics & Metrics

![Language Distribution](https://img.shields.io/badge/PowerShell-95%25-blue)
![Documentation](https://img.shields.io/badge/Documentation-Comprehensive-green)
![Maintenance](https://img.shields.io/badge/Maintenance-Active-brightgreen)
![Enterprise Ready](https://img.shields.io/badge/Enterprise-Ready-blue)

### 📈 Script Metrics
| Category | Script Count | Lines of Code | Last Updated |
|----------|--------------|---------------|--------------|
| **Network & Connectivity** | 2 | 1,200+ | October 2025 |
| **System & Updates** | 4 | 800+ | October 2025 |
| **Intune & MDM** | 2 | 400+ | October 2025 |
| **User & Group Management** | 6 | 600+ | October 2025 |
| **Remediation Scripts** | 15+ | 1,000+ | October 2025 |
| **Troubleshooting Tools** | 2 | 300+ | October 2025 |
| **Total** | **30+** | **4,300+** | **Actively maintained** |

---

## 📄 License & Legal Information

### 📜 Open Source License
This project is licensed under the **[GNU General Public License v3.0](LICENSE)**

**Key License Points:**
- ✅ **Commercial Use** allowed
- ✅ **Modification** and **Distribution** allowed  
- ✅ **Patent Use** protected
- ⚠️ **Source Code Disclosure** required for distribution
- ⚠️ **Same License** required for derivative works

### 👨‍💻 Author & Maintainer
**Ronny Alhelm**
- 🌐 **GitHub**: [@roalhelm](https://github.com/roalhelm)
- 📧 **Contact**: Via GitHub Issues (preferred)
- 💼 **Professional**: Enterprise PowerShell Solutions

### 🙏 Acknowledgments & Credits
- **Microsoft Documentation Team** - For comprehensive API documentation
- **PowerShell Community** - For best practices and code reviews
- **Enterprise IT Feedback** - For real-world requirements and use cases
- **Open Source Contributors** - For testing, bug reports, and feature suggestions

---

<div align="center">

## 🎯 Ready for Enterprise Deployment

[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-Compatible-blue)](https://www.powershellgallery.com/)
[![Enterprise Ready](https://img.shields.io/badge/Enterprise-Ready-success)](https://github.com/roalhelm/PowershellScripts)
[![Security Tested](https://img.shields.io/badge/Security-Tested-green)](https://github.com/roalhelm/PowershellScripts)
[![Documentation](https://img.shields.io/badge/Documentation-Complete-brightgreen)](https://github.com/roalhelm/PowershellScripts)

### 💼 **Professional** | 🚀 **Continuously Updated** | 🛡️ **Security Focused** | 📱 **Modern Design** | 🏢 **Enterprise Grade**

---

*This script collection is actively used in enterprise environments and continuously developed.*

</div>