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
- Empfangene Nachrichten können in der App, über Gmail Read-only oder über die Share Extension als Kontext übernommen werden.
- Gmail Read-only Sektion in der App: Status, Verbinden, Mails laden, Thread für Tastatur übernehmen.
- Separate optionale KI Backend URL für bessere Entwürfe, ohne Gmail-Read-only oder Senderechte zu vermischen.
- Vorname, Nachname, Geschlecht/Anredeprofil, App-Name, formeller und persönlicher Absender.
- Creator-Profil mit Rolle, Nische, Leistungen, Media-Kit, Social Links, Preisregel, Nutzungsrechten und Briefing-Checkliste.
- Keyboard Extension mit kompaktem QWERTZ-Layout, `ABC`, `123` und Apple-ähnlicheren Buchstabentasten.
- Kompakte Kopfzeile mit Kontext-Menü `Auto/Privat/Arbeit`, Sprache, Anrede, Profil-Initialen bzw. `Kontext`-Status und Tastaturwechsel.
- Kleine Aktionsleiste statt großer Textbuttons: intelligente Antwort, Zusage, Absage, Stilmenü `Aa`, weitere Aktionen `...`.
- Stilmenü: `Kürzer`, `Freundlicher`, `Professioneller`, `Übersetzen`.
- Im Arbeitsmodus ist `3x` ein Vorlagen-Menü: `Kurz`, `Freundlich`, `Professionell`; nur die ausgewählte Vorlage wird eingefügt.
- Im WhatsApp-/Privatmodus ist `3x` entfernt; dort liegt der Fokus auf natürlicher Antwort, Ja/Nein, Kurz, Warm, Klar, Treffen und Später.
- `Check` erzeugt im Privatmodus konkrete Antwortvorschläge und im Arbeitsmodus eine kurze Ableitung aus Kontext, Stil und Antwortlogik.
- Wenn ein erzeugter Entwurf am Cursor steht, ersetzen `Kürzer`, `Freundlicher`, `Professioneller`, `Übersetzen`, Vorlagen und `Antwort` den vorherigen Entwurf statt ihn darunter zu stapeln.
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
7. In Mail/WhatsApp das Antwortfeld öffnen, `Mail Reply Keyboard` wählen und `Antwort`, Vorlage oder `Check` tippen.

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

Fuer den Nachmittags-Test mit Simulator-Preflight und automatischer iPhone-Erkennung:

```bash
ios/scripts/afternoon-preflight.sh
```

Der genaue Testablauf steht in [AFTERNOON_IPHONE_TEST.md](AFTERNOON_IPHONE_TEST.md).

## iPhone aktivieren

1. App einmal starten.
2. Profil in der App einstellen.
3. iPhone Einstellungen öffnen.
4. `Allgemein > Tastatur > Tastaturen`.
5. `Mail Reply Keyboard` hinzufügen.
6. Optional `Vollen Zugriff erlauben`.

## Kontext aus Mail oder WhatsApp übernehmen

Beste iPhone-Route ohne Hintergrundzugriff:

1. Empfangene Mail, WhatsApp-Nachricht oder DM markieren.
2. `Teilen` öffnen.
3. `Mail Reply Desk` wählen.
4. Die Share Extension zeigt `Kontext gespeichert`.
5. Zurück ins Antwortfeld wechseln.
6. `Mail Reply Keyboard` öffnen.
7. Oben muss `Kontext` erscheinen.
8. In WhatsApp `Antwort`, `Ja`, `Nein`, `Kurz`, `Warm`, `Klar` oder `Check` nutzen. In Mail zusätzlich `3x` als Vorlagen-Menü nutzen.

Alternativ kann der Kontext in der App unter `Empfangene Nachricht` eingefügt oder über `Gmail Read-only > Mails laden` übernommen werden.

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

Die aktuelle Produktstrategie für die kompakte iPhone-Tastatur, Distribution und P0/P1/P2 steht in [KEYBOARD_PRODUCT_STRATEGY.md](KEYBOARD_PRODUCT_STRATEGY.md).

## Weitergabe per Link

GitHub Pages kann die Web-App live ausliefern. Eine native iPhone-Tastatur kann iOS aber nicht direkt von einem GitHub-Link installieren. Dafür braucht es immer eine signierte iOS-App:

- kostenlos lokal: Xcode Free Personal Team, sinnvoll für eigene Geräte;
- teilbar per Link: Apple Developer Program mit TestFlight;
- öffentlich: App Store.

## Wichtige Grenze

Apple erlaubt einer Custom Keyboard Extension nicht, automatisch den kompletten Apple-Mail- oder WhatsApp-Verlauf zu lesen. Die Tastatur kann Text einfügen und begrenzten Textkontext sehen. Für perfekte Antworten nutzt die App deshalb bewusst freigegebenen Kontext über Gmail Read-only, die Share Extension oder die App-Einstellung `Empfangene Nachricht`.

Apple erlaubt Drittanbieter-Tastaturen außerdem keinen direkten Start der System-Diktierfunktion. Der Button `Diktat` wechselt deshalb zur nächsten Tastatur; dort kann die Apple-Diktierfunktion genutzt werden.

Quellen:

- https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard
- https://developer.apple.com/documentation/uikit/uiinputviewcontroller
- https://developer.apple.com/documentation/xcode/configuring-app-groups
