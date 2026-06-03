# Native iPhone Tastatur

Dieses iOS-Geruest enthaelt:

- `MailReplyDesk`: Container-App mit Settings.
- `MailReplyKeyboard`: iOS Custom Keyboard Extension.
- Geteiltes Profil ueber App Group.

## Aktueller Stand

Die Tastatur ist eine erste native Version:

- Nutzerprofil in der App aenderbar.
- Vorname, Nachname, Geschlecht/Anredeprofil, App-Name, formeller und persoenlicher Absender.
- Creator-Profil mit Rolle, Nische, Leistungen, Media-Kit, Social Links, Preisregel, Nutzungsrechten und Briefing-Checkliste.
- Keyboard Extension mit QWERTZ-Layout.
- Buttons: `Antwort`, `Mail`, `Termin`, `Briefing`, `Preis`, `Follow-up`, `MediaKit`, `Kurz`, `Warm`, `Profi`.
- Text wird direkt in Apple Mail, Gmail, WhatsApp usw. eingefuegt, sofern Drittanbieter-Tastaturen erlaubt sind.

Noch nicht enthalten:

- echtes Gmail-Read-Only-Backend.
- iCloud CalDAV.
- echte Thread-Erkennung aus Mail.

## Xcode Schritte

1. Xcode installieren.
2. `ios/MailReplyDesk.xcodeproj` oeffnen.
3. Target `MailReplyDesk` auswaehlen.
4. Unter `Signing & Capabilities` dein Team setzen.
5. Target `MailReplyKeyboard` auswaehlen.
6. Dort ebenfalls dasselbe Team setzen.
7. App Group pruefen: `group.com.jonasgamper.mailreplydesk`.
8. Wenn Xcode eine andere Bundle ID verlangt, Bundle IDs und App Group eindeutig anpassen.
9. Auf ein echtes iPhone builden.

## iPhone aktivieren

1. App einmal starten.
2. Profil in der App einstellen.
3. iPhone Einstellungen oeffnen.
4. `Allgemein > Tastatur > Tastaturen`.
5. `Mail Reply Keyboard` hinzufuegen.
6. Optional `Vollen Zugriff erlauben`.

## Kostenloser Apple-ID-Test

Wenn Xcode mit `App Groups` oder Signing wegen einer Personal Team-ID blockiert, zuerst den Free-Account-Modus verwenden:

```bash
ios/scripts/use-free-personal-team-mode.sh
```

Details stehen in [FREE_ACCOUNT_TEST.md](FREE_ACCOUNT_TEST.md). Der Modus ist fuer den ersten Tastaturtest gedacht. Fuer Profil-Sync zwischen Settings-App und Tastatur danach wieder App Groups aktivieren:

```bash
ios/scripts/use-app-group-mode.sh
```

## Wichtige Grenze

Apple erlaubt einer Custom Keyboard Extension nicht, automatisch den kompletten Apple-Mail-Verlauf zu lesen. Die Tastatur kann Text einfuegen und begrenzten Textkontext sehen. Fuer perfekte Mailantworten braucht sie spaeter das Backend, das freigegebene Mailkonten Read-Only liest.

Quellen:

- https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard
- https://developer.apple.com/documentation/uikit/uiinputviewcontroller
- https://developer.apple.com/documentation/xcode/configuring-app-groups
