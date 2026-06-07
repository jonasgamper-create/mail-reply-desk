# Linda Social Desk

Private PWA für Linda Hiller: Mail-/DM-Antwortentwürfe, Stilprofil, Brand-Profile, Content-Hilfen, Follow-ups und Content-Kalender.

## Aktueller Fokus

Die App ist jetzt auf Creator-/Influencer-Mailworkflows optimiert:

- Kooperationsanfragen erkennen
- Gmail Read-only verbinden und passende Threads direkt übernehmen
- 3 Richtungen vorschlagen: Briefing, Budget/Rechte, kurze Entscheidung
- Media-Kit, Social Links, Leistungen und Brand-Safety-Regeln im Profil speichern
- Budget, Deliverables, Nutzungsrechte, Timing und Freigaben automatisch abfragen
- auf iPhone als native Tastatur mit Creator-Schnellbuttons testen

Die Recherche- und A/B-Entscheidungen stehen in [AB_OPTIMIERUNGEN.md](AB_OPTIMIERUNGEN.md).

## Start auf dem Mac

```bash
python3 -m http.server 4173
```

Dann im Browser öffnen:

```text
http://localhost:4173
```

## Mac als Split-Screen-Begleiter

Für Lindas Mac ist die App als Web-Begleiter gedacht:

1. Mail, Gmail, Outlook oder Instagram im linken Fenster öffnen.
2. `Linda Social Desk` im rechten Fenster öffnen.
3. Bei Gmail das lokale Read-only-Backend verbinden und passende Mails laden.
4. Mail anklicken, Verlauf automatisch übernehmen lassen und einen der 3 Entwürfe wählen.
5. Entwurf kopieren und in Mail/DM einfügen.

Der wichtigste Grund: Am Mac bleibt Linda in ihrem normalen Mail-Workflow, während die App dauerhaft daneben offen ist. Automatisch senden ist bewusst nicht eingebaut.

## Gmail ohne Copy/Paste

Für `info@jonnyandlinda.com` und spätere Gmail-/Google-Workspace-Konten gibt es ein lokales Read-only-Backend:

```bash
scripts/setup-gmail-readonly.sh
```

Danach in der App im Mail-Bereich:

1. `Status` prüfen.
2. `Verbinden` für Google OAuth öffnen.
3. `Mails laden` drücken.
4. Mail auswählen.

Die App übernimmt dann Betreff, Absender, Verlauf, offene Fragen, Timing/Budget-Hinweise und erstellt direkt 3 Antwortvorschläge. Scope bleibt ausschließlich:

```text
https://www.googleapis.com/auth/gmail.readonly
```

Es gibt keine Senderechte.

## Fokusliste

Die App ist auf Lindas konkrete Mailkonten begrenzt:

- `info@jonnyandlinda.com` → Google Workspace / Gmail via Wix
- `linda.hiller@skinfit.eu` → Provider noch klären
- `hillerlinda@icloud.com` → iCloud Mail
- `lindas.contentfactory@gmail.com` → Gmail

Primärer Kalender ist iCloud. Termine werden zuerst als `.ics` vorbereitet, damit Linda kontrolliert, bevor etwas in den Kalender kommt.

## Auf andere Geräte schicken

Für Mac und Laptop reicht ein ZIP des Projektordners oder ein privates Git-Repo. Danach im Ordner starten:

```bash
python3 -m http.server 4173
```

Für iPhone als Web-App muss die App über HTTPS erreichbar sein. Praktisch sind:

- Cloudflare Pages
- Netlify
- GitHub Pages
- eigener kleiner Server

Danach in Safari öffnen und `Zum Home-Bildschirm` wählen.

## GitHub Pages Deployment

Empfehlung für den ersten Online-Test: GitHub Pages.

Im Projekt ist bereits `.github/workflows/pages.yml` vorbereitet. Vorgehen:

1. Neues GitHub-Repo erstellen, z.B. `mail-reply-desk`.
2. Dieses Projekt auf den Branch `main` pushen.
3. In GitHub unter `Settings > Pages` die Quelle `GitHub Actions` wählen.
4. Nach dem Push läuft die Action automatisch.
5. Die App ist danach unter `https://<github-user>.github.io/<repo-name>/` erreichbar.

Hinweis: GitHub Pages hostet die PWA nur statisch. Für echte Mail-Logins und OAuth braucht es später zusätzlich ein Backend.

## iPhone ohne Apple Developer Account

Der pragmatische Weg ist eine PWA:

1. App über eine HTTPS-Adresse öffnen.
2. In Safari teilen.
3. `Zum Home-Bildschirm` wählen.

Für das iPhone muss die App später auf HTTPS liegen, zum Beispiel Cloudflare Pages, Netlify, GitHub Pages oder ein eigener Server. Ein lokales `file://` ist für PWA, Service Worker und spätere API-Aufrufe nicht ausreichend.

## Native iPhone-Tastatur

Im Ordner `ios/` liegt jetzt ein natives iOS-Gerüst:

- Container-App für Profil/Settings
- `MailReplyKeyboard` als Custom Keyboard Extension
- geteiltes Profil per App Group
- QWERTZ-Tastatur mit Schnellbuttons für `Antwort`, `Mail`, `Termin`, `Briefing`, `Preis`, `Follow-up`, `MediaKit`, `Kurz`, `Warm`, `Profi`
- Share Extension, um markierte Mails/Nachrichten an die Tastatur zu übergeben

Öffnen:

```text
ios/MailReplyDesk.xcodeproj
```

Danach in Xcode Team/Signing setzen und auf ein iPhone builden. Details stehen in [ios/README.md](ios/README.md).

## Technische Grenze bei iOS-Tastaturen

Eine echte systemweite iPhone-Tastatur braucht eine native iOS-App mit Custom Keyboard Extension. Dafür sind Xcode, Signierung und praktisch ein Apple Developer Account nötig. Custom Keyboards haben außerdem Einschränkungen: sie laufen isoliert, brauchen für Netzwerkzugriff Open Access, bekommen nicht beliebig Mailverlauf und können die Apple-Diktierfunktion nicht wie die originale Apple-Tastatur übernehmen.

Wenn die Tastatur wirklich direkt in iPhone-Apps erscheinen soll, ist HTML/PWA nicht genug. Dann braucht es:

- native iOS-App als Container
- Keyboard Extension
- Apple Developer Account für private Installation/TestFlight/Ad Hoc
- Backend für KI und Mailverlauf
- klare Datenschutzregeln für `Allow Full Access`

Deshalb ist die Reihenfolge sinnvoll:

1. PWA als private Arbeits-App.
2. Backend für KI und Mail-Import.
3. Native iOS/Mac-App.
4. Keyboard Extension als Komfortschicht.

## KI-Modus

Aktuell gibt es zwei Modi:

- `Lokal`: erzeugt Entwürfe und Prompts ohne API-Key im Browser.
- `Backend`: sendet `{ operation, prompt, context }` an eine eigene Backend-URL und erwartet JSON mit `text`, `output`, `answer` oder `message.content`.

Kein API-Key wird im Frontend gespeichert. Das ist wichtig, weil ein Browser-Key sonst auslesbar wäre.

## Mail-Konten

Vorkonfiguriert:

- `info@jonnyandlinda.com`
- `linda.hiller@skinfit.eu`
- `hillerlinda@icloud.com`
- `lindas.contentfactory@gmail.com`

Weitere Konten können im Setup ergänzt und per Export/Import auf einen anderen Rechner übertragen werden.

## Nächster Backend-Schritt

Für echte Mailverläufe braucht es je Provider eine saubere Anbindung:

- Gmail / Google Workspace: OAuth + Gmail API
- iCloud: IMAP mit App-spezifischem Passwort
- Microsoft 365 / Outlook: Microsoft Graph
- Eigene Domains: meist IMAP/SMTP oder Provider-API

Das Backend darf weiterhin nie automatisch senden. Es soll nur lesen, zusammenfassen und Entwürfe zurückgeben.
