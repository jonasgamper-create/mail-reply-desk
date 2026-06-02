import SwiftUI

struct SettingsView: View {
    @StateObject private var store = ProfileStore()

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
                    Text("1. iPhone Einstellungen oeffnen\n2. Allgemein > Tastatur > Tastaturen\n3. Mail Reply Keyboard hinzufuegen\n4. Optional: Vollen Zugriff erlauben, wenn Backend und geteilte Einstellungen genutzt werden sollen")
                        .font(.footnote)
                    Link("Apple Hinweis zu Tastaturen", destination: URL(string: "https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard")!)
                }
            }
            .navigationTitle(store.profile.appName.isEmpty ? "Mail Reply Desk" : store.profile.appName)
            .toolbar {
                Button("Speichern") {
                    store.save()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
