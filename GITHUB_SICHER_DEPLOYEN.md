# GitHub sicher und kostenlos deployen

## Ziel

Die PWA soll ohne Kosten online erreichbar sein, damit sie am Mac und iPhone getestet werden kann.

Empfehlung: GitHub Pages mit öffentlichem Repository.

Wichtig: Auf GitHub Free ist GitHub Pages für öffentliche Repositories verfügbar. Wenn der Code privat bleiben soll, ist GitHub Pages je nach Plan nicht kostenlos. In diesem Projekt dürfen deshalb keine Passwörter, Tokens, Kundendaten oder echten Mailinhalte ins Repository.

## Was bereits vorbereitet ist

- `.github/workflows/pages.yml`: GitHub Actions Deployment für Pages.
- `.nojekyll`: verhindert Jekyll-Verarbeitung.
- `manifest.webmanifest`: PWA-Metadaten.
- `sw.js`: Offline-/Cache-Datei.

## Schritt 1: GitHub Repo erstellen

1. Auf GitHub einloggen.
2. Neues Repository erstellen.
3. Name z.B. `mail-reply-desk`.
4. Repository auf `Public` stellen, wenn es kostenlos über GitHub Pages laufen soll.
5. Kein README auf GitHub erzeugen, weil das Projekt bereits lokale Dateien hat.

## Schritt 2: Lokal verbinden und pushen

Im Projektordner:

```bash
git init
git add .
git commit -m "Initial Mail Reply Desk PWA"
git branch -M main
git remote add origin https://github.com/DEIN-USER/mail-reply-desk.git
git push -u origin main
```

Wenn `git init` bereits ausgeführt wurde, startet man bei `git add .`.

## Schritt 3: GitHub Pages aktivieren

1. GitHub Repository öffnen.
2. `Settings` öffnen.
3. `Pages` öffnen.
4. Unter `Build and deployment` die Quelle `GitHub Actions` wählen.
5. Zurück zu `Actions`.
6. Workflow `Deploy static PWA to GitHub Pages` prüfen.

Die URL sieht danach ungefähr so aus:

```text
https://DEIN-USER.github.io/mail-reply-desk/
```

## Schritt 4: iPhone installieren

1. URL in Safari am iPhone öffnen.
2. Teilen-Menü öffnen.
3. `Zum Home-Bildschirm` wählen.
4. App starten.

## Sicherheitsregeln

- Keine API-Keys in `app.js`, `index.html` oder GitHub Secrets für die PWA.
- Keine echten Mailinhalte committen.
- Keine Passwörter committen.
- Keine OAuth Refresh Tokens committen.
- Keine `.env` committen.
- Mail-Logins gehören später in ein Backend.

## Warum das Backend nicht auf GitHub Pages geht

GitHub Pages kann nur statische Dateien hosten. Gmail OAuth, iCloud CalDAV/IMAP, Token-Speicherung und sichere API-Aufrufe brauchen ein Backend.

Kostenlose Backend-Option für den MVP:

- Cloudflare Workers Free Plan.
- Für private Tests reicht das typischerweise aus.
- Trotzdem: Limits beachten und keine Kostenfunktionen aktivieren.

## Gmail-Hinweis

`gmail.readonly` ist ein Gmail OAuth Scope. Google kann für sensitive/restricted Scopes App-Verifizierung verlangen. Für einen internen/privaten Test mit eigenen Konten ist das anders zu bewerten als für eine öffentliche App.

Für den MVP gilt:

- nur `gmail.readonly`
- keine Senderechte
- keine `gmail.modify`
- keine `https://mail.google.com/`
- keine automatische Verarbeitung außerhalb der freigegebenen Konten
