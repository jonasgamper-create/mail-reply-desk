# Mail Reply Desk Backend

Lokales Backend für Gmail Read-only. Es liest freigegebene Gmail-/Google-Workspace-Mails und gibt sie als JSON an die App weiter. Es sendet keine Mails.

## Start

1. In Google Cloud einen OAuth Client für `Web application` erstellen.
2. Redirect URI setzen:

```text
http://127.0.0.1:8787/oauth/google/callback
```

3. `.env.example` nach `.env` kopieren und ausfüllen.
4. Server starten:

```bash
cd backend
npm start
```

5. Im Browser öffnen:

```text
http://127.0.0.1:8787/auth/google
```

6. Nach Login testen:

```text
http://127.0.0.1:8787/gmail/messages?max=10
```

Weitere Endpunkte:

```text
GET /gmail/status
GET /gmail/messages?max=10&q=to:info@jonnyandlinda.com newer_than:30d
GET /gmail/messages/:id
GET /gmail/threads/:id
```

`/gmail/threads/:id` liefert den vollständigen Verlauf als `contextText`, damit die Web-App ohne Copy/Paste einen Antwortkontext übernehmen kann.

## Scopes

Aktuell wird nur dieser Scope verwendet:

```text
https://www.googleapis.com/auth/gmail.readonly
```

Nicht enthalten:

- `gmail.send`
- SMTP
- automatisches Senden

## Fokusfilter

Der Standardfilter steht in `.env`:

```text
GMAIL_FOCUS_QUERY=to:info@jonnyandlinda.com newer_than:30d
```

Beispiele:

```text
to:info@jonnyandlinda.com newer_than:30d
from:agentur newer_than:90d
label:inbox newer_than:14d
```

## Sicherheit

- Token liegen lokal in `backend/.local/google-token.json`.
- Die Datei ist nicht für Git gedacht.
- Für Produktion müssen Tokens verschlüsselt gespeichert werden.
- Nur Read-only verwenden, bis Linda explizit echte Gmail-Entwürfe will.
- CORS ist standardmäßig nur für lokale Entwicklung und GitHub Pages freigegeben.
