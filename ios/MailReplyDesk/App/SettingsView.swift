import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var store = ProfileStore()
    @State private var importText = ""
    @State private var statusMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Nutzerprofil") {
                    TextField("Vorname", text: $store.profile.firstName)
                    TextField("Nachname", text: $store.profile.lastName)
                    Picker("Geschlecht / Anrede", selection: $store.profile.gender) {
                        Text("weiblich").tag("female")
                        Text("maennlich").tag("male")
                        Text("neutral").tag("neutral")
                    }
                    TextField("App-Name", text: $store.profile.appName)
                }

                Section("Absender") {
                    TextField("Formeller Absender", text: $store.profile.formalSender)
                    TextField("Persoenlicher Absender", text: $store.profile.casualSender)
                    Text("Beispiele: Frau Hiller, Linda, Herr Mustermann, Max Mustermann.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Schreibstil") {
                    TextEditor(text: $store.profile.styleVoice)
                        .frame(minHeight: 90)
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
                    Button("Speichern und fuer Tastatur kopieren") {
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

                Section("Backend spaeter") {
                    TextField("Backend URL", text: $store.profile.backendURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Aktuell erzeugt die Tastatur lokale Entwuerfe. Fuer echte Mail-Kontexte wird spaeter das Read-Only-Mail-Backend verbunden.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Tastatur aktivieren") {
                    Text("1. iPhone Einstellungen oeffnen\n2. Allgemein > Tastatur > Tastaturen\n3. Mail Reply Keyboard hinzufuegen\n4. Bei Bedarf Vollen Zugriff erlauben")
                        .font(.footnote)
                    Text(ProfileStore.isAppGroupAvailable ? "Geteilte Einstellungen aktiv." : "Free-Testmodus: Speichern kopiert das Profil fuer die Tastatur. Dafuer in iOS bei der Tastatur Vollen Zugriff erlauben.")
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

    private func saveAndCopyProfile(message: String = "Gespeichert. Profil ist fuer die Tastatur kopiert.") {
        store.save()
        UIPasteboard.general.string = ProfileStore.exportString(for: store.profile)
        statusMessage = message
    }
}

#Preview {
    SettingsView()
}
