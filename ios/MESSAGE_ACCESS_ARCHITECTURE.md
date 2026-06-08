# Message Access Architecture

Ziel: Die Tastatur soll im Alltag schnell schreiben. Echter Zugriff auf Nachrichten darf nicht in der Keyboard Extension versteckt werden, sondern muss explizit und nachvollziehbar passieren.

## P0: Tastatur ohne Kontozugriff

Status: in der Keyboard Extension umgesetzt.

- `Auto`, `Privat`, `Arbeit` als sichtbarer Modus.
- Privat-Layout für WhatsApp/DM/Alltag ohne `3x`; Fokus auf direkte natürliche Antworten.
- Arbeitslayout mit `3x` als Vorlagen-Menü, nicht als eingefügter Drei-Entwürfe-Block.
- Arbeit-Layout für Mail, Kollegen, Kooperationen und Kunden.
- `Check` erzeugt im Privatmodus Antwortvorschläge und im Arbeitsmodus eine kurze Ableitung: Modus, Intention, Stil, Antwortlogik, Kontext.
- Kurze getippte Stichworte werden intern als Stichworte markiert und zu ganzen Sätzen umformuliert.
- `Übersetz.` erzeugt eine Antwort in der jeweils anderen Sprache mit gleichem Kontext.
- Lernlogik: Nutzung von `Kurz`, `Warm/Freundlich`, `Klar/Profi` wird lokal gezählt und beeinflusst bevorzugte Antworten.
- Kein automatisches Senden.

Grenze: Die Tastatur sieht nur den Text im aktuellen Eingabefeld, kurze System-Kontexte und optional Clipboard bei Vollzugriff. Sie kann WhatsApp- oder Mail-Verläufe nicht frei auslesen.

## P1: Share Extension für perfekten Kontext

Status: als `MailReplyShare` Extension umgesetzt.

Eine Share Extension nimmt bewusst geteilten Text entgegen:

1. Linda markiert oder teilt eine Mail, WhatsApp-Nachricht oder DM.
2. Sie wählt `Mail Reply Desk`.
3. Die App speichert den Text lokal als letzten Kontext.
4. Die Tastatur liest diesen Kontext und erstellt eine passende Antwort.

Technische Umsetzung:

- iOS Share Extension mit `NSExtensionActivationSupportsText`.
- Speicherung über lokalen Context Store, wenn möglich.
- Clipboard-Fallback mit `Mail Reply Desk Context`, damit der kostenlose iPhone-Test ohne App Group funktioniert.
- Kontext-Daten lokal halten, automatisch nach kurzer Zeit löschen.
- Keine Senderechte, keine heimliche Hintergrundüberwachung.

Warum das wichtig ist: Diese Lösung ist deutlich näher an echter Nachrichtenerkennung, bleibt aber kontrolliert und App-Store-konform.

## P2: Mail-/Kalender-Backend

Status: lokales Gmail Read-only Backend in `backend/` angelegt. Die iOS-App hat zusätzlich eine optionale `KI Backend URL`, damit ein späterer Entwurfsdienst lokale Tastaturentwürfe verbessern kann.

Gmail / Google Workspace:

- `gmail.readonly` zum Lesen von Nachrichten.
- `gmail.compose` nur falls echte Gmail-Entwürfe erstellt werden sollen.
- Keine `gmail.send`-Rechte.
- Startpunkt: `backend/gmail-readonly-server.mjs`.
- Login: `http://127.0.0.1:8787/auth/google`.
- Nachrichten: `http://127.0.0.1:8787/gmail/messages?max=10`.

KI-Entwürfe:

- Separates Feld `KI Backend URL` in den iPhone-Einstellungen.
- Die Tastatur erzeugt zuerst sofort einen lokalen Entwurf.
- Wenn eine KI-URL gesetzt ist und voller Tastaturzugriff aktiv ist, sendet die Tastatur Kontext, Profil und lokalen Entwurf an diesen Endpunkt.
- Die KI-Antwort ersetzt den lokalen Entwurf nur, wenn der Cursor noch direkt hinter demselben Entwurf steht.
- Keine automatische Sendefunktion.

iCloud:

- Mail über IMAP mit app-spezifischem Passwort.
- Kalender zuerst als `.ics`; später CalDAV nur nach Bestätigung.

WhatsApp:

- Private WhatsApp-App bietet keinen sauberen API-Zugriff auf normale Chats.
- Offizieller Zugriff geht über WhatsApp Business Platform / Cloud API mit Webhooks.
- Das ist für private Chats meist zu schwergewichtig und kann eine eigene Business-Nummer erfordern.

## Sicherheitsregeln

- Draft-only: nie automatisch senden.
- Zugriff sichtbar erklären.
- Token verschlüsselt speichern, nie im Frontend.
- Audit-Log: Konto verbunden, Nachricht gelesen, Entwurf erzeugt.
- Sensitive Inhalte im Keyboard ignorieren: Passwörter, TAN, OTP, 2FA, Kreditkarten.
- Kontext nach Nutzung löschen oder mit kurzer TTL speichern.

## Quellen

- Apple App Extension Keys: `NSExtensionActivationSupportsText`
- Google Gmail API Scopes: `gmail.readonly`, `gmail.compose`
- WhatsApp Business Platform / Cloud API: eingehende Nachrichten nur per Webhook/API, nicht aus der privaten WhatsApp-App
