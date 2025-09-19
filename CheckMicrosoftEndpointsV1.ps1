
<#
.SYNOPSIS
    Checks connectivity to all required Microsoft endpoints for Windows Update for Business, Intune, and Defender on Windows 10/11 clients.

    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script tests if the client can reach all necessary Microsoft service URLs for Windows Update for Business, Intune, and Microsoft Defender. It attempts to connect to each endpoint and reports the result, grouped by backend. The output is color-coded and grouped for clarity.

.NOTES
    File Name     : CheckMicrosoftEndpointsV1.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : 2025-09-18

.CHANGES
    1.0 (2025-09-18) - Initial release

.VERSION
    1.0

.EXAMPLE
    PS C:\> .\CheckMicrosoftEndpointsV1.ps1
    # Runs the endpoint connectivity check and outputs the results grouped by backend.
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
    'Intune' = @(
        'https://device.login.microsoftonline.com',
        'https://endpoint.microsoft.com',
        'https://graph.microsoft.com',
        'https://login.microsoftonline.com',
        'https://manage.microsoft.com'
    ) | Sort-Object -Unique
    'Defender' = @(
        'https://*.defender.microsoft.com',
        'https://*.microsoft.com',
        'https://*.protection.outlook.com',
        'https://*.security.microsoft.com',
        'https://*.wdcp.microsoft.com',
        'https://go.microsoft.com',
        'https://wdcp.microsoft.com'
    ) | Sort-Object -Unique
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
foreach ($backend in $backendUrls.Keys) {
    Write-Host "`nBackend: $backend" -ForegroundColor Cyan
    $backendResults = $results | Where-Object { $backendUrls[$backend] -contains $_.URL }
    $backendResults | Format-Table URL, Status, IPAddress -AutoSize
    if ($backendResults.Status -contains 'FAILED') {
        Write-Host "Some endpoints for $backend could NOT be reached!" -ForegroundColor Red
    } else {
        Write-Host "All endpoints for $backend are reachable." -ForegroundColor Green
    }
}

$results | Format-Table -AutoSize

if ($results.Status -contains 'FAILED') {
    Write-Host "\nSome required Microsoft endpoints could NOT be reached!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "\nAll required Microsoft endpoints are reachable." -ForegroundColor Green
    exit 0
}
