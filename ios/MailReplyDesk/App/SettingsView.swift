import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var store = ProfileStore()
    @StateObject private var gmail = GmailInboxViewModel()
    @State private var importText = ""
    @State private var manualContext = ""
    @State private var statusMessage = ""
    @State private var contextStatusMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Identität") {
                    TextField("Vorname", text: $store.profile.firstName)
                    TextField("Nachname", text: $store.profile.lastName)
                    Picker("Geschlecht / Anrede", selection: $store.profile.gender) {
                        Text("weiblich").tag("female")
                        Text("männlich").tag("male")
                        Text("neutral").tag("neutral")
                    }
                    TextField("App-Name", text: $store.profile.appName)
                    TextField("Formeller Absender", text: $store.profile.formalSender)
                    TextField("Persönlicher Absender", text: $store.profile.casualSender)
                    Text("Beispiele: Frau Hiller, Linda, Herr Mustermann, Max Mustermann.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Mailkonten") {
                    VStack(alignment: .leading) {
                        Text("Eigene Mailkonten").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $store.profile.mailAccounts)
                            .frame(minHeight: 86)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Button("Gmail Suche daraus erstellen") {
                        store.profile.gmailQuery = store.profile.suggestedGmailQuery
                        saveAndCopyProfile(message: "Mailkonten gespeichert. Gmail Suche aktualisiert.")
                    }
                    Text("Ein Konto pro Zeile. Diese Liste wird mit dem Profil exportiert und macht die App übertragbar.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Empfangene Nachricht") {
                    VStack(alignment: .leading) {
                        Text("Mail, WhatsApp oder Verlauf").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $manualContext)
                            .frame(minHeight: 120)
                            .textInputAutocapitalization(.sentences)
                    }
                    HStack {
                        Button("Für Tastatur übernehmen") {
                            saveManualContext()
                        }
                        Button("Leeren") {
                            manualContext = ""
                            MessageContextStore.clear()
                            contextStatusMessage = "Kontext geleert."
                        }
                    }
                    .buttonStyle(.bordered)
                    Text("Besser als Copy/Paste: Nachricht oder Mail markieren, Teilen öffnen und Mail Reply Desk wählen. Danach kombiniert die Tastatur diese Nachricht mit deinen Stichworten im Antwortfeld.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if !contextStatusMessage.isEmpty {
                        Text(contextStatusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Schreibstil") {
                    TextEditor(text: $store.profile.styleVoice)
                        .frame(minHeight: 90)
                }

                Section("Lernregeln") {
                    TextEditor(text: $store.profile.learningNotes)
                        .frame(minHeight: 110)
                    Text("Diese Regeln nutzt die Tastatur für Ton, Länge und Entscheidung: Antwort, Kooperation, Preis, Termin, Follow-up oder Absage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Creator-Profil") {
                    TextField("Rolle", text: $store.profile.roleTitle)
                    TextField("Nische", text: $store.profile.niche)
                    VStack(alignment: .leading) {
                        Text("Leistungen").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $store.profile.services)
                            .frame(minHeight: 80)
                    }
                    TextField("Media-Kit URL", text: $store.profile.mediaKitURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    VStack(alignment: .leading) {
                        Text("Social Links").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $store.profile.socialLinks)
                            .frame(minHeight: 80)
                    }
                }

                Section("Kooperationen") {
                    VStack(alignment: .leading) {
                        Text("Preisregel").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $store.profile.rateCardNote)
                            .frame(minHeight: 80)
                    }
                    VStack(alignment: .leading) {
                        Text("Nutzungsrechte").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $store.profile.usageRightsPolicy)
                            .frame(minHeight: 80)
                    }
                    VStack(alignment: .leading) {
                        Text("Briefing-Checkliste").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $store.profile.briefingChecklist)
                            .frame(minHeight: 110)
                    }
                    VStack(alignment: .leading) {
                        Text("Brand-Safety No-Gos").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $store.profile.brandSafetyNoGos)
                            .frame(minHeight: 80)
                    }
                    Text("Diese Felder steuern die Tastaturbuttons Briefing, Preis, Follow-up und MediaKit.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Profil teilen") {
                    ShareLink("Profil teilen", item: ProfileStore.exportString(for: store.profile))
                    Button("Speichern und für Tastatur kopieren") {
                        saveAndCopyProfile()
                    }
                    VStack(alignment: .leading) {
                        Text("Profil importieren").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $importText)
                            .frame(minHeight: 110)
                    }
                    Button("Importieren") {
                        if store.importProfile(from: importText) {
                            importText = ""
                            statusMessage = "Profil importiert."
                        } else {
                            statusMessage = "Import nicht erkannt."
                        }
                    }
                    Button("Creator Standard laden") {
                        store.resetToDefault()
                        saveAndCopyProfile(message: "Creator Standard gespeichert.")
                    }
                    Button("Linda Vorlage laden") {
                        store.loadLindaPreset()
                        saveAndCopyProfile(message: "Linda Vorlage gespeichert.")
                    }
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Gmail Read-only") {
                    TextField("Backend URL", text: $store.profile.backendURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Gmail Suche", text: $store.profile.gmailQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    LabeledContent("Status") {
                        Text(gmail.statusBadge)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(gmail.isConnected ? .green : .secondary)
                    }

                    HStack {
                        Button("Status") {
                            store.save()
                            Task { await gmail.checkStatus(baseURL: store.profile.backendURL) }
                        }
                        Button("Verbinden") {
                            store.save()
                            gmail.openOAuth(baseURL: store.profile.backendURL)
                        }
                        Button("Mails laden") {
                            store.save()
                            Task { await gmail.loadMessages(baseURL: store.profile.backendURL, query: activeGmailQuery) }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(gmail.isLoading)

                    if gmail.isLoading {
                        ProgressView()
                    }

                    Text(gmail.statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if !gmail.importedSubject.isEmpty {
                        Text("Übernommen: \(gmail.importedSubject)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !gmail.importedContextPreview.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Kontext für Tastatur")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(gmail.importedContextPreview)
                                .font(.footnote)
                                .lineLimit(4)
                            Button("Kontext erneut kopieren") {
                                gmail.copyImportedContextToClipboard()
                            }
                        }
                    }

                    Text("Am iPhone hier die Mac-IP eintragen, z.B. http://192.168.1.20:8787. OAuth am besten zuerst am Mac verbinden; das iPhone lädt danach über Read-only.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(gmail.messages) { message in
                        Button {
                            store.save()
                            Task { await gmail.importThread(message, baseURL: store.profile.backendURL) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(message.subjectLine)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(message.senderLine)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if !message.previewLine.isEmpty {
                                    Text(message.previewLine)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                                if gmail.selectedThreadId == message.threadId {
                                    Text("Für Tastatur bereit")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }

                Section("Tastatur aktivieren") {
                    Text("1. iPhone Einstellungen öffnen\n2. Allgemein > Tastatur > Tastaturen\n3. Mail Reply Keyboard hinzufügen\n4. Vollen Zugriff erlauben, damit Profil und übernommene Threads aus App/Share Extension gelesen werden können")
                        .font(.footnote)
                    Text(ProfileStore.isAppGroupAvailable ? "Geteilte Einstellungen aktiv." : "Free-Testmodus: Speichern kopiert das Profil für die Tastatur. Dafür in iOS bei der Tastatur Vollen Zugriff erlauben.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link("Apple Hinweis zu Tastaturen", destination: URL(string: "https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard")!)
                }
            }
            .navigationTitle(store.profile.appName.isEmpty ? "Mail Reply Desk" : store.profile.appName)
            .toolbar {
                Button("Speichern") {
                    saveAndCopyProfile()
                }
            }
        }
    }

    private func saveAndCopyProfile(message: String = "Gespeichert. Profil ist für die Tastatur kopiert.") {
        store.save()
        UIPasteboard.general.string = ProfileStore.exportString(for: store.profile)
        statusMessage = message
    }

    private func saveManualContext() {
        let trimmed = manualContext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            contextStatusMessage = "Kein Kontext eingegeben."
            return
        }
        MessageContextStore.save(trimmed)
        contextStatusMessage = "Kontext übernommen. Jetzt Antwortfeld öffnen und Tastatur nutzen."
    }

    private var activeGmailQuery: String {
        let query = store.profile.gmailQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? UserProfile.default.gmailQuery : query
    }
}

#Preview {
    SettingsView()
}
