# Company Portal Reinstall (Intune Proactive Remediation)

Dieses Paket liefert ein Detection- und ein Remediation-Skript fuer Intune.
Ziel: Company Portal im SYSTEM-Kontext neu installieren.

## Dateien

- detection.ps1
- remediation.ps1

## Intune Einstellungen

1. Intune Admin Center > Devices > Scripts and remediations > Remediations.
2. Neues Paket anlegen.
3. Detection script: detection.ps1
4. Remediation script: remediation.ps1
5. Run this script using the logged-on credentials: No
6. Enforce script signature check: No (oder entsprechend eurer Richtlinie)
7. Run script in 64-bit PowerShell: Yes

## Parameter

Detection:

- ReinstallWindowDays (Default: 3)

Remediation:

- PackageId (Default: 9WZDNCRFJ3PZ)
- MaxAttempts (Default: 2)

Hinweis: Die Remediation nutzt fest die Quelle msstore (Microsoft Store).

Hinweis zur Detection: Es wird nur geprueft, ob im Remediation-Log in den letzten X Tagen ein erfolgreicher Reinstall verzeichnet ist.

## Exit Codes

Detection:

- 0 = Compliant
- 1 = Non-compliant (Remediation wird gestartet)

Remediation:

- 0 = Erfolgreich remediated
- 1 = Fehler oder weiterhin non-compliant

## Logging

- C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\CompanyPortal-Detection.log
- C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\CompanyPortal-Remediation.log

## Hinweise

- Der Store-Installer im SYSTEM-Kontext ist abhaengig von App Installer und Store-Erreichbarkeit.
- Wenn der Store-Installer unter SYSTEM nicht verfuegbar ist, schreibt das Remediation-Skript einen klaren Fehler und beendet mit Exit 1.
- Die Remediation fuehrt bei vorhandenem Company Portal eine Deinstallation und anschliessend Neuinstallation durch.

## Nur reinstallieren, wenn Company Portal fehlt (CP.APP.MISSING)

`detection.ps1` fordert absichtlich alle paar Tage eine Neuinstallation an. Wer nur reparieren will, wenn die App wirklich fehlt, nimmt stattdessen `Detect-CompanyPortalMissing.ps1` als Detection und `remediation.ps1` als Remediation. Das ist das Paket, das die [ClientFixPage](https://roalhelm.github.io/ClientFixPage/) bei `CP.APP.MISSING` empfiehlt. Fuer eine Company Portal App, die installiert ist, aber haengt oder sich nicht anmelden laesst, gibt es `../CompanyPortalReset` (`CP.APP.BROKEN`).
