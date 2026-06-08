# Nachmittag: iPhone Test

Stand: 2026-06-08

## Ziel

Heute Nachmittag soll die native Tastatur auf dem echten iPhone installiert und in Mail/WhatsApp getestet werden.

## Vor dem Anschliessen

1. iPhone entsperren.
2. USB-Kabel direkt am Mac anschliessen.
3. Falls am iPhone gefragt wird: `Diesem Computer vertrauen`.
4. Falls am Mac/Xcode gefragt wird: Pairing/Developer Mode bestaetigen.

## Automatischer Ablauf

Im Projektordner ausfuehren:

```bash
ios/scripts/afternoon-preflight.sh
```

Der Script macht automatisch:

1. Xcode-Version pruefen.
2. Simulator bauen, installieren, starten und Screenshot schreiben.
3. Verbundenes iPhone suchen.
4. Wenn iPhone online ist: Device-Build mit Team-ID bauen.
5. App auf dem iPhone installieren.

Wenn kein iPhone online ist, endet der Script sauber mit Hinweis. Das ist unterwegs/Remote normal.

## Nach der Installation am iPhone

1. App `Mail Reply Desk` einmal oeffnen.
2. Optional Profil einstellen oder Linda Vorlage laden.
3. `Speichern` tippen.
4. iPhone Einstellungen oeffnen.
5. `Allgemein > Tastatur > Tastaturen > Neue Tastatur hinzufuegen`.
6. Fuer Mail `Mail Reply Mail`, fuer WhatsApp `Mail Reply Chat` waehlen.
7. Die gewaehlte Tastatur antippen.
8. `Vollen Zugriff erlauben` aktivieren.

## Test 1: WhatsApp privat

In WhatsApp oder Notizen eingeben:

```text
Hast du morgen kurz Zeit auf einen Kaffee?
```

Tastatur verwenden:

- oben `Auto` oder `Privat`;
- `↩` tippen.

Erwartung:

- kurze natuerliche Antwort;
- keine Mail-Grußformel;
- kein `Beste Gruesse`.

## Test 2: Mail Kooperation

In Mail/Notizen eingeben:

```text
Hallo Linda, wir planen eine Kampagne mit 2 Reels und 3 Stories. Koennen Sie uns bitte Ihre Preise und Verfuegbarkeit fuer Juli senden?
```

Tastatur verwenden:

- oben `Arbeit`;
- `↩` oder `... > Preis/Budget` tippen.

Erwartung:

- formelle Antwort;
- fragt Scope, Timing, Budgetrahmen, Nutzungsrechte/Usage Rights ab;
- keine automatische Zusage;
- Absender passend als formeller Sender.

## Test 3: Termin

In Mail/Notizen eingeben:

```text
Koennen wir naechste Woche einen kurzen Call zur Kampagne einplanen?
```

Tastatur verwenden:

- oben `Arbeit`;
- `... > Termin` tippen.

Erwartung:

- fragt zwei bis drei Zeitfenster ab;
- klare, kurze Terminlogik.

## Test 4: Stilmenue

Beliebigen Kontext eingeben und `Aa` testen:

- `Kuerzer`;
- `Freundlicher`;
- `Professioneller`;
- `Uebersetzen`.

Erwartung:

- Aktionen sind hinter dem Menue, nicht als grosse Leiste sichtbar;
- Tastatur bleibt kompakt.

## Bekannte iOS-Grenzen

- Native Tastatur kann nicht direkt von GitHub installiert werden.
- Native Tastatur braucht eine signierte iOS-App.
- GitHub Pages ist nur fuer die Web-App live.
- Custom Keyboard kann WhatsApp/Mail nicht heimlich im Hintergrund lesen.
- Fuer echten Mailverlauf: Share Extension oder Gmail Read-only Backend.
- Apple-Diktat kann nicht direkt in der Drittanbieter-Tastatur gestartet werden; `Dikt.` wechselt zur Apple-Tastatur.
