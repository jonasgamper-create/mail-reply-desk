# Deep-Research-Prompt

Ziel: Recherchiere die beste technische und produktseitige Architektur für einen privaten Mail-/Kalender-Assistenten, der nach Login automatisch Mails lesen, den Kontext verstehen, drei Antwortentwürfe erstellen und Kalendertermine vorbereiten kann. Der Nutzer soll nur freigegebene Mailkonten verbinden und nie automatische Senderechte geben.

Kontext:

- Statische PWA existiert bereits.
- Hauptworkflow: Mail antworten, Mail erstellen, Kalendertermin erstellen.
- Startkonto: `info@jonnyandlinda.com`, gehostet über Wix, aktuell Gmail / Google Workspace.
- Weitere Konten sollen später per Copy/Paste oder Fokusliste ergänzt werden.
- Primärer Kalender: iCloud.
- iPhone-Ziel: native Custom Keyboard Extension als spätere Eingabeschicht.
- Mac-Ziel: Web-App im Split Screen.
- Kein automatisches Senden. Immer Entwurf und Nutzerbestätigung.

Bitte recherchiere kritisch:

1. Beste UX-Muster aus Superhuman, Gmail, Outlook, Apple Mail, Shortwave, Flowrite, Missive, Spark und relevanten Reddit/HN/Productivity-Foren.
2. Welche Features tatsächlich Zeit sparen und welche Overengineering sind.
3. Optimale Minimalarchitektur für Gmail Read-Only OAuth, iCloud CalDAV/IMAP, Backend, PWA und spätere iOS-Tastatur.
4. Sicherheitsmodell: Scopes, Token-Speicherung, Datenschutz, Audit-Logs, keine Senderechte.
5. Wie man aus Absender, Vorname, Nachname, Geschlecht/Anredeprofil und Mailverlauf automatisch Du/Sie, formelle Anrede und passenden Absender wählt.
6. Kalendertermin-Erstellung mit iCloud: erst ICS, später CalDAV nach Bestätigung.
7. A/B-ähnliche Produktentscheidungen: 1 Entwurf vs. 3 Entwürfe, kurze vs. volle Zusammenfassung, Inline-Leiste vs. Seitenpanel, Tastatur vs. Companion-App.

Output:

- Priorisierte Empfehlung mit P0/P1/P2.
- Konkrete Architektur.
- Datenmodell.
- Erforderliche OAuth-/API-Scopes.
- Risiken und Gegenmaßnahmen.
- MVP-Plan für 2 Wochen.
- Entscheidung, wann die iPhone-Tastatur sinnvoll ist.
