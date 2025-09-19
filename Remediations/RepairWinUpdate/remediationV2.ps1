#region PowerShell Help
<#
.SYNOPSIS
    Erweiterte Remediation für Windows Update-Probleme, setzt Update-bezogene Registry-Werte zurück, startet Dienste neu und erstellt Diagnoselogs.

    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    Dieses Skript setzt verschiedene Windows Update- und Telemetrie-Registry-Werte zurück, startet relevante Dienste neu, registriert System-DLLs, setzt WinSock zurück und erstellt abschließend Diagnoselogs. Es ist für Intune-Remediation-Szenarien konzipiert und loggt alle Aktionen in eine Logdatei.

.NOTES
    File Name     : remediationV2.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : 2025-09-19

.CHANGES
    1.0 - Initialversion

.VERSION
    1.0

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\remediationV2.ps1
    # Führt die vollständige Remediation für Windows Update durch und erstellt Diagnoselogs.
#>
#endregion
<#
    This script logs all output to C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\RepairWinUpdate_remediationV2.log
#>

$global:LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\RepairWinUpdate_remediationV2.log"
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp - $message"
    Write-Output $logLine
    Add-Content -Path $global:LogPath -Value $logLine
}

#Run DISM
try {Repair-WindowsImage -RestoreHealth -NoRestart -Online -LogPath "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\#DISM.log" -Verbose -ErrorAction SilentlyContinue}
catch {Write-Log "DISM error occurred. Check logs"}
finally {
        #Check registry for pauses
        $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        $TestPath = Test-Path $Path
        if  ($TestPath -eq $true)
            {
            Write-Log "Deleting $Path"
            Remove-Item -Path $Path -Recurse -Verbose
            }

        $key = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings"
        $TestKey = Test-Path $key
        if  ($TestKey -eq $true)
            {
            $val = (Get-Item $key -EA Ignore);
            $PausedQualityDate = (Get-Item $key -EA Ignore).Property -contains "PausedQualityDate"
            $PausedFeatureDate = (Get-Item $key -EA Ignore).Property -contains "PausedFeatureDate"
            $PausedQualityStatus = (Get-Item $key -EA Ignore).Property -contains "PausedQualityStatus"
            $PausedQualityStatusValue = $val.GetValue("PausedQualityStatus");
            $PausedFeatureStatus = (Get-Item $key -EA Ignore).Property -contains "PausedFeatureStatus"
            $PausedFeatureStatusValue = $val.GetValue("PausedFeatureStatus");

            if  ($PausedQualityDate -eq $true)
                {
                Write-Log "PausedQualityDate under $key present"
                Remove-ItemProperty -Path $key -Name "PausedQualityDate" -Verbose -ErrorAction SilentlyContinue
                $PausedQualityDate = (Get-Item $key -EA Ignore).Property -contains "PausedQualityDate"
                }

            if  ($PausedFeatureDate -eq $true)
                {
                Write-Log "PausedFeatureDate under $key present"
                Remove-ItemProperty -Path $key -Name "PausedFeatureDate" -Verbose -ErrorAction SilentlyContinue
                $PausedFeatureDate = (Get-Item $key -EA Ignore).Property -contains "PausedFeatureDate"
                }

            if  ($PausedQualityStatus -eq $true)
                {
                Write-Log "PausedQualityStatus under $key present"
                Write-Log "Currently set to $PausedQualityStatusValue"
                if  ($PausedQualityStatusValue -ne "0")
                    {
                    Set-ItemProperty -Path $key -Name "PausedQualityStatus" -Value "0" -Verbose
                    $PausedQualityStatusValue = $val.GetValue("PausedQualityStatus");
                    }
                }

            if  ($PausedFeatureStatus -eq $true)
                {
                Write-Log "PausedFeatureStatus under $key present"
                Write-Log "Currently set to $PausedFeatureStatusValue"
                if  ($PausedFeatureStatusValue -ne "0")
                    {
                    Set-ItemProperty -Path $key -Name "PausedFeatureStatus" -Value "0" -Verbose
                    $PausedFeatureStatusValue = $val.GetValue("PausedFeatureStatus");
                    }
                }
            }

        $key2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update"
        $TestKey2 = Test-Path $key2
        if  ($TestKey2 -eq $true)
            {
            $val2 = (Get-Item $key2 -EA Ignore);

            $PauseQualityUpdatesStartTime = (Get-Item $key2 -EA Ignore).Property -contains "PauseQualityUpdatesStartTime"
            $PauseFeatureUpdatesStartTime = (Get-Item $key2 -EA Ignore).Property -contains "PauseFeatureUpdatesStartTime"
            $PauseQualityUpdates = (Get-Item $key2 -EA Ignore).Property -contains "PauseQualityUpdates"
            $PauseQualityUpdatesValue = $val2.GetValue("PauseQualityUpdates");
            $PauseFeatureUpdates = (Get-Item $key2 -EA Ignore).Property -contains "PauseFeatureUpdates"
            $PauseFeatureUpdatesValue = $val2.GetValue("PauseFeatureUpdates");
            $DeferFeatureUpdates = (Get-Item $key2 -EA Ignore).Property -contains "DeferFeatureUpdatesPeriodInDays"
            $DeferFeatureUpdatesValue = $val2.GetValue("DeferFeatureUpdatesPeriodInDays");

            if  ($DeferFeatureUpdates -eq $true)
                {
                Write-Output "DeferFeatureUpdatesPeriodInDays under $key2 present"
                Write-Output "Currently set to $DeferFeatureUpdatesValue"
                if  ($DeferFeatureUpdatesValue -ne "0")
                    {
                    Set-ItemProperty -Path $key2 -Name "DeferFeatureUpdatesPeriodInDays" -Value "0" -Verbose
                    $DeferFeatureUpdatesValue = $val2.GetValue("DeferFeatureUpdatesPeriodInDays");
                    }
                }    

            if  ($PauseQualityUpdatesStartTime -eq $true)
                {
                Write-Output "PauseQualityUpdatesStartTime under $key2 present"
                Remove-ItemProperty -Path $key2 -Name "PauseQualityUpdatesStartTime" -Verbose -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $key2 -Name "PauseQualityUpdatesStartTime_ProviderSet" -Verbose -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $key2 -Name "PauseQualityUpdatesStartTime_WinningProvider" -Verbose -ErrorAction SilentlyContinue
                $PauseQualityUpdatesStartTime = (Get-Item $key2 -EA Ignore).Property -contains "PauseQualityUpdatesStartTime"
                }

            if  ($PauseFeatureUpdatesStartTime -eq $true)
                {
                Write-Output "PauseFeatureUpdatesStartTime under $key2 present"
                Remove-ItemProperty -Path $key2 -Name "PauseFeatureUpdatesStartTime" -Verbose -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $key2 -Name "PauseFeatureUpdatesStartTime_ProviderSet" -Verbose -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $key2 -Name "PauseFeatureUpdatesStartTime_WinningProvider" -Verbose -ErrorAction SilentlyContinue
                $PauseFeatureUpdatesStartTime = (Get-Item $key2 -EA Ignore).Property -contains "PauseFeatureUpdatesStartTime"
                }

            if  ($PauseQualityUpdates -eq $true)
                {
                Write-Output "PauseQualityUpdates under $key2 present"
                Write-Output "Currently set to $PauseQualityUpdatesValue"
                if  ($PauseQualityUpdatesValue -ne "0")
                    {
                    Set-ItemProperty -Path $key2 -Name "PauseQualityUpdates" -Value "0" -Verbose
                    $PauseQualityUpdatesValue = $val2.GetValue("PausedQualityStatus");
                    }
                }

            if  ($PauseFeatureUpdates -eq $true)
                {
                Write-Output "PauseFeatureUpdates under $key2 present"
                Write-Output "Currently set to $PauseFeatureUpdatesValue"
                if  ($PauseFeatureUpdatesValue -ne "0")
                    {
                    Set-ItemProperty -Path $key2 -Name "PauseFeatureUpdates" -Value "0" -Verbose
                    $PauseFeatureUpdatesValue = $val2.GetValue("PauseFeatureUpdates");
                    }
                }
            }

        $key3 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        $TestKey3 = Test-Path $key3
        if  ($TestKey3 -eq $true)
            {
            $val3 = (Get-Item $key3 -EA Ignore);

            $AllowDeviceNameInTelemetry = (Get-Item $key3 -EA Ignore).Property -contains "AllowDeviceNameInTelemetry"
            $AllowTelemetry_PolicyManager = (Get-Item $key3 -EA Ignore).Property -contains "AllowTelemetry_PolicyManager"
            $AllowDeviceNameInTelemetryValue = $val3.GetValue("AllowDeviceNameInTelemetry");
            $AllowTelemetry_PolicyManagerValue = $val3.GetValue("AllowTelemetry_PolicyManager");

            if  ($AllowDeviceNameInTelemetry -eq $true)
                {
                Write-Output "AllowDeviceNameInTelemetry under $key3 present"
                Write-Output "Currently set to $AllowDeviceNameInTelemetryValue"
                }
            else{New-ItemProperty -Path $key3 -PropertyType DWORD -Name "AllowDeviceNameInTelemetry" -Value "1" -Verbose}

            if  ($AllowDeviceNameInTelemetryValue -ne "1")
                {Set-ItemProperty -Path $key3 -Name "AllowDeviceNameInTelemetry" -Value "1" -Verbose}

            if  ($AllowTelemetry_PolicyManager -eq $true)
                {
                Write-Output "AllowTelemetry_PolicyManager under $key3 present"
                Write-Output "Currently set to $AllowTelemetry_PolicyManagerValue"
                }
            else{New-ItemProperty -Path $key3 -PropertyType DWORD -Name "AllowTelemetry_PolicyManager" -Value "1" -Verbose}

            if  ($AllowTelemetry_PolicyManagerValue -ne "1")
                {Set-ItemProperty -Path $key3 -Name "AllowTelemetry_PolicyManager" -Value "1" -Verbose}
            }


        $key4 = "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser\GWX"
        $TestKey4 = Test-Path $key4
        if  ($TestKey4 -eq $true)
            {
            $val4 = (Get-Item $key4 -EA Ignore);

            $GStatus = (Get-Item $key4 -EA Ignore).Property -contains "GStatus"
            $GStatusValue = $val4.GetValue("GStatus");
            
            if  ($GStatus -eq $true) 
                {
                Write-Output "GStatus under $key4 present"
                Write-Output "Currently set to $GStatusValue"
                }
            else{New-ItemProperty -Path $key4 -PropertyType DWORD -Name "GStatus" -Value "2" -Verbose}

            if  ($GStatusValue -ne "2")
                {Set-ItemProperty -Path $key4 -Name "GStatus" -Value "2" -Verbose}
            }

        Write-Host "1. Stopping Windows Update Services..." 
        Stop-Service -Name BITS -Force -Verbose -ErrorAction SilentlyContinue
        Stop-Service -Name wuauserv -Force -Verbose -ErrorAction SilentlyContinue
        Stop-Service -Name cryptsvc -Force -Verbose -ErrorAction SilentlyContinue

        Write-Host "2. Remove QMGR Data file..." 
        Remove-Item -Path "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue -Verbose

        Write-Host "3. Removing the Software Distribution and CatRoot Folder..." 
        Remove-Item -Path "$env:systemroot\SoftwareDistribution" -ErrorAction SilentlyContinue -Recurse -Verbose
        Remove-Item -Path "$env:systemroot\System32\Catroot2" -ErrorAction SilentlyContinue -Recurse -Verbose

        Write-Host "4. Resetting the Windows Update Services to default settings..." 
        Start-Process "sc.exe" -ArgumentList "sdset bits D:(A;CI;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)"
        Start-Process "sc.exe" -ArgumentList "sdset wuauserv D:(A;;CCLCSWRPLORC;;;AU)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)"

        Set-Location $env:systemroot\system32 

        Write-Host "5. Registering some DLLs..." 
        regsvr32.exe atl.dll /s
        regsvr32.exe urlmon.dll /s
        regsvr32.exe mshtml.dll /s
        regsvr32.exe shdocvw.dll /s
        regsvr32.exe browseui.dll /s
        regsvr32.exe jscript.dll /s
        regsvr32.exe vbscript.dll /s
        regsvr32.exe scrrun.dll /s
        regsvr32.exe msxml.dll /s
        regsvr32.exe msxml3.dll /s
        regsvr32.exe msxml6.dll /s
        regsvr32.exe actxprxy.dll /s
        regsvr32.exe softpub.dll /s
        regsvr32.exe wintrust.dll /s
        regsvr32.exe dssenh.dll /s
        regsvr32.exe rsaenh.dll /s
        regsvr32.exe gpkcsp.dll /s
        regsvr32.exe sccbase.dll /s
        regsvr32.exe slbcsp.dll /s
        regsvr32.exe cryptdlg.dll /s
        regsvr32.exe oleaut32.dll /s
        regsvr32.exe ole32.dll /s
        regsvr32.exe shell32.dll /s
        regsvr32.exe initpki.dll /s
        regsvr32.exe wuapi.dll /s
        regsvr32.exe wuaueng.dll /s
        regsvr32.exe wuaueng1.dll /s
        regsvr32.exe wucltui.dll /s
        regsvr32.exe wups.dll /s
        regsvr32.exe wups2.dll /s
        regsvr32.exe wuweb.dll /s
        regsvr32.exe qmgr.dll /s
        regsvr32.exe qmgrprxy.dll /s
        regsvr32.exe wucltux.dll /s
        regsvr32.exe muweb.dll /s
        regsvr32.exe wuwebv.dll /s

        Write-Host "6) Resetting the WinSock..." 
        netsh winsock reset 

        Write-Host "7) Starting Windows Update Services..." 
        Start-Service -Name BITS -Verbose
        Start-Service -Name wuauserv -Verbose 
        Start-Service -Name cryptsvc -Verbose

        Write-Host "8) Forcing discovery..."
        USOClient.exe StartInteractiveScan

        Write-Host "9) Pausing for 5 minutes"
        Start-Sleep -Seconds 300
        
        try { 
            Write-Host "10) Create diagnostic logs"
            $logs = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
            $OldLogs = "$logs\logs*.zip"
            $dir = "C:\BH IT\"
            $webClient = New-Object System.Net.WebClient
            $url = "https://go.microsoft.com/fwlink/?linkid=870142"
            $file = "$($dir)\SetupDiag.exe"
            $webClient.DownloadFile($url,$file)
            
            $checkLogs = Test-Path -Path $OldLogs
            if  ($checkLogs -eq $true)
                {Remove-Item -Path $OldLogs -Force -Recurse}

            ."$file" /Output:"$logs\#Windows Updates - Diagnostics.log"
            }
        catch {Write-Output "Diagnostic log creation failed. Check logs"}
        # Step 13 (scheduled midnight reboot task) has been removed as requested.
    }