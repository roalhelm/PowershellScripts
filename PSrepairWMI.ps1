<#
.SYNOPSIS
    Advanced WMI repair script for local and remote computers.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script performs comprehensive WMI repairs:
    - Handles both local and remote computers
    - Manages WMI repository folders
    - Verifies and repairs WMI repository
    - Provides detailed status updates

.PARAMETER ComputerName
    Target computer name (local if not specified)

.NOTES
    Filename: PSrepairWMI.ps1
    Version: 2.0.0
    Author: Ronny Alhelm
#>

function Repair-LocalWMI {
    $wmiRootPath = "C:\Windows\System32\wbem"
    $currentWmiFolder = "Repository"
    $backupFolderName = "Repository_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    Write-Host "Checking WMI repository folders..."
    $repositoryFolders = Get-ChildItem -Path $wmiRootPath -Directory | 
        Where-Object { $_.Name -like "Repository*" }

    if ($repositoryFolders.Count -gt 1) {
        $largestFolder = $repositoryFolders | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name TotalSize -Value (
                Get-ChildItem -Path $_.FullName -Recurse | 
                Measure-Object -Property Length -Sum
            ).Sum -PassThru
        } | Sort-Object -Property TotalSize -Descending | Select-Object -First 1

        if ($largestFolder.Name -ne $currentWmiFolder) {
            Write-Host "Repairing WMI repository structure..."
            Stop-Service -Name winmgmt -Force
            
            $currentPath = Join-Path $wmiRootPath $currentWmiFolder
            $backupPath = Join-Path $wmiRootPath $backupFolderName
            
            if (Test-Path $currentPath) {
                Rename-Item -Path $currentPath -NewName $backupFolderName
            }
            
            New-Item -Path $currentPath -ItemType Directory | Out-Null
            Copy-Item -Path "$($largestFolder.FullName)\*" -Destination $currentPath -Recurse -Force
            
            Start-Service -Name winmgmt
        }
    }

    # Verify and repair repository
    Write-Host "Verifying WMI repository..."
    winmgmt /verifyrepository
    $repositoryStatus = winmgmt /salvagerepository
    
    if ($repositoryStatus -like "*success*") {
        Write-Host "WMI repository successfully repaired." -ForegroundColor Green
    } else {
        Write-Host "WMI repository repair failed." -ForegroundColor Red
    }
}

function Repair-RemoteWMI {
    param([string]$ComputerName)

    Write-Host "Connecting to remote computer: $ComputerName"
    
    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host "Cannot connect to $ComputerName" -ForegroundColor Red
        return
    }

    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock ${function:Repair-LocalWMI} `
            -Credential (Get-Credential) -ErrorAction Stop
    } catch {
        Write-Host "Error connecting" -ForegroundColor Red
    }
}

# Main script execution
$computerName = Read-Host -Prompt "Enter computer name (press Enter for local repair)"

if ([string]::IsNullOrWhiteSpace($computerName)) {
    Repair-LocalWMI
} else {
    Repair-RemoteWMI -ComputerName $computerName
}
