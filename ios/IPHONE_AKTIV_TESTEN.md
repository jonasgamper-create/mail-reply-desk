# iPhone aktiv testen

## Ziel

Die native `Mail Reply Keyboard` Tastatur auf einem echten iPhone testen.

## Was du brauchst

- Mac mit Xcode
- iPhone
- Apple-ID
- USB-Kabel oder WLAN-Debugging
- optional Apple Developer Program, wenn App Groups und spaetere Verteilung sauber funktionieren sollen

## Schritt 1: Xcode installieren

1. App Store am Mac oeffnen.
2. `Xcode` suchen.
3. Xcode installieren.
4. Xcode einmal starten.
5. Lizenz akzeptieren und Zusatzkomponenten installieren.

## Schritt 2: Projekt oeffnen

Im Finder:

```text
ios/MailReplyDesk.xcodeproj
```

Mit Xcode oeffnen.

## Schritt 3: iPhone anschliessen

1. iPhone per Kabel verbinden.
2. Am iPhone `Diesem Computer vertrauen` bestaetigen.
3. In Xcode oben als Zielgeraet dein iPhone auswaehlen.

## Schritt 4: Signing setzen

In Xcode links das Projekt `MailReplyDesk` anklicken.

Target `MailReplyDesk`:

1. `Signing & Capabilities`
2. `Automatically manage signing` aktivieren.
3. Bei `Team` deine Apple-ID / dein Team auswaehlen.

Target `MailReplyKeyboard`:

1. `Signing & Capabilities`
2. `Automatically manage signing` aktivieren.
3. Dasselbe Team auswaehlen.

## Schritt 5: Falls App Groups Fehler machen

Wenn Xcode meldet, dass `App Groups` nicht verfuegbar oder nicht registriert sind:

Option A, beste Variante:

- Apple Developer Program verwenden.
- App Group `group.com.jonasgamper.mailreplydesk` registrieren.
- Beide Targets der App Group zuordnen.

Option B, schneller erster Test:

- App Group Capability in beiden Targets entfernen.
- Die Tastatur laeuft dann mit Standardprofil.
- Settings werden dann noch nicht sauber zwischen App und Tastatur geteilt.

## Schritt 6: App auf iPhone starten

1. In Xcode `MailReplyDesk` Scheme auswaehlen.
2. Run klicken.
3. Wenn iOS einen Entwicklerhinweis zeigt:
   - iPhone `Einstellungen > Allgemein > VPN & Geraeteverwaltung`
   - Entwickler-App vertrauen.
4. App starten.
5. Profil eintragen und speichern.

## Schritt 7: Tastatur aktivieren

Am iPhone:

1. `Einstellungen`
2. `Allgemein`
3. `Tastatur`
4. `Tastaturen`
5. `Tastatur hinzufuegen`
6. `Mail Reply Keyboard` auswaehlen.
7. Optional `Vollen Zugriff erlauben`.

## Schritt 8: In Mail testen

1. Apple Mail oder Gmail oeffnen.
2. Auf eine Mail antworten.
3. Im Eingabefeld Tastatur wechseln, Globus-Taste.
4. `Mail Reply Keyboard` auswaehlen.
5. Buttons testen:
   - `Antwort`
   - `Mail`
   - `Termin`
   - `Kurz`
   - `Freundlich`
   - `Professionell`

## Erwartung fuer den ersten Test

Die Tastatur fuegt lokale Entwurfstexte direkt ins Mailfeld ein.

Noch nicht erwartet:

- automatische Mail-Erkennung
- echter Thread-Kontext
- Gmail/iCloud Login

Dafuer braucht es das Backend.
