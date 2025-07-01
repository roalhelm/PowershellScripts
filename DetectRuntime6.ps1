# Intune Detection Script: Prüft, ob eine oder mehrere Versionen von "Microsoft Windows Desktop Runtime - 6.*" installiert sind

$found = $false
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($path in $registryPaths) {
    $subKeys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
    foreach ($subKey in $subKeys) {
        $displayName = (Get-ItemProperty -Path "$path\$($subKey.PSChildName)" -ErrorAction SilentlyContinue).DisplayName
        if ($displayName -like "Microsoft Windows Desktop Runtime - 6*") {
            Write-Output "Gefunden: $displayName"
            $found = $true
        }
    }
}

if ($found) {
    Write-Output "Microsoft Windows Desktop Runtime - 6.* wurde gefunden."
    exit 1  # Detected
} else {
    Write-Output "Microsoft Windows Desktop Runtime - 6.* wurde nicht gefunden."
    exit 0  # Not detected
}