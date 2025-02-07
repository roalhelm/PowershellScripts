# User festlegen
$User1 = "User1"
$User2 = "User2"

# Funktion zum Abrufen der Gruppennamen eines Benutzers
function Get-UserGroups {
    param ($User)
    Get-ADUser -Identity $User -Property MemberOf | Select-Object -ExpandProperty MemberOf | ForEach-Object { ($_ -split ',')[0] -replace 'CN=' }
}

# Gruppen der Benutzer abrufen
$GroupsUser1 = Get-UserGroups -User $User1
$GroupsUser2 = Get-UserGroups -User $User2

# Ausgabe der Gruppen für jeden Benutzer
Write-Host "Gruppen von $User1 :" -ForegroundColor Green
$GroupsUser1 | ForEach-Object { Write-Host $_ }

Write-Host "`nGruppen von $User2 :" -ForegroundColor Cyan
$GroupsUser2 | ForEach-Object { Write-Host $_ }

# Gruppenvergleich: Welche Gruppen fehlen Benutzer 2?
$MissingGroups = $GroupsUser1 | Where-Object { $_ -notin $GroupsUser2 }

Write-Host "`nGruppen, die $User2 fehlen:" -ForegroundColor Yellow
if ($MissingGroups) {
    $MissingGroups | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Keine fehlenden Gruppen! Beide Benutzer haben die gleichen Gruppen."
}
