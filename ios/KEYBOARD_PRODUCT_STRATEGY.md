# Keyboard Product Strategy

Stand: 2026-06-08

## Ziel

Die Tastatur soll im Alltag wie eine schlanke Erweiterung der Apple-Tastatur wirken:

- QWERTZ / Österreich-nahes Layout.
- Buchstaben ungefähr in Apple-Keyboard-Größe.
- Keine breite Textleiste mit vielen sichtbaren Befehlen.
- Kontext oben nur als kleine Steuerung: `Auto`, `Privat`, `Arbeit`, Sprache, Anrede.
- Schreibaktionen kompakt über Symbole und Menüs.
- Niemals automatisch senden.

## Recherche-Fazit

Apple setzt für Custom Keyboards harte Grenzen:

- Eine Tastatur-Extension läuft isoliert und hat ohne `Allow Full Access` keinen Netzwerkzugriff.
- Mit `Allow Full Access` steigt die Datenschutzverantwortung stark.
- Drittanbieter-Tastaturen bekommen keinen direkten Zugriff auf Mikrofon/Diktat.
- Die Tastatur kann nicht beliebig Apple Mail oder WhatsApp im Hintergrund auslesen.
- Distribution läuft über eine installierte, signierte iOS-App, nicht über einen einfachen Weblink.

Aus Produktmustern bei Superhuman, Shortwave, Spark und Missive ergibt sich:

- Ein kleiner AI-Einstiegspunkt ist besser als viele permanente Buttons.
- Entwürfe müssen kontextbezogen, aber prüfbar bleiben.
- Stiländerungen funktionieren am besten als Menü/Command-Palette: kürzer, freundlicher, professioneller, übersetzen.
- Für Mails spart echter Verlauf am meisten Zeit. Dafür braucht es Read-only OAuth oder bewusstes Teilen per Share Extension.
- Bei Chat/WhatsApp ist kurze natürliche Antwortlogik besser als E-Mail-Format mit Grußformel.

## Aktuelle Umsetzung

Die Tastatur nutzt jetzt:

- Kopfzeile: Kontext-Menü, Sprache, Anrede, Profil-Initialen, Tastaturwechsel.
- Aktionsleiste: intelligente Antwort, Zusage, Absage, Stilmenü `Aa`, weitere Aktionen `...`.
- Stilmenü: Kürzer, Freundlicher, Professioneller, Übersetzen.
- Weitere Aktionen: 3 Entwürfe, Analyse, Termin, Preis/Budget, Kooperation, Briefing, Follow-up, MediaKit, Signatur.
- Größere Buchstaben und ruhigere Key-Hintergründe.
- Kompaktere Gesamthöhe.

## P0

Für den täglichen Test muss funktionieren:

- Tastatur auf echtem iPhone installieren.
- In Mail `Mail Reply Mail` waehlen; in WhatsApp `Mail Reply Chat` waehlen.
- Oben `Auto`, `Privat` oder `Arbeit` setzen.
- Im Textfeld Stichworte oder kopierten Kontext haben.
- `↩` für intelligente Antwort nutzen.
- `Aa` für Stiländerung nutzen.
- `...` für Spezialfälle nutzen.

## P1

Als nächstes bringt am meisten Gewinn:

- Share Extension stabil testen: markierten Mail-/WhatsApp-Text bewusst an die App geben.
- Gmail Read-only Backend am iPhone über WLAN testen.
- App-Settings optisch straffen, damit Profilanlage schneller ist.
- Kleine Testfälle einbauen: private Frage, geschäftliche Kooperation, Termin, Preis, Absage.

## P2

Später, sobald der Nutzen klar ist:

- Apple Developer Program für TestFlight/Public Link.
- Backend mit echter KI statt lokaler Regeln.
- Read-only Gmail OAuth produktionsfähig mit sicherer Token-Speicherung.
- iCloud Kalender zuerst per ICS, danach CalDAV nur nach Bestätigung.
- Lernlogik serverseitig und transparent: gewählte Entwürfe verbessern Stil, ohne automatische Senderechte.

## Weitergabe

Es gibt drei realistische Wege:

1. GitHub Pages / PWA:
   - Jeder mit Link kann die Web-App öffnen.
   - Änderungen sind sofort live.
   - Keine native iPhone-Tastatur.

2. Xcode Free Personal Team:
   - Kostenlos.
   - Direktes Testen auf eigenen Geräten.
   - Nicht sinnvoll für viele andere Personen.
   - Regelmäßiges Neuinstallieren kann nötig sein.

3. Apple Developer Program + TestFlight:
   - Beste Lösung für Weitergabe per Link.
   - Nutzer installieren über TestFlight.
   - Änderungen kommen als neue Builds.
   - Native Tastatur ist sauber verteilbar.

## Empfehlung

Für heute:

1. Native Tastatur lokal auf dem iPhone testen.
2. UX der kompakten Menüs prüfen.
3. Drei echte Situationen testen: WhatsApp privat, Mail Kooperation, Mail Termin.
4. Danach entscheiden, ob TestFlight nötig ist.

Für "jeder mit Link kann es nutzen" ist TestFlight oder App Store technisch notwendig, wenn es eine echte iPhone-Tastatur sein soll. GitHub allein reicht nur für die Web-App.
