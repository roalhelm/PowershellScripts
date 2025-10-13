
<#
.SYNOPSIS
    Comprehensive connectivity test for all critical Microsoft cloud service endpoints including Autopatch, Intune, Defender, and Microsoft 365.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This extensive connectivity testing script validates network access to critical Microsoft service endpoints
    required for modern Windows environments and Microsoft cloud services. It covers all major services including
    Windows Update for Business, Windows Autopatch, Microsoft Intune, Microsoft Defender, Azure AD, Microsoft 365,
    Microsoft Store, Windows Activation, Microsoft Edge, and Windows Telemetry services.
    
    The script performs the following operations:
    1. Tests TCP connectivity to essential Microsoft service URLs on port 443 (HTTPS)
    2. Groups results by service backend for organized reporting
    3. Provides color-coded output for easy identification of connectivity issues
    4. Reports IP addresses of reachable endpoints for network troubleshooting
    5. Returns appropriate exit codes for automation and monitoring scenarios
    
    Tested Service Categories:
    - Windows Update for Business (WUfB)
    - Windows Autopatch (automated patch management)
    - Microsoft Intune (device management)
    - Microsoft Defender (security services)
    - Azure Active Directory (identity services)
    - Microsoft 365 (productivity suite)
    - Microsoft Store (app distribution)
    - Windows Activation (licensing services)
    - Microsoft Edge (browser services)
    - Windows Telemetry (diagnostic data)
    
    This tool is particularly useful for:
    - Network administrators validating comprehensive firewall configurations
    - Enterprise deployment teams ensuring all Microsoft services are accessible
    - Troubleshooting connectivity issues across multiple Microsoft platforms
    - Compliance verification for complete Microsoft cloud service access
    - Pre-deployment network validation in complex enterprise environments

.NOTES
    File Name     : CheckMicrosoftEndpointsV1.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025
    Requirements  : PowerShell 5.1 or higher
    Network       : Internet connectivity required
    Ports         : HTTPS (443) access to Microsoft endpoints
    Permissions   : No elevated privileges required

.CHANGES
    Version 1.0 (2025-10-13):
    - Initial release with comprehensive endpoint testing
    - Added support for Windows Update for Business endpoints
    - Included Microsoft Intune service endpoints
    - Added Microsoft Defender endpoint validation
    - Implemented color-coded output for better readability
    - Added grouped results display by service backend
    - Implemented proper exit codes for automation
    - Added IP address resolution for troubleshooting

.VERSION
    1.0

.EXAMPLE
    .\CheckMicrosoftEndpointsV1.ps1
    Runs the complete endpoint connectivity check and displays results grouped by service backend.
    
    Sample Output:
    Backend: Windows Update for Business
    URL                                    Status  IPAddress
    ---                                    ------  ---------
    https://dl.delivery.mp.microsoft.com  OK      52.97.144.85
    https://download.windowsupdate.com     OK      204.79.197.200
    
    All endpoints for Windows Update for Business are reachable.

.EXAMPLE
    # Use in automated monitoring
    .\CheckMicrosoftEndpointsV1.ps1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "All Microsoft endpoints accessible"
    } else {
        Write-Host "Connectivity issues detected" -ForegroundColor Red
    }

.EXAMPLE
    # Run with error capture for logging
    $output = .\CheckMicrosoftEndpointsV1.ps1 2>&1
    $exitCode = $LASTEXITCODE
    Add-Content -Path "C:\Logs\EndpointCheck.log" -Value "$(Get-Date): Exit Code $exitCode"

#>


# List of required Microsoft service endpoints (as of 2025)
$backendUrls = @{
    'Windows Update for Business' = @(
        'https://dl.delivery.mp.microsoft.com',
        'https://download.windowsupdate.com',
        'https://fe3.delivery.mp.microsoft.com',
        'https://sws.update.microsoft.com',
        'https://update.microsoft.com',
        'https://windowsupdate.microsoft.com',
        'https://www.delivery.mp.microsoft.com',
        'https://www.dl.delivery.mp.microsoft.com',
        'https://www.update.microsoft.com',
        'https://www.windowsupdate.com',
        'https://www.windowsupdate.microsoft.com',
        'https://*.delivery.mp.microsoft.com',
        'https://*.dl.delivery.mp.microsoft.com',
        'https://*.update.microsoft.com',
        'https://*.windowsupdate.com',
        'https://*.windowsupdate.microsoft.com'
    ) | Sort-Object -Unique
    
    'Windows Autopatch' = @(
        'https://api.update.microsoft.com',
        'https://autopatch.microsoft.com',
        'https://config.edge.skype.com',
        'https://graph.microsoft.com',
        'https://login.microsoftonline.com',
        'https://manage.microsoft.com',
        'https://nexusrules.officeapps.live.com'
    ) | Sort-Object -Unique
    
    'Intune' = @(
        'https://device.login.microsoftonline.com',
        'https://endpoint.microsoft.com',
        'https://graph.microsoft.com',
        'https://login.microsoftonline.com',
        'https://manage.microsoft.com',
        'https://portal.manage.microsoft.com',
        'https://enrollment.manage.microsoft.com',
        'https://enterpriseregistration.windows.net',
        'https://r.manage.microsoft.com',
        'https://i.manage.microsoft.com',
        'https://p.manage.microsoft.com',
        'https://c.manage.microsoft.com',
        'https://m.manage.microsoft.com'
    ) | Sort-Object -Unique
    
    'Microsoft Defender' = @(
        'https://*.defender.microsoft.com',
        'https://*.protection.outlook.com',
        'https://*.security.microsoft.com',
        'https://*.wdcp.microsoft.com',
        'https://go.microsoft.com',
        'https://wdcp.microsoft.com',
        'https://definitionupdates.microsoft.com',
        'https://www.microsoft.com',
        'https://unitedstates.cp.wd.microsoft.com',
        'https://europe.cp.wd.microsoft.com',
        'https://asia.cp.wd.microsoft.com'
    ) | Sort-Object -Unique
    
    'Azure Active Directory' = @(
        'https://login.microsoftonline.com',
        'https://device.login.microsoftonline.com',
        'https://enterpriseregistration.windows.net',
        'https://pas.windows.net',
        'https://management.azure.com',
        'https://policykeyservice.dc.ad.msft.net',
        'https://aadcdn.msauth.net',
        'https://aadcdn.msftauth.net'
    ) | Sort-Object -Unique
    
    'Microsoft 365' = @(
        'https://admin.microsoft.com',
        'https://config.office.com',
        'https://graph.microsoft.com',
        'https://login.microsoftonline.com',
        'https://officecdn.microsoft.com',
        'https://protection.office.com',
        'https://portal.office.com',
        'https://*.office.com',
        'https://*.office365.com',
        'https://*.sharepoint.com',
        'https://*.onedrive.com'
    ) | Sort-Object -Unique
    
    'Microsoft Store' = @(
        'https://storeedgefd.dsx.mp.microsoft.com',
        'https://livetileedge.dsx.mp.microsoft.com',
        'https://storecatalogrevocation.storequality.microsoft.com',
        'https://img-prod-cms-rt-microsoft-com.akamaized.net',
        'https://store-images.s-microsoft.com',
        'https://displaycatalog.mp.microsoft.com',
        'https://licensing.mp.microsoft.com',
        'https://purchase.mp.microsoft.com'
    ) | Sort-Object -Unique
    
    'Windows Activation' = @(
        'https://activation.sls.microsoft.com',
        'https://crl.microsoft.com',
        'https://validation.sls.microsoft.com',
        'https://activation-v2.sls.microsoft.com',
        'https://purchase.mp.microsoft.com',
        'https://licensing.mp.microsoft.com'
    ) | Sort-Object -Unique
    
    'Microsoft Edge' = @(
        'https://config.edge.skype.com',
        'https://edge.microsoft.com',
        'https://msedge.api.cdp.microsoft.com',
        'https://dual-s-01.dual.dualstack.edge-enterprise.activity.windows.com',
        'https://nav.smartscreen.microsoft.com',
        'https://unitedstates.smartscreen-prod.microsoft.com'
    ) | Sort-Object -Unique
    
    'Windows Telemetry' = @(
        'https://v10c.events.data.microsoft.com',
        'https://v20.events.data.microsoft.com',
        'https://watson.telemetry.microsoft.com',
        'https://umwatsonc.events.data.microsoft.com',
        'https://ceuswatcab01.blob.core.windows.net',
        'https://ceuswatcab02.blob.core.windows.net',
        'https://eaus2watcab01.blob.core.windows.net',
        'https://eaus2watcab02.blob.core.windows.net',
        'https://weus2watcab01.blob.core.windows.net',
        'https://weus2watcab02.blob.core.windows.net'
    ) | Sort-Object -Unique
}

# Service impact descriptions for failed connectivity
$serviceImpacts = @{
    'Windows Update for Business' = @{
        'Impact' = 'Windows Updates und Feature Updates können nicht heruntergeladen werden'
        'Symptoms' = 'Update-Fehler, veraltete Sicherheitspatches, fehlende Feature-Updates'
    }
    'Windows Autopatch' = @{
        'Impact' = 'Automatische Patch-Verwaltung funktioniert nicht'
        'Symptoms' = 'Manuelle Update-Verwaltung erforderlich, keine automatischen Deployment-Zeitpläne'
    }
    'Intune' = @{
        'Impact' = 'Geräte-Enrollment, App-Deployment und Compliance-Checks funktionieren nicht'
        'Symptoms' = 'Neue Geräte können nicht registriert werden, Apps installieren nicht, Compliance-Berichte fehlen'
    }
    'Microsoft Defender' = @{
        'Impact' = 'Antivirus-Updates und Cloud-Schutz funktionieren nicht'
        'Symptoms' = 'Veraltete Virensignaturen, keine Cloud-basierten Bedrohungsanalysen, eingeschränkter Schutz'
    }
    'Azure Active Directory' = @{
        'Impact' = 'Anmeldung und Geräte-Authentication können fehlschlagen'
        'Symptoms' = 'Login-Probleme, Geräte-Registrierung fehlgeschlagen, SSO funktioniert nicht'
    }
    'Microsoft 365' = @{
        'Impact' = 'Office-Apps, SharePoint und OneDrive funktionieren nicht vollständig'
        'Symptoms' = 'Office-Apps starten nicht, Dokumente synchronisieren nicht, Admin Center nicht erreichbar'
    }
    'Microsoft Store' = @{
        'Impact' = 'App-Installation und -Updates aus dem Microsoft Store funktionieren nicht'
        'Symptoms' = 'Store öffnet nicht, Apps können nicht installiert/aktualisiert werden'
    }
    'Windows Activation' = @{
        'Impact' = 'Windows-Aktivierung und Lizenzvalidierung funktionieren nicht'
        'Symptoms' = 'Aktivierungsfehler, Lizenz-Warnungen, eingeschränkte Funktionalität'
    }
    'Microsoft Edge' = @{
        'Impact' = 'Browser-Updates und Enterprise-Features funktionieren eingeschränkt'
        'Symptoms' = 'SmartScreen deaktiviert, keine automatischen Updates, Enterprise-Policies funktionieren nicht'
    }
    'Windows Telemetry' = @{
        'Impact' = 'Diagnose-Daten und Fehlerberichte werden nicht übertragen'
        'Symptoms' = 'Keine Windows-Diagnosedaten, Fehlerberichte gehen verloren, Update-Qualität kann beeinträchtigt sein'
    }
}

# Function to display service impact warnings
function Show-ServiceImpactWarning {
    param (
        [string]$ServiceName,
        [array]$FailedEndpoints
    )
    
    if ($serviceImpacts.ContainsKey($ServiceName)) {
        Write-Host "    ⚠️  AUSWIRKUNGEN:" -ForegroundColor Yellow
        Write-Host "       • $($serviceImpacts[$ServiceName].Impact)" -ForegroundColor Yellow
        Write-Host "    🔍 SYMPTOME:" -ForegroundColor Cyan
        Write-Host "       • $($serviceImpacts[$ServiceName].Symptoms)" -ForegroundColor Cyan
        Write-Host "    🚫 Betroffene Endpunkte: $($FailedEndpoints.Count)" -ForegroundColor Red
        Write-Host ""
    }
}

# Flatten all URLs for testing
$urls = $backendUrls.Values | ForEach-Object { $_ } 


# Remove wildcards for direct test (cannot resolve * in Test-NetConnection)
$testUrls = $urls | ForEach-Object {
    if ($_ -like '*.*.*.*') { $_ } else { $_ -replace '\*\.', 'www.' }
}

$results = @()



foreach ($url in $testUrls) {
    $testHost = ($url -replace 'https://', '').Split('/')[0]
    $result = Test-NetConnection -ComputerName $testHost -Port 443 -WarningAction SilentlyContinue
    $status = if ($result.TcpTestSucceeded) { 'OK' } else { 'FAILED' }
    $results += [PSCustomObject]@{
        URL = $url
        Host = $testHost
        Status = $status
        IPAddress = $result.RemoteAddress
    }
}

# Output grouped results by backend
$failedServices = @()
foreach ($backend in $backendUrls.Keys) {
    Write-Host "`nBackend: $backend" -ForegroundColor Cyan
    $backendResults = $results | Where-Object { $backendUrls[$backend] -contains $_.URL }
    $backendResults | Format-Table URL, Status, IPAddress -AutoSize
    
    $failedEndpoints = $backendResults | Where-Object { $_.Status -eq 'FAILED' }
    if ($failedEndpoints.Count -gt 0) {
        Write-Host "❌ $($failedEndpoints.Count) Endpunkt(e) für $backend sind NICHT erreichbar!" -ForegroundColor Red
        $failedServices += $backend
        Show-ServiceImpactWarning -ServiceName $backend -FailedEndpoints $failedEndpoints
    } else {
        Write-Host "✅ Alle Endpunkte für $backend sind erreichbar." -ForegroundColor Green
    }
}

# Summary table of all results
Write-Host "`n" + "="*80 -ForegroundColor White
Write-Host "GESAMTÜBERSICHT ALLER ENDPUNKT-TESTS" -ForegroundColor White
Write-Host "="*80 -ForegroundColor White
$results | Format-Table -AutoSize

# Final summary with service impact overview
if ($results.Status -contains 'FAILED') {
    $totalFailed = ($results | Where-Object { $_.Status -eq 'FAILED' }).Count
    $totalTested = $results.Count
    
    Write-Host "`n🚨 WARNUNG: $totalFailed von $totalTested Microsoft-Endpunkten sind NICHT erreichbar!" -ForegroundColor Red
    Write-Host "="*80 -ForegroundColor Red
    
    if ($failedServices.Count -gt 0) {
        Write-Host "📋 BETROFFENE SERVICES UND MÖGLICHE AUSWIRKUNGEN:" -ForegroundColor Yellow
        Write-Host "-"*50 -ForegroundColor Yellow
        foreach ($service in $failedServices) {
            Write-Host "🔴 $service" -ForegroundColor Red
            if ($serviceImpacts.ContainsKey($service)) {
                Write-Host "   └─ $($serviceImpacts[$service].Impact)" -ForegroundColor Yellow
            }
        }
        Write-Host "`n💡 EMPFEHLUNG: Überprüfen Sie Ihre Firewall- und Proxy-Konfiguration für die oben genannten Services." -ForegroundColor Cyan
    }
    exit 1
} else {
    Write-Host "`n✅ ERFOLG: Alle $($results.Count) Microsoft-Endpunkte sind erreichbar!" -ForegroundColor Green
    Write-Host "🎉 Alle Microsoft Cloud Services sollten ordnungsgemäß funktionieren." -ForegroundColor Green
    exit 0
}
