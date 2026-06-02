# Architektur und Entscheidungen

## Entscheidung für Version 1

Für Linda ohne Apple Developer Account ist eine PWA der richtige Start:

- läuft auf Mac im Browser
- kann auf dem iPhone per Safari zum Home-Bildschirm hinzugefügt werden
- ist ohne App Store, TestFlight und Xcode nutzbar
- lässt sich auf einen anderen Rechner kopieren
- speichert Setup, Brand-Profile und Follow-ups lokal

Eine echte iPhone-Systemtastatur ist erst Phase 4. Sie braucht eine native iOS-App mit Custom Keyboard Extension und Signierung.

## Zielbetrieb

### iPhone

Das Ziel ist eine echte zusätzliche iPhone-Tastatur. Sie erscheint über die Globus-Taste wie andere Drittanbieter-Tastaturen und enthält Lindas KI-Leiste:

- `Antwort`
- `Kürzer`
- `Freundlicher`
- `Professioneller`
- `Deutsch/Englisch`

Diese Tastatur kann Text in Mail, Instagram, WhatsApp, LinkedIn und andere Apps einfügen. Sie darf aber nicht automatisch senden. Für KI und Mailverlauf braucht sie entweder Daten aus der Container-App oder ein Backend.

HTML oder eine reine PWA können keine systemweite iPhone-Tastatur bereitstellen. Dafür ist ein natives iOS-Projekt nötig.

### Mac

Am Mac ist keine native Tastatur nötig. Der sinnvollste Workflow ist eine Web-App als rechte Split-Screen-Spalte:

- links: Apple Mail, Gmail, Outlook, Instagram oder Browser
- rechts: Linda Social Desk
- Verlauf/Stichworte rein
- Entwurf kopieren
- Linda prüft und sendet manuell

Das ist schneller, stabiler und vermeidet unnötige Systemrechte auf dem Mac.

## Fokusstrategie

Die App wird bewusst nicht als universeller Mail-Agent gebaut. Sie arbeitet nur mit Lindas freigegebener Mail-Liste. Das reduziert Integrationsaufwand, Fehlerquellen und Datenschutzrisiko.

Aktuelle Fokusliste:

- `info@jonnyandlinda.com`: Google Workspace / Gmail via Wix
- `linda.hiller@skinfit.eu`: Provider noch offen
- `hillerlinda@icloud.com`: iCloud Mail
- `lindas.contentfactory@gmail.com`: Gmail

Primärer Kalender: iCloud. Die beste erste Umsetzung ist `ICS zuerst`: Die App erzeugt eine Kalenderdatei und Linda bestätigt. CalDAV-Zugriff auf iCloud wird erst später ergänzt, wenn freie Zeiten automatisch geprüft werden sollen.

## Versand und Installation

### PWA / Webseite

Für Mac und Laptop kann der Projektordner verschickt oder über ein privates Git-Repo geteilt werden. Für iPhone muss die PWA über HTTPS gehostet werden, damit Safari sie sauber als Home-Screen-App installieren kann.

### Native iPhone-Tastatur

Für die echte Tastatur gibt es realistische Verteilungswege:

- TestFlight für private Beta
- Ad Hoc für registrierte Geräte
- App Store, falls später öffentlich

Alle drei Wege setzen praktisch ein Apple Developer Program voraus. Ohne Developer Account kann man auf einem eigenen Gerät mit Xcode entwickeln/testen, aber das ist nicht geeignet, um Linda zuverlässig eine private Tastatur-App zu schicken.

## Was aktuell integriert ist

- KI-Leiste: `Antwort`, `Kürzer`, `Freundlicher`, `Professioneller`, `Deutsch/Englisch`
- vier Mail-Identitäten
- automatische Wahl von `Linda`, `Linda Hiller` oder `Frau Hiller`
- Verlauf-Zusammenfassung
- Antwortgenerator für Mails und DMs
- Ton-Presets: freundlich, kurz, luxuriös, verbindlich, entschuldigend
- Brand-Profile
- Angebots-/Kooperationsantworten
- Caption-Generator
- Hashtag- und Hook-Generator
- Content-Kalender
- Vorlagen für Briefings, Absagen und Kooperationen
- Follow-up-Liste
- Export/Import der Konfiguration
- Diktat-Fallback: Apple-Tastatur-Diktat oder Web Speech API, wenn verfügbar

## Cloud, lokal oder hybrid

### Lokal im Browser

Vorteile:

- keine Maildaten verlassen das Gerät
- sofort nutzbar
- keine API-Kosten

Nachteile:

- keine perfekte KI-Qualität
- kein echter Zugriff auf Mailkonten
- Übersetzung und Stil-Imitation bleiben begrenzt

Empfehlung: gut für MVP und Workflow-Test.

### Cloud-KI über Backend

Vorteile:

- beste Textqualität
- Mailverläufe können sauber zusammengefasst werden
- Stilprofile und Brand-Kontext können zuverlässig genutzt werden
- iPhone und Mac nutzen dieselbe Logik

Nachteile:

- Mailinhalte werden an ein Backend und an einen KI-Anbieter übertragen
- Datenschutz, Zugriffsschutz und Kosten müssen sauber gelöst werden
- API-Key darf nicht im Frontend liegen

Empfehlung: beste Produktivversion, aber nur mit eigenem Backend.

### Lokale KI auf dem Mac

Vorteile:

- sehr privat
- keine externen KI-Kosten

Nachteile:

- auf dem iPhone nur indirekt nutzbar
- Qualität meist schwächer als starke Cloud-Modelle
- Mac muss laufen, wenn das iPhone den Dienst nutzt

Empfehlung: nur sinnvoll, wenn Datenschutz wichtiger ist als beste Antwortqualität.

### Hybrid

Vorteile:

- lokale Vorverarbeitung und sensible Regeln
- Cloud nur für finalen Entwurf
- später erweiterbar

Nachteile:

- mehr Entwicklungsaufwand

Empfehlung für Linda: Hybrid mit Cloud-KI über Backend, aber strikt `draft-only`.

## Mail-Anbindungen

Die vier Konten brauchen vermutlich unterschiedliche Wege:

- `lindas.contentfactory@gmail.com`: Gmail API mit OAuth
- `hillerlinda@icloud.com`: IMAP mit app-spezifischem Passwort
- `linda.hiller@skinfit.eu`: abhängig vom Anbieter, vermutlich Microsoft 365, Google Workspace oder IMAP
- `info@jonnyandlinda.com`: abhängig vom Mailhost, meistens IMAP/SMTP oder Provider-API

Wichtig: Das System soll Mails lesen und Entwürfe erstellen, aber niemals automatisch senden.

## Native App und Tastatur

Eine native iOS-Version hätte:

- iOS-App für Setup, Auth, Verlauf und Entwürfe
- Custom Keyboard Extension für systemweite Eingabe
- App Group für geteilte Daten zwischen App und Tastatur
- Open Access für Netzwerkzugriff der Tastatur
- klare Privacy-Hinweise, weil Tastaturdaten sensibel sind
- österreichisches QWERTZ-Layout als Nachbau der Apple-Tastatur
- eigene KI-Leiste über der Tastatur

Einschränkungen:

- Drittanbieter-Tastaturen bekommen nicht beliebig Mailverlauf
- sichere Eingabefelder blockieren Drittanbieter-Tastaturen
- die originale Apple-Diktierfunktion kann nicht einfach kopiert werden
- die österreichische Apple-Tastatur kann nur nachgebaut, nicht übernommen werden

## Nächste Umsetzungsschritte

1. PWA auf HTTPS deployen und Linda auf Mac/iPhone testen lassen.
2. Mac-Split-Screen-Workflow mit echten Mails testen.
3. 20 bis 50 echte Antworten werden als Stilbeispiele ergänzt.
4. Backend bauen: Auth, Mail-Import, KI-Generierung, Audit-Log.
5. Apple Developer Account anlegen.
6. Native iOS-App mit Keyboard Extension bauen.
7. TestFlight oder Ad Hoc für Linda bereitstellen.
