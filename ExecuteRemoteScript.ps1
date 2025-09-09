<#
.SYNOPSIS
    Executes a specified PowerShell script on a list of remote servers.
    GitHub Repository: https://github.com/roalhelm/

.DESCRIPTION
    This script reads a list of server names from a file and executes a specified 
    PowerShell script on each server. The script uses the provided credentials to 
    establish a remote connection to each server in the list and runs the script 
    in the specified path on each remote server. 

    For each server, it outputs whether the execution was successful or if there 
    was an error. This is useful for performing batch operations across multiple 
    servers from a central location.

.PARAMETER serverListPath
    Path to the file containing the list of server names.

.PARAMETER remoteScriptPath
    Path to the PowerShell script to be executed remotely on each server.

.NOTES
    Script requires the necessary permissions to connect to the remote servers.
    Each server in the server list must allow PowerShell Remoting.

.AUTHOR
    Script created by Ronny Alhelm
    Date: 05.11.2024

.EXAMPLE
    .\ExecuteRemoteScript.ps1

    This command will execute the script specified in $remoteScriptPath on all 
    servers listed in $serverListPath.
#>

# Main Script: ExecuteRemoteScript.ps1

# Path to the server list
$serverListPath = ".\clientList.txt"

# Path to the script that should be executed on the remote servers
$remoteScriptPath = ".\Script.ps1"

# Load script content
$scriptContent = Get-Content -Path $remoteScriptPath -Raw

# Load server list
$servers = Get-Content -Path $serverListPath

# Prompt for credentials
$credential = Get-Credential

foreach ($server in $servers) {
    try {
        Write-Host "Connecting to $server..."

        # Execute remote script
        Invoke-Command -ComputerName $server -ScriptBlock {
            param ($script)
            Invoke-Expression $script
        } -ArgumentList $scriptContent -Credential $credential

        Write-Host "Script executed successfully on $server.`n"
    } catch {
        Write-Host "Error executing script on $server $_`n" -ForegroundColor Red
    }
}
