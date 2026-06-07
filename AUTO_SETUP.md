# Automatisches Setup

Dieses Projekt kann lokal fast komplett automatisch eingerichtet werden. Zwei Schritte brauchen trotzdem eine bewusste Anmeldung:

- GitHub: Login für Push ins Repository.
- Google: OAuth-Freigabe für Gmail Read-only.

## GitHub Push

```bash
scripts/setup-github-and-push.sh
```

Das Skript:

1. installiert GitHub CLI lokal in `.tools/bin`, falls `gh` nicht vorhanden ist.
2. startet den GitHub Login.
3. richtet Git-Credentials ein.
4. pusht die lokalen Commits.

Nur Installation ohne Login:

```bash
scripts/setup-github-and-push.sh --install-only
```

## Gmail Read-only Backend

```bash
scripts/setup-gmail-readonly.sh
```

Das Skript:

1. erstellt `backend/.env`, falls es fehlt.
2. öffnet Google Cloud Credentials, falls Client-ID/Secret fehlen.
3. startet danach den lokalen Backend-Server.
4. öffnet `http://127.0.0.1:8787/auth/google`.

Wichtig: Der verwendete Scope ist nur:

```text
https://www.googleapis.com/auth/gmail.readonly
```

Es gibt keine Senderechte.

## iPhone Build/Installation

```bash
ios/scripts/build-install-personal-team.sh
```

Danach App einmal starten und die Tastatur in iOS aktivieren.
