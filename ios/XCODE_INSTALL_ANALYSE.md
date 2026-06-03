# Xcode- und iPhone-Testanalyse

Stand: 03.06.2026

## Exakte Zusammenfassung

Das Projekt ist technisch vorbereitet. Die PWA ist live, das iOS-Projekt existiert, die native Tastatur ist implementiert und GitHub Actions baut beide iOS-Targets erfolgreich auf einem Apple-Runner.

Der lokale Mac hat aktuell aber nur die Apple Command Line Tools installiert. Es fehlt das vollstaendige Xcode mit `iphoneos`- und `iphonesimulator`-SDK. Deshalb kann lokal noch kein iPhone-Build gestartet werden.

Der Blocker ist nicht der Code, sondern die Xcode-Installation mit Apple-ID-Login. Direkte Downloads alter Xcode-Versionen benoetigen eine Apple-ID-Anmeldung. Ohne Eingabe von Apple-ID und 2FA kann die Installation nicht vollautomatisch abgeschlossen werden.

## Lokaler Befund

- macOS: Sequoia 15.7.8
- Mac: MacBookPro16,3, Intel Core i5, 8 GB RAM
- freier Speicher: ca. 112 GB
- installiert: `Xcodes.app`
- installiert: Xcodes CLI unter `/tmp/xcodes-cli/xcodes`
- aktiv: `/Library/Developer/CommandLineTools`
- fehlt: `/Applications/Xcode.app`
- fehlt: iPhoneOS SDK
- fehlt: iPhoneSimulator SDK

## GitHub-Befund

- Repository: `jonasgamper-create/mail-reply-desk`
- Branch: `main`
- PWA-Deploy: erfolgreich
- iOS Xcode Check: erfolgreich
- Letzte relevante Commits:
  - `Optimize creator mail workflows`
  - `Add remote iOS build check`
  - `Add free Apple ID iPhone test mode`

Damit ist belegt: Das iOS-Projekt ist grundsaetzlich buildbar. Der lokale Mac braucht nur noch die passende Xcode-Installation und danach Signing.

## Kritische A/B-Entscheidungen

| Thema | A | B | Entscheidung |
| --- | --- | --- | --- |
| Xcode installieren | Mac App Store | Xcodes App / Apple Developer Downloads | B, weil aktuelle App-Store-Versionen auf diesem macOS nicht passend sein koennen |
| Xcode-Version | neueste Xcode-Version | Xcode 26.3 fuer macOS 15.7.8 | B, weil Apple Xcode 26.3 fuer macOS Sequoia 15.6+ listet |
| iPhone-Test | sofort mit App Groups | zuerst Free-Account-Modus ohne App Groups, falls Signing blockiert | B als sicherer erster Test, A danach fuer Profil-Sync |
| Verteilung | TestFlight/App Store | lokale Installation ueber Xcode | B, weil kein bezahlter Apple Developer Account vorhanden ist |
| Sideloading | AltStore/Sideloadly/AppDB | offizieller Xcode Personal-Team-Build | B, weniger Sicherheits- und Signing-Risiko |
| iPhone-UX | PWA aus Mail heraus oeffnen | Native Custom Keyboard Extension | B, weil sie direkt im Mail-Textfeld nutzbar ist |
| Mail-Kontext | Tastatur liest Mail automatisch | Backend liest freigegebene Konten read-only | B, weil Apple-Tastaturen keinen kompletten Mailverlauf lesen duerfen |
| AI in Tastatur | direkte KI-Netzwerkaufrufe | lokale Schnellbausteine zuerst, Backend spaeter | B, weil Full-Access/Datenschutz sonst zu frueh riskant wird |

## Empfehlung

### P0: Jetzt richtig

1. Xcode 26.3 ueber Xcodes App oder Apple Developer Downloads installieren.
2. Xcode einmal starten, Lizenz und Zusatzkomponenten akzeptieren.
3. `ios/MailReplyDesk.xcodeproj` oeffnen.
4. iPhone per USB anschliessen und vertrauen.
5. Signing fuer `MailReplyDesk` und `MailReplyKeyboard` setzen.
6. Wenn App Groups blockieren: `ios/scripts/use-free-personal-team-mode.sh` ausfuehren und zuerst ohne Profil-Sync testen.
7. Tastatur am iPhone aktivieren und in Apple Mail testen.

### P1: Danach produktiv machen

1. Settings-App so nutzen, dass Name, Anrede, Signatur und Creator-Profil fuer jede Person anpassbar sind.
2. Creator-Schnellaktionen in der Tastatur scharf testen: Antwort, Briefing, Preis, Follow-up, MediaKit, Kurz, Warm, Profi.
3. Mac-PWA weiter als Split-Screen-Arbeitsplatz verwenden.
4. Erst wenn der manuelle iPhone-Workflow sitzt: Gmail Read-Only OAuth fuer `info@jonnyandlinda.com` bauen.

### P2: Erst nach stabilem Alltagstest

1. Gmail-Thread-Zusammenfassung.
2. Drei echte Entwuerfe aus Mailverlauf plus Stichworten.
3. ICS-Terminvorbereitung fuer iCloud Kalender.
4. CalDAV erst spaeter, weil Login, App-spezifisches Passwort und Fehlerfaelle mehr Komplexitaet erzeugen.

## Was ich bewusst nicht installiert habe

- kein Homebrew nur fuer diesen Zweck
- kein `mas` CLI fuer den Mac App Store
- kein AltStore
- kein Sideloadly
- kein AppDB
- keine Signing-Hacks

Begruendung: Diese Tools loesen den Kernblocker nicht sauberer als Xcode, erhoehen aber Sicherheits-, Wartungs- oder Account-Risiken. Fuer einen privaten iPhone-Test ist Xcode mit Apple-ID der direkteste kostenlose Weg.

## Grenzen der iPhone-Tastatur

Eine iOS Custom Keyboard Extension kann systemweit Text einfuegen und begrenzten Textkontext ueber das aktuelle Eingabefeld sehen. Sie darf aber nicht automatisch den gesamten Apple-Mail-Verlauf auslesen. Einige Apps koennen Drittanbieter-Tastaturen ausserdem deaktivieren.

Darum ist die langfristig saubere Architektur zweigeteilt:

- Tastatur: schnelle Eingabe direkt im Mailfeld.
- Backend/PWA: freigegebene Mailkonten read-only lesen, Kontext verstehen, Entwuerfe vorbereiten.

## Offene Fragen

1. Welche iOS-Version hat das iPhone 17 Pro genau?
2. Soll der erste echte iPhone-Test bei Signing-Problemen im Free-Account-Modus ohne App-Groups laufen? Empfehlung: ja.
3. Soll spaeter nur `info@jonnyandlinda.com` angebunden werden oder direkt eine Fokusliste mit mehreren Konten? Empfehlung: zuerst nur ein Konto.

## Quellen

- Apple Xcode Support: https://developer.apple.com/support/xcode/
- Apple Mitgliedschaften: https://developer.apple.com/de/support/compare-memberships/
- Apple iOS Capabilities: https://developer.apple.com/help/account/reference/supported-capabilities-ios/
- Apple Custom Keyboard Interface: https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface
- Xcodes App: https://github.com/XcodesOrg/XcodesApp
- Xcodes CLI: https://github.com/XcodesOrg/xcodes
