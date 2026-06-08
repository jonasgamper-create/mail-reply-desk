# Mac Desktop Mail Assist

## Aktueller Stand

Die bestehende Web-App ist die Mac-Desktop-Oberflaeche:

- Split-Screen neben Apple Mail, Gmail, Outlook oder WhatsApp Web.
- `Mail Reply Mail` Preset fuer geschaeftliche E-Mail-Antworten.
- `Mail Reply Chat` Preset fuer kurze private Chat-Antworten.
- Gmail Read-only kann echte Threads ueber das lokale Backend uebernehmen.
- Keine Senderechte, nur Entwurf und Kopieren.

## Warum noch kein echtes Apple-Mail-Plugin

Ein Plugin direkt in Apple Mail ist technisch kein iPhone-Keyboard, sondern eine macOS-App mit MailKit Extension. Das ist ein eigener Xcode-Ausbau:

1. macOS Container-App erstellen.
2. MailKit Extension Target hinzufuegen.
3. Entitlement `com.apple.developer.mail-client-extension` aktivieren.
4. App signieren und lokal in Apple Mail aktivieren.
5. Erst lesen, zusammenfassen und Entwurf vorbereiten; nie automatisch senden.

## Empfohlene Reihenfolge

P0 bleibt die Desktop-Weboberflaeche, weil sie sofort funktioniert und alle Mail-Clients parallel unterstuetzt.

P1 ist ein lokaler Mac-Menueleisten-Wrapper, der die Web-App als immer sichtbares Seitenfenster oeffnet.

P2 ist die echte Apple-MailKit-Extension, sobald ein Apple Developer Account und die genaue Mail-App-Integration fix sind.
