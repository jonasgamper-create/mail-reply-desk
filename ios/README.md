# Native iPhone Tastatur

Dieses iOS-Gerüst enthält:

- `MailReplyDesk`: Container-App mit Settings.
- `MailReplyKeyboard`: iOS Custom Keyboard Extension.
- `MailReplyShare`: Share Extension für bewusst geteilte Nachrichtentexte.
- Profil in der App, im Free-Testmodus mit stabilem Tastatur-Default; geteilter Sync später über App Group.

## Aktueller Stand

Die Tastatur ist eine native Testversion für den direkten iPhone-Einsatz:

- Nutzerprofil in der App änderbar.
- Profil kann kopiert, geteilt und per Copy/Paste importiert werden.
- Gmail Read-only Sektion in der App: Status, Verbinden, Mails laden, Thread für Tastatur übernehmen.
- Vorname, Nachname, Geschlecht/Anredeprofil, App-Name, formeller und persönlicher Absender.
- Creator-Profil mit Rolle, Nische, Leistungen, Media-Kit, Social Links, Preisregel, Nutzungsrechten und Briefing-Checkliste.
- Keyboard Extension mit kompaktem QWERTZ-Layout, `ABC`, `123` und `Tools`.
- Sichtbarer Modus `Auto`, `Privat`, `Arbeit`.
- Adaptive Tools: privat mit `Danke`, `Sorry`, `Treffen`, `Später`, `Übersetz.`; Arbeit mit `Termin`, `Preis`, `Koop`, `Briefing`, `Follow-up`, `Rechnung`, `MediaKit`.
- `Check` erzeugt eine kurze Ableitung aus Kontext, Stil und Antwortlogik.
- Umschalter für `DE/EN` und `Du/Sie` direkt in der Tastatur.
- Text wird direkt in Apple Mail, Gmail, WhatsApp usw. eingefügt, sofern Drittanbieter-Tastaturen erlaubt sind.

Noch nicht enthalten:

- iCloud CalDAV.
- private WhatsApp-Hintergrundlesung.
- automatisches Senden.

## Gmail am iPhone

1. Am Mac Gmail OAuth verbinden:

```bash
scripts/setup-gmail-readonly.sh
```

2. Für das iPhone im gleichen WLAN starten:

```bash
scripts/start-phone-backend.sh
```

3. Eine ausgegebene `iPhone Backend URL` in der iPhone-App unter `Gmail Read-only > Backend URL` eintragen.
4. In der iPhone-App `Status` prüfen.
5. `Mails laden` drücken.
6. Mail antippen. Der Thread ist danach für die Tastatur bereit.
7. In Mail/WhatsApp das Antwortfeld öffnen, `Mail Reply Keyboard` wählen und `Antwort`, `3x` oder `Check` tippen.

## Xcode Schritte

1. Xcode installieren.
2. `ios/MailReplyDesk.xcodeproj` öffnen.
3. Target `MailReplyDesk` auswählen.
4. Unter `Signing & Capabilities` dein Team setzen.
5. Target `MailReplyKeyboard` auswählen.
6. Dort ebenfalls dasselbe Team setzen.
7. App Group pruefen: `group.com.jonasgamper.mailreplydesk`.
8. Wenn Xcode eine andere Bundle ID verlangt, Bundle IDs und App Group eindeutig anpassen.
9. Auf ein echtes iPhone builden.

Oder lokal automatisch bauen und installieren:

```bash
ios/scripts/build-install-personal-team.sh
```

## iPhone aktivieren

1. App einmal starten.
2. Profil in der App einstellen.
3. iPhone Einstellungen öffnen.
4. `Allgemein > Tastatur > Tastaturen`.
5. `Mail Reply Keyboard` hinzufügen.
6. Optional `Vollen Zugriff erlauben`.

## Kostenloser Apple-ID-Test

Wenn Xcode mit `App Groups` oder Signing wegen einer Personal Team-ID blockiert, zuerst den Free-Account-Modus verwenden:

```bash
ios/scripts/use-free-personal-team-mode.sh
```

Details stehen in [FREE_ACCOUNT_TEST.md](FREE_ACCOUNT_TEST.md). Der Modus ist für den ersten Tastaturtest gedacht. Für Profil-Sync zwischen Settings-App und Tastatur danach wieder App Groups aktivieren:

```bash
ios/scripts/use-app-group-mode.sh
```

## Analyse und empfohlene Installationsroute

Die aktuelle Analyse zum lokalen Xcode-Blocker, zur empfohlenen Xcode-Version und zu den A/B-Entscheidungen steht in [XCODE_INSTALL_ANALYSE.md](XCODE_INSTALL_ANALYSE.md).

Die Architektur für Nachrichtenzugriff, Share Extension, Gmail Read-only und WhatsApp-Grenzen steht in [MESSAGE_ACCESS_ARCHITECTURE.md](MESSAGE_ACCESS_ARCHITECTURE.md).

## Wichtige Grenze

Apple erlaubt einer Custom Keyboard Extension nicht, automatisch den kompletten Apple-Mail-Verlauf zu lesen. Die Tastatur kann Text einfügen und begrenzten Textkontext sehen. Für perfekte Mailantworten nutzt die App deshalb das Gmail Read-only Backend oder die Share Extension.

Apple erlaubt Drittanbieter-Tastaturen außerdem keinen direkten Start der System-Diktierfunktion. Der Button `Diktat` wechselt deshalb zur nächsten Tastatur; dort kann die Apple-Diktierfunktion genutzt werden.

Quellen:

- https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard
- https://developer.apple.com/documentation/uikit/uiinputviewcontroller
- https://developer.apple.com/documentation/xcode/configuring-app-groups
