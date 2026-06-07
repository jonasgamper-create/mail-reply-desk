# Mail Reply Desk Backend

Lokales Backend fuer Gmail Read-only. Es liest freigegebene Gmail-/Google-Workspace-Mails und gibt sie als JSON an die App weiter. Es sendet keine Mails.

## Start

1. In Google Cloud einen OAuth Client fuer `Web application` erstellen.
2. Redirect URI setzen:

```text
http://127.0.0.1:8787/oauth/google/callback
```

3. `.env.example` nach `.env` kopieren und ausfuellen.
4. Server starten:

```bash
cd backend
npm start
```

5. Im Browser oeffnen:

```text
http://127.0.0.1:8787/auth/google
```

6. Nach Login testen:

```text
http://127.0.0.1:8787/gmail/messages?max=10
```

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
- Die Datei ist nicht fuer Git gedacht.
- Fuer Produktion muessen Tokens verschluesselt gespeichert werden.
- Nur Read-only verwenden, bis Linda explizit echte Gmail-Entwuerfe will.
