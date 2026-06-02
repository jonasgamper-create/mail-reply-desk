# Benötigte Zugriffe

Das Ziel sind drei Workflows:

- Mail erstellen
- Mail beantworten
- Kalendertermin erstellen

Grundregel: Die App darf lesen, Entwürfe vorbereiten und Kalendertermine vorbereiten. Sie soll nie automatisch Mails senden.

## Produktentscheidung

Der Assistent wird nicht als allgemeiner Mail-Client gebaut. Er fokussiert nur auf Lindas freigegebene Mail-Liste:

- `info@jonnyandlinda.com` → Google Workspace / Gmail via Wix
- `linda.hiller@skinfit.eu` → Provider noch klären
- `hillerlinda@icloud.com` → iCloud Mail
- `lindas.contentfactory@gmail.com` → Gmail

Der primäre Kalender ist iCloud. Standard ist `ICS zuerst`, damit Linda den Termin kontrolliert, bevor er im Kalender landet.

## Zugriffsstufen

### Stufe 1: Kein Zugriff

Aktueller Stand:

- Linda fügt Kontext oder Stichworte ein.
- Die App erzeugt 3 Varianten.
- Für Termine kann eine `.ics`-Kalenderdatei erzeugt werden.

Keine Passwörter, keine OAuth-Verbindung, keine externen Daten.

### Stufe 2: Mail lesen

Nötig für automatische Mailantworten ohne Copy/Paste.

- Gmail / Google Workspace: OAuth mit Gmail Read-Only. Das gilt für `info@jonnyandlinda.com` und `lindas.contentfactory@gmail.com`.
- Microsoft 365 / Outlook: OAuth mit Microsoft Graph Mail.Read.
- iCloud: IMAP mit app-spezifischem Passwort.
- Eigene Maildomains: abhängig vom Provider, meist IMAP.

Keine Senderechte anfordern.

### Stufe 3: Kalender lesen und vorbereiten

Nötig, damit freie Zeiten erkannt und Termine vorbereitet werden können.

- iCloud Calendar: CalDAV mit app-spezifischem Passwort.
- Google Calendar: Calendar API, aktuell nicht primär.
- Microsoft 365 / Outlook: Microsoft Graph Calendar, aktuell nicht primär.

Empfehlung: Erst Kalender lesen und `.ics` oder Entwurf vorbereiten. Direktes Erstellen im Kalender nur nach Bestätigung.

### Stufe 4: Native iPhone-Tastatur

Nötig für direkte iPhone-Integration.

- Apple Developer Account.
- iOS-App mit Keyboard Extension.
- `Allow Full Access` für Backend-Verbindung.
- App Group für geteilte Einstellungen.

Die Tastatur bekommt nur begrenzten Textkontext aus dem aktuellen Eingabefeld. Den vollständigen Mailverlauf muss sie über das Backend abrufen.

## Was Linda konkret freigeben müsste

Für den nächsten echten Automationsschritt brauche ich von Linda:

- Welche Adresse ist Hauptkonto?
- Welcher Provider steckt hinter `linda.hiller@skinfit.eu`?
- Welcher Provider steckt hinter `info@jonnyandlinda.com`?
- Soll Kalender primär Google, iCloud oder Microsoft sein?
- Darf das System Mailinhalte an eine Cloud-KI senden, wenn sie vorher autorisiert wurde?

Passwörter sollten nicht im Chat geteilt werden. OAuth-Logins und app-spezifische Passwörter gehören in die spätere Backend-Setup-Oberfläche.
