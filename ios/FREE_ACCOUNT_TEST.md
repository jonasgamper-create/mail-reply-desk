# iPhone-Test mit kostenloser Apple-ID

Ziel: Die Tastatur zuerst auf dem iPhone starten, auch wenn kein Apple Developer Program vorhanden ist.

## Warum dieser Modus existiert

Das Projekt nutzt normalerweise App Groups, damit die Container-App ihr Profil mit der Keyboard Extension teilen kann.
App Groups sind eine Apple-Capability und koennen bei einer kostenlosen Personal Team-ID blockieren.

Damit der erste iPhone-Test trotzdem moeglich ist, gibt es einen Free-Account-Modus:

- App Groups werden aus den Entitlements entfernt.
- Die Tastatur kann lokal mit Default-Profil starten.
- Profil-Sync zwischen Settings-App und Tastatur ist in diesem Modus nicht garantiert; Profil-Export/Import per Copy/Paste bleibt nutzbar.
- Automatisches Senden bleibt weiterhin nicht vorhanden.

## Free-Account-Modus aktivieren

```bash
ios/scripts/use-free-personal-team-mode.sh
```

Danach in Xcode:

1. `ios/MailReplyDesk.xcodeproj` oeffnen.
2. Target `MailReplyDesk` und `MailReplyKeyboard` jeweils auf deine Personal Team-ID setzen.
3. Auf echtes iPhone builden.
4. Tastatur in iOS Einstellungen aktivieren.

Wenn Xcode bereits mit Apple-ID angemeldet ist, kann der Build und die Installation auch automatisch laufen:

```bash
ios/scripts/build-install-personal-team.sh
```

## App-Group-Modus wiederherstellen

```bash
ios/scripts/use-app-group-mode.sh
```

Diesen Modus verwenden, wenn App Groups in Xcode sauber funktionieren oder ein Apple Developer Program vorhanden ist.
