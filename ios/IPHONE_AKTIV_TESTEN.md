# iPhone aktiv testen

## Ziel

Die nativen Tastaturen `Mail Reply Mail` und `Mail Reply Chat` auf einem echten iPhone testen.

## Was du brauchst

- Mac mit Xcode
- iPhone
- Apple-ID
- USB-Kabel oder WLAN-Debugging
- optional Apple Developer Program, wenn App Groups und spätere Verteilung sauber funktionieren sollen

## Schritt 1: Xcode installieren

1. App Store am Mac öffnen.
2. `Xcode` suchen.
3. Xcode installieren.
4. Xcode einmal starten.
5. Lizenz akzeptieren und Zusatzkomponenten installieren.

## Schritt 2: Projekt oeffnen

Im Finder:

```text
ios/MailReplyDesk.xcodeproj
```

Mit Xcode öffnen.

## Schritt 3: iPhone anschliessen

1. iPhone per Kabel verbinden.
2. Am iPhone `Diesem Computer vertrauen` bestätigen.
3. In Xcode oben als Zielgerät dein iPhone auswählen.

## Schritt 4: Signing setzen

In Xcode links das Projekt `MailReplyDesk` anklicken.

Target `MailReplyDesk`:

1. `Signing & Capabilities`
2. `Automatically manage signing` aktivieren.
3. Bei `Team` deine Apple-ID / dein Team auswählen.

Target `MailReplyKeyboard`:

1. `Signing & Capabilities`
2. `Automatically manage signing` aktivieren.
3. Dasselbe Team auswählen.

## Schritt 5: Falls App Groups Fehler machen

Wenn Xcode meldet, dass `App Groups` nicht verfuegbar oder nicht registriert sind:

Option A, beste Variante:

- Apple Developer Program verwenden.
- App Group `group.com.jonasgamper.mailreplydesk` registrieren.
- Beide Targets der App Group zuordnen.

Option B, schneller erster Test:

- App Group Capability in beiden Targets entfernen.
- Die Tastatur läuft dann mit Standardprofil.
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
5. `Tastatur hinzufügen`
6. Für Mail `Mail Reply Mail`, für WhatsApp `Mail Reply Chat` auswählen.
7. Optional `Vollen Zugriff erlauben`.

## Schritt 8: Kontext übernehmen

Für echte Ableitungen aus der vorherigen Nachricht:

1. In Mail, Gmail, WhatsApp oder Instagram eine Nachricht markieren.
2. `Teilen` öffnen.
3. `Mail Reply Desk` wählen.
4. Prüfen, ob `Kontext gespeichert` erscheint.
5. Zurück ins Antwortfeld wechseln.

Wenn Teilen nicht verfügbar ist:

1. Nachricht kopieren.
2. `Mail Reply Desk` App öffnen.
3. Unter `Empfangene Nachricht` einfügen.
4. `Für Tastatur übernehmen` drücken.

## Schritt 9: In Mail oder WhatsApp testen

1. Apple Mail oder Gmail oeffnen.
2. Auf eine Mail antworten.
3. Im Eingabefeld Tastatur wechseln, Globus-Taste.
4. Fuer Mail `Mail Reply Mail`, fuer WhatsApp `Mail Reply Chat` auswaehlen.
5. Oben prüfen, ob `Kontext` sichtbar ist.
6. Buttons testen:
   - `Antwort`
   - `Mail`
   - `Termin`
   - `Briefing`
   - `Preis`
   - `Follow-up`
   - `MediaKit`
   - `Kurz`
   - `Warm`
   - `Profi`
   - `Kürzer`
   - `Check`

## Erwartung fuer den ersten Test

Die Tastatur fügt Entwurfstexte direkt ins Mail- oder Chatfeld ein. Wenn `Kontext` oben sichtbar ist, wird die vorher übernommene Nachricht für die Antwortlogik verwendet.

Wichtig: Im WhatsApp-/Privatmodus gibt es kein `3x`. Im Mail-/Arbeitsmodus ist `3x` ein Vorlagen-Menü mit `Kurz`, `Freundlich` und `Professionell`; nur die ausgewählte Vorlage wird eingefügt.

Wenn bereits ein Tastaturentwurf im Textfeld steht, sollen `Kürzer`, `Freundlicher`, `Profi`, `Übersetz.`, Vorlagen und `Antwort` den vorherigen Entwurf ersetzen. Es sollen nicht mehrere Versionen untereinander entstehen.

Stichworttest: Tippe z.B. `ja morgen 18 Uhr` in das Antwortfeld und drücke `Antwort`. Erwartung: Die Stichworte werden gelöscht und durch einen natürlichen Satz ersetzt.

Noch nicht erwartet:

- automatische Hintergrund-Erkennung aus privatem WhatsApp
- automatische Hintergrund-Erkennung aus Apple Mail ohne Teilen/Gmail
- automatisches Senden

Dafür braucht es bewusst verbundenen Zugriff, z.B. Gmail Read-only Backend oder Share Extension. Automatisches Senden bleibt absichtlich deaktiviert.
