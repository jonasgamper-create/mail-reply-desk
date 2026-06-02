# AB-Optimierungen fuer Creator Mail Desk

Stand: 02.06.2026

## Kurzfazit

Die beste erste Version ist keine neue Mail-App. Sie ist eine schnelle Eingabeschicht:

- iPhone: native Tastatur mit Creator-Schnellaktionen direkt im Antwortfeld.
- Mac: PWA als Split-Screen-Begleiter.
- Backend spaeter: Gmail/iCloud nur Read-only lesen, Entwuerfe vorbereiten, nie automatisch senden.

## A/B-Entscheidungen

| Thema | A | B | Entscheidung |
| --- | --- | --- | --- |
| Antwortauswahl | 1 perfekter Entwurf | 3 erkennbare Richtungen | B: 3 Richtungen fuer Creator-Mails, danach Volltext |
| iPhone-UX | PWA verlassen, Text kopieren | Tastatur im Mailfeld | B fuer Alltag, PWA bleibt fuer Setup |
| Mailzugriff | alle Konten anbinden | Fokusliste pro Konto | B: weniger Risiko, weniger falscher Kontext |
| Senden | automatisch senden | nur Entwurf, Nutzer bestaetigt | B zwingend |
| Creator-Anfrage | freundlich antworten | Briefing/Budget/Rechte/Timing klaeren | B: spart die meisten Rueckfragen |
| Preise | Rate sofort nennen | Preis nach Scope und Nutzungsrechten | B: keine falschen Zusagen |
| Kalender | CalDAV sofort | ICS zuerst, CalDAV spaeter | B: sicherer MVP |
| KI-Platzierung | Chatbot/Sidebar | Inline-Aktionen und Snippets | B: weniger App-Wechsel |

## P0: Eingebaute Optimierungen

- Creator-Profil mit Rolle, Nische, Leistungen, Media-Kit, Social Links.
- Kooperationen haben jetzt Preisregel, Nutzungsrechte, Briefing-Checkliste und Brand-Safety-No-Gos.
- KI-Leiste erweitert: Antwort, Briefing, Preis, Follow-up, Kuerzer, Freundlicher, Professioneller, Deutsch/Englisch.
- 3 Vorschlaege fuer Kooperationsmails:
  - Interesse + Briefing
  - Budget & Rechte
  - Kurz entscheiden
- Zusammenfassung erkennt Creator-Kontext und zeigt die Briefing-Checkliste.
- iPhone-Tastatur erweitert:
  - Antwort
  - Mail
  - Termin
  - Briefing
  - Preis
  - Follow-up
  - MediaKit
  - Kurz / Warm / Profi

## P1: Naechste sinnvolle Optimierungen

- Backend fuer `info@jonnyandlinda.com` mit Gmail OAuth.
- Nur `gmail.readonly` fuer Lesen, optional spaeter `gmail.compose` fuer echte Gmail-Entwuerfe.
- Kontaktprofil aus Absender ableiten: Vorname, Nachname, Firma, Du/Sie, letzte Beziehung.
- Media-Kit-Link und Social Links in Settings sauber hinterlegen.
- Follow-up als Kalender-/Reminder-Entwurf statt nur lokale Liste.

## P2: Erst nach stabilem Test

- iCloud CalDAV fuer echte Kalenderanlage nach Bestaetigung.
- Mehrere Nutzerprofile statt nur ein Profil.
- Automatische Inbox-Triage, Labels, Priorisierung.
- CRM-/Notion-/Projektmanagement-Integrationen.

## Was bewusst nicht gebaut wird

- Kein automatisches Senden.
- Kein Vollzugriff auf beliebige Mailkonten.
- Kein Versuch, Apple Mail komplett zu ersetzen.
- Keine Preise erfinden, wenn Scope, Laufzeit oder Nutzungsrechte fehlen.
- Keine KI-Netzwerkaufrufe direkt aus der Tastatur, bevor Full-Access-Vertrauen und Backend sauber geloest sind.

## Quellen und Signale

- Superhuman: AI direkt im Inbox-Workflow, Auto-Summaries, Instant Replies, Tone Matching.
  https://superhuman.com/products/mail/plp/ai-v1
- Shortwave: AI-Assistent im Mailclient statt Copy/Paste zwischen Apps.
  https://www.shortwave.com/docs/guides/ai-assistant/
- Missive: AI mit Mail-, Kalender-, Kontakt- und Template-Kontext.
  https://missiveapp.com/docs/ai/overview
- Spark: AI ueber Mail, Anhaenge, Kalender und Meeting Notes.
  https://sparkmailapp.com/help/spark-ai/ai-assistant
- Reddit/Productivity: Drafts plus Review sind nuetzlicher als Vollautomatisierung.
  https://www.reddit.com/r/ProductivityApps/comments/1r26exs/whats_your_best_suggested_email_ai_assistant_for/
- Reddit/Productivity: Follow-ups und alles im bestehenden Gmail-Workflow sind wichtiger als getrennte Task-Systeme.
  https://www.reddit.com/r/productivity/comments/1t5yonx/gmail_managing_follow_ups_better/
- Reddit/InfluencerMarketing: Media Kit spart Rueckfragen zu Stats, Services und Rates.
  https://www.reddit.com/r/influencermarketing/comments/1q94uo8/whats_an_influencer_media_kit_and_why_it_still/
- Reddit/InfluencerMarketing: Creator nutzen Media Kits, PDFs oder Links fuer Brand Outreach.
  https://www.reddit.com/r/influencermarketing/comments/17xdt8q
- Apple Custom Keyboard: Drittanbieter-Tastaturen funktionieren systemweit nur dort, wo Host-Apps sie erlauben.
  https://developer.apple.com/documentation/uikit/configuring-a-custom-keyboard-interface
- Apple Open Access: Netzwerk/shared container brauchen Open Access.
  https://developer.apple.com/documentation/bundleresources/information-property-list/nsextension/nsextensionattributes/requestsopenaccess
- Google Gmail Scopes: moeglichst engste Scopes verwenden; `gmail.readonly` ist restricted und braucht saubere Behandlung.
  https://developers.google.com/workspace/gmail/api/auth/scopes
