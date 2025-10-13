<#
.SYNOPSIS
    Unblocks files downloaded from the internet by removing the zone identifier.

    GitHub Repository: https://github.com/roalhelm/PowershellScripts

.DESCRIPTION
    This script removes the Windows zone identifier from files that have been downloaded from the internet.
    The zone identifier is what causes Windows to show security warnings when opening downloaded files.
    The script can unblock a single file or recursively unblock all files in a directory structure.

.NOTES
    File Name     : UnblockFiles.ps1
    Author        : Ronny Alhelm
    Version       : 1.0
    Creation Date : October 13, 2025

.CHANGES
    1.0 - Initial version with directory recursion support

.VERSION
    1.0

.EXAMPLE
    .\UnblockFiles.ps1
    Unblocks all files in the current directory and subdirectories.

.EXAMPLE
    .\UnblockFiles.ps1 -DirectoryPath "C:\Downloads"
    Unblocks all files in the specified directory and subdirectories.

.EXAMPLE
    .\UnblockFiles.ps1 -DirectoryPath "C:\MyFile.zip" -Recurse:$false
    Unblocks only the specified file without recursion.

#>

param (
    [Parameter(Mandatory = $false, HelpMessage = "Path to the directory or file to unblock")]
    [string]$DirectoryPath = ".",
    
    [Parameter(Mandatory = $false, HelpMessage = "Process files recursively in subdirectories")]
    [switch]$Recurse = $true
)

try {
    if (Test-Path -Path $DirectoryPath) {
        if ((Get-Item $DirectoryPath).PSIsContainer) {
            # It's a directory
            if ($Recurse) {
                Get-ChildItem -Path $DirectoryPath -Recurse -File | Unblock-File
                Write-Host "All files in '$DirectoryPath' and subdirectories have been unblocked." -ForegroundColor Green
            } else {
                Get-ChildItem -Path $DirectoryPath -File | Unblock-File
                Write-Host "All files in '$DirectoryPath' have been unblocked." -ForegroundColor Green
            }
        } else {
            # It's a single file
            Unblock-File -Path $DirectoryPath
            Write-Host "File '$DirectoryPath' has been unblocked." -ForegroundColor Green
        }
    } else {
        Write-Error "Path '$DirectoryPath' does not exist."
        exit 1
    }
} catch {
    Write-Error "An error occurred while unblocking files: $($_.Exception.Message)"
    exit 1
}


